# app/api/v1/profile.py
from fastapi import APIRouter, Depends, UploadFile, File, HTTPException
from pathlib import Path
from datetime import date
from pydantic import BaseModel, EmailStr
from typing import Optional
import uuid

from app.dependencies.auth import get_current_user
from app.core.db import get_db

router = APIRouter(prefix="/profile", tags=["Profile"])


class ProfileUpdate(BaseModel):
    email: Optional[EmailStr] = None
    phone: Optional[str] = None
    birthday: Optional[date] = None


@router.get("/")
def get_my_profile(db=Depends(get_db), current_user=Depends(get_current_user)):
    with db.cursor(dictionary=True) as cur:
        cur.execute("""
            SELECT
              id, employee_number, name, email, phone,
              COALESCE(role_id, 3) AS role_id,
              area, position, avatar,
              entry_date, birthday, active, last_login
            FROM users
            WHERE id=%s
        """, (current_user["id"],))
        row = cur.fetchone()

    if not row:
        raise HTTPException(status_code=404, detail="Usuario no encontrado")

    return row


@router.put("/")
def update_my_profile(
    data: ProfileUpdate,
    db=Depends(get_db),
    current_user=Depends(get_current_user),
):
    fields, params = [], []

    if data.email is not None:
        fields.append("email=%s")
        params.append(data.email)

    if data.phone is not None:
        fields.append("phone=%s")
        params.append(data.phone)

    if data.birthday is not None:
        if current_user.get("birthday") is not None:
            raise HTTPException(
                status_code=403,
                detail="El cumpleaños ya está registrado y no se puede editar."
            )
        fields.append("birthday=%s")
        params.append(data.birthday)

    if not fields:
        return {"message": "Nada que actualizar"}

    params.append(current_user["id"])
    cur = db.cursor()
    cur.execute(f"UPDATE users SET {', '.join(fields)} WHERE id=%s", tuple(params))
    db.commit()
    cur.close()

    return {"message": "Perfil actualizado"}


@router.post("/avatar")
def upload_my_avatar(
    file: UploadFile = File(...),
    db=Depends(get_db),
    current_user=Depends(get_current_user),
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

    base_dir = Path(__file__).resolve().parents[3] / "uploads" / "avatars"
    base_dir.mkdir(parents=True, exist_ok=True)

    old_avatar = None
    with db.cursor(dictionary=True) as cur:
        cur.execute("SELECT avatar FROM users WHERE id=%s", (current_user["id"],))
        row = cur.fetchone()
        if row:
            old_avatar = row.get("avatar")

    new_name = f"{current_user['id']}_{uuid.uuid4().hex}{ext}"
    out_path = base_dir / new_name

    with out_path.open("wb") as f:
        while True:
            chunk = file.file.read(1024 * 1024)
            if not chunk:
                break
            f.write(chunk)

    public_path = f"/uploads/avatars/{new_name}"

    cur = db.cursor()
    cur.execute(
        "UPDATE users SET avatar=%s WHERE id=%s",
        (public_path, current_user["id"]),
    )
    db.commit()
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
        print(f"No se pudo borrar avatar anterior: {e}")

    return {
        "avatar_url": public_path,
        "avatar": public_path,
    }