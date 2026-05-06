# app/api/v1/user.py
from fastapi import APIRouter, Depends, HTTPException, UploadFile, File
from pathlib import Path
import uuid

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
                role_id,
                area,
                position,
                COALESCE(active, 1) AS active,
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
def delete_user(user_id: int, db=Depends(get_db), _user=Depends(get_current_user)):
    cur = db.cursor()
    try:
        cur.execute("DELETE FROM users WHERE id=%s", (user_id,))
        db.commit()

        if cur.rowcount == 0:
            raise HTTPException(status_code=404, detail="Usuario no encontrado")

        return {"message": "Usuario eliminado"}
    finally:
        cur.close()


@router.post("/{user_id}/avatar")
def upload_user_avatar(
    user_id: int,
    file: UploadFile = File(...),
    db=Depends(get_db),
    _user=Depends(get_current_user),
):
    filename = (file.filename or "").lower().strip()
    ct = (file.content_type or "").lower().strip()
    ext = Path(filename).suffix.lower()

    allowed = {".jpg", ".jpeg", ".png", ".webp", ".gif", ".jfif", ".heic", ".heif"}

    if ext == "":
        if "png" in ct:
            ext = ".png"
        elif "webp" in ct:
            ext = ".webp"
        elif "gif" in ct:
            ext = ".gif"
        else:
            ext = ".jpg"

    if (ext not in allowed) and (not ct.startswith("image/")):
        raise HTTPException(status_code=400, detail="Solo se permiten archivos de imagen.")

    cur = db.cursor(dictionary=True)
    try:
        cur.execute("SELECT id, avatar FROM users WHERE id=%s", (user_id,))
        row = cur.fetchone()
    finally:
        cur.close()

    if not row:
        raise HTTPException(status_code=404, detail="Usuario no encontrado")

    old_avatar = row.get("avatar")

    # rh_backend/uploads/avatars
    base_dir = Path(__file__).resolve().parents[3] / "uploads" / "avatars"
    base_dir.mkdir(parents=True, exist_ok=True)

    new_name = f"{user_id}_{uuid.uuid4().hex}{ext}"
    out_path = base_dir / new_name

    with out_path.open("wb") as f:
        while True:
            chunk = file.file.read(1024 * 1024)
            if not chunk:
                break
            f.write(chunk)

    public_path = f"/uploads/avatars/{new_name}"

    cur = db.cursor()
    try:
        cur.execute(
            "UPDATE users SET avatar=%s WHERE id=%s",
            (public_path, user_id),
        )
        db.commit()
    finally:
        cur.close()

    try:
        if old_avatar:
            old_avatar_clean = old_avatar.split("?")[0].strip()
            if old_avatar_clean.startswith("/uploads/avatars/"):
                old_name = Path(old_avatar_clean).name
                old_path = base_dir / old_name
                if old_path.exists() and old_path.is_file() and old_path != out_path:
                    old_path.unlink()
    except Exception as e:
        print(f"No se pudo borrar avatar anterior del usuario {user_id}: {e}")

    return {
        "avatar_url": public_path,
        "avatar": public_path,
    }