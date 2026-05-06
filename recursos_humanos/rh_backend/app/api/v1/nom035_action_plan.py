# nom035_action_plan.py

import os
import mimetypes
from uuid import uuid4
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Form
from fastapi.responses import FileResponse

from app.core.db_mysql import get_mysql_conn
from app.dependencies.roles import require_role

router = APIRouter(
    prefix="/nom035-action-plans",
    tags=["NOM035 Action Plans"],
    dependencies=[Depends(require_role(1, 2))],
)

UPLOAD_DIR = "uploads/nom035_action_plans"
os.makedirs(UPLOAD_DIR, exist_ok=True)


def _row_to_dict(cursor, row):
    cols = [col[0] for col in cursor.description]
    return dict(zip(cols, row))


def _get_plan_or_404(cur, plan_id: int):
    cur.execute(
        """
        SELECT id, cycle_id, action_title
        FROM nom035_action_plans
        WHERE id = %s
        """,
        (plan_id,),
    )
    row = cur.fetchone()
    if not row:
        raise HTTPException(status_code=404, detail="Plan de acción no encontrado")
    return row


@router.get("")
def get_action_plans(cycle_id: int):
    conn = next(get_mysql_conn())
    cur = conn.cursor(dictionary=True)

    cur.execute(
        """
        SELECT
            p.id,
            p.cycle_id,
            p.department_id,
            p.department_name,
            p.risk_level,
            p.action_title,
            p.action_description,
            p.responsible_name,
            p.due_date,
            p.status,
            p.progress_percent,
            p.created_by_user_id,
            p.created_at,
            p.updated_at,
            (
                SELECT COUNT(*)
                FROM nom035_action_plan_attachments a
                WHERE a.action_plan_id = p.id
            ) AS attachments_count
        FROM nom035_action_plans p
        WHERE p.cycle_id = %s
        ORDER BY p.id DESC
        """,
        (cycle_id,),
    )

    rows = cur.fetchall()
    cur.close()

    return {"items": rows}


@router.post("")
def create_action_plan(
    cycle_id: int = Form(...),
    department_id: Optional[int] = Form(None),
    department_name: Optional[str] = Form(None),
    risk_level: Optional[str] = Form(None),
    action_title: str = Form(...),
    action_description: Optional[str] = Form(None),
    responsible_name: Optional[str] = Form(None),
    due_date: Optional[str] = Form(None),
    created_by_user_id: Optional[int] = Form(None),
):
    conn = next(get_mysql_conn())
    cur = conn.cursor()

    action_title = (action_title or "").strip()
    department_name = (department_name or "").strip() or None
    risk_level = (risk_level or "").strip() or None
    action_description = (action_description or "").strip() or None
    responsible_name = (responsible_name or "").strip() or None
    due_date = (due_date or "").strip() or None

    if not action_title:
        raise HTTPException(status_code=400, detail="El título es obligatorio")

    cur.execute(
        """
        INSERT INTO nom035_action_plans (
            cycle_id,
            department_id,
            department_name,
            risk_level,
            action_title,
            action_description,
            responsible_name,
            due_date,
            created_by_user_id
        ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
        """,
        (
            cycle_id,
            department_id,
            department_name,
            risk_level,
            action_title,
            action_description,
            responsible_name,
            due_date,
            created_by_user_id,
        ),
    )
    conn.commit()

    return {
        "success": True,
        "message": "Plan de acción creado",
        "id": cur.lastrowid,
    }


@router.put("/{plan_id}")
def update_action_plan(
    plan_id: int,
    department_name: Optional[str] = Form(None),
    risk_level: Optional[str] = Form(None),
    action_title: str = Form(...),
    action_description: Optional[str] = Form(None),
    responsible_name: Optional[str] = Form(None),
    due_date: Optional[str] = Form(None),
    status: str = Form("pendiente"),
    progress_percent: float = Form(0),
):
    conn = next(get_mysql_conn())
    cur = conn.cursor()

    _get_plan_or_404(cur, plan_id)

    action_title = (action_title or "").strip()
    department_name = (department_name or "").strip() or None
    risk_level = (risk_level or "").strip() or None
    action_description = (action_description or "").strip() or None
    responsible_name = (responsible_name or "").strip() or None
    due_date = (due_date or "").strip() or None

    valid_status = {"pendiente", "en_proceso", "completado", "cancelado"}
    if status not in valid_status:
        raise HTTPException(status_code=400, detail="Estatus inválido")

    if progress_percent < 0:
        progress_percent = 0
    if progress_percent > 100:
        progress_percent = 100

    if not action_title:
        raise HTTPException(status_code=400, detail="El título es obligatorio")

    cur.execute(
        """
        UPDATE nom035_action_plans
        SET
            department_name = %s,
            risk_level = %s,
            action_title = %s,
            action_description = %s,
            responsible_name = %s,
            due_date = %s,
            status = %s,
            progress_percent = %s
        WHERE id = %s
        """,
        (
            department_name,
            risk_level,
            action_title,
            action_description,
            responsible_name,
            due_date,
            status,
            progress_percent,
            plan_id,
        ),
    )
    conn.commit()

    return {"success": True, "message": "Plan actualizado"}
    

@router.delete("/{plan_id}")
def delete_action_plan(plan_id: int):
    conn = next(get_mysql_conn())
    cur = conn.cursor()

    _get_plan_or_404(cur, plan_id)

    cur.execute("DELETE FROM nom035_action_plans WHERE id = %s", (plan_id,))
    conn.commit()

    return {"success": True, "message": "Plan eliminado"}


@router.get("/{plan_id}/attachments")
def list_action_plan_attachments(plan_id: int):
    conn = next(get_mysql_conn())
    cur = conn.cursor()

    _get_plan_or_404(cur, plan_id)

    cur.execute(
        """
        SELECT
            id,
            action_plan_id,
            original_name,
            stored_name,
            file_path,
            mime_type,
            file_size,
            uploaded_by_user_id,
            created_at
        FROM nom035_action_plan_attachments
        WHERE action_plan_id = %s
        ORDER BY id DESC
        """,
        (plan_id,),
    )
    rows = cur.fetchall()

    items = []
    for row in rows:
        item = _row_to_dict(cur, row)
        item["download_url"] = f"/nom035-action-plans/attachments/{item['id']}/download"
        items.append(item)

    return {"items": items}


@router.post("/{plan_id}/attachments")
async def upload_action_plan_attachment(
    plan_id: int,
    file: UploadFile = File(...),
    uploaded_by_user_id: Optional[int] = Form(None),
):
    conn = next(get_mysql_conn())
    cur = conn.cursor()

    _get_plan_or_404(cur, plan_id)

    if not file.filename:
        raise HTTPException(status_code=400, detail="Archivo inválido")

    original_name = file.filename.strip()
    ext = os.path.splitext(original_name)[1]
    stored_name = f"{uuid4().hex}{ext}"
    plan_dir = os.path.join(UPLOAD_DIR, str(plan_id))
    os.makedirs(plan_dir, exist_ok=True)

    abs_path = os.path.join(plan_dir, stored_name)
    relative_path = abs_path.replace("\\", "/")

    content = await file.read()
    if not content:
        raise HTTPException(status_code=400, detail="El archivo está vacío")

    with open(abs_path, "wb") as f:
        f.write(content)

    mime_type = file.content_type or mimetypes.guess_type(original_name)[0]
    file_size = len(content)

    cur.execute(
        """
        INSERT INTO nom035_action_plan_attachments (
            action_plan_id,
            original_name,
            stored_name,
            file_path,
            mime_type,
            file_size,
            uploaded_by_user_id
        ) VALUES (%s, %s, %s, %s, %s, %s, %s)
        """,
        (
            plan_id,
            original_name,
            stored_name,
            relative_path,
            mime_type,
            file_size,
            uploaded_by_user_id,
        ),
    )
    conn.commit()

    attachment_id = cur.lastrowid

    return {
        "success": True,
        "message": "Archivo adjunto cargado",
        "id": attachment_id,
        "original_name": original_name,
        "download_url": f"/nom035-action-plans/attachments/{attachment_id}/download",
    }


@router.get("/attachments/{attachment_id}/download")
def download_action_plan_attachment(attachment_id: int):
    conn = next(get_mysql_conn())
    cur = conn.cursor()

    cur.execute(
        """
        SELECT
            id,
            original_name,
            file_path,
            mime_type
        FROM nom035_action_plan_attachments
        WHERE id = %s
        """,
        (attachment_id,),
    )
    row = cur.fetchone()
    if not row:
        raise HTTPException(status_code=404, detail="Adjunto no encontrado")

    item = _row_to_dict(cur, row)
    file_path = item["file_path"]

    if not os.path.exists(file_path):
        raise HTTPException(status_code=404, detail="Archivo físico no encontrado")

    return FileResponse(
        path=file_path,
        filename=item["original_name"],
        media_type=item["mime_type"] or "application/octet-stream",
    )


@router.delete("/attachments/{attachment_id}")
def delete_action_plan_attachment(attachment_id: int):
    conn = next(get_mysql_conn())
    cur = conn.cursor()

    cur.execute(
        """
        SELECT id, file_path
        FROM nom035_action_plan_attachments
        WHERE id = %s
        """,
        (attachment_id,),
    )
    row = cur.fetchone()
    if not row:
        raise HTTPException(status_code=404, detail="Adjunto no encontrado")

    item = _row_to_dict(cur, row)

    cur.execute(
        "DELETE FROM nom035_action_plan_attachments WHERE id = %s",
        (attachment_id,),
    )
    conn.commit()

    try:
        if item["file_path"] and os.path.exists(item["file_path"]):
            os.remove(item["file_path"])
    except Exception:
        pass

    return {"success": True, "message": "Adjunto eliminado"}