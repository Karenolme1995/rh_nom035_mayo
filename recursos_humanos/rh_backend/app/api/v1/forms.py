# app/api/v1/forms.py
from typing import Any, Dict, List, Optional
from fastapi import APIRouter, Depends, HTTPException, status
from app.core.db import get_db
from app.dependencies.auth import get_current_user
from app.dependencies.roles import require_role

router = APIRouter(prefix="/forms", tags=["Forms"])


def _get_user_area(db, user_id: int) -> str:
    cur = db.cursor(dictionary=True)
    try:
        cur.execute("SELECT area FROM users WHERE id=%s AND COALESCE(active,1)=1", (user_id,))
        row = cur.fetchone()
        if not row:
            raise HTTPException(status_code=404, detail="Usuario no encontrado")
        return (row.get("area") or "").strip()
    finally:
        cur.close()


@router.get("/available", dependencies=[Depends(require_role(1, 2, 3))])
def list_available_forms(db=Depends(get_db), u=Depends(get_current_user)):
    """
    Regresa formularios disponibles para el usuario:
      - scope=general o scope=area y forms.area == users.area (string)
      - dentro de open_at/due_at
      - dentro de horario start_time/end_time (si aplica)
      - si NO tiene submitted_at (si tiene in_progress, aparece como continuar)
    """
    user_id = int(u["id"])
    user_area = _get_user_area(db, user_id)

    cur = db.cursor(dictionary=True)
    try:
        cur.execute(
            """
            SELECT
              f.id               AS form_id,
              f.title            AS title,
              f.description      AS description,
              f.type             AS type,
              f.scope            AS scope,
              f.area             AS area,
              f.open_at          AS open_at,
              f.due_at           AS due_at,
              f.start_time       AS start_time,
              f.end_time         AS end_time,
              f.allow_save_draft AS allow_save_draft,
              f.shuffle_options  AS shuffle_options,

              s.id               AS submission_id,
              s.status           AS submission_status,
              s.started_at       AS started_at
            FROM forms f
            LEFT JOIN submissions s
              ON s.form_id = f.id AND s.user_id = %s
            WHERE
              COALESCE(f.active,1)=1
              AND COALESCE(f.published,1)=1

              AND (f.open_at IS NULL OR f.open_at <= NOW())
              AND (f.due_at  IS NULL OR f.due_at  >= NOW())

              AND (
                f.start_time IS NULL
                OR f.end_time IS NULL
                OR (TIME(NOW()) >= f.start_time AND TIME(NOW()) <= f.end_time)
              )

              AND (
                f.scope='general'
                OR (f.scope='area' AND f.area = %s)
              )

              -- si ya lo envió, NO debe aparecer aquí
              AND (s.submitted_at IS NULL)

            ORDER BY
              COALESCE(f.due_at, '2999-12-31 23:59:59') ASC,
              f.id DESC
            """,
            (user_id, user_area),
        )

        rows = cur.fetchall() or []
        # Normalizar estado para UI
        for r in rows:
            if r.get("submission_id") and (r.get("submission_status") == "in_progress"):
                r["status"] = "in_progress"
            else:
                r["status"] = "available"
        return rows
    finally:
        cur.close()


@router.get("/completed", dependencies=[Depends(require_role(1, 2, 3))])
def list_completed_forms(db=Depends(get_db), u=Depends(get_current_user)):
    """
    Regresa lo concluido: submitted_at no null
    """
    user_id = int(u["id"])
    cur = db.cursor(dictionary=True)
    try:
        cur.execute(
            """
            SELECT
              f.id          AS form_id,
              f.title       AS title,
              f.type        AS type,
              s.id          AS submission_id,
              s.status      AS status,
              s.started_at  AS started_at,
              s.submitted_at AS submitted_at,
              s.score       AS score,
              s.observations AS observations,
              s.reviewed_at AS reviewed_at
            FROM submissions s
            INNER JOIN forms f ON f.id = s.form_id
            WHERE
              s.user_id = %s
              AND s.submitted_at IS NOT NULL
              AND COALESCE(f.active,1)=1
            ORDER BY s.submitted_at DESC
            """,
            (user_id,),
        )
        return cur.fetchall()
    finally:
        cur.close()


@router.get("/{form_id}", dependencies=[Depends(require_role(1, 2, 3))])
def get_form_detail(form_id: int, db=Depends(get_db), u=Depends(get_current_user)):
    """
    Devuelve:
      - form (instrucciones)
      - secciones
      - preguntas + opciones
    """
    user_id = int(u["id"])
    user_area = _get_user_area(db, user_id)

    cur = db.cursor(dictionary=True)
    try:
        # Validar que el usuario pueda ver el form (general o su área)
        cur.execute(
            """
            SELECT *
            FROM forms
            WHERE id=%s AND COALESCE(active,1)=1 AND COALESCE(published,1)=1
            """,
            (form_id,),
        )
        form = cur.fetchone()
        if not form:
            raise HTTPException(status_code=404, detail="Formulario no encontrado")

        if form["scope"] == "area" and (form.get("area") or "") != user_area:
            raise HTTPException(status_code=403, detail="No autorizado para este formulario")

        # Secciones
        cur.execute(
            """
            SELECT id, form_id, title, description, sort_order
            FROM form_sections
            WHERE form_id=%s
            ORDER BY sort_order ASC, id ASC
            """,
            (form_id,),
        )
        sections = cur.fetchall() or []
        section_ids = [s["id"] for s in sections]

        questions: List[Dict[str, Any]] = []
        options_by_q: Dict[int, List[Dict[str, Any]]] = {}

        if section_ids:
            # Preguntas
            format_ids = ",".join(["%s"] * len(section_ids))
            cur.execute(
                f"""
                SELECT
                  id, section_id, question_text, question_type, required, points, sort_order
                FROM questions
                WHERE section_id IN ({format_ids})
                ORDER BY section_id ASC, sort_order ASC, id ASC
                """,
                tuple(section_ids),
            )
            questions = cur.fetchall() or []

            q_ids = [q["id"] for q in questions]
            if q_ids:
                format_q = ",".join(["%s"] * len(q_ids))
                cur.execute(
                    f"""
                    SELECT
                      id, question_id, option_text, is_correct, sort_order
                    FROM question_options
                    WHERE question_id IN ({format_q})
                    ORDER BY question_id ASC, sort_order ASC, id ASC
                    """,
                    tuple(q_ids),
                )
                opts = cur.fetchall() or []
                for o in opts:
                    options_by_q.setdefault(int(o["question_id"]), []).append(o)

        # Armar estructura tipo Google Forms
        sections_out = []
        for s in sections:
            sid = int(s["id"])
            sec_questions = [q for q in questions if int(q["section_id"]) == sid]
            for q in sec_questions:
                qid = int(q["id"])
                q["options"] = options_by_q.get(qid, [])
            sections_out.append(
                {
                    "id": sid,
                    "title": s["title"],
                    "description": s.get("description"),
                    "sort_order": s.get("sort_order"),
                    "questions": sec_questions,
                }
            )

        return {
            "form": {
                "id": form["id"],
                "title": form["title"],
                "description": form.get("description"),
                "type": form.get("type"),
                "scope": form.get("scope"),
                "area": form.get("area"),
                "open_at": form.get("open_at"),
                "due_at": form.get("due_at"),
                "start_time": form.get("start_time"),
                "end_time": form.get("end_time"),
                "allow_save_draft": form.get("allow_save_draft"),
                "shuffle_options": form.get("shuffle_options"),
            },
            "sections": sections_out,
        }
    finally:
        cur.close()
