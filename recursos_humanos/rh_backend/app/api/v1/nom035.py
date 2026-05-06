# rh_backend/app/v1/nom035.py
import io
from sqlalchemy.orm import Session
from sqlalchemy import text
from fastapi import APIRouter, Depends, HTTPException, Query
from fastapi.responses import StreamingResponse
from app.dependencies.auth import get_current_user
from app.core.db_mysql import get_mysql_conn
from app.dependencies.roles import require_role
from app.schemas.nom035 import (
    Nom035AnswerIn,
    Nom035CycleUpsert,
    Nom035QuestionUpsert,
    Nom035SetCycleQuestions,
)

from app.services.nom035_service import nom035_service


router = APIRouter(
    prefix="/nom035",
    tags=["NOM-035"],
    dependencies=[Depends(require_role(1, 2, 3))],
)


@router.get("/forms/available")
def nom035_available(db=Depends(get_mysql_conn), user: dict = Depends(get_current_user)):
    try:
        user_id = int(user.get("id", 0))
        return nom035_service.available_forms_for_user(conn=db, user_id=user_id)
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.get("/forms/completed")
def nom035_completed(db: Session = Depends(get_mysql_conn), user: dict = Depends(get_current_user)):
    try:
       user_id = int(user.get("id", 0))
       return nom035_service.completed_forms_for_user(db, user_id)
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.post("/forms/{cycle_id}/start")
def nom035_start(
    cycle_id: int,
    db = Depends(get_mysql_conn),
    user: dict = Depends(get_current_user),
):
    try:
        user_id = int(user.get("id", 0))
        return nom035_service.start_form(conn=db, cycle_id=cycle_id, user_id=user_id)
    except PermissionError as e:
        raise HTTPException(status_code=403, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.get("/forms/{cycle_id}/detail")
def nom035_form_detail(
    cycle_id: int,
    db = Depends(get_mysql_conn),
    user: dict = Depends(get_current_user),
):
    try:
        user_id = int(user.get("id", 0))
        return nom035_service.get_form_detail(conn=db, cycle_id=cycle_id, user_id=user_id)
    except PermissionError as e:
        raise HTTPException(status_code=403, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.post("/submissions/{submission_id}/answer")
def nom035_answer(
    submission_id: int,
    payload: Nom035AnswerIn,
    db: Session = Depends(get_mysql_conn),
    user: dict = Depends(get_current_user),
):
    try:
        import json

        user_id = int(user.get("id", 0))

        if payload.option_id is not None:
            answer_value = str(payload.option_id)

        elif payload.option_ids is not None:
            answer_value = json.dumps(payload.option_ids, ensure_ascii=False)

        elif payload.answer_text is not None and payload.answer_text.strip():
            answer_value = payload.answer_text.strip()

        elif payload.answer_value is not None:
            if isinstance(payload.answer_value, list):
                answer_value = json.dumps(payload.answer_value, ensure_ascii=False)
            else:
                answer_value = str(payload.answer_value).strip()

            if not answer_value:
                raise HTTPException(status_code=422, detail="Respuesta vacía")

        else:
            raise HTTPException(status_code=422, detail="Respuesta vacía")

        return nom035_service.upsert_answer(
            conn=db,
            submission_id=submission_id,
            user_id=user_id,
            question_id=payload.question_id,
            answer_value=answer_value,
        )

    except HTTPException:
        raise
    except PermissionError as e:
        raise HTTPException(status_code=403, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))
#


@router.post("/submissions/{submission_id}/submit")
def nom035_submit(submission_id: int, db: Session = Depends(get_mysql_conn), user: dict = Depends(get_current_user)):
    try:
        user_id = int(user.get("id", 0))
        return nom035_service.submit_form(db, submission_id, user_id)
    except PermissionError as e:
        raise HTTPException(status_code=403, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.get("/submissions/{submission_id}/result")
def nom035_result(submission_id: int, db: Session = Depends(get_mysql_conn), user: dict = Depends(get_current_user)):
    try:
        return nom035_service.get_result(db, submission_id, user)
    except PermissionError as e:
        raise HTTPException(status_code=403, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))



#----------------------------------------------------#
@router.get("/submissions/{submission_id}/answers")
def get_nom035_submission_answers(
    submission_id: int,
    db = Depends(get_mysql_conn),
    user: dict = Depends(get_current_user),
):
    cursor = None
    try:
        cursor = db.cursor(dictionary=True)

        cursor.execute("""
            SELECT
                question_id,
                answer_value
            FROM nom035_answers
            WHERE submission_id = %s
            ORDER BY question_id
        """, (submission_id,))

        rows = cursor.fetchall()

        out = []

        for r in rows:
            val = r["answer_value"]
            question_id = int(r["question_id"])

            if val is None:
                continue

            val_str = str(val).strip()
            if not val_str:
                continue

            item = {"question_id": question_id}

            # multiselección guardada como JSON: [1,2]
            if val_str.startswith("[") and val_str.endswith("]"):
                try:
                    import json
                    parsed = json.loads(val_str)
                    if isinstance(parsed, list):
                        item["option_ids"] = parsed
                    else:
                        item["answer_text"] = val_str
                except Exception:
                    item["answer_text"] = val_str

            # opción numérica
            elif val_str.isdigit():
                item["option_id"] = int(val_str)

            # opción tipo "M", "F", "25-29", etc.
            elif len(val_str) <= 50:
                item["option_id"] = val_str

            # texto libre
            else:
                item["answer_text"] = val_str

            out.append(item)

        return out

    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Error get answers: {str(e)}")
    finally:
        if cursor is not None:
            cursor.close()
# ============================
# ADMIN (role_id 1,2)
# ============================

@router.get("/admin/cycles")
def admin_cycles(db: Session = Depends(get_mysql_conn), user: dict = Depends(get_current_user)):
    try:
        return nom035_service.admin_list_cycles(db, user)
    except PermissionError as e:
        raise HTTPException(status_code=403, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.post("/admin/cycles")
def admin_create_cycle(payload: Nom035CycleUpsert, db: Session = Depends(get_mysql_conn), user: dict = Depends(get_current_user)):
    try:
        return nom035_service.admin_create_cycle(db, user, payload.model_dump())
    except PermissionError as e:
        raise HTTPException(status_code=403, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.put("/admin/cycles/{cycle_id}")
def admin_update_cycle(
    cycle_id: int,
    payload: Nom035CycleUpsert,
    db: Session = Depends(get_mysql_conn),
    user: dict = Depends(get_current_user),
):
    try:
        return nom035_service.admin_update_cycle(
            db,
            user,
            cycle_id,
            payload.model_dump(),
        )
    except PermissionError as e:
        raise HTTPException(status_code=403, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.delete("/admin/cycles/{cycle_id}")
def admin_delete_cycle(
    cycle_id: int,
    db: Session = Depends(get_mysql_conn),
    user: dict = Depends(get_current_user),
):
    try:
        return nom035_service.admin_delete_cycle(db, user, cycle_id)
    except PermissionError as e:
        raise HTTPException(status_code=403, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.get("/admin/questions")
def admin_questions(db: Session = Depends(get_mysql_conn), user: dict = Depends(get_current_user)):
    try:
        return nom035_service.admin_list_questions(db, user)
    except PermissionError as e:
        raise HTTPException(status_code=403, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.post("/admin/questions")
def admin_upsert_question(payload: Nom035QuestionUpsert, db: Session = Depends(get_mysql_conn), user: dict = Depends(get_current_user)):
    try:
        return nom035_service.admin_upsert_question(db, user, payload.model_dump())
    except PermissionError as e:
        raise HTTPException(status_code=403, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.post("/admin/cycles/{cycle_id}/questions")
def admin_cycle_questions(cycle_id: int, payload: Nom035SetCycleQuestions, db: Session = Depends(get_mysql_conn), user: dict = Depends(get_current_user)):
    try:
        return nom035_service.admin_set_cycle_questions(db, user, cycle_id, payload.question_ids)
    except PermissionError as e:
        raise HTTPException(status_code=403, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))
    



# ADMIN - SUBMISSIONS / RESULTADOS (role_id 1,2)


@router.get("/admin/cycles/{cycle_id}/submissions", dependencies=[Depends(require_role(1, 2))])
def admin_cycle_submissions(
    cycle_id: int,
    status: str | None = Query(default=None, description="available|in_progress|submitted"),
    q: str | None = Query(default=None, description="Búsqueda por nombre/empleado/área"),
    risk: str | None = Query(default=None, description="Filtro por risk_level"),
    page: int = Query(default=1, ge=1),
    page_size: int = Query(default=25, ge=1, le=200),
    db: Session = Depends(get_mysql_conn),
    user: dict = Depends(get_current_user),
):
    """
    Lista de usuarios y sus submissions del ciclo (para Admin).
    """
    try:
        return nom035_service.admin_list_cycle_submissions(
        db, user, cycle_id,
        status=status,
        q=q,
        risk=risk,
        page=page,
        page_size=page_size,
        )
    except PermissionError as e:
        raise HTTPException(status_code=403, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.get("/admin/submissions/{submission_id}", dependencies=[Depends(require_role(1, 2))])
def admin_submission_detail(
    submission_id: int,
    db: Session = Depends(get_mysql_conn),
    user: dict = Depends(get_current_user),
):
    """
    Detalle completo de la guía respondida (secciones -> preguntas -> respuesta elegida),
    para corroboración de evaluación.
    """
    try:
        return nom035_service.admin_get_submission_detail(db, user, submission_id)
    except PermissionError as e:
        raise HTTPException(status_code=403, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.get("/admin/submissions/{submission_id}/export", dependencies=[Depends(require_role(1, 2))])
def admin_export_submission(
    submission_id: int,
    format: str = Query(default="pdf", description="pdf|xlsx|docx"),
    db: Session = Depends(get_mysql_conn),
    user: dict = Depends(get_current_user),
):
    """
    Exporta la guía respondida a PDF / Excel / Word.
    Retorna archivo descargable.
    """
    try:
        fmt = (format or "").lower().strip()
        if fmt not in ("pdf", "xlsx", "docx"):
            raise HTTPException(status_code=422, detail="format inválido. Usa: pdf|xlsx|docx")

        # Esperamos que el service regrese: {"filename": "...", "content_type": "...", "bytes": b"..."}
        result = nom035_service.admin_export_submission(db, user, submission_id, fmt=fmt)

        filename = result.get("filename") or f"nom035_submission_{submission_id}.{fmt}"
        content_type = result.get("content_type") or "application/octet-stream"
        data = result.get("bytes") or b""

        return StreamingResponse(
            io.BytesIO(data),
            media_type=content_type,
            headers={"Content-Disposition": f'attachment; filename="{filename}"'},
        )

    except HTTPException:
        raise
    except PermissionError as e:
        raise HTTPException(status_code=403, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.get("/admin/cycles/{cycle_id}/metrics", dependencies=[Depends(require_role(1, 2))])
def admin_cycle_metrics(
    cycle_id: int,
    db: Session = Depends(get_mysql_conn),
    user: dict = Depends(get_current_user),
):
    """
    Métricas del ciclo para gráficas (KPIs, conteos por riesgo, progreso, etc).
    """
    try:
        return nom035_service.admin_cycle_metrics(db, user, cycle_id)
    except PermissionError as e:
        raise HTTPException(status_code=403, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.get("/admin/sections")
def admin_sections(db: Session = Depends(get_mysql_conn), user: dict = Depends(get_current_user)):
    try:
        return nom035_service.admin_list_sections(db, user)
    except PermissionError as e:
        raise HTTPException(status_code=403, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))
      

