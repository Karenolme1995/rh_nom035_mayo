from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.orm import Session
from sqlalchemy import text
from datetime import datetime, timedelta
from jose import JWTError

from app.core.db import get_db
from app.core.security import verify_password, hash_password
from app.core.jwt import create_access_token
from app.core.jwt import decode_token
from app.core.redis_client import redis_client
from app.schemas.auth import (
    LoginSchema,
    ForgotPasswordSchema,
    VerifyCodeSchema,
    ResetPasswordSchema
)

from app.core.utils import generate_code  # si no existe, te digo cómo hacerlo


router = APIRouter(prefix="/auth", tags=["Auth"])
security = HTTPBearer()



def _is_sqlalchemy_session(db) -> bool:
    # Session de SQLAlchemy tiene .execute y suele tener .commit también
    # MySQLConnection NO tiene .execute, pero sí .cursor
    return hasattr(db, "execute") and not hasattr(db, "cursor")


def _fetchone(db, sql_sa: str, params: dict, sql_mysql: str, args: tuple):
    """
    Devuelve un row (dict-like o tuple-like) compatible.
    - SQLAlchemy: retorna Row (acceso por atributo si vienen labels/columnas)
    - MySQL: retorna dict si dictionary=True
    """
    if _is_sqlalchemy_session(db):
        return db.execute(text(sql_sa), params).fetchone()

    # MySQLConnection
    cursor = db.cursor(dictionary=True)
    try:
        cursor.execute(sql_mysql, args)
        return cursor.fetchone()
    finally:
        cursor.close()


def _execute(db, sql_sa: str, params: dict, sql_mysql: str, args: tuple):
    if _is_sqlalchemy_session(db):
        db.execute(text(sql_sa), params)
        return

    cursor = db.cursor()
    try:
        cursor.execute(sql_mysql, args)
    finally:
        cursor.close()


def _commit(db):
    if hasattr(db, "commit"):
        db.commit()


# ---------------- LOGIN ----------------
@router.post("/login")
def login(data: LoginSchema, db: Session = Depends(get_db)):

    emp = (data.employee_number or "").strip()
    pwd = data.password or ""

    user = _fetchone(
        db,
        sql_sa="""
            SELECT id, employee_number, name, password, role_id, area, position, plant, avatar
            FROM users
            WHERE employee_number = :emp AND active = 1
        """,
        params={"emp": emp},
        sql_mysql="""
            SELECT id, employee_number, name, password, role_id, area, position, plant, avatar
            FROM users
            WHERE employee_number = %s AND active = 1
        """,
        args=(emp,)
    )

    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Empleado o contraseña incorrectos"
        )

    user_password = user.password if hasattr(user, "password") else user.get("password")

    # DEBUG opcional (quita después)
    # print("DEBUG emp:", emp)
    # print("DEBUG hash prefix:", str(user_password)[:4])

    if not verify_password(pwd, user_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Empleado o contraseña incorrectos"
        )

    user_id = user.id if hasattr(user, "id") else user.get("id")
    role_id = user.role_id if hasattr(user, "role_id") else user.get("role_id")

    token = create_access_token({
        "user_id": user_id,
        "role_id": role_id
    })

    redis_client.setex(token, 1800, "active")

    def _get(field):
        return getattr(user, field) if hasattr(user, field) else user.get(field)

    return {
        "access_token": token,
        "token_type": "bearer",
        "user": {
            "id": _get("id"),
            "employee_number": _get("employee_number"),
            "name": _get("name"),
            "role_id": _get("role_id"),
            "area": _get("area"),
            "position": _get("position"),
            "plant": _get("plant"),
            "avatar": _get("avatar")
        }
    }


# ---------------- LOGOUT ----------------
@router.post("/logout")
def logout(credentials: HTTPAuthorizationCredentials = Depends(security)):
    token = credentials.credentials
    redis_client.delete(token)
    return {"message": "Sesión cerrada correctamente"}


# -------- RECUPERAR CONTRASEÑA --------
@router.post("/forgot-password")
def forgot_password(data: ForgotPasswordSchema, db: Session = Depends(get_db)):

    user = _fetchone(
        db,
        sql_sa="""
            SELECT id, email
            FROM users
            WHERE employee_number = :emp AND active = 1
        """,
        params={"emp": data.employee_number},
        sql_mysql="""
            SELECT id, email
            FROM users
            WHERE employee_number = %s AND active = 1
        """,
        args=(data.employee_number,)
    )

    if not user:
        raise HTTPException(status_code=404, detail="Usuario no encontrado")

    user_email = user.email if hasattr(user, "email") else user.get("email")
    if user_email != data.email:
        raise HTTPException(status_code=404, detail="Usuario no encontrado")

    user_id = user.id if hasattr(user, "id") else user.get("id")

    code = generate_code()
    expires = datetime.utcnow() + timedelta(minutes=10)

    _execute(
        db,
        sql_sa="""
            INSERT INTO password_resets (user_id, code, expires_at, used)
            VALUES (:uid, :code, :exp, 0)
        """,
        params={"uid": user_id, "code": code, "exp": expires},
        sql_mysql="""
            INSERT INTO password_resets (user_id, code, expires_at, used)
            VALUES (%s, %s, %s, 0)
        """,
        args=(user_id, code, expires)
    )
    _commit(db)

    # Aquí luego conectamos email
    print("Código recuperación:", code)

    return {"ok": True}


# -------- VERIFICAR CÓDIGO --------
@router.post("/verify-code")
def verify_code(data: VerifyCodeSchema, db: Session = Depends(get_db)):

    reset = _fetchone(
        db,
        sql_sa="""
            SELECT pr.id
            FROM password_resets pr
            JOIN users u ON u.id = pr.user_id
            WHERE u.employee_number = :emp
              AND pr.code = :code
              AND pr.used = 0
              AND pr.expires_at > NOW()
        """,
        params={"emp": data.employee_number, "code": data.code},
        sql_mysql="""
            SELECT pr.id
            FROM password_resets pr
            JOIN users u ON u.id = pr.user_id
            WHERE u.employee_number = %s
              AND pr.code = %s
              AND pr.used = 0
              AND pr.expires_at > NOW()
        """,
        args=(data.employee_number, data.code)
    )

    if not reset:
        raise HTTPException(status_code=400, detail="Código inválido o expirado")

    return {"ok": True}


# -------- RESETEAR CONTRASEÑA --------
@router.post("/reset-password")
def reset_password(data: ResetPasswordSchema, db: Session = Depends(get_db)):

    reset = _fetchone(
        db,
        sql_sa="""
            SELECT pr.id, pr.user_id
            FROM password_resets pr
            JOIN users u ON u.id = pr.user_id
            WHERE u.employee_number = :emp
              AND pr.code = :code
              AND pr.used = 0
              AND pr.expires_at > NOW()
        """,
        params={"emp": data.employee_number, "code": data.code},
        sql_mysql="""
            SELECT pr.id, pr.user_id
            FROM password_resets pr
            JOIN users u ON u.id = pr.user_id
            WHERE u.employee_number = %s
              AND pr.code = %s
              AND pr.used = 0
              AND pr.expires_at > NOW()
        """,
        args=(data.employee_number, data.code)
    )

    if not reset:
        raise HTTPException(status_code=400, detail="Token inválido")

    reset_id = reset.id if hasattr(reset, "id") else reset.get("id")
    reset_user_id = reset.user_id if hasattr(reset, "user_id") else reset.get("user_id")

    _execute(
        db,
        sql_sa="UPDATE users SET password = :pwd WHERE id = :uid",
        params={"pwd": hash_password(data.new_password), "uid": reset_user_id},
        sql_mysql="UPDATE users SET password = %s WHERE id = %s",
        args=(hash_password(data.new_password), reset_user_id)
    )

    _execute(
        db,
        sql_sa="UPDATE password_resets SET used = 1 WHERE id = :rid",
        params={"rid": reset_id},
        sql_mysql="UPDATE password_resets SET used = 1 WHERE id = %s",
        args=(reset_id,)
    )

    _commit(db)

    return {"ok": True}


def get_current_user(credentials: HTTPAuthorizationCredentials = Depends(security)) -> dict:
    token = credentials.credentials
    try:
        payload = decode_token(token)

        user_id = payload.get("user_id") or payload.get("sub")
        role_id = payload.get("role_id")

        if not user_id:
            raise HTTPException(status_code=401, detail="Token inválido")

        return {"user_id": int(user_id), "role_id": role_id}

    except JWTError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token inválido o expirado",
        )
