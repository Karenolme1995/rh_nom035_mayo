# app/api/v1/nom035_evidence.py
import os
from uuid import uuid4
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Form
from fastapi.responses import FileResponse

from app.core.db_mysql import get_mysql_conn
from app.dependencies.roles import require_role

router = APIRouter(
    prefix="/nom035-evidences",
    tags=["NOM035 Evidences"],
    dependencies=[Depends(require_role(1, 2))],
)

UPLOAD_DIR = "uploads/nom035_evidence"
os.makedirs(UPLOAD_DIR, exist_ok=True)


def _row_to_dict(cursor, row):
    cols = [col[0] for col in cursor.description]
    return dict(zip(cols, row))


def _get_evidence_or_404(cur, evidence_id: int):
    cur.execute(
        """
        SELECT id, cycle_id, action_plan_id, file_url, file_name
        FROM nom035_evidences
        WHERE id = %s
        """,
        (evidence_id,),
    )
    row = cur.fetchone()
    if not row:
        raise HTTPException(status_code=404, detail="Evidencia no encontrada")
    return row


@router.get("/")
def get_evidences(
    cycle_id: int,
    conn=Depends(get_mysql_conn),
):
    cur = conn.cursor()
    try:
        cur.execute(
            """
            SELECT
                e.id,
                e.cycle_id,
                e.action_plan_id,
                e.evidence_type,
                e.title,
                e.file_url,
                e.file_name,
                e.uploaded_by_user_id,
                e.created_at,
                p.action_title
            FROM nom035_evidences e
            LEFT JOIN nom035_action_plans p ON p.id = e.action_plan_id
            WHERE e.cycle_id = %s
            ORDER BY e.id DESC
            """,
            (cycle_id,),
        )

        rows = cur.fetchall()
        result = [_row_to_dict(cur, row) for row in rows]
        return {"ok": True, "items": result}
    finally:
        cur.close()


@router.post("/")
async def create_evidence(
    cycle_id: int = Form(...),
    evidence_type: str = Form(...),
    title: str = Form(...),
    action_plan_id: Optional[int] = Form(None),
    uploaded_by_user_id: Optional[int] = Form(None),
    file: UploadFile = File(...),
    conn=Depends(get_mysql_conn),
):
    cur = conn.cursor()
    try:
        if not title.strip():
            raise HTTPException(status_code=400, detail="El título es obligatorio")

        ext = os.path.splitext(file.filename or "")[1]
        stored_name = f"{uuid4().hex}{ext}"
        file_path = os.path.join(UPLOAD_DIR, stored_name)

        content = await file.read()
        with open(file_path, "wb") as f:
            f.write(content)

        file_url = f"/{UPLOAD_DIR}/{stored_name}"

        cur.execute(
            """
            INSERT INTO nom035_evidences
            (
                cycle_id,
                action_plan_id,
                evidence_type,
                title,
                file_url,
                file_name,
                uploaded_by_user_id
            )
            VALUES (%s, %s, %s, %s, %s, %s, %s)
            """,
            (
                cycle_id,
                action_plan_id,
                evidence_type,
                title.strip(),
                file_url,
                file.filename,
                uploaded_by_user_id,
            ),
        )

        conn.commit()
        return {"ok": True, "message": "Evidencia creada correctamente"}
    except Exception:
        conn.rollback()
        raise
    finally:
        cur.close()


@router.put("/{evidence_id}")
async def update_evidence(
    evidence_id: int,
    cycle_id: int = Form(...),
    evidence_type: str = Form(...),
    title: str = Form(...),
    action_plan_id: Optional[int] = Form(None),
    uploaded_by_user_id: Optional[int] = Form(None),
    file: Optional[UploadFile] = File(None),
    conn=Depends(get_mysql_conn),
):
    cur = conn.cursor()
    try:
        if not title.strip():
            raise HTTPException(status_code=400, detail="El título es obligatorio")

        evidence = _get_evidence_or_404(cur, evidence_id)

        # SELECT: id, cycle_id, action_plan_id, file_url, file_name
        file_url = evidence[3]
        current_file_name = evidence[4]

        if file:
            old_path = file_url.lstrip("/")
            if os.path.exists(old_path):
                try:
                    os.remove(old_path)
                except Exception:
                    pass

            ext = os.path.splitext(file.filename or "")[1]
            stored_name = f"{uuid4().hex}{ext}"
            file_path = os.path.join(UPLOAD_DIR, stored_name)

            content = await file.read()
            with open(file_path, "wb") as f:
                f.write(content)

            file_url = f"/{UPLOAD_DIR}/{stored_name}"
            file_name = file.filename
        else:
            file_name = current_file_name

        cur.execute(
            """
            UPDATE nom035_evidences
            SET
                cycle_id = %s,
                action_plan_id = %s,
                evidence_type = %s,
                title = %s,
                file_url = %s,
                file_name = %s,
                uploaded_by_user_id = %s
            WHERE id = %s
            """,
            (
                cycle_id,
                action_plan_id,
                evidence_type,
                title.strip(),
                file_url,
                file_name,
                uploaded_by_user_id,
                evidence_id,
            ),
        )

        conn.commit()
        return {"ok": True, "message": "Evidencia actualizada"}
    except Exception:
        conn.rollback()
        raise
    finally:
        cur.close()


@router.delete("/{evidence_id}")
def delete_evidence(
    evidence_id: int,
    conn=Depends(get_mysql_conn),
):
    cur = conn.cursor()
    try:
        evidence = _get_evidence_or_404(cur, evidence_id)

        file_url = evidence[3]
        file_path = file_url.lstrip("/")

        cur.execute(
            "DELETE FROM nom035_evidences WHERE id = %s",
            (evidence_id,),
        )
        conn.commit()

        if file_path and os.path.exists(file_path):
            try:
                os.remove(file_path)
            except Exception:
                pass

        return {"ok": True, "message": "Evidencia eliminada"}
    except Exception:
        conn.rollback()
        raise
    finally:
        cur.close()


@router.get("/{evidence_id}/download")
def download_evidence(
    evidence_id: int,
    conn=Depends(get_mysql_conn),
):
    cur = conn.cursor()
    try:
        evidence = _get_evidence_or_404(cur, evidence_id)

        file_url = evidence[3]
        original_file_name = evidence[4] or os.path.basename(file_url)
        file_path = file_url.lstrip("/")

        if not os.path.exists(file_path):
            raise HTTPException(status_code=404, detail="Archivo no encontrado")

        return FileResponse(
            path=file_path,
            filename=original_file_name,
            media_type="application/octet-stream",
        )
    finally:
        cur.close()


@router.get("/by-plan/{plan_id}")
def get_evidences_by_plan(
    plan_id: int,
    conn=Depends(get_mysql_conn),
):
    cur = conn.cursor()
    try:
        cur.execute(
            """
            SELECT *
            FROM nom035_evidences
            WHERE action_plan_id = %s
            ORDER BY id DESC
            """,
            (plan_id,),
        )

        rows = cur.fetchall()
        result = [_row_to_dict(cur, row) for row in rows]

        return {"ok": True, "items": result}
    finally:
        cur.close()