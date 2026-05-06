# nom035_audit.py
import io
import os
from datetime import datetime
from typing import Optional
from uuid import uuid4

from fastapi import APIRouter, Depends, File, Form, HTTPException, UploadFile
from fastapi.responses import FileResponse, StreamingResponse

from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER, TA_LEFT
from reportlab.lib.pagesizes import letter
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import cm
from reportlab.platypus import (
    Image,
    Paragraph,
    SimpleDocTemplate,
    Spacer,
    Table,
    TableStyle,
)
from sqlalchemy import table

from app.core.db_mysql import get_mysql_conn
from app.dependencies.roles import require_role


router = APIRouter(
    prefix="/nom035-audit",
    tags=["NOM035 Audit"],
    dependencies=[Depends(require_role(1, 2))],
)

download_router = APIRouter(
    prefix="/nom035-audit",
    tags=["NOM035 Audit Downloads"],
)

UPLOAD_DIR = "uploads/nom035_evidence"
ATTACHMENTS_DIR = "uploads/nom035_action_plan_attachments"
LOGO_PATH = "./assets/images/favicon.png"
COMPANY_NAME = "Vitracoat Pinturas en Polvo SA de CV"

os.makedirs(UPLOAD_DIR, exist_ok=True)
os.makedirs(ATTACHMENTS_DIR, exist_ok=True)


def bool_from_count(value) -> bool:
    return (value or 0) > 0


def validate_date(value: Optional[str]) -> Optional[str]:
    if value is None:
        return None

    value = value.strip()
    if not value:
        return None

    try:
        datetime.strptime(value, "%Y-%m-%d")
        return value
    except ValueError:
        raise HTTPException(
            status_code=400,
            detail="Formato de fecha inválido. Usa YYYY-MM-DD",
        )


def _safe_date_text(value) -> str:
    if not value:
        return "—"
    try:
        return value.strftime("%d/%m/%Y")
    except Exception:
        return str(value)


def _status_label(status: Optional[str]) -> str:
    value = (status or "").strip().lower()
    if value == "en_proceso":
        return "En proceso"
    if value == "completado":
        return "Completado"
    if value == "cancelado":
        return "Cancelado"
    return "Pendiente"


def _draw_pdf_background(canvas, doc):
    canvas.saveState()

    page_width, page_height = letter

    # Fondo principal
    canvas.setFillColor(colors.HexColor("#F7F7F7"))
    canvas.rect(0, 0, page_width, page_height, fill=1, stroke=0)

    # Franja superior azul
    canvas.setFillColor(colors.HexColor("#1F2D7A"))
    canvas.rect(0, page_height - 34, page_width * 0.55, 18, fill=1, stroke=0)

    # Diagonal superior derecha azul
    canvas.setFillColor(colors.HexColor("#1F2D7A"))
    path = canvas.beginPath()
    path.moveTo(page_width * 0.68, page_height)
    path.lineTo(page_width, page_height)
    path.lineTo(page_width, page_height * 0.60)
    path.close()
    canvas.drawPath(path, fill=1, stroke=0)

    # Línea amarilla diagonal
    canvas.setLineWidth(16)
    canvas.setStrokeColor(colors.HexColor("#F4D000"))
    canvas.line(page_width * 0.66, page_height, page_width, page_height * 0.62)

    # Franja inferior azul
    canvas.setFillColor(colors.HexColor("#1F2D7A"))
    canvas.rect(0, 0, page_width, 22, fill=1, stroke=0)

    # Detalle sutil gris tipo curva/fondo
    canvas.setStrokeColor(colors.HexColor("#E8E8E8"))
    canvas.setLineWidth(2)
    canvas.bezier(
        40, page_height * 0.72,
        page_width * 0.35, page_height * 0.82,
        page_width * 0.52, page_height * 0.40,
        page_width * 0.78, page_height * 0.52
    )

    canvas.restoreState()


@router.post("/action-plans")
def create_action_plan(
    cycle_id: int = Form(...),
    department_id: Optional[int] = Form(None),
    department_name: Optional[str] = Form(None),
    risk_level: Optional[str] = Form(None),
    action_title: str = Form(...),
    action_description: Optional[str] = Form(None),
    responsible_name: Optional[str] = Form(None),
    responsible_user_id: Optional[int] = Form(None),
    due_date: Optional[str] = Form(None),
    created_by_user_id: Optional[int] = Form(None),
    conn=Depends(get_mysql_conn),
):
    action_title = (action_title or "").strip()
    if not action_title:
        raise HTTPException(
            status_code=400,
            detail="El título de la acción es obligatorio",
        )

    due_date = validate_date(due_date)
    cur = conn.cursor(dictionary=True)

    try:
        cur.execute(
            """
            SELECT id, title, status
            FROM nom035_cycles
            WHERE id = %s
            LIMIT 1
            """,
            (cycle_id,),
        )
        cycle = cur.fetchone()

        if not cycle:
            raise HTTPException(status_code=404, detail="Ciclo NOM-035 no encontrado")

        cur.execute(
            """
            INSERT INTO nom035_action_plans
            (
                cycle_id,
                department_id,
                department_name,
                risk_level,
                action_title,
                action_description,
                responsible_name,
                responsible_user_id,
                due_date,
                created_by_user_id
            )
            VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)
            """,
            (
                cycle_id,
                department_id,
                (department_name or "").strip() or None,
                (risk_level or "").strip() or None,
                action_title,
                (action_description or "").strip() or None,
                (responsible_name or "").strip() or None,
                responsible_user_id,
                due_date,
                created_by_user_id,
            ),
        )
        conn.commit()

        return {
            "ok": True,
            "id": cur.lastrowid,
            "message": "Plan de acción creado correctamente",
        }
    finally:
        cur.close()


@router.get("/action-plans/cycle/{cycle_id}")
def get_action_plans(
    cycle_id: int,
    conn=Depends(get_mysql_conn),
):
    cur = conn.cursor(dictionary=True)

    try:
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
                p.responsible_user_id,
                p.due_date,
                p.status,
                p.progress_percent,
                p.created_by_user_id,
                p.created_at,
                p.updated_at,
                COUNT(a.id) AS attachments_count
            FROM nom035_action_plans p
            LEFT JOIN nom035_action_plan_attachments a
                ON a.action_plan_id = p.id
            WHERE p.cycle_id = %s
            GROUP BY
                p.id,
                p.cycle_id,
                p.department_id,
                p.department_name,
                p.risk_level,
                p.action_title,
                p.action_description,
                p.responsible_name,
                p.responsible_user_id,
                p.due_date,
                p.status,
                p.progress_percent,
                p.created_by_user_id,
                p.created_at,
                p.updated_at
            ORDER BY p.created_at DESC, p.id DESC
            """,
            (cycle_id,),
        )
        rows = cur.fetchall()

        return {
            "ok": True,
            "items": rows,
        }
    finally:
        cur.close()


@router.put("/action-plans/{plan_id}")
def update_action_plan(
    plan_id: int,
    cycle_id: Optional[int] = Form(None),
    status: Optional[str] = Form(None),
    progress_percent: Optional[float] = Form(None),
    department_id: Optional[int] = Form(None),
    department_name: Optional[str] = Form(None),
    risk_level: Optional[str] = Form(None),
    action_title: Optional[str] = Form(None),
    action_description: Optional[str] = Form(None),
    responsible_name: Optional[str] = Form(None),
    responsible_user_id: Optional[int] = Form(None),
    due_date: Optional[str] = Form(None),
    conn=Depends(get_mysql_conn),
):
    cur = conn.cursor(dictionary=True)

    try:
        cur.execute(
            """
            SELECT id
            FROM nom035_action_plans
            WHERE id = %s
            LIMIT 1
            """,
            (plan_id,),
        )
        exists = cur.fetchone()

        if not exists:
            raise HTTPException(status_code=404, detail="Plan de acción no encontrado")

        allowed_status = {"pendiente", "en_proceso", "completado", "cancelado"}
        if status is not None:
            status = status.strip()
            if status not in allowed_status:
                raise HTTPException(
                    status_code=400,
                    detail="Estatus inválido. Usa: pendiente, en_proceso, completado o cancelado",
                )

        if progress_percent is not None and (progress_percent < 0 or progress_percent > 100):
            raise HTTPException(
                status_code=400,
                detail="progress_percent debe estar entre 0 y 100",
            )

        if action_title is not None:
            action_title = action_title.strip()
            if not action_title:
                raise HTTPException(
                    status_code=400,
                    detail="El título de la acción no puede ir vacío",
                )

        due_date = validate_date(due_date)

        fields = []
        values = []

        if cycle_id is not None:
            fields.append("cycle_id = %s")
            values.append(cycle_id)

        if status is not None:
            fields.append("status = %s")
            values.append(status)

        if progress_percent is not None:
            fields.append("progress_percent = %s")
            values.append(progress_percent)

        if department_id is not None:
            fields.append("department_id = %s")
            values.append(department_id)

        if department_name is not None:
            fields.append("department_name = %s")
            values.append(department_name.strip() or None)

        if risk_level is not None:
            fields.append("risk_level = %s")
            values.append(risk_level.strip() or None)

        if action_title is not None:
            fields.append("action_title = %s")
            values.append(action_title)

        if action_description is not None:
            fields.append("action_description = %s")
            values.append(action_description.strip() or None)

        if responsible_name is not None:
            fields.append("responsible_name = %s")
            values.append(responsible_name.strip() or None)

        if responsible_user_id is not None:
            fields.append("responsible_user_id = %s")
            values.append(responsible_user_id)

        if due_date is not None:
            fields.append("due_date = %s")
            values.append(due_date)

        if not fields:
            raise HTTPException(status_code=400, detail="No hay campos para actualizar")

        values.append(plan_id)

        sql = f"""
            UPDATE nom035_action_plans
            SET {", ".join(fields)}
            WHERE id = %s
        """

        cur.execute(sql, tuple(values))
        conn.commit()

        return {
            "ok": True,
            "message": "Plan de acción actualizado correctamente",
        }
    finally:
        cur.close()


@router.delete("/action-plans/{plan_id}")
def delete_action_plan(
    plan_id: int,
    conn=Depends(get_mysql_conn),
):
    cur = conn.cursor(dictionary=True)

    try:
        cur.execute(
            """
            SELECT id
            FROM nom035_action_plans
            WHERE id = %s
            LIMIT 1
            """,
            (plan_id,),
        )
        exists = cur.fetchone()

        if not exists:
            raise HTTPException(status_code=404, detail="Plan de acción no encontrado")

        cur.execute(
            """
            DELETE FROM nom035_action_plans
            WHERE id = %s
            """,
            (plan_id,),
        )
        conn.commit()

        return {
            "ok": True,
            "message": "Plan de acción eliminado correctamente",
        }
    finally:
        cur.close()


@router.post("/evidences")
async def upload_evidence(
    cycle_id: int = Form(...),
    evidence_type: str = Form(...),
    title: str = Form(...),
    action_plan_id: Optional[int] = Form(None),
    uploaded_by_user_id: Optional[int] = Form(None),
    file: UploadFile = File(...),
    conn=Depends(get_mysql_conn),
):
    allowed_types = {
        "policy",
        "diffusion",
        "training",
        "diagnostic",
        "action_plan",
        "action_execution",
        "stps_support",
    }

    evidence_type = (evidence_type or "").strip()
    title = (title or "").strip()

    if evidence_type not in allowed_types:
        raise HTTPException(status_code=400, detail="Tipo de evidencia inválido")

    if not title:
        raise HTTPException(
            status_code=400,
            detail="El título de la evidencia es obligatorio",
        )

    cur = conn.cursor(dictionary=True)

    try:
        cur.execute(
            """
            SELECT id
            FROM nom035_cycles
            WHERE id = %s
            LIMIT 1
            """,
            (cycle_id,),
        )
        cycle = cur.fetchone()

        if not cycle:
            raise HTTPException(status_code=404, detail="Ciclo NOM-035 no encontrado")

        if action_plan_id is not None:
            cur.execute(
                """
                SELECT id, cycle_id
                FROM nom035_action_plans
                WHERE id = %s
                LIMIT 1
                """,
                (action_plan_id,),
            )
            plan = cur.fetchone()

            if not plan:
                raise HTTPException(status_code=404, detail="Plan de acción no encontrado")

            if int(plan["cycle_id"]) != int(cycle_id):
                raise HTTPException(
                    status_code=400,
                    detail="El plan de acción no pertenece al ciclo enviado",
                )

        ext = os.path.splitext(file.filename or "")[1]
        unique_name = f"{uuid4().hex}{ext}"
        save_path = os.path.join(UPLOAD_DIR, unique_name)

        content = await file.read()
        with open(save_path, "wb") as f:
            f.write(content)

        file_url = f"/{UPLOAD_DIR}/{unique_name}"

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
            VALUES (%s,%s,%s,%s,%s,%s,%s)
            """,
            (
                cycle_id,
                action_plan_id,
                evidence_type,
                title,
                file_url,
                file.filename,
                uploaded_by_user_id,
            ),
        )
        conn.commit()
        evidence_id = cur.lastrowid

        return {
            "ok": True,
            "id": evidence_id,
            "file_url": file_url,
            "file_name": file.filename,
            "message": "Evidencia cargada correctamente",
        }
    finally:
        cur.close()


@router.get("/evidences/{cycle_id}")
def get_evidences(
    cycle_id: int,
    conn=Depends(get_mysql_conn),
):
    cur = conn.cursor(dictionary=True)

    try:
        cur.execute(
            """
            SELECT
                id,
                cycle_id,
                action_plan_id,
                evidence_type,
                title,
                file_url,
                file_name,
                uploaded_by_user_id,
                created_at
            FROM nom035_evidences
            WHERE cycle_id = %s
            ORDER BY created_at DESC, id DESC
            """,
            (cycle_id,),
        )
        rows = cur.fetchall()

        return {
            "ok": True,
            "items": rows,
        }
    finally:
        cur.close()


@router.delete("/evidences/{evidence_id}")
def delete_evidence(
    evidence_id: int,
    conn=Depends(get_mysql_conn),
):
    cur = conn.cursor(dictionary=True)

    try:
        cur.execute(
            """
            SELECT id, file_url
            FROM nom035_evidences
            WHERE id = %s
            LIMIT 1
            """,
            (evidence_id,),
        )
        evidence = cur.fetchone()

        if not evidence:
            raise HTTPException(status_code=404, detail="Evidencia no encontrada")

        file_url = evidence.get("file_url") or ""
        relative_path = file_url.lstrip("/")

        cur.execute(
            """
            DELETE FROM nom035_evidences
            WHERE id = %s
            """,
            (evidence_id,),
        )
        conn.commit()

        if relative_path and os.path.exists(relative_path):
            try:
                os.remove(relative_path)
            except Exception:
                pass

        return {
            "ok": True,
            "message": "Evidencia eliminada correctamente",
        }
    finally:
        cur.close()


@router.get("/compliance/{cycle_id}")
def get_cycle_compliance(
    cycle_id: int,
    conn=Depends(get_mysql_conn),
):
    cur = conn.cursor(dictionary=True)

    try:
        cur.execute(
            """
            SELECT COUNT(*) AS total
            FROM nom035_evidences
            WHERE cycle_id = %s
              AND evidence_type = 'policy'
            """,
            (cycle_id,),
        )
        policy_uploaded = bool_from_count(cur.fetchone()["total"])

        cur.execute(
            """
            SELECT COUNT(*) AS total
            FROM nom035_evidences
            WHERE cycle_id = %s
            """,
            (cycle_id,),
        )
        evidence_uploaded = bool_from_count(cur.fetchone()["total"])

        cur.execute(
            """
            SELECT COUNT(*) AS total
            FROM nom035_submissions
            WHERE cycle_id = %s
              AND status = 'submitted'
            """,
            (cycle_id,),
        )
        results_generated = bool_from_count(cur.fetchone()["total"])

        cur.execute(
            """
            SELECT COUNT(*) AS total
            FROM nom035_action_plans
            WHERE cycle_id = %s
            """,
            (cycle_id,),
        )
        action_plan_created = bool_from_count(cur.fetchone()["total"])

        stps_file_ready = (
            policy_uploaded
            and evidence_uploaded
            and results_generated
            and action_plan_created
        )

        return {
            "ok": True,
            "compliance": {
                "policy_uploaded": policy_uploaded,
                "evidence_uploaded": evidence_uploaded,
                "results_generated": results_generated,
                "action_plan_created": action_plan_created,
                "stps_file_ready": stps_file_ready,
            },
        }
    finally:
        cur.close()


@router.post("/audit-file/rebuild/{cycle_id}")
def rebuild_audit_file(
    cycle_id: int,
    generated_by_user_id: Optional[int] = Form(None),
    notes: Optional[str] = Form(None),
    conn=Depends(get_mysql_conn),
):
    cur = conn.cursor(dictionary=True)

    try:
        cur.execute(
            """
            SELECT COUNT(*) AS total
            FROM nom035_evidences
            WHERE cycle_id = %s
              AND evidence_type = 'policy'
            """,
            (cycle_id,),
        )
        policy_uploaded = bool_from_count(cur.fetchone()["total"])

        cur.execute(
            """
            SELECT COUNT(*) AS total
            FROM nom035_evidences
            WHERE cycle_id = %s
            """,
            (cycle_id,),
        )
        evidence_uploaded = bool_from_count(cur.fetchone()["total"])

        cur.execute(
            """
            SELECT COUNT(*) AS total
            FROM nom035_submissions
            WHERE cycle_id = %s
              AND status = 'submitted'
            """,
            (cycle_id,),
        )
        results_generated = bool_from_count(cur.fetchone()["total"])

        cur.execute(
            """
            SELECT COUNT(*) AS total
            FROM nom035_action_plans
            WHERE cycle_id = %s
            """,
            (cycle_id,),
        )
        action_plan_created = bool_from_count(cur.fetchone()["total"])

        is_ready = (
            policy_uploaded
            and evidence_uploaded
            and results_generated
            and action_plan_created
        )

        cur.execute(
            """
            SELECT id
            FROM nom035_audit_files
            WHERE cycle_id = %s
            LIMIT 1
            """,
            (cycle_id,),
        )
        existing = cur.fetchone()

        if existing:
            cur.execute(
                """
                UPDATE nom035_audit_files
                SET
                    is_ready = %s,
                    notes = %s,
                    generated_at = NOW(),
                    generated_by_user_id = %s
                WHERE cycle_id = %s
                """,
                (
                    1 if is_ready else 0,
                    (notes or "").strip() or None,
                    generated_by_user_id,
                    cycle_id,
                ),
            )
        else:
            cur.execute(
                """
                INSERT INTO nom035_audit_files
                (
                    cycle_id,
                    is_ready,
                    notes,
                    generated_at,
                    generated_by_user_id
                )
                VALUES (%s,%s,%s,NOW(),%s)
                """,
                (
                    cycle_id,
                    1 if is_ready else 0,
                    (notes or "").strip() or None,
                    generated_by_user_id,
                ),
            )

        conn.commit()

        return {
            "ok": True,
            "message": "Expediente STPS recalculado correctamente",
            "is_ready": is_ready,
            "compliance": {
                "policy_uploaded": policy_uploaded,
                "evidence_uploaded": evidence_uploaded,
                "results_generated": results_generated,
                "action_plan_created": action_plan_created,
                "stps_file_ready": is_ready,
            },
        }
    finally:
        cur.close()


@router.get("/stps-file/{cycle_id}")
def get_stps_file(
    cycle_id: int,
    conn=Depends(get_mysql_conn),
):
    cur = conn.cursor(dictionary=True)

    try:
        cur.execute(
            """
            SELECT
                c.id,
                c.year,
                c.title,
                c.start_at,
                c.due_at,
                c.status
            FROM nom035_cycles c
            WHERE c.id = %s
            LIMIT 1
            """,
            (cycle_id,),
        )
        cycle = cur.fetchone()

        if not cycle:
            raise HTTPException(status_code=404, detail="Ciclo NOM-035 no encontrado")

        cur.execute(
            """
            SELECT
                COUNT(*) AS total_assigned,
                SUM(CASE WHEN status = 'submitted' THEN 1 ELSE 0 END) AS submitted_count,
                SUM(CASE WHEN status = 'in_progress' THEN 1 ELSE 0 END) AS in_progress_count,
                SUM(CASE WHEN status = 'available' THEN 1 ELSE 0 END) AS available_count,
                AVG(score_total) AS avg_score
            FROM nom035_submissions
            WHERE cycle_id = %s
            """,
            (cycle_id,),
        )
        submission_stats = cur.fetchone() or {}

        cur.execute(
            """
            SELECT
                COALESCE(risk_level, 'Sin clasificar') AS risk_level,
                COUNT(*) AS total
            FROM nom035_submissions
            WHERE cycle_id = %s
              AND status = 'submitted'
            GROUP BY COALESCE(risk_level, 'Sin clasificar')
            ORDER BY total DESC
            """,
            (cycle_id,),
        )
        risk_distribution = cur.fetchall()

        cur.execute(
            """
            SELECT
                id,
                department_id,
                department_name,
                risk_level,
                action_title,
                action_description,
                responsible_name,
                due_date,
                status,
                progress_percent,
                created_at,
                updated_at
            FROM nom035_action_plans
            WHERE cycle_id = %s
            ORDER BY created_at DESC, id DESC
            """,
            (cycle_id,),
        )
        action_plans = cur.fetchall()

        cur.execute(
            """
            SELECT
                id,
                action_plan_id,
                evidence_type,
                title,
                file_url,
                file_name,
                uploaded_by_user_id,
                created_at
            FROM nom035_evidences
            WHERE cycle_id = %s
            ORDER BY created_at DESC, id DESC
            """,
            (cycle_id,),
        )
        evidences = cur.fetchall()

        cur.execute(
            """
            SELECT
                id,
                cycle_id,
                is_ready,
                notes,
                generated_at,
                generated_by_user_id,
                created_at,
                updated_at
            FROM nom035_audit_files
            WHERE cycle_id = %s
            LIMIT 1
            """,
            (cycle_id,),
        )
        audit_file = cur.fetchone()

        total_assigned = int(submission_stats.get("total_assigned") or 0)
        submitted_count = int(submission_stats.get("submitted_count") or 0)
        in_progress_count = int(submission_stats.get("in_progress_count") or 0)
        available_count = int(submission_stats.get("available_count") or 0)
        avg_score = float(submission_stats.get("avg_score") or 0)

        policy_uploaded = any(e.get("evidence_type") == "policy" for e in evidences)
        evidence_uploaded = len(evidences) > 0
        results_generated = submitted_count > 0
        action_plan_created = len(action_plans) > 0

        computed_ready = (
            policy_uploaded
            and evidence_uploaded
            and results_generated
            and action_plan_created
        )

        ready = bool(audit_file.get("is_ready")) if audit_file else computed_ready

        return {
            "ok": True,
            "cycle": cycle,
            "submission_stats": {
                "total_assigned": total_assigned,
                "submitted_count": submitted_count,
                "in_progress_count": in_progress_count,
                "available_count": available_count,
                "avg_score": round(avg_score, 2),
            },
            "risk_distribution": risk_distribution,
            "action_plans": action_plans,
            "evidences": evidences,
            "audit_file": audit_file,
            "compliance": {
                "policy_uploaded": policy_uploaded,
                "evidence_uploaded": evidence_uploaded,
                "results_generated": results_generated,
                "action_plan_created": action_plan_created,
                "stps_file_ready": computed_ready,
            },
            "ready": ready,
        }
    finally:
        cur.close()


@router.get("/action-plans/{plan_id}/attachments")
def get_action_plan_attachments(
    plan_id: int,
    conn=Depends(get_mysql_conn),
):
    cur = conn.cursor(dictionary=True)

    try:
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

        return {
            "ok": True,
            "items": rows,
        }
    finally:
        cur.close()


@router.post("/action-plans/{plan_id}/attachments")
async def upload_action_plan_attachment(
    plan_id: int,
    file: UploadFile = File(...),
    uploaded_by_user_id: Optional[int] = Form(None),
    conn=Depends(get_mysql_conn),
):
    cur = conn.cursor(dictionary=True)

    try:
        cur.execute(
            """
            SELECT id
            FROM nom035_action_plans
            WHERE id = %s
            LIMIT 1
            """,
            (plan_id,),
        )
        plan = cur.fetchone()

        if not plan:
            raise HTTPException(status_code=404, detail="Plan de acción no encontrado")

        ext = os.path.splitext(file.filename or "")[1]
        stored_name = f"{uuid4().hex}{ext}"
        file_path = os.path.join(ATTACHMENTS_DIR, stored_name)

        content = await file.read()
        with open(file_path, "wb") as f:
            f.write(content)

        cur.execute(
            """
            INSERT INTO nom035_action_plan_attachments
            (
                action_plan_id,
                original_name,
                stored_name,
                file_path,
                mime_type,
                file_size,
                uploaded_by_user_id
            )
            VALUES (%s,%s,%s,%s,%s,%s,%s)
            """,
            (
                plan_id,
                file.filename,
                stored_name,
                file_path,
                file.content_type,
                len(content),
                uploaded_by_user_id,
            ),
        )
        conn.commit()

        return {
            "ok": True,
            "id": cur.lastrowid,
            "file_name": file.filename,
            "message": "Archivo adjunto cargado correctamente",
        }
    finally:
        cur.close()


@router.delete("/action-plan-attachments/{attachment_id}")
def delete_action_plan_attachment(
    attachment_id: int,
    conn=Depends(get_mysql_conn),
):
    cur = conn.cursor(dictionary=True)

    try:
        cur.execute(
            """
            SELECT
                id,
                file_path
            FROM nom035_action_plan_attachments
            WHERE id = %s
            LIMIT 1
            """,
            (attachment_id,),
        )
        row = cur.fetchone()

        if not row:
            raise HTTPException(status_code=404, detail="Adjunto no encontrado")

        file_path = row["file_path"]

        cur.execute(
            """
            DELETE FROM nom035_action_plan_attachments
            WHERE id = %s
            """,
            (attachment_id,),
        )
        conn.commit()

        if file_path and os.path.exists(file_path):
            try:
                os.remove(file_path)
            except Exception:
                pass

        return {
            "ok": True,
            "message": "Adjunto eliminado correctamente",
        }
    finally:
        cur.close()


@download_router.get("/action-plan-attachments/{attachment_id}/download")
def download_action_plan_attachment(
    attachment_id: int,
    conn=Depends(get_mysql_conn),
):
    cur = conn.cursor(dictionary=True)

    try:
        cur.execute(
            """
            SELECT
                original_name,
                file_path,
                mime_type
            FROM nom035_action_plan_attachments
            WHERE id = %s
            LIMIT 1
            """,
            (attachment_id,),
        )
        row = cur.fetchone()

        if not row:
            raise HTTPException(status_code=404, detail="Adjunto no encontrado")

        file_path = row["file_path"]
        original_name = row["original_name"] or "archivo"
        mime_type = row["mime_type"] or "application/octet-stream"

        if not file_path or not os.path.exists(file_path):
            raise HTTPException(status_code=404, detail="Archivo no encontrado")

        return FileResponse(
            path=file_path,
            filename=original_name,
            media_type=mime_type,
        )
    finally:
        cur.close()


@download_router.get("/action-plans/cycle/{cycle_id}/pdf")
def download_action_plans_cycle_pdf(
    cycle_id: int,
    conn=Depends(get_mysql_conn),
):
    cur = conn.cursor(dictionary=True)

    try:
        cur.execute(
            """
            SELECT
                ap.id,
                ap.cycle_id,
                ap.department_id,
                ap.department_name,
                ap.risk_level,
                ap.action_title,
                ap.action_description,
                ap.responsible_name,
                ap.responsible_user_id,
                ap.due_date,
                ap.status,
                ap.progress_percent,
                ap.created_at,
                ap.updated_at
            FROM nom035_action_plans ap
            WHERE ap.cycle_id = %s
            ORDER BY ap.id DESC
            """,
            (cycle_id,),
        )
        rows = cur.fetchall()

        buffer = io.BytesIO()
        doc = SimpleDocTemplate(
            buffer,
            pagesize=letter,
            leftMargin=20,
            rightMargin=20,
            topMargin=55,
            bottomMargin=28,
        )

        styles = getSampleStyleSheet()

        title_style = ParagraphStyle(
            "CustomTitle",
            parent=styles["Title"],
            fontName="Helvetica-Bold",
            fontSize=20,
            leading=24,
            alignment=TA_CENTER,
            textColor=colors.HexColor("#0D3B66"),
            spaceAfter=6,
        )

        subtitle_style = ParagraphStyle(
            "CustomSubtitle",
            parent=styles["Normal"],
            fontName="Helvetica",
            fontSize=10,
            leading=13,
            alignment=TA_CENTER,
            textColor=colors.HexColor("#4A6572"),
            spaceAfter=10,
        )

        section_style = ParagraphStyle(
            "SectionTitle",
            parent=styles["Heading2"],
            fontName="Helvetica-Bold",
            fontSize=12,
            leading=14,
            alignment=TA_LEFT,
            textColor=colors.HexColor("#0D5C8F"),
            spaceAfter=8,
        )

        body_style = ParagraphStyle(
            "BodyStyle",
            parent=styles["Normal"],
            fontName="Helvetica",
            fontSize=9,
            leading=12,
            textColor=colors.HexColor("#1F2933"),
        )

        elements = []

        if os.path.exists(LOGO_PATH):
            logo = Image(LOGO_PATH, width=2.2 * cm, height=2.2 * cm)
            logo.hAlign = "CENTER"
            elements.append(logo)
            elements.append(Spacer(1, 0.15 * cm))

        elements.append(Paragraph(COMPANY_NAME, title_style))
        elements.append(
            Paragraph(
                f"Plan de Acción NOM-035 (2026) - Ciclo {cycle_id}",
                title_style,
            )
        )

        generated_at = datetime.now().strftime("%d/%m/%Y %H:%M")
        elements.append(
            Paragraph(
                f"Documento generado el {generated_at}",
                subtitle_style,
            )
        )

        elements.append(Spacer(1, 0.20 * cm))
        elements.append(Paragraph("Resumen general", section_style))

        total_planes = len(rows)
        completados = sum(1 for r in rows if (r.get("status") or "") == "completado")
        en_proceso = sum(1 for r in rows if (r.get("status") or "") == "en_proceso")
        pendientes = sum(1 for r in rows if (r.get("status") or "") == "pendiente")
        cancelados = sum(1 for r in rows if (r.get("status") or "") == "cancelado")

        resumen_data = [
            ["Total planes", "Pendientes", "En proceso", "Completados", "Cancelados"],
            [
                str(total_planes),
                str(pendientes),
                str(en_proceso),
                str(completados),
                str(cancelados),
            ],
        ]

        resumen_table = Table(
            resumen_data,
            colWidths=[3.4 * cm, 3.4 * cm, 3.4 * cm, 3.4 * cm, 3.4 * cm],
        )
        resumen_table.setStyle(
            TableStyle(
                [
                    ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#1F2D7A")),
                    ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
                    ("FONTNAME", (0, 0), (-1, 0), "Helvetica-Bold"),
                    ("FONTSIZE", (0, 0), (-1, -1), 8),
                    ("GRID", (0, 0), (-1, -1), 0.35, colors.HexColor("#C7D1D8")),
                    ("VALIGN", (0, 0), (-1, -1), "TOP"),
                    ("ROWBACKGROUNDS", (0, 1), (-1, -1), [
                        colors.white,
                        colors.HexColor("#F3F6FA"),
                    ]),
                    ("LEFTPADDING", (0, 0), (-1, -1), 4),
                    ("RIGHTPADDING", (0, 0), (-1, -1), 4),
                    ("TOPPADDING", (0, 0), (-1, -1), 5),
                    ("BOTTOMPADDING", (0, 0), (-1, -1), 5),
                ]
            )
        )
        elements.append(resumen_table)
        elements.append(Spacer(1, 0.35 * cm))

        elements.append(Paragraph("Tabla de planes de acción", section_style))

        if not rows:
            elements.append(
                Paragraph(
                    "No hay planes de acción registrados para este ciclo.",
                    body_style,
                )
            )
        else:
            data = [
                [
                    "ID",
                    "Departamento",
                    "Riesgo",
                    "Título",
                    "Responsable",
                    "Fecha límite",
                    "Estatus",
                    "Avance",
                ]
            ]

            for row in rows:
                data.append(
                    [
                        str(row.get("id") or ""),
                        str(row.get("department_name") or "—"),
                        str(row.get("risk_level") or "—"),
                        str(row.get("action_title") or "—"),
                        str(row.get("responsible_name") or "—"),
                        _safe_date_text(row.get("due_date")),
                        _status_label(row.get("status")),
                        f"{float(row.get('progress_percent') or 0):.0f}%",
                    ]
                )

            table = Table(
                data,
                repeatRows=1,
                colWidths=[
                    1.1 * cm,
                    2.8 * cm,
                    2.0 * cm,
                    5.2 * cm,
                    3.0 * cm,
                    2.3 * cm,
                    2.4 * cm,
                    1.7 * cm,
                ],
            )

            table.setStyle(
                TableStyle(
                    [
                        ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#1F2D7A")),
                        ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
                        ("FONTNAME", (0, 0), (-1, 0), "Helvetica-Bold"),
                        ("FONTSIZE", (0, 0), (-1, -1), 8),
                        ("GRID", (0, 0), (-1, -1), 0.35, colors.HexColor("#C7D1D8")),
                        ("VALIGN", (0, 0), (-1, -1), "TOP"),
                        ("ROWBACKGROUNDS", (0, 1), (-1, -1), [
                            colors.white,
                            colors.HexColor("#F3F6FA"),
                        ]),
                        ("LEFTPADDING", (0, 0), (-1, -1), 4),
                        ("RIGHTPADDING", (0, 0), (-1, -1), 4),
                        ("TOPPADDING", (0, 0), (-1, -1), 5),
                        ("BOTTOMPADDING", (0, 0), (-1, -1), 5),
                    ]
                )
            )
            elements.append(table)

            elements.append(Spacer(1, 0.35 * cm))
            elements.append(Paragraph("Detalle de planes", section_style))

            for row in rows:
                detail = f"""
                <b>ID:</b> {row.get('id') or '—'}<br/>
                <b>Título:</b> {row.get('action_title') or '—'}<br/>
                <b>Departamento:</b> {row.get('department_name') or '—'}<br/>
                <b>Riesgo:</b> {row.get('risk_level') or '—'}<br/>
                <b>Responsable:</b> {row.get('responsible_name') or '—'}<br/>
                <b>Fecha límite:</b> {_safe_date_text(row.get('due_date'))}<br/>
                <b>Estatus:</b> {_status_label(row.get('status'))}<br/>
                <b>Avance:</b> {float(row.get('progress_percent') or 0):.0f}%<br/>
                <b>Descripción:</b> {row.get('action_description') or '—'}
                """
                elements.append(Paragraph(detail, body_style))
                elements.append(Spacer(1, 0.22 * cm))

        doc.build(
            elements,
            onFirstPage=_draw_pdf_background,
            onLaterPages=_draw_pdf_background,
        )
        buffer.seek(0)

        return StreamingResponse(
            buffer,
            media_type="application/pdf",
            headers={
                "Content-Disposition": f'inline; filename="vitracoat_planes_accion_ciclo_{cycle_id}.pdf"'
            },
        )
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Error generando PDF del ciclo: {str(e)}",
        )
    finally:
        cur.close()



@download_router.get("/action-plans/{plan_id}/pdf")
def download_action_plan_pdf(
    plan_id: int,
    conn=Depends(get_mysql_conn),
):
    cur = conn.cursor(dictionary=True)

    try:
        cur.execute(
            """
            SELECT
                ap.id,
                ap.cycle_id,
                ap.department_id,
                ap.department_name,
                ap.risk_level,
                ap.action_title,
                ap.action_description,
                ap.responsible_name,
                ap.responsible_user_id,
                ap.due_date,
                ap.status,
                ap.progress_percent,
                ap.created_at,
                ap.updated_at
            FROM nom035_action_plans ap
            WHERE ap.id = %s
            LIMIT 1
            """,
            (plan_id,),
        )
        row = cur.fetchone()

        if not row:
            raise HTTPException(status_code=404, detail="Plan de acción no encontrado")

        buffer = io.BytesIO()
        doc = SimpleDocTemplate(
            buffer,
            pagesize=letter,
            leftMargin=24,
            rightMargin=24,
            topMargin=55,
            bottomMargin=28,
        )

        styles = getSampleStyleSheet()

        title_style = ParagraphStyle(
            "PlanTitle",
            parent=styles["Title"],
            fontName="Helvetica-Bold",
            fontSize=20,
            leading=24,
            alignment=TA_CENTER,
            textColor=colors.HexColor("#0D3B66"),
            spaceAfter=8,
        )

        label_style = ParagraphStyle(
            "PlanBody",
            parent=styles["Normal"],
            fontName="Helvetica",
            fontSize=10,
            leading=14,
            textColor=colors.HexColor("#1F2933"),
        )

        section_style = ParagraphStyle(
            "PlanSection",
            parent=styles["Heading2"],
            fontName="Helvetica-Bold",
            fontSize=12,
            leading=14,
            textColor=colors.HexColor("#0D5C8F"),
            spaceAfter=8,
        )

        elements = []

        if os.path.exists(LOGO_PATH):
            logo = Image(LOGO_PATH, width=2.4 * cm, height=2.4 * cm)
            logo.hAlign = "CENTER"
            elements.append(logo)
            elements.append(Spacer(1, 0.18 * cm))

        elements.append(Paragraph(COMPANY_NAME, title_style))
        elements.append(
            Paragraph(f"Plan de Acción NOM-035 #{row['id']}", title_style)
        )

        generated_at = datetime.now().strftime("%d/%m/%Y %H:%M")
        elements.append(
            Paragraph(
                f"Documento generado el {generated_at}",
                ParagraphStyle(
                    "smallCenter",
                    parent=styles["Normal"],
                    alignment=TA_CENTER,
                    fontSize=10,
                    textColor=colors.HexColor("#4A6572"),
                ),
            )
        )

        elements.append(Spacer(1, 0.35 * cm))
        elements.append(Paragraph("Información general", section_style))

        info_data = [
            ["Campo", "Valor"],
            ["Ciclo", str(row.get("cycle_id") or "—")],
            ["Departamento", str(row.get("department_name") or "—")],
            ["Riesgo", str(row.get("risk_level") or "—")],
            ["Título", str(row.get("action_title") or "—")],
            ["Responsable", str(row.get("responsible_name") or "—")],
            ["Fecha límite", _safe_date_text(row.get("due_date"))],
            ["Estatus", _status_label(row.get("status"))],
            ["Avance", f"{float(row.get('progress_percent') or 0):.0f}%"],
        ]

        info_table = Table(
            info_data,
            colWidths=[4.3 * cm, 13.6 * cm],
        )

        info_table.setStyle(
            TableStyle(
                [
                    ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#1F2D7A")),
                    ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
                    ("FONTNAME", (0, 0), (-1, 0), "Helvetica-Bold"),
                    ("FONTSIZE", (0, 0), (-1, -1), 8),
                    ("GRID", (0, 0), (-1, -1), 0.35, colors.HexColor("#C7D1D8")),
                    ("VALIGN", (0, 0), (-1, -1), "TOP"),
                    ("ROWBACKGROUNDS", (0, 1), (-1, -1), [
                        colors.white,
                        colors.HexColor("#F3F6FA"),
                    ]),
                    ("LEFTPADDING", (0, 0), (-1, -1), 4),
                    ("RIGHTPADDING", (0, 0), (-1, -1), 4),
                    ("TOPPADDING", (0, 0), (-1, -1), 5),
                    ("BOTTOMPADDING", (0, 0), (-1, -1), 5),
                ]
            )
        )

        elements.append(info_table)

        elements.append(Spacer(1, 0.35 * cm))
        elements.append(Paragraph("Descripción del plan", section_style))
        elements.append(
            Paragraph(
                row.get("action_description") or "—",
                label_style,
            )
        )

        doc.build(
            elements,
            onFirstPage=_draw_pdf_background,
            onLaterPages=_draw_pdf_background,
        )
        buffer.seek(0)

        return StreamingResponse(
            buffer,
            media_type="application/pdf",
            headers={
                "Content-Disposition": f'inline; filename="vitracoat_plan_accion_{plan_id}.pdf"'
            },
        )
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Error generando PDF del plan: {str(e)}",
        )
    finally:
        cur.close()