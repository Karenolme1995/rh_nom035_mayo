from datetime import date
from fastapi import APIRouter, Depends
from app.core.db import get_db
from app.dependencies.auth import get_current_user

router = APIRouter(
    prefix="/work_anniversaries",
    tags=["Work Anniversaries"],
)


@router.get("/today")
def get_work_anniversaries_today(
    db=Depends(get_db),
    current_user: dict = Depends(get_current_user),
):
    today = date.today()
    user_id = current_user.get("id")

    cursor = db.cursor(dictionary=True)

    cursor.execute("""
        SELECT id, role_id, area
        FROM users
        WHERE id = %s
        LIMIT 1
    """, (user_id,))
    me = cursor.fetchone()

    if not me:
        cursor.close()
        return []

    current_role_id = int(me.get("role_id") or 0)
    current_area = (me.get("area") or "").strip()

    if current_role_id in [1, 2]:
        cursor.execute("""
            SELECT
                id,
                name,
                avatar,
                area,
                position,
                entry_date
            FROM users
            WHERE active = 1
              AND entry_date IS NOT NULL
              AND MONTH(entry_date) = %s
              AND DAY(entry_date) = %s
            ORDER BY entry_date ASC, name ASC
        """, (today.month, today.day))
    else:
        if not current_area:
            cursor.close()
            return []

        cursor.execute("""
            SELECT
                id,
                name,
                avatar,
                area,
                position,
                entry_date
            FROM users
            WHERE active = 1
              AND entry_date IS NOT NULL
              AND area = %s
              AND MONTH(entry_date) = %s
              AND DAY(entry_date) = %s
            ORDER BY entry_date ASC, name ASC
        """, (current_area, today.month, today.day))

    users = cursor.fetchall()
    cursor.close()

    result = []

    for idx, u in enumerate(users, start=1):
        entry_date = u["entry_date"]
        years = today.year - entry_date.year if entry_date else 0

        result.append({
            "rank": idx,
            "id": u["id"],
            "name": u["name"],
            "avatar": u["avatar"],
            "area": u["area"],
            "position": u["position"],
            "entry_date": entry_date.isoformat() if entry_date else None,
            "years": years,
        })

    return result


@router.get("/ranking")
def get_work_anniversaries_ranking(
    db=Depends(get_db),
    current_user: dict = Depends(get_current_user),
):
    today = date.today()
    user_id = current_user.get("id")

    cursor = db.cursor(dictionary=True)

    cursor.execute("""
        SELECT id, role_id, area
        FROM users
        WHERE id = %s
        LIMIT 1
    """, (user_id,))
    me = cursor.fetchone()

    if not me:
        cursor.close()
        return []

    current_role_id = int(me.get("role_id") or 0)
    current_area = (me.get("area") or "").strip()

    if current_role_id in [1, 2]:
        cursor.execute("""
            SELECT
                id,
                name,
                avatar,
                area,
                position,
                entry_date
            FROM users
            WHERE active = 1
              AND entry_date IS NOT NULL
            ORDER BY entry_date ASC, name ASC
        """)
    else:
        if not current_area:
            cursor.close()
            return []

        cursor.execute("""
            SELECT
                id,
                name,
                avatar,
                area,
                position,
                entry_date
            FROM users
            WHERE active = 1
              AND entry_date IS NOT NULL
              AND area = %s
            ORDER BY entry_date ASC, name ASC
        """, (current_area,))

    users = cursor.fetchall()
    cursor.close()

    result = []

    for idx, u in enumerate(users, start=1):
        entry_date = u["entry_date"]
        years = today.year - entry_date.year if entry_date else 0

        result.append({
            "rank": idx,
            "id": u["id"],
            "name": u["name"],
            "avatar": u["avatar"],
            "area": u["area"],
            "position": u["position"],
            "entry_date": entry_date.isoformat() if entry_date else None,
            "years": years,
        })

    return result