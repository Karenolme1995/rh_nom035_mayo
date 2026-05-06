from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import Optional
from app.core.db_mysql import get_mysql_conn

router = APIRouter(prefix="/nom035-audit-file", tags=["NOM035 Audit File"])


class RebuildAuditFileRequest(BaseModel):
    cycle_id: int
    generated_by_user_id: int


def fetch_one_dict(cursor) -> Optional[dict]:
    row = cursor.fetchone()
    return row if row else None


def fetch_all_dict(cursor) -> list[dict]:
    rows = cursor.fetchall()
    return list(rows) if rows else []


@router.get("/{cycle_id}")
def get_nom035_audit_stps_file(cycle_id: int):
    conn = get_mysql_conn()
    try:
        with conn.cursor() as cursor:
            cursor.execute("""
                SELECT id, title, year, status
                FROM nom035_cycles
                WHERE id = %s
                LIMIT 1
            """, (cycle_id,))
            cycle = fetch_one_dict(cursor)

            if not cycle:
                raise HTTPException(status_code=404, detail="Ciclo no encontrado")

            cursor.execute("""
                SELECT id, cycle_id, is_ready, notes, generated_at, generated_by_user_id
                FROM nom035_audit_files
                WHERE cycle_id = %s
                LIMIT 1
            """, (cycle_id,))
            audit_file = fetch_one_dict(cursor) or {}

            cursor.execute("""
                SELECT
                    COUNT(*) AS total_assigned,
                    SUM(CASE WHEN status = 'submitted' THEN 1 ELSE 0 END) AS submitted_count,
                    SUM(CASE WHEN status = 'in_progress' THEN 1 ELSE 0 END) AS in_progress_count,
                    SUM(CASE WHEN status = 'available' THEN 1 ELSE 0 END) AS available_count,
                    AVG(COALESCE(score_total, 0)) AS avg_score
                FROM nom035_submissions
                WHERE cycle_id = %s
            """, (cycle_id,))
            submission_stats = fetch_one_dict(cursor) or {}

            cursor.execute("""
                SELECT
                    EXISTS(
                        SELECT 1
                        FROM nom035_evidences
                        WHERE cycle_id = %s
                          AND evidence_type = 'policy'
                        LIMIT 1
                    ) AS policy_uploaded,
                    EXISTS(
                        SELECT 1
                        FROM nom035_evidences
                        WHERE cycle_id = %s
                        LIMIT 1
                    ) AS evidence_uploaded,
                    EXISTS(
                        SELECT 1
                        FROM nom035_submissions
                        WHERE cycle_id = %s
                          AND status = 'submitted'
                        LIMIT 1
                    ) AS results_generated,
                    EXISTS(
                        SELECT 1
                        FROM nom035_action_plans
                        WHERE cycle_id = %s
                        LIMIT 1
                    ) AS action_plan_created
            """, (cycle_id, cycle_id, cycle_id, cycle_id))
            compliance = fetch_one_dict(cursor) or {}

            compliance["stps_file_ready"] = bool(audit_file.get("is_ready", 0))

            cursor.execute("""
                SELECT
                    id,
                    cycle_id,
                    action_title,
                    department_name,
                    status,
                    created_at
                FROM nom035_action_plans
                WHERE cycle_id = %s
                ORDER BY id DESC
            """, (cycle_id,))
            action_plans = fetch_all_dict(cursor)

            cursor.execute("""
                SELECT
                    id,
                    cycle_id,
                    action_plan_id,
                    evidence_type,
                    title,
                    file_name,
                    created_at
                FROM nom035_evidences
                WHERE cycle_id = %s
                ORDER BY id DESC
            """, (cycle_id,))
            evidences = fetch_all_dict(cursor)

            cursor.execute("""
                SELECT
                    COALESCE(risk_level, 'Sin riesgo') AS risk_level,
                    COUNT(*) AS total
                FROM nom035_submissions
                WHERE cycle_id = %s
                  AND status = 'submitted'
                GROUP BY COALESCE(risk_level, 'Sin riesgo')
                ORDER BY total DESC
            """, (cycle_id,))
            risk_distribution = fetch_all_dict(cursor)

            return {
                "ready": bool(audit_file.get("is_ready", 0)),
                "notes": audit_file.get("notes", ""),
                "generated_at": audit_file.get("generated_at"),
                "generated_by_user_id": audit_file.get("generated_by_user_id"),
                "cycle": cycle,
                "submission_stats": {
                    "total_assigned": int(submission_stats.get("total_assigned") or 0),
                    "submitted_count": int(submission_stats.get("submitted_count") or 0),
                    "in_progress_count": int(submission_stats.get("in_progress_count") or 0),
                    "available_count": int(submission_stats.get("available_count") or 0),
                    "avg_score": float(submission_stats.get("avg_score") or 0),
                },
                "compliance": {
                    "policy_uploaded": bool(compliance.get("policy_uploaded", 0)),
                    "evidence_uploaded": bool(compliance.get("evidence_uploaded", 0)),
                    "results_generated": bool(compliance.get("results_generated", 0)),
                    "action_plan_created": bool(compliance.get("action_plan_created", 0)),
                    "stps_file_ready": bool(compliance.get("stps_file_ready", 0)),
                },
                "action_plans": action_plans,
                "evidences": evidences,
                "risk_distribution": risk_distribution,
            }
    finally:
        conn.close()


@router.post("/rebuild")
def rebuild_nom035_audit_file(payload: RebuildAuditFileRequest):
    conn = get_mysql_conn()
    try:
        with conn.cursor() as cursor:
            cursor.execute("""
                SELECT id, title, year, status
                FROM nom035_cycles
                WHERE id = %s
                LIMIT 1
            """, (payload.cycle_id,))
            cycle = fetch_one_dict(cursor)

            if not cycle:
                raise HTTPException(status_code=404, detail="Ciclo no encontrado")

            cursor.execute("""
                SELECT COUNT(*) AS total
                FROM nom035_evidences
                WHERE cycle_id = %s
                  AND evidence_type = 'policy'
            """, (payload.cycle_id,))
            policy_count = int((fetch_one_dict(cursor) or {}).get("total", 0))
            policy_uploaded = policy_count > 0

            cursor.execute("""
                SELECT COUNT(*) AS total
                FROM nom035_evidences
                WHERE cycle_id = %s
            """, (payload.cycle_id,))
            evidence_count = int((fetch_one_dict(cursor) or {}).get("total", 0))
            evidence_uploaded = evidence_count > 0

            cursor.execute("""
                SELECT COUNT(*) AS total
                FROM nom035_submissions
                WHERE cycle_id = %s
                  AND status = 'submitted'
            """, (payload.cycle_id,))
            submitted_count = int((fetch_one_dict(cursor) or {}).get("total", 0))
            results_generated = submitted_count > 0

            cursor.execute("""
                SELECT COUNT(*) AS total
                FROM nom035_action_plans
                WHERE cycle_id = %s
            """, (payload.cycle_id,))
            action_plan_count = int((fetch_one_dict(cursor) or {}).get("total", 0))
            action_plan_created = action_plan_count > 0

            is_ready = (
                policy_uploaded
                and evidence_uploaded
                and results_generated
                and action_plan_created
            )

            notes_parts = []
            if not policy_uploaded:
                notes_parts.append("Falta política")
            if not evidence_uploaded:
                notes_parts.append("Faltan evidencias")
            if not results_generated:
                notes_parts.append("Faltan resultados")
            if not action_plan_created:
                notes_parts.append("Falta plan de acción")

            notes = (
                "Expediente completo NOM-035"
                if is_ready
                else " | ".join(notes_parts)
            )

            cursor.execute("""
                INSERT INTO nom035_audit_files (
                    cycle_id,
                    is_ready,
                    notes,
                    generated_at,
                    generated_by_user_id
                )
                VALUES (%s, %s, %s, NOW(), %s)
                ON DUPLICATE KEY UPDATE
                    is_ready = VALUES(is_ready),
                    notes = VALUES(notes),
                    generated_at = NOW(),
                    generated_by_user_id = VALUES(generated_by_user_id)
            """, (
                payload.cycle_id,
                1 if is_ready else 0,
                notes,
                payload.generated_by_user_id,
            ))

            conn.commit()

            return {
                "ok": True,
                "cycle_id": payload.cycle_id,
                "is_ready": is_ready,
                "notes": notes,
                "compliance": {
                    "policy_uploaded": policy_uploaded,
                    "evidence_uploaded": evidence_uploaded,
                    "results_generated": results_generated,
                    "action_plan_created": action_plan_created,
                    "stps_file_ready": is_ready,
                }
            }
    except HTTPException:
        raise
    except Exception as e:
        conn.rollback()
        raise HTTPException(
            status_code=500,
            detail=f"Error al reconstruir expediente: {e}"
        )
    finally:
        conn.close()