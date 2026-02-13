from fastapi import APIRouter, Depends, HTTPException
from app.dependencies.auth import get_current_user
from app.core.db import get_db
from app.core.security import hash_password
from app.schemas.user import UserCreate, UserUpdate
from app.dependencies.roles import require_role

router = APIRouter(
    prefix="/users",
    tags=["Users"],
    dependencies=[Depends(require_role(1, 2))]
)

@router.get("/")
def list_users(db=Depends(get_db), _user=Depends(get_current_user)):
    cur = db.cursor(dictionary=True)
    try:
        cur.execute("""
            SELECT
                id,
                employee_number,
                name,
                email,
                COALESCE(role_id, 3)      AS role_id,
                area,
                position,
                COALESCE(active, 1)       AS active,
                entry_date,
                avatar,
                plant,
                curp,
                phone,
                birthday
            FROM users
            ORDER BY id DESC
        """)
        return cur.fetchall()
    finally:
        cur.close()

@router.post("/")
def create_user(user: UserCreate, db=Depends(get_db), _user=Depends(get_current_user)):
    cur = db.cursor()
    try:
        hashed = hash_password(user.password)

        cur.execute("""
            INSERT INTO users
            (employee_number, name, email, password, role_id, area, position,
             curp, phone, birthday, entry_date, plant, active)
            VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)
        """, (
            user.employee_number,
            user.name,
            user.email,
            hashed,
            user.role_id if user.role_id is not None else 3,
            user.area,
            user.position,
            user.curp,
            user.phone,
            user.birthday,
            user.entry_date,
            user.plant,
            user.active if user.active is not None else 1
        ))

        db.commit()
        return {"message": "Usuario creado correctamente"}
    finally:
        cur.close()

@router.put("/{user_id}")
def update_user(user_id: int, data: UserUpdate, db=Depends(get_db), _user=Depends(get_current_user)):
    cur = db.cursor()
    try:
        fields, params = [], []

        updates = {
            "employee_number": data.employee_number,
            "name": data.name,
            "email": data.email,
            "role_id": data.role_id,
            "area": data.area,
            "position": data.position,
            "curp": data.curp,
            "phone": data.phone,
            "birthday": data.birthday,
            "entry_date": data.entry_date,
            "plant": data.plant,
            "active": data.active,
        }

        for col, val in updates.items():
            if val is not None:
                fields.append(f"{col}=%s")
                params.append(val)

        if data.password is not None and data.password.strip() != "":
            fields.append("password=%s")
            params.append(hash_password(data.password))

        if not fields:
            return {"message": "Nada que actualizar"}

        params.append(user_id)
        cur.execute(f"UPDATE users SET {', '.join(fields)} WHERE id=%s", tuple(params))
        db.commit()

        if cur.rowcount == 0:
            raise HTTPException(status_code=404, detail="Usuario no encontrado")

        return {"message": "Usuario actualizado"}
    finally:
        cur.close()

@router.delete("/{user_id}")
def deactivate_user(user_id: int, db=Depends(get_db), _user=Depends(get_current_user)):
    """
    IMPORTANTE:
    Esto NO borra, solo desactiva (active=0).
    Si quieres borrado real, dime y lo cambio a DELETE FROM users.
    """
    cur = db.cursor()
    try:
        cur.execute("UPDATE users SET active=0 WHERE id=%s", (user_id,))
        db.commit()

        if cur.rowcount == 0:
            raise HTTPException(status_code=404, detail="Usuario no encontrado")

        return {"message": "Usuario desactivado"}
    finally:
        cur.close()
