from fastapi import APIRouter, Depends
from app.dependencies.auth import get_current_user
from app.core.db import get_db
from app.core.security import hash_password
from app.schemas.user import UserCreate, UserUpdate
from app.dependencies.roles import require_role

# rh.py
router = APIRouter(
    prefix="/rh",
    tags=["RH"],
    dependencies=[Depends(require_role(2))]
)

@router.get("/profile/{user_id}")
def get_user_profile(user_id: int):
    # RH puede ver solo empleados de su área
    conn = get_db()
    cursor = conn.cursor(dictionary=True)
    cursor.execute("SELECT * FROM users WHERE id=%s AND role_id=3", (user_id,))
    return cursor.fetchone()
