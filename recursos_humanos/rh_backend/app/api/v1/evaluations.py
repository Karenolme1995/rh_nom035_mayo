import json

from fastapi import APIRouter, Depends, HTTPException
from app.dependencies.auth import get_current_user


from app.core.db import get_db

router = APIRouter(prefix="/evaluations", tags=["Evaluations"])


# =========================
# HELPERS
# =========================

def require_admin_or_rh(user: dict):
    role_id = int(user.get("role_id", 0))
    if role_id not in (1, 2):
        raise HTTPException(status_code=403, detail="No autorizado (solo Admin/RH)")


def _get_user_id(user: dict):
    return user.get("user_id") or user.get("id")


def _get_role_id(user: dict) -> int:
    return int(user.get("role_id", 0))


def _is_true(value) -> bool:
    return value is True or value == 1 or value == "1"


def _parse_json_list(value) -> list:
    if not value:
        return []

    if isinstance(value, list):
        return value

    if isinstance(value, str):
        try:
            data = json.loads(value)
            return data if isinstance(data, list) else []
        except Exception:
            return []

    return []


def _get_user_area_position(cur, user: dict) -> dict:
    user_id = _get_user_id(user)

    cur.execute(
        """
        SELECT id, name, area, position
        FROM users
        WHERE id = %s
        LIMIT 1
        """,
        (user_id,),
    )

    user_row = cur.fetchone()

    area_value = (user_row.get("area") or "").strip()
    position_value = (user_row.get("position") or "").strip()

    area_id = None
    position_id = None

    # 🔥 SI YA ES NÚMERO → USAR DIRECTO
    if area_value.isdigit():
        area_id = int(area_value)
    else:
        cur.execute(
            """
            SELECT id
            FROM areas
            WHERE UPPER(TRIM(name)) = UPPER(TRIM(%s))
            LIMIT 1
            """,
            (area_value,),
        )
        row = cur.fetchone()
        if row:
            area_id = row["id"]

    # 🔥 MISMA LÓGICA PARA POSITION
    if position_value.isdigit():
        position_id = int(position_value)
    else:
        if area_id:
            cur.execute(
                """
                SELECT id
                FROM positions
                WHERE area_id = %s
                  AND UPPER(TRIM(name)) = UPPER(TRIM(%s))
                LIMIT 1
                """,
                (area_id, position_value),
            )
            row = cur.fetchone()
        else:
            row = None

        if not row:
            cur.execute(
                """
                SELECT id
                FROM positions
                WHERE UPPER(TRIM(name)) = UPPER(TRIM(%s))
                LIMIT 1
                """,
                (position_value,),
            )
            row = cur.fetchone()

        if row:
            position_id = row["id"]

    print("DEBUG FIX FINAL:", {
        "area_raw": area_value,
        "position_raw": position_value,
        "area_id": area_id,
        "position_id": position_id,
    })

    return {
        "user_id": user_id,
        "area": area_value,
        "position": position_value,
        "area_id": area_id,
        "position_id": position_id,
    }


def _insert_evaluation_targets(cur, evaluation_id: int, payload: dict):
    all_areas = int(payload.get("all_areas") or 0)
    all_positions = int(payload.get("all_positions") or 0)

    area_ids = payload.get("area_ids") or []
    position_ids = payload.get("position_ids") or []

    if all_areas == 1 and all_positions == 1:
        return

    if all_areas == 1 and all_positions == 0:
        for position_id in position_ids:
            try:
                position_id = int(position_id)
            except Exception:
                continue

            cur.execute(
                """
                INSERT INTO evaluation_targets (evaluation_id, area_id, position_id)
                VALUES (%s, NULL, %s)
                """,
                (evaluation_id, position_id),
            )
        return

    if all_areas == 0 and all_positions == 1:
        for area_id in area_ids:
            try:
                area_id = int(area_id)
            except Exception:
                continue

            cur.execute(
                """
                INSERT INTO evaluation_targets (evaluation_id, area_id, position_id)
                VALUES (%s, %s, NULL)
                """,
                (evaluation_id, area_id),
            )
        return

    for area_id in area_ids:
        try:
            area_id = int(area_id)
        except Exception:
            continue

        for position_id in position_ids:
            try:
                position_id = int(position_id)
            except Exception:
                continue

            cur.execute(
                """
                INSERT INTO evaluation_targets (evaluation_id, area_id, position_id)
                VALUES (%s, %s, %s)
                """,
                (evaluation_id, area_id, position_id),
            )


def _insert_sections_questions_options(cur, evaluation_id: int, payload: dict):
    for section_index, section in enumerate(payload.get("sections", []), start=1):
        cur.execute(
            """
            INSERT INTO evaluation_sections (evaluation_id, title, description, order_index)
            VALUES (%s, %s, %s, %s)
            """,
            (
                evaluation_id,
                section.get("title"),
                section.get("description"),
                section.get("order_index") or section_index,
            ),
        )

        section_id = cur.lastrowid

        for question_index, q in enumerate(section.get("questions", []), start=1):
            cur.execute(
                """
                INSERT INTO evaluation_questions (
                    section_id, question_text, question_type, is_required,
                    order_index, image_url, points
                )
                VALUES (%s, %s, %s, %s, %s, %s, %s)
                """,
                (
                    section_id,
                    q.get("question_text"),
                    q.get("question_type"),
                    1 if q.get("is_required") else 0,
                    q.get("order_index") or question_index,
                    q.get("image_url"),
                    int(q.get("points") or 0),
                ),
            )

            question_id = cur.lastrowid

            if q.get("question_type") == "text":
                continue

            for opt in q.get("options", []):
                option_text = opt.get("option_text")

                if option_text is None or str(option_text).strip() == "":
                    continue

                cur.execute(
                    """
                    INSERT INTO evaluation_options (question_id, option_text, value)
                    VALUES (%s, %s, %s)
                    """,
                    (question_id, option_text, int(opt.get("value") or 0)),
                )


# =========================
# EMPLEADO: LISTAR EVALUACIONES DISPONIBLES
# =========================

@router.get("/available")
def get_available_evaluations(current_user: dict = Depends(get_current_user)):
    conn = get_db()
    cursor = conn.cursor(dictionary=True)

    try:
        user_info = _get_user_area_position(cursor, current_user)

        area_id = user_info["area_id"]
        position_id = user_info["position_id"]
        user_id = user_info["user_id"]

        cursor.execute(
            """
            SELECT DISTINCT
                e.id,
                e.name,
                e.description,
                e.type,
                e.is_active,
                e.all_areas,
                e.all_positions,
                e.created_at,
                CASE 
                    WHEN e.all_areas = 1 THEN 'Todas las áreas'
                    ELSE GROUP_CONCAT(DISTINCT a.name ORDER BY a.name SEPARATOR ', ')
                END AS area_name,
                CASE 
                    WHEN e.all_positions = 1 THEN 'Todos los puestos'
                    ELSE GROUP_CONCAT(DISTINCT p.name ORDER BY p.name SEPARATOR ', ')
                END AS position_name
            FROM evaluations e
            LEFT JOIN evaluation_targets et ON et.evaluation_id = e.id
            LEFT JOIN areas a ON a.id = et.area_id
            LEFT JOIN positions p ON p.id = et.position_id
            WHERE e.is_active = 1

              AND NOT EXISTS (
                  SELECT 1
                  FROM evaluation_submissions es_done
                  WHERE es_done.evaluation_id = e.id
                    AND es_done.user_id = %s
                    AND es_done.status = 'completed'
              )

                AND (
                e.all_areas = 1
                OR (
                %s IS NOT NULL
                AND EXISTS (
                SELECT 1
                FROM evaluation_targets et_area
                WHERE et_area.evaluation_id = e.id
                AND et_area.area_id = %s
                )
                )
                )


                            AND (
                            e.all_positions = 1
                            OR (
                            %s IS NOT NULL
                            AND EXISTS (
                            SELECT 1
                            FROM evaluation_targets et_pos
                            WHERE et_pos.evaluation_id = e.id
                            AND et_pos.position_id = %s
                            )
                            )
                            )
              )

            GROUP BY
                e.id, e.name, e.description, e.type, e.is_active,
                e.all_areas, e.all_positions, e.created_at
            ORDER BY e.created_at DESC
            """,
            (user_id, area_id, area_id, position_id, position_id),
        )

        evaluations = cursor.fetchall()

        return {
            "ok": True,
            "user": user_info,
            "evaluations": evaluations,
        }

    finally:
        cursor.close()
        conn.close()


# =========================
# EMPLEADO / ADMIN: LISTAR CONCLUIDAS
# =========================

@router.get("/completed")
def get_completed_evaluations(
    db=Depends(get_db),
    user=Depends(get_current_user),
):
    cur = db.cursor(dictionary=True)

    try:
        user_id = _get_user_id(user)
        role_id = _get_role_id(user)

        if not user_id:
            raise HTTPException(status_code=401, detail="Usuario no identificado en token")

        if role_id in (1, 2):
            cur.execute(
                """
                SELECT 
                    e.id,
                    e.name,
                    e.description,
                    e.type,
                    e.is_active,
                    e.all_areas,
                    e.all_positions,
                    e.created_at,
                    es.status,
                    es.score,
                    es.id AS submission_id,
                    es.completed_at,
                    u.id AS user_id,
                    u.name AS user_name,
                    u.employee_number,
                    u.area,
                    u.position,
                    CASE 
                        WHEN e.all_areas = 1 THEN 'Todas las áreas'
                        ELSE GROUP_CONCAT(DISTINCT a.name ORDER BY a.name SEPARATOR ', ')
                    END AS area_name,
                    CASE 
                        WHEN e.all_positions = 1 THEN 'Todos los puestos'
                        ELSE GROUP_CONCAT(DISTINCT p.name ORDER BY p.name SEPARATOR ', ')
                    END AS position_name
                FROM evaluations e
                LEFT JOIN evaluation_targets et ON et.evaluation_id = e.id
                LEFT JOIN areas a ON a.id = et.area_id
                LEFT JOIN positions p ON p.id = et.position_id
                INNER JOIN evaluation_submissions es ON es.evaluation_id = e.id
                INNER JOIN users u ON u.id = es.user_id
                WHERE es.status = 'completed'
                GROUP BY 
                    e.id, e.name, e.description, e.type, e.is_active,
                    e.all_areas, e.all_positions, e.created_at,
                    es.status, es.score, es.id, es.completed_at,
                    u.id, u.name, u.employee_number, u.area, u.position
                ORDER BY es.completed_at DESC
                """
            )
        else:
            cur.execute(
                """
                SELECT 
                    e.id,
                    e.name,
                    e.description,
                    e.type,
                    e.is_active,
                    e.all_areas,
                    e.all_positions,
                    e.created_at,
                    es.status,
                    es.score,
                    es.id AS submission_id,
                    es.completed_at,
                    CASE 
                        WHEN e.all_areas = 1 THEN 'Todas las áreas'
                        ELSE GROUP_CONCAT(DISTINCT a.name ORDER BY a.name SEPARATOR ', ')
                    END AS area_name,
                    CASE 
                        WHEN e.all_positions = 1 THEN 'Todos los puestos'
                        ELSE GROUP_CONCAT(DISTINCT p.name ORDER BY p.name SEPARATOR ', ')
                    END AS position_name
                FROM evaluation_submissions es
                INNER JOIN evaluations e ON e.id = es.evaluation_id
                LEFT JOIN evaluation_targets et ON et.evaluation_id = e.id
                LEFT JOIN areas a ON a.id = et.area_id
                LEFT JOIN positions p ON p.id = et.position_id
                WHERE es.user_id = %s
                  AND es.status = 'completed'
                GROUP BY 
                    e.id, e.name, e.description, e.type, e.is_active,
                    e.all_areas, e.all_positions, e.created_at,
                    es.status, es.score, es.id, es.completed_at
                ORDER BY es.completed_at DESC
                """,
                (user_id,),
            )

        return {"ok": True, "items": cur.fetchall()}

    finally:
        cur.close()


# =========================
# ADMIN: LISTAR TODAS
# =========================

@router.get("/admin")
def admin_list_evaluations(
    db=Depends(get_db),
    user=Depends(get_current_user),
):
    require_admin_or_rh(user)

    cur = db.cursor(dictionary=True)

    try:
        cur.execute(
            """
            SELECT 
                e.id,
                e.name,
                e.description,
                e.type,
                e.is_active,
                e.all_areas,
                e.all_positions,
                e.created_by,
                e.created_at,
                NULL AS status,
                CASE 
                    WHEN e.all_areas = 1 THEN 'Todas las áreas'
                    ELSE GROUP_CONCAT(DISTINCT a.name ORDER BY a.name SEPARATOR ', ')
                END AS area_name,
                CASE 
                    WHEN e.all_positions = 1 THEN 'Todos los puestos'
                    ELSE GROUP_CONCAT(DISTINCT p.name ORDER BY p.name SEPARATOR ', ')
                END AS position_name,
                GROUP_CONCAT(DISTINCT et.area_id ORDER BY et.area_id SEPARATOR ',') AS area_ids_csv,
                GROUP_CONCAT(DISTINCT et.position_id ORDER BY et.position_id SEPARATOR ',') AS position_ids_csv,
                COUNT(DISTINCT CASE WHEN es.status = 'completed' THEN es.id END) AS completed_count,
                COUNT(DISTINCT es.id) AS started_count
            FROM evaluations e
            LEFT JOIN evaluation_targets et ON et.evaluation_id = e.id
            LEFT JOIN areas a ON a.id = et.area_id
            LEFT JOIN positions p ON p.id = et.position_id
            LEFT JOIN evaluation_submissions es ON es.evaluation_id = e.id
            GROUP BY 
                e.id,
                e.name,
                e.description,
                e.type,
                e.is_active,
                e.all_areas,
                e.all_positions,
                e.created_by,
                e.created_at
            ORDER BY e.created_at DESC
            """
        )

        rows = cur.fetchall()

        for row in rows:
            area_csv = row.pop("area_ids_csv", None)
            position_csv = row.pop("position_ids_csv", None)

            row["area_ids"] = [
                int(x)
                for x in str(area_csv or "").split(",")
                if x.strip().isdigit()
            ]
            row["position_ids"] = [
                int(x)
                for x in str(position_csv or "").split(",")
                if x.strip().isdigit()
            ]

        return {
            "ok": True,
            "items": rows,
        }

    finally:
        cur.close()


# =========================
# INICIAR EVALUACION
# =========================

@router.post("/{evaluation_id}/start")
def start_evaluation(
    evaluation_id: int,
    db=Depends(get_db),
    user=Depends(get_current_user),
):
    cur = db.cursor(dictionary=True)

    try:
        user_id = _get_user_id(user)

        if not user_id:
            raise HTTPException(status_code=401, detail="Usuario no identificado en token")

        cur.execute(
            """
            SELECT id, status
            FROM evaluation_submissions
            WHERE evaluation_id = %s
              AND user_id = %s
            LIMIT 1
            """,
            (evaluation_id, user_id),
        )

        existing = cur.fetchone()

        if existing:
            return {
                "submission_id": existing["id"],
                "status": existing["status"],
            }

        cur.execute(
            """
            INSERT INTO evaluation_submissions (
                evaluation_id,
                user_id,
                status,
                started_at
            )
            VALUES (%s, %s, 'in_progress', NOW())
            """,
            (evaluation_id, user_id),
        )

        db.commit()

        return {
            "submission_id": cur.lastrowid,
            "status": "in_progress",
        }

    except Exception:
        db.rollback()
        raise

    finally:
        cur.close()


# =========================
# RESULTADO
# =========================

@router.get("/submissions/{submission_id}/result")
def get_evaluation_result(
    submission_id: int,
    db=Depends(get_db),
    user=Depends(get_current_user),
):
    cur = db.cursor(dictionary=True)

    try:
        cur.execute(
            """
            SELECT score, status, completed_at
            FROM evaluation_submissions
            WHERE id = %s
            """,
            (submission_id,),
        )

        row = cur.fetchone()

        if not row:
            raise HTTPException(status_code=404, detail="Resultado no encontrado")

        return {"ok": True, **row}

    finally:
        cur.close()


# =========================
# CREAR EVALUACION ADMIN
# =========================

@router.post("/admin")
def create_evaluation(
    payload: dict,
    db=Depends(get_db),
    user=Depends(get_current_user),
):
    require_admin_or_rh(user)

    cur = db.cursor()

    try:
        all_areas = int(payload.get("all_areas") or 0)
        all_positions = int(payload.get("all_positions") or 0)

        cur.execute(
            """
            INSERT INTO evaluations (
                name,
                description,
                type,
                is_active,
                all_areas,
                all_positions,
                created_by,
                created_at
            )
            VALUES (%s, %s, %s, 1, %s, %s, %s, NOW())
            """,
            (
                payload.get("name"),
                payload.get("description"),
                payload.get("type"),
                all_areas,
                all_positions,
                _get_user_id(user),
            ),
        )

        evaluation_id = cur.lastrowid

        _insert_evaluation_targets(cur, evaluation_id, payload)
        _insert_sections_questions_options(cur, evaluation_id, payload)

        db.commit()

        return {
            "ok": True,
            "evaluation_id": evaluation_id,
            "message": "Evaluación creada correctamente",
        }

    except Exception:
        db.rollback()
        raise

    finally:
        cur.close()


# =========================
# DETALLE EVALUACION PARA CONTESTAR
# =========================

@router.get("/{evaluation_id}/detail")
def get_evaluation_detail(
    evaluation_id: int,
    db=Depends(get_db),
    user=Depends(get_current_user),
):
    cur = db.cursor(dictionary=True)

    try:
        cur.execute(
            """
            SELECT id, name, description, type
            FROM evaluations
            WHERE id = %s
              AND is_active = 1
            LIMIT 1
            """,
            (evaluation_id,),
        )
        evaluation = cur.fetchone()

        if not evaluation:
            raise HTTPException(status_code=404, detail="Evaluación no encontrada")

        cur.execute(
            """
            SELECT id, title, description, order_index
            FROM evaluation_sections
            WHERE evaluation_id = %s
            ORDER BY order_index ASC, id ASC
            """,
            (evaluation_id,),
        )
        sections = cur.fetchall()

        for section in sections:
            cur.execute(
                """
                SELECT id, question_text, question_type, is_required,
                       order_index, image_url, points
                FROM evaluation_questions
                WHERE section_id = %s
                ORDER BY order_index ASC, id ASC
                """,
                (section["id"],),
            )
            questions = cur.fetchall()

            for q in questions:
                cur.execute(
                    """
                    SELECT id, option_text, value
                    FROM evaluation_options
                    WHERE question_id = %s
                    ORDER BY id ASC
                    """,
                    (q["id"],),
                )
                q["options"] = cur.fetchall()

            section["questions"] = questions

        evaluation["sections"] = sections

        return {"ok": True, **evaluation}

    finally:
        cur.close()


# =========================
# GUARDAR RESPUESTAS
# =========================

@router.post("/submissions/{submission_id}/answers")
def submit_evaluation_answers(
    submission_id: int,
    payload: dict,
    db=Depends(get_db),
    user=Depends(get_current_user),
):
    user_id = _get_user_id(user)

    cur = db.cursor(dictionary=True)

    try:
        if not user_id:
            raise HTTPException(status_code=401, detail="Usuario no identificado en token")

        cur.execute(
            """
            SELECT id, evaluation_id, user_id, status
            FROM evaluation_submissions
            WHERE id = %s
            LIMIT 1
            """,
            (submission_id,),
        )
        submission = cur.fetchone()

        if not submission:
            raise HTTPException(status_code=404, detail="Submission no encontrada")

        if int(submission["user_id"]) != int(user_id):
            raise HTTPException(status_code=403, detail="No puedes enviar esta evaluación")

        if submission["status"] == "completed":
            raise HTTPException(status_code=400, detail="Esta evaluación ya fue enviada")

        answers = payload.get("answers") or {}

        if not isinstance(answers, dict):
            raise HTTPException(status_code=400, detail="Formato de respuestas inválido")

        total_score = 0

        cur.execute(
            """
            DELETE FROM evaluation_answers
            WHERE submission_id = %s
            """,
            (submission_id,),
        )

        for question_id_raw, answer_value in answers.items():
            try:
                question_id = int(question_id_raw)
            except Exception:
                continue

            cur.execute(
                """
                SELECT id, question_type
                FROM evaluation_questions
                WHERE id = %s
                LIMIT 1
                """,
                (question_id,),
            )
            question = cur.fetchone()

            if not question:
                continue

            question_type = question["question_type"]

            if question_type in ("single", "yes_no"):
                option_id = None
                answer_text = None
                option_points = 0

                try:
                    option_id = int(answer_value)
                except Exception:
                    answer_text = str(answer_value)

                option = None

                if option_id is not None:
                    cur.execute(
                        """
                        SELECT id, option_text, value
                        FROM evaluation_options
                        WHERE id = %s
                          AND question_id = %s
                        LIMIT 1
                        """,
                        (option_id, question_id),
                    )
                    option = cur.fetchone()

                    if not option and question_type == "yes_no":
                        cur.execute(
                            """
                            SELECT id, option_text, value
                            FROM evaluation_options
                            WHERE question_id = %s
                              AND value = %s
                            LIMIT 1
                            """,
                            (question_id, option_id),
                        )
                        option = cur.fetchone()

                if option:
                    option_id = option["id"]
                    answer_text = option["option_text"]
                    option_points = int(option.get("value") or 0)
                elif question_type == "yes_no":
                    answer_text = "Sí" if str(answer_value) == "1" else "No"
                    try:
                        option_points = int(answer_value or 0)
                    except Exception:
                        option_points = 0

                total_score += option_points

                cur.execute(
                    """
                    INSERT INTO evaluation_answers (
                        submission_id,
                        question_id,
                        answer_text,
                        option_id
                    )
                    VALUES (%s, %s, %s, %s)
                    """,
                    (submission_id, question_id, answer_text, option_id),
                )

            elif question_type == "multi":
                if not isinstance(answer_value, list):
                    answer_value = []

                for option_id_raw in answer_value:
                    try:
                        option_id = int(option_id_raw)
                    except Exception:
                        continue

                    cur.execute(
                        """
                        SELECT id, option_text, value
                        FROM evaluation_options
                        WHERE id = %s
                          AND question_id = %s
                        LIMIT 1
                        """,
                        (option_id, question_id),
                    )
                    option = cur.fetchone()

                    if not option:
                        continue

                    total_score += int(option.get("value") or 0)

                    cur.execute(
                        """
                        INSERT INTO evaluation_answers (
                            submission_id,
                            question_id,
                            answer_text,
                            option_id
                        )
                        VALUES (%s, %s, %s, %s)
                        """,
                        (
                            submission_id,
                            question_id,
                            option["option_text"],
                            option_id,
                        ),
                    )

            elif question_type == "text":
                cur.execute(
                    """
                    INSERT INTO evaluation_answers (
                        submission_id,
                        question_id,
                        answer_text,
                        option_id
                    )
                    VALUES (%s, %s, %s, NULL)
                    """,
                    (submission_id, question_id, str(answer_value)),
                )

        cur.execute(
            """
            UPDATE evaluation_submissions
            SET status = 'completed',
                score = %s,
                completed_at = NOW()
            WHERE id = %s
            """,
            (total_score, submission_id),
        )

        db.commit()

        return {
            "ok": True,
            "submission_id": submission_id,
            "score": total_score,
            "status": "completed",
        }

    except Exception:
        db.rollback()
        raise

    finally:
        cur.close()


# =========================
# ADMIN DETALLE PARA EDITAR
# =========================

@router.get("/admin/{evaluation_id}")
def admin_get_evaluation_detail(
    evaluation_id: int,
    db=Depends(get_db),
    user=Depends(get_current_user),
):
    require_admin_or_rh(user)

    cur = db.cursor(dictionary=True)

    try:
        cur.execute(
            """
            SELECT id, name, description, type, is_active,
                   all_areas, all_positions, created_by, created_at
            FROM evaluations
            WHERE id = %s
            LIMIT 1
            """,
            (evaluation_id,),
        )
        evaluation = cur.fetchone()

        if not evaluation:
            raise HTTPException(status_code=404, detail="Evaluación no encontrada")

        cur.execute(
            """
            SELECT DISTINCT area_id
            FROM evaluation_targets
            WHERE evaluation_id = %s AND area_id IS NOT NULL
            """,
            (evaluation_id,),
        )
        evaluation["area_ids"] = [r["area_id"] for r in cur.fetchall()]

        cur.execute(
            """
            SELECT DISTINCT position_id
            FROM evaluation_targets
            WHERE evaluation_id = %s AND position_id IS NOT NULL
            """,
            (evaluation_id,),
        )
        evaluation["position_ids"] = [r["position_id"] for r in cur.fetchall()]

        cur.execute(
            """
            SELECT id, title, description, order_index
            FROM evaluation_sections
            WHERE evaluation_id = %s
            ORDER BY order_index ASC, id ASC
            """,
            (evaluation_id,),
        )
        sections = cur.fetchall()

        for section in sections:
            cur.execute(
                """
                SELECT id, question_text, question_type, is_required,
                       order_index, image_url, points
                FROM evaluation_questions
                WHERE section_id = %s
                ORDER BY order_index ASC, id ASC
                """,
                (section["id"],),
            )
            questions = cur.fetchall()

            for q in questions:
                cur.execute(
                    """
                    SELECT id, option_text, value
                    FROM evaluation_options
                    WHERE question_id = %s
                    ORDER BY id ASC
                    """,
                    (q["id"],),
                )
                q["options"] = cur.fetchall()

            section["questions"] = questions

        evaluation["sections"] = sections

        return {"ok": True, **evaluation}

    finally:
        cur.close()


# =========================
# ADMIN ACTUALIZAR
# =========================

@router.put("/admin/{evaluation_id}")
def admin_update_evaluation(
    evaluation_id: int,
    payload: dict,
    db=Depends(get_db),
    user=Depends(get_current_user),
):
    require_admin_or_rh(user)

    cur = db.cursor(dictionary=True)

    try:
        cur.execute("SELECT id FROM evaluations WHERE id = %s", (evaluation_id,))
        exists = cur.fetchone()

        if not exists:
            raise HTTPException(status_code=404, detail="Evaluación no encontrada")

        all_areas = int(payload.get("all_areas") or 0)
        all_positions = int(payload.get("all_positions") or 0)

        cur.execute(
            """
            UPDATE evaluations
            SET name = %s,
                description = %s,
                type = %s,
                all_areas = %s,
                all_positions = %s
            WHERE id = %s
            """,
            (
                payload.get("name"),
                payload.get("description"),
                payload.get("type"),
                all_areas,
                all_positions,
                evaluation_id,
            ),
        )

        cur.execute(
            "DELETE FROM evaluation_targets WHERE evaluation_id = %s",
            (evaluation_id,),
        )
        _insert_evaluation_targets(cur, evaluation_id, payload)

        cur.execute(
            """
            SELECT id
            FROM evaluation_sections
            WHERE evaluation_id = %s
            """,
            (evaluation_id,),
        )
        old_sections = cur.fetchall()

        for s in old_sections:
            cur.execute(
                """
                SELECT id
                FROM evaluation_questions
                WHERE section_id = %s
                """,
                (s["id"],),
            )
            old_questions = cur.fetchall()

            for q in old_questions:
                cur.execute(
                    "DELETE FROM evaluation_options WHERE question_id = %s",
                    (q["id"],),
                )

            cur.execute(
                "DELETE FROM evaluation_questions WHERE section_id = %s",
                (s["id"],),
            )

        cur.execute(
            "DELETE FROM evaluation_sections WHERE evaluation_id = %s",
            (evaluation_id,),
        )

        _insert_sections_questions_options(cur, evaluation_id, payload)

        db.commit()

        return {"ok": True, "evaluation_id": evaluation_id}

    except Exception:
        db.rollback()
        raise

    finally:
        cur.close()


# =========================
# ADMIN ACTIVAR / DESACTIVAR
# =========================

@router.put("/admin/{evaluation_id}/status")
def admin_update_evaluation_status(
    evaluation_id: int,
    payload: dict,
    db=Depends(get_db),
    user=Depends(get_current_user),
):
    require_admin_or_rh(user)

    is_active = int(payload.get("is_active", 1))

    cur = db.cursor()

    try:
        cur.execute(
            """
            UPDATE evaluations
            SET is_active = %s
            WHERE id = %s
            """,
            (is_active, evaluation_id),
        )

        if cur.rowcount == 0:
            raise HTTPException(status_code=404, detail="Evaluación no encontrada")

        db.commit()

        return {"ok": True, "is_active": is_active}

    except Exception:
        db.rollback()
        raise

    finally:
        cur.close()


# =========================
# ADMIN ELIMINAR
# =========================

@router.delete("/admin/{evaluation_id}")
def admin_delete_evaluation(
    evaluation_id: int,
    db=Depends(get_db),
    user=Depends(get_current_user),
):
    require_admin_or_rh(user)

    cur = db.cursor(dictionary=True)

    try:
        cur.execute("SELECT id FROM evaluations WHERE id = %s", (evaluation_id,))
        exists = cur.fetchone()

        if not exists:
            raise HTTPException(status_code=404, detail="Evaluación no encontrada")

        cur.execute(
            """
            SELECT id
            FROM evaluation_submissions
            WHERE evaluation_id = %s
            """,
            (evaluation_id,),
        )
        submissions = cur.fetchall()

        for sub in submissions:
            cur.execute(
                "DELETE FROM evaluation_answers WHERE submission_id = %s",
                (sub["id"],),
            )

        cur.execute(
            "DELETE FROM evaluation_submissions WHERE evaluation_id = %s",
            (evaluation_id,),
        )

        cur.execute(
            """
            SELECT id
            FROM evaluation_sections
            WHERE evaluation_id = %s
            """,
            (evaluation_id,),
        )
        sections = cur.fetchall()

        for section in sections:
            cur.execute(
                """
                SELECT id
                FROM evaluation_questions
                WHERE section_id = %s
                """,
                (section["id"],),
            )
            questions = cur.fetchall()

            for q in questions:
                cur.execute(
                    "DELETE FROM evaluation_options WHERE question_id = %s",
                    (q["id"],),
                )

            cur.execute(
                "DELETE FROM evaluation_questions WHERE section_id = %s",
                (section["id"],),
            )

        cur.execute(
            "DELETE FROM evaluation_sections WHERE evaluation_id = %s",
            (evaluation_id,),
        )

        cur.execute(
            "DELETE FROM evaluation_targets WHERE evaluation_id = %s",
            (evaluation_id,),
        )

        cur.execute(
            "DELETE FROM evaluations WHERE id = %s",
            (evaluation_id,),
        )

        db.commit()

        return {"ok": True}

    except Exception:
        db.rollback()
        raise

    finally:
        cur.close()


# =========================
# ADMIN USUARIOS CONTESTARON / FALTAN
# =========================

@router.get("/admin/{evaluation_id}/submissions")
def admin_get_evaluation_submissions(
    evaluation_id: int,
    db=Depends(get_db),
    user=Depends(get_current_user),
):
    require_admin_or_rh(user)

    cur = db.cursor(dictionary=True)

    try:
        cur.execute(
            """
            SELECT id, name, all_areas, all_positions
            FROM evaluations
            WHERE id = %s
            LIMIT 1
            """,
            (evaluation_id,),
        )
        evaluation = cur.fetchone()

        if not evaluation:
            raise HTTPException(status_code=404, detail="Evaluación no encontrada")

        all_areas = _is_true(evaluation.get("all_areas"))
        all_positions = _is_true(evaluation.get("all_positions"))

        cur.execute(
            """
            SELECT DISTINCT area_id
            FROM evaluation_targets
            WHERE evaluation_id = %s
              AND area_id IS NOT NULL
            """,
            (evaluation_id,),
        )
        area_ids = [r["area_id"] for r in cur.fetchall()]

        cur.execute(
            """
            SELECT DISTINCT position_id
            FROM evaluation_targets
            WHERE evaluation_id = %s
              AND position_id IS NOT NULL
            """,
            (evaluation_id,),
        )
        position_ids = [r["position_id"] for r in cur.fetchall()]

        query = """
            SELECT DISTINCT
                u.id AS user_id,
                u.name AS user_name,
                u.name,
                u.employee_number,
                u.area,
                u.position,
                es.id AS submission_id,
                es.status,
                es.score,
                es.completed_at
            FROM users u
            LEFT JOIN areas a 
                ON UPPER(TRIM(a.name)) = UPPER(TRIM(u.area))
            LEFT JOIN positions p 
                ON UPPER(TRIM(p.name)) = UPPER(TRIM(u.position))
               AND (a.id IS NULL OR p.area_id = a.id)
            LEFT JOIN evaluation_submissions es
                ON es.user_id = u.id
               AND es.evaluation_id = %s
            WHERE u.active = 1
        """
        params = [evaluation_id]

        if not all_areas:
            if not area_ids:
                return {
                    "ok": True,
                    "evaluation_id": evaluation_id,
                    "completed": [],
                    "pending": [],
                }

            placeholders = ",".join(["%s"] * len(area_ids))

            query += f"""
            AND (
                a.id IN ({placeholders})
                OR u.area IS NOT NULL
            )
            """

            params.extend(area_ids)

        if not all_positions:
            if not position_ids:
                return {
                    "ok": True,
                    "evaluation_id": evaluation_id,
                    "completed": [],
                    "pending": [],
                }

            placeholders = ",".join(["%s"] * len(position_ids))
            query += f"""
            AND (
                p.id IN ({placeholders})
                OR u.position IS NOT NULL
            )
            """
            params.extend(position_ids)

        query += " ORDER BY u.name ASC"

        cur.execute(query, tuple(params))
        rows = cur.fetchall()

        completed = []
        pending = []

        for row in rows:
            if row.get("status") == "completed":
                completed.append(row)
            else:
                pending.append(row)

        return {
            "ok": True,
            "evaluation_id": evaluation_id,
            "completed": completed,
            "pending": pending,
        }

    finally:
        cur.close()


# =========================
# ADMIN DETALLE RESPUESTAS
# =========================

@router.get("/admin/submissions/{submission_id}")
def admin_get_evaluation_submission_detail(
    submission_id: int,
    db=Depends(get_db),
    user=Depends(get_current_user),
):
    require_admin_or_rh(user)

    cur = db.cursor(dictionary=True)

    try:
        cur.execute(
            """
            SELECT 
                es.id AS submission_id,
                es.score,
                es.status,
                es.completed_at,
                u.id AS user_id,
                u.name AS user_name,
                u.employee_number,
                u.area,
                u.position,
                e.id AS evaluation_id,
                e.name AS evaluation_name
            FROM evaluation_submissions es
            INNER JOIN users u ON u.id = es.user_id
            INNER JOIN evaluations e ON e.id = es.evaluation_id
            WHERE es.id = %s
            LIMIT 1
            """,
            (submission_id,),
        )
        header = cur.fetchone()

        if not header:
            raise HTTPException(status_code=404, detail="Respuesta no encontrada")

        cur.execute(
            """
            SELECT 
                q.id AS question_id,
                q.question_text,
                q.question_type,
                ea.answer_text,
                ea.option_id,
                eo.option_text,
                eo.value AS points
            FROM evaluation_answers ea
            INNER JOIN evaluation_questions q ON q.id = ea.question_id
            LEFT JOIN evaluation_options eo ON eo.id = ea.option_id
            WHERE ea.submission_id = %s
            ORDER BY q.order_index ASC, q.id ASC
            """,
            (submission_id,),
        )

        answers = cur.fetchall()

        return {
            "ok": True,
            **header,
            "answers": answers,
        }

    finally:
        cur.close()
