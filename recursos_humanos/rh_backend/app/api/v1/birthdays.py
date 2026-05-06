from fastapi import APIRouter, Depends
from app.dependencies.auth import get_current_user
from app.core.db import get_db
from datetime import date

router = APIRouter(prefix="/birthdays", tags=["Birthdays"])

@router.get("/today")
def birthdays_today(db=Depends(get_db), _user=Depends(get_current_user)):
    today = date.today()
    cur = db.cursor(dictionary=True)
    try:
        cur.execute("""
            SELECT id, name, position, avatar, birthday
            FROM users
            WHERE COALESCE(active,1)=1
              AND birthday IS NOT NULL
              AND MONTH(birthday)=%s
              AND DAY(birthday)=%s
            ORDER BY name
        """, (today.month, today.day))
        return cur.fetchall()
    finally:
        cur.close()

#-----------------------------------------------------------------#
@router.get("/month")
def birthdays_current_month(db=Depends(get_db), current_user=Depends(get_current_user)):
    today = date.today()
    month = today.month

    with db.cursor(dictionary=True) as cur:
        cur.execute("""
            SELECT
              id,
              name,
              position,
              avatar,
              birthday
            FROM users
            WHERE COALESCE(active,1)=1
              AND birthday IS NOT NULL
              AND MONTH(birthday) = %s
            ORDER BY DAY(birthday), name
        """, (month,))
        rows = cur.fetchall()

    return rows