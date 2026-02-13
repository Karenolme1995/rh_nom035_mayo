from typing import Optional
from fastapi import APIRouter, Depends

# ⚠️ Ajusta estos imports a tu proyecto real
from app.dependencies.auth import get_current_user
from app.core.db import get_db

router = APIRouter()

@router.get("/users/birthdays/today")
def birthdays_today(plant: Optional[str] = None, db=Depends(get_db), user=Depends(get_current_user)):
    query = """
        SELECT id, name, position, avatar, plant, birthday
        FROM users
        WHERE active = 1
          AND MONTH(birthday) = MONTH(CURDATE())
          AND DAY(birthday) = DAY(CURDATE())
          AND (%s IS NULL OR plant = %s)
        ORDER BY name ASC
    """
    cur = db.cursor(dictionary=True)
    cur.execute(query, (plant, plant))
    rows = cur.fetchall()
    return {"ok": True, "items": rows}