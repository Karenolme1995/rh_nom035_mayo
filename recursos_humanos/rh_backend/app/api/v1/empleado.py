from fastapi import APIRouter, Depends
from app.dependencies.auth import get_current_user
from app.dependencies.roles import require_role


# empleado.py
router = APIRouter(
    prefix="/employee",
    tags=["Employee"],
    dependencies=[Depends(require_role(3))]
)

@router.get("/profile")
def get_my_profile(current_user=Depends(get_current_user)):
    return current_user
