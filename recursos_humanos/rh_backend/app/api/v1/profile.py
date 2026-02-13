# profile.py
from fastapi import APIRouter, Depends
from app.dependencies.auth import get_current_user

router = APIRouter(
    prefix="/profile",
    tags=["Profile"]
)

@router.get("/")
def get_my_profile(current_user=Depends(get_current_user)):
    """
    Devuelve el perfil del usuario logueado, incluyendo avatar y fecha de creación
    """
    return {
        "id": current_user["id"],
        "name": current_user["name"],
        "email": current_user["email"],
        "role_id": current_user["role_id"],
        "area": current_user.get("area"),
        "position": current_user.get("position"),
        "avatar": current_user.get("avatar"),         
        "created_at": current_user.get("created_at"), 
        "active": current_user.get("active")
    }
