import os
import shutil
from datetime import datetime
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Form

from app.schemas.notices import NoticeUpdate

# ⚠️ Ajusta estos imports a tu proyecto real
from app.dependencies.auth import get_current_user  # debe retornar dict con role_id e id
from app.core.db import get_db                  # debe retornar conexión o cursor

router = APIRouter()

UPLOAD_DIR = os.path.join("uploads", "notices")

def require_admin_or_rh(user: dict):
    role_id = int(user.get("role_id", 0))
    if role_id not in (1, 2):
        raise HTTPException(status_code=403, detail="No autorizado (solo Admin/RH)")

@router.get("/notices/latest")
def latest_notice(plant: Optional[str] = None, db=Depends(get_db), user=Depends(get_current_user)):
    # roles 1,2,3 pueden ver
    query = """
        SELECT id, title, body, plant, active, created_by, created_at, image_url
        FROM notices
        WHERE active = 1
          AND (%s IS NULL OR plant = %s OR plant IS NULL)
        ORDER BY created_at DESC
        LIMIT 1
    """
    cur = db.cursor(dictionary=True)
    cur.execute(query, (plant, plant))
    row = cur.fetchone()
    return {"ok": True, "notice": row}

@router.get("/notices")
def list_notices(plant: Optional[str] = None, db=Depends(get_db), user=Depends(get_current_user)):
    query = """
        SELECT id, title, body, plant, active, created_by, created_at, image_url
        FROM notices
        WHERE active = 1
          AND (%s IS NULL OR plant = %s OR plant IS NULL)
        ORDER BY created_at DESC
        LIMIT 50
    """
    cur = db.cursor(dictionary=True)
    cur.execute(query, (plant, plant))
    rows = cur.fetchall()
    return {"ok": True, "items": rows}

@router.post("/notices")
def create_notice(
    title: str = Form(...),
    body: str = Form(...),
    plant: Optional[str] = Form(None),
    image: Optional[UploadFile] = File(None),
    db=Depends(get_db),
    user=Depends(get_current_user),
):
    require_admin_or_rh(user)

    image_url = None
    if image:
        os.makedirs(UPLOAD_DIR, exist_ok=True)
        safe_name = image.filename.replace(" ", "_")
        filename = f"{int(datetime.now().timestamp())}_{safe_name}"
        filepath = os.path.join(UPLOAD_DIR, filename)

        with open(filepath, "wb") as buffer:
            shutil.copyfileobj(image.file, buffer)

        image_url = f"/uploads/notices/{filename}"

    query = """
        INSERT INTO notices (title, body, plant, active, created_by, created_at, image_url)
        VALUES (%s, %s, %s, 1, %s, NOW(), %s)
    """
    cur = db.cursor()
    cur.execute(query, (title, body, plant, user.get("id"), image_url))
    db.commit()

    return {"ok": True, "message": "Notice created"}

@router.put("/notices/{notice_id}")
def update_notice(
    notice_id: int,
    payload: NoticeUpdate,
    db=Depends(get_db),
    user=Depends(get_current_user),
):
    require_admin_or_rh(user)

    fields = []
    values = []

    if payload.title is not None:
        fields.append("title=%s")
        values.append(payload.title)
    if payload.body is not None:
        fields.append("body=%s")
        values.append(payload.body)
    if payload.plant is not None:
        fields.append("plant=%s")
        values.append(payload.plant)
    if payload.active is not None:
        fields.append("active=%s")
        values.append(1 if payload.active else 0)

    if not fields:
        return {"ok": True, "message": "Nothing to update"}

    values.append(notice_id)

    query = f"UPDATE notices SET {', '.join(fields)} WHERE id=%s"
    cur = db.cursor()
    cur.execute(query, tuple(values))
    db.commit()

    return {"ok": True, "message": "Notice updated"}

@router.post("/notices/{notice_id}/image")
def update_notice_image(
    notice_id: int,
    image: UploadFile = File(...),
    db=Depends(get_db),
    user=Depends(get_current_user),
):
    require_admin_or_rh(user)

    os.makedirs(UPLOAD_DIR, exist_ok=True)
    safe_name = image.filename.replace(" ", "_")
    filename = f"{int(datetime.now().timestamp())}_{safe_name}"
    filepath = os.path.join(UPLOAD_DIR, filename)

    with open(filepath, "wb") as buffer:
        shutil.copyfileobj(image.file, buffer)

    image_url = f"/uploads/notices/{filename}"

    query = "UPDATE notices SET image_url=%s WHERE id=%s"
    cur = db.cursor()
    cur.execute(query, (image_url, notice_id))
    db.commit()

    return {"ok": True, "image_url": image_url}

@router.delete("/notices/{notice_id}")
def delete_notice(
    notice_id: int,
    db=Depends(get_db),
    user=Depends(get_current_user),
):
    require_admin_or_rh(user)

    # ✅ soft delete
    query = "UPDATE notices SET active=0 WHERE id=%s"
    cur = db.cursor()
    cur.execute(query, (notice_id,))
    db.commit()

    return {"ok": True, "message": "Notice deleted"}