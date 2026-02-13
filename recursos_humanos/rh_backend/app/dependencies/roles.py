from fastapi import Depends, HTTPException, status
from app.dependencies.auth import get_current_user

# IDs: 1=ADMIN, 2=RH, 3=EMPLEADO
def require_role(*roles_permitidos):
    def role_checker(user=Depends(get_current_user)):
        if user["role_id"] not in roles_permitidos:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="No tienes permisos para esta acción"
            )
        return user
    return role_checker



