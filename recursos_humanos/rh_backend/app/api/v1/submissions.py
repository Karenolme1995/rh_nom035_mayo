# app/api/v1/submissions.py
from typing import Any, Dict, List, Optional, Union
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field
from app.core.db import get_db
from app.dependencies.auth import get_current_user
from app.dependencies.roles import require_role

router = APIRouter(tags=["Submissions"])


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


def _validate_form_access(db, form_id: int, user_area: str) -> Dict[str, Any]:
    cur = db.cursor(dictionary=True)
    try:
        cur.execute(
            "SELECT * FROM forms WHERE id=%s AND COALESCE(active,1)=1 AND COALESCE(published,1)=1",
            (form_id,),
        )
        form = cur.fetchone()
        if not form:
            raise HTTPException(status_code=404, detail="Formulario no encontrado")

        if form["scope"] == "area" and (form.get("area") or "") != user_area:
            raise HTTPException(status_code=403, detail="No autorizado para este formulario")

        # Validación de fechas/horarios (por si intentan entrar directo)
        # open_at/due_at
        cur.execute(
            """
            SELECT
              (open_at IS NULL OR open_at <= NOW()) AS ok_open,
              (due_at  IS NULL OR due_at  >= NOW()) AS ok_due,
              (
                start_time IS NULL
                OR end_time IS NULL
                OR (TIME(NOW()) >= start_time AND TIME(NOW()) <= end_time)
              ) AS ok_time
            FROM forms
            WHERE id=%s
            """,
            (form_id,),
        )
        chk = cur.fetchone() or {}
        if not chk.get("ok_open") or not chk.get("ok_due") or not chk.get("ok_time"):
            raise HTTPException(status_code=403, detail="Formulario fuera de ventana/horario permitido")

        return form
    finally:
        cur.close()


class AnswerItem(BaseModel):
    question_id: int
    # Para single: option_id
    option_id: Optional[int] = None
    # Para multi: option_ids
    option_ids: Optional[List[int]] = None
    # Para text:
    answer_text: Optional[str] = None


class SaveAnswersPayload(BaseModel):
    answers: List[AnswerItem] = Field(default_factory=list)


class ReviewPayload(BaseModel):
    score: float
    observations: Optional[str] = ""


@router.post("/forms/{form_id}/start", dependencies=[Depends(require_role(1, 2, 3))])
def start_form(form_id: int, db=Depends(get_db), u=Depends(get_current_user)):
    """
    Crea o retorna submission (1 por usuario, sin reintentos).
    - Si ya está submitted, bloquea.
    """
    user_id = int(u["id"])
    user_area = _get_user_area(db, user_id)
    _validate_form_access(db, form_id, user_area)

    cur = db.cursor(dictionary=True)
    cur2 = db.cursor()
    try:
        # ¿Ya existe submission?
        cur.execute(
            "SELECT * FROM submissions WHERE form_id=%s AND user_id=%s",
            (form_id, user_id),
        )
        sub = cur.fetchone()
        if sub:
            if sub.get("submitted_at") is not None:
                raise HTTPException(status_code=409, detail="Ya concluiste este formulario")
            # Si existe en progreso, lo devolvemos
            return {
                "submission_id": sub["id"],
                "status": sub["status"],
                "started_at": sub.get("started_at"),
            }

        # Crear submission nuevo
        cur2.execute(
            """
            INSERT INTO submissions (form_id, user_id, status, started_at)
            VALUES (%s, %s, 'in_progress', NOW())
            """,
            (form_id, user_id),
        )
        db.commit()
        submission_id = cur2.lastrowid

        return {"submission_id": submission_id, "status": "in_progress"}
    finally:
        cur.close()
        cur2.close()


@router.put("/submissions/{submission_id}/answers", dependencies=[Depends(require_role(1, 2, 3))])
def save_answers(submission_id: int, payload: SaveAnswersPayload, db=Depends(get_db), u=Depends(get_current_user)):
    """
    Guarda respuestas (borrador). Maneja:
      - single: option_id
      - multi: option_ids (lista)
      - text: answer_text
    Estrategia simple: borra respuestas previas de cada question_id y vuelve a insertar.
    """
    user_id = int(u["id"])

    cur = db.cursor(dictionary=True)
    curw = db.cursor()
    try:
        # Validar que submission sea del usuario y siga in_progress
        cur.execute(
            """
            SELECT s.*, f.id AS form_id, f.scope, f.area
            FROM submissions s
            INNER JOIN forms f ON f.id = s.form_id
            WHERE s.id=%s
            """,
            (submission_id,),
        )
        sub = cur.fetchone()
        if not sub:
            raise HTTPException(status_code=404, detail="Submission no encontrado")

        if int(sub["user_id"]) != user_id:
            raise HTTPException(status_code=403, detail="No autorizado")

        if sub.get("submitted_at") is not None or sub.get("status") != "in_progress":
            raise HTTPException(status_code=409, detail="Submission ya finalizado o no editable")

        # Borrar e insertar por pregunta
        for a in payload.answers:
            qid = int(a.question_id)
            curw.execute(
                "DELETE FROM answers WHERE submission_id=%s AND question_id=%s",
                (submission_id, qid),
            )

            # Multi selección
            if a.option_ids and len(a.option_ids) > 0:
                for oid in a.option_ids:
                    curw.execute(
                        """
                        INSERT INTO answers (submission_id, question_id, option_id, answer_text)
                        VALUES (%s,%s,%s,NULL)
                        """,
                        (submission_id, qid, int(oid)),
                    )
                continue

            # Single opción
            if a.option_id is not None:
                curw.execute(
                    """
                    INSERT INTO answers (submission_id, question_id, option_id, answer_text)
                    VALUES (%s,%s,%s,NULL)
                    """,
                    (submission_id, qid, int(a.option_id)),
                )
                continue

            # Texto libre
            if a.answer_text is not None:
                curw.execute(
                    """
                    INSERT INTO answers (submission_id, question_id, option_id, answer_text)
                    VALUES (%s,%s,NULL,%s)
                    """,
                    (submission_id, qid, a.answer_text),
                )

        db.commit()
        return {"message": "Respuestas guardadas"}
    finally:
        cur.close()
        curw.close()

@router.post("/submissions/{submission_id}/submit", dependencies=[Depends(require_role(1, 2, 3))])
def submit_form(submission_id: int, db=Depends(get_db), u=Depends(get_current_user)):
    """
    Finaliza submission: guarda submitted_at (HORA exacta) y status=submitted.
    Devuelve submitted_at real.
    """
    user_id = int(u["id"])

    cur = db.cursor(dictionary=True)
    curw = db.cursor()
    try:
        cur.execute("SELECT * FROM submissions WHERE id=%s", (submission_id,))
        sub = cur.fetchone()
        if not sub:
            raise HTTPException(status_code=404, detail="Submission no encontrado")

        if int(sub["user_id"]) != user_id:
            raise HTTPException(status_code=403, detail="No autorizado")

        if sub.get("submitted_at") is not None:
            raise HTTPException(status_code=409, detail="Ya enviado")

        curw.execute(
            """
            UPDATE submissions
            SET status='submitted', submitted_at=NOW()
            WHERE id=%s
            """,
            (submission_id,),
        )
        db.commit()

        # leer hora real
        cur.execute("SELECT submitted_at FROM submissions WHERE id=%s", (submission_id,))
        row = cur.fetchone() or {}

        return {"message": "Formulario enviado", "submitted_at": row.get("submitted_at")}
    finally:
        cur.close()
        curw.close()


@router.put("/submissions/{submission_id}/review", dependencies=[Depends(require_role(1, 2))])
def review_submission(submission_id: int, payload: ReviewPayload, db=Depends(get_db), u=Depends(get_current_user)):
    """
    Solo rol 1/2: asigna score y observations, marca reviewed.
    """
    reviewer_id = int(u["id"])

    cur = db.cursor(dictionary=True)
    curw = db.cursor()
    try:
        cur.execute("SELECT * FROM submissions WHERE id=%s", (submission_id,))
        sub = cur.fetchone()
        if not sub:
            raise HTTPException(status_code=404, detail="Submission no encontrado")

        if sub.get("submitted_at") is None:
            raise HTTPException(status_code=409, detail="Aún no se ha enviado, no se puede evaluar")

        curw.execute(
            """
            UPDATE submissions
            SET
              status='reviewed',
              score=%s,
              observations=%s,
              reviewer_id=%s,
              reviewed_at=NOW()
            WHERE id=%s
            """,
            (payload.score, payload.observations or "", reviewer_id, submission_id),
        )
        db.commit()

        return {"message": "Evaluación guardada"}
    finally:
        cur.close()
        curw.close()


@router.get("/submissions/{submission_id}", dependencies=[Depends(require_role(1, 2, 3))])
def get_submission_detail(submission_id: int, db=Depends(get_db), u=Depends(get_current_user)):
    """
    Devuelve detalle de la submission para:
    - empleado dueño (rol 1/2/3)
    - o admin/RH (rol 1/2) aunque no sea dueño
    """
    user_id = int(u["id"])
    role_id = u.get("role_id")

    cur = db.cursor(dictionary=True)
    try:
        cur.execute(
            """
            SELECT
              s.id,
              s.form_id,
              f.title,
              f.type,
              s.status,
              s.started_at,
              s.submitted_at,
              s.reviewed_at,
              s.score,
              s.observations,
              s.user_id,
              s.reviewer_id
            FROM submissions s
            INNER JOIN forms f ON f.id = s.form_id
            WHERE s.id=%s
            """,
            (submission_id,),
        )
        row = cur.fetchone()
        if not row:
            raise HTTPException(status_code=404, detail="Submission no encontrado")

        # permisos: dueño o rol 1/2
        if int(row["user_id"]) != user_id and role_id not in (1, 2, "1", "2"):
            raise HTTPException(status_code=403, detail="No autorizado")

        return row
    finally:
        cur.close()
