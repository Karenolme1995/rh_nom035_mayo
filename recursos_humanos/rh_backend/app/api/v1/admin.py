from fastapi import APIRouter, Depends
from app.dependencies.auth import get_current_user
from app.dependencies.roles import require_role
from app.core.db import get_db

router = APIRouter(
    prefix="/admin",
    tags=["Admin"],
    dependencies=[Depends(require_role(1))]
)

@router.get("/profile/{user_id}")
def get_user_profile(user_id: int):
    conn = get_db()
    cursor = conn.cursor(dictionary=True)
    cursor.execute("SELECT * FROM users WHERE id=%s", (user_id,))
    return cursor.fetchone()


