from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from jose import JWTError

from app.core.jwt import decode_token
from app.core.db import get_db

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/v1/auth/login")


def resolve_user_id(conn, payload: dict) -> int:
    """
    Convierte lo que venga en el token a users.id real.
    Si el token trae employee_number en sub o id, lo busca.
    """
    raw = payload.get("user_id") or payload.get("id") or payload.get("sub")

    if raw is None:
        raise ValueError("Token sin identificador")

    cur = conn.cursor(dictionary=True)
    try:
        # 1) ¿raw ya es users.id?
        try:
            raw_int = int(raw)
            cur.execute("SELECT id FROM users WHERE id = %s LIMIT 1", (raw_int,))
            row = cur.fetchone()
            if row:
                return int(row["id"])
        except Exception:
            pass

        # 2) Probar como employee_number
        cur.execute(
            "SELECT id FROM users WHERE employee_number = %s LIMIT 1",
            (str(raw),),
        )
        row = cur.fetchone()
        if row:
            return int(row["id"])

    finally:
        cur.close()

    raise ValueError("No se pudo resolver users.id desde token")


def get_current_user(
    token: str = Depends(oauth2_scheme),
    db=Depends(get_db),
) -> dict:
    if not token:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token requerido",
            headers={"WWW-Authenticate": "Bearer"},
        )

    try:
        payload = decode_token(token)
    except JWTError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token inválido o expirado",
            headers={"WWW-Authenticate": "Bearer"},
        )

    try:
        user_id = resolve_user_id(db, payload)
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=str(e),
            headers={"WWW-Authenticate": "Bearer"},
        )

    cur = db.cursor(dictionary=True)
    try:
        cur.execute(
            """
            SELECT
                u.id,
                u.name,
                u.employee_number,
                u.role_id,
                u.area AS area_id,
                a.name AS area_name
            FROM users u
            LEFT JOIN areas a ON a.id = u.area
            WHERE u.id = %s
            LIMIT 1
            """,
            (user_id,),
        )
        user_row = cur.fetchone()
    finally:
        cur.close()

    if not user_row:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Usuario no encontrado",
            headers={"WWW-Authenticate": "Bearer"},
        )

    role_id = user_row.get("role_id")
    area_id = user_row.get("area_id")

    try:
        role_id = int(role_id) if role_id is not None else None
    except Exception:
        pass

    try:
        area_id = int(area_id) if area_id is not None else None
    except Exception:
        pass

    return {
        "id": int(user_row["id"]),
        "user_id": int(user_row["id"]),
        "name": user_row.get("name"),
        "employee_number": user_row.get("employee_number"),
        "role_id": role_id,
        "area_id": area_id,
        "area": (user_row.get("area_name") or "").strip(),
        "token_payload": payload,
    }

