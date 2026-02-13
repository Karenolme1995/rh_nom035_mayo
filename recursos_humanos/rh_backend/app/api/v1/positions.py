from fastapi import APIRouter, Depends, HTTPException, Query, Path
from pydantic import BaseModel, Field
from app.dependencies.auth import get_current_user
from app.core.db import get_db

router = APIRouter(prefix="/positions", tags=["positions"])


class PositionCreate(BaseModel):
    area_id: int | None = Field(default=None)
    name: str = Field(min_length=1, max_length=150)
    active: int = Field(default=1, ge=0, le=1)


class PositionUpdate(BaseModel):
    area_id: int | None = Field(default=None)
    name: str | None = Field(default=None, min_length=1, max_length=150)
    active: int | None = Field(default=None, ge=0, le=1)


@router.get("")
def list_positions(
    area_id: int | None = Query(None),
    q: str | None = Query(None, description="Búsqueda por nombre del puesto"),
    active: int | None = Query(1, description="1 activos, 0 inactivos, null todos"),
    db=Depends(get_db),
    _user=Depends(get_current_user),
):
    try:
        where = []
        params = []

        if area_id is not None:
            where.append("p.area_id=%s")
            params.append(area_id)

        if active in (0, 1):
            where.append("p.active=%s")
            params.append(active)

        if q:
            where.append("p.name LIKE %s")
            params.append(f"%{q.strip()}%")

        where_sql = ("WHERE " + " AND ".join(where)) if where else ""

        sql = f"""
            SELECT
                p.id,
                p.area_id,
                a.name AS area_name,
                p.name,
                p.active
            FROM positions p
            LEFT JOIN areas a ON a.id = p.area_id
            {where_sql}
            ORDER BY a.name, p.name
        """

        with db.cursor() as cur:
            cur.execute(sql, params)
            rows = cur.fetchall()

        return rows

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("", status_code=201)
def create_position(
    payload: PositionCreate,
    db=Depends(get_db),
    _user=Depends(get_current_user),
):
    try:
        # valida área si viene
        if payload.area_id is not None:
            with db.cursor() as cur:
                cur.execute("SELECT id FROM areas WHERE id=%s", (payload.area_id,))
                if not cur.fetchone():
                    raise HTTPException(status_code=400, detail="area_id no existe")

        with db.cursor() as cur:
            cur.execute(
                """
                INSERT INTO positions (area_id, name, active)
                VALUES (%s, %s, %s)
                """,
                (payload.area_id, payload.name.strip(), payload.active),
            )
            new_id = cur.lastrowid

        db.commit()
        return {"id": new_id, "message": "Position creada"}

    except Exception as e:
        # Manejo simple de duplicado (unique uk_positions_name_area)
        msg = str(e).lower()
        if "duplicate" in msg or "duplicate entry" in msg:
            raise HTTPException(status_code=409, detail="Ya existe un puesto con ese nombre en esa área")
        raise HTTPException(status_code=500, detail=str(e))


@router.put("/{position_id}")
def update_position(
    position_id: int = Path(..., ge=1),
    payload: PositionUpdate = ...,
    db=Depends(get_db),
    _user=Depends(get_current_user),
):
    try:
        with db.cursor() as cur:
            cur.execute("SELECT * FROM positions WHERE id=%s", (position_id,))
            current = cur.fetchone()

        if not current:
            raise HTTPException(status_code=404, detail="Position no encontrada")

        new_area_id = payload.area_id if payload.area_id is not None else current["area_id"]
        new_name = payload.name.strip() if payload.name is not None else current["name"]
        new_active = payload.active if payload.active is not None else current["active"]

        # valida área si viene (o si quedó asignada)
        if new_area_id is not None:
            with db.cursor() as cur:
                cur.execute("SELECT id FROM areas WHERE id=%s", (new_area_id,))
                if not cur.fetchone():
                    raise HTTPException(status_code=400, detail="area_id no existe")

        with db.cursor() as cur:
            cur.execute(
                """
                UPDATE positions
                SET area_id=%s, name=%s, active=%s
                WHERE id=%s
                """,
                (new_area_id, new_name, new_active, position_id),
            )

        db.commit()
        return {"id": position_id, "message": "Position actualizada"}

    except Exception as e:
        msg = str(e).lower()
        if "duplicate" in msg or "duplicate entry" in msg:
            raise HTTPException(status_code=409, detail="Ya existe un puesto con ese nombre en esa área")
        raise HTTPException(status_code=500, detail=str(e))
