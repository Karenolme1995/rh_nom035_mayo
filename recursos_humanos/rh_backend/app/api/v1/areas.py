# app/api/v1/areas.py
from fastapi import APIRouter, Depends, HTTPException, Query
from app.dependencies.auth import get_current_user
from app.core.db import get_db
from app.dependencies.roles import require_role

router = APIRouter(
    prefix="/areas",
    tags=["areas"],
    dependencies=[Depends(require_role(1, 2, 3))]
)

@router.get("")
def list_areas(
    active: int | None = Query(1),
    q: str | None = Query(None),
    db=Depends(get_db),
    _user=Depends(get_current_user),
):
    try:
        where, params = [], []

        if active in (0, 1):
            where.append("active=%s")
            params.append(active)

        if q:
            where.append("name LIKE %s")
            params.append(f"%{q.strip()}%")

        sql = "SELECT id, name, active FROM areas"
        if where:
            sql += " WHERE " + " AND ".join(where)
        sql += " ORDER BY name"

        cur = db.cursor(dictionary=True)
        try:
            cur.execute(sql, tuple(params))
            return cur.fetchall()
        finally:
            cur.close()

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
