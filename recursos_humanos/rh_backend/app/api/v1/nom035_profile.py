from fastapi import APIRouter, Depends, HTTPException, Query

from app.services.nom035_profile_service import nom035_profile_service
from app.core.db_mysql import get_mysql_conn
from app.dependencies.auth import get_current_user

router = APIRouter(prefix="/nom035", tags=["nom035-profile"])


@router.get("/profile-stats")
def get_profile_stats(
    cycle_id: int = Query(..., gt=0),
    conn=Depends(get_mysql_conn),
    user: dict = Depends(get_current_user),
):
    try:
        return nom035_profile_service.get_profile_stats(
            conn=conn,
            user=user,
            cycle_id=cycle_id,
        )
    except PermissionError as e:
        raise HTTPException(status_code=403, detail=str(e))
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Error obteniendo profile-stats: {e}",
        )