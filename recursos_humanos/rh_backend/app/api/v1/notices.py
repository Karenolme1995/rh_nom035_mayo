import json
import shutil
from datetime import datetime
from pathlib import Path
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Form

from app.dependencies.auth import get_current_user
from app.core.db import get_db

router = APIRouter()

# Carpeta base física donde se guardan archivos
BASE_UPLOAD_DIR = Path(__file__).resolve().parents[3] / "uploads"
NOTICE_UPLOAD_DIR = BASE_UPLOAD_DIR / "notices"


def require_admin_or_rh(user: dict):
    role_id = int(user.get("role_id", 0))
    if role_id not in (1, 2):
        raise HTTPException(status_code=403, detail="No autorizado (solo Admin/RH)")


def _save_upload(upload: UploadFile, subfolder: str = "") -> str:
    target_dir = NOTICE_UPLOAD_DIR / subfolder if subfolder else NOTICE_UPLOAD_DIR
    target_dir.mkdir(parents=True, exist_ok=True)

    safe_name = (upload.filename or "archivo").replace(" ", "_")
    filename = f"{int(datetime.now().timestamp())}_{safe_name}"
    filepath = target_dir / filename

    try:
        with open(filepath, "wb") as buffer:
            shutil.copyfileobj(upload.file, buffer)
    except OSError as e:
        if "No space left on device" in str(e):
            raise HTTPException(
                status_code=507,
                detail="No hay espacio disponible en el servidor para guardar el archivo.",
            )
        raise

    return f"/uploads/notices/{subfolder + '/' if subfolder else ''}{filename}"


def _delete_file(file_url: Optional[str]):
    if not file_url:
        return

    try:
        relative = file_url.replace("/uploads/", "", 1).lstrip("/")
        file_path = BASE_UPLOAD_DIR / relative

        if file_path.exists() and file_path.is_file():
            file_path.unlink()
    except Exception:
        pass


def _parse_json_list(value) -> list:
    if not value:
        return []

    if isinstance(value, list):
        return value

    if isinstance(value, str):
        try:
            data = json.loads(value)
            return data if isinstance(data, list) else []
        except Exception:
            return []

    return []


def _delete_multiple_files(image_urls_raw):
    urls = _parse_json_list(image_urls_raw)
    for url in urls:
        if isinstance(url, str) and url.strip():
            _delete_file(url)


def _get_user_id(user: dict):
    return user.get("user_id") or user.get("id")


def _get_user_area(user: dict) -> str:
    return (user.get("area") or "").strip()


def _get_role_id(user: dict) -> int:
    return int(user.get("role_id", 0))


def _load_notice_areas(cur, notice_id: int):
    cur.execute(
        """
        SELECT a.id, a.name
        FROM notice_areas na
        INNER JOIN areas a ON a.id = na.area_id
        WHERE na.notice_id = %s
        ORDER BY a.name
        """,
        (notice_id,),
    )
    return cur.fetchall()


def _can_user_see_notice(user: dict, notice_areas: list[dict]) -> bool:
    role_id = int(user.get("role_id", 0))

    if role_id in (1, 2):
        return True

    user_area = _get_user_area(user).lower().strip()

    if not notice_areas:
        return False

    for area in notice_areas:
        area_name = (area.get("name") or "").strip().lower()
        if user_area and area_name == user_area:
            return True

    return False


@router.get("/notices/latest")
def latest_notice(
    plant: Optional[str] = None,
    db=Depends(get_db),
    user=Depends(get_current_user),
):
    cur = db.cursor(dictionary=True)
    try:
        role_id = _get_role_id(user)

        if role_id in (1, 2):
            cur.execute(
                """
                SELECT n.id, n.title, n.body, n.plant, n.active, n.created_by,
                       n.created_at, n.image_url, n.image_urls, n.pdf_url
                FROM notices n
                WHERE (%s IS NULL OR n.plant = %s OR n.plant IS NULL)
                ORDER BY n.created_at DESC
                """,
                (plant, plant),
            )
        else:
            cur.execute(
                """
                SELECT n.id, n.title, n.body, n.plant, n.active, n.created_by,
                       n.created_at, n.image_url, n.image_urls, n.pdf_url
                FROM notices n
                WHERE n.active = 1
                  AND (%s IS NULL OR n.plant = %s OR n.plant IS NULL)
                ORDER BY n.created_at DESC
                """,
                (plant, plant),
            )

        rows = cur.fetchall()

        for row in rows:
            row["areas"] = _load_notice_areas(cur, row["id"])
            if _can_user_see_notice(user, row["areas"]):
                return {"ok": True, "notice": row}

        return {"ok": True, "notice": None}
    finally:
        cur.close()


@router.get("/notices")
def list_notices(db=Depends(get_db), user=Depends(get_current_user)):
    cur = db.cursor(dictionary=True)
    try:
        role_id = _get_role_id(user)

        if role_id in (1, 2):
            cur.execute(
                """
                SELECT n.*
                FROM notices n
                ORDER BY n.created_at DESC
                """
            )
        else:
            cur.execute(
                """
                SELECT n.*
                FROM notices n
                WHERE n.active = 1
                ORDER BY n.created_at DESC
                """
            )

        rows = cur.fetchall()

        visible_rows = []
        for row in rows:
            row["areas"] = _load_notice_areas(cur, row["id"])
            if _can_user_see_notice(user, row["areas"]):
                visible_rows.append(row)

        return {"ok": True, "items": visible_rows}
    finally:
        cur.close()


@router.get("/notices/unread-count")
def unread_count(db=Depends(get_db), user=Depends(get_current_user)):
    user_id = _get_user_id(user)
    role_id = _get_role_id(user)

    cur = db.cursor(dictionary=True)
    try:
        if role_id in (1, 2):
            cur.execute(
                """
                SELECT n.id
                FROM notices n
                ORDER BY n.created_at DESC
                """
            )
        else:
            cur.execute(
                """
                SELECT n.id
                FROM notices n
                WHERE n.active = 1
                ORDER BY n.created_at DESC
                """
            )

        rows = cur.fetchall()
        count = 0

        for row in rows:
            notice_id = row["id"]
            areas = _load_notice_areas(cur, notice_id)

            if not _can_user_see_notice(user, areas):
                continue

            cur.execute(
                """
                SELECT 1
                FROM notice_views v
                WHERE v.notice_id = %s
                  AND v.user_id = %s
                LIMIT 1
                """,
                (notice_id, user_id),
            )
            viewed = cur.fetchone()

            if not viewed:
                count += 1

        return {"count": count}
    finally:
        cur.close()


@router.post("/notices")
def create_notice(
    title: str = Form(...),
    body: str = Form(...),
    plant: Optional[str] = Form(None),
    area_ids: Optional[str] = Form(None),
    image: Optional[UploadFile] = File(None),
    images: Optional[list[UploadFile]] = File(None),
    pdf: Optional[UploadFile] = File(None),
    db=Depends(get_db),
    user=Depends(get_current_user),
):
    require_admin_or_rh(user)

    image_url = None
    image_urls = []
    pdf_url = None

    if image and image.filename:
        image_url = _save_upload(image, "images")

    if images:
        for img in images:
            if img and img.filename:
                image_urls.append(_save_upload(img, "images"))

    if pdf and pdf.filename:
        pdf_url = _save_upload(pdf, "pdf")

    cur = db.cursor()
    try:
        cur.execute(
            """
            INSERT INTO notices (
                title, body, plant, active, created_by, created_at,
                image_url, image_urls, pdf_url
            )
            VALUES (%s, %s, %s, 1, %s, NOW(), %s, %s, %s)
            """,
            (
                title,
                body,
                plant,
                _get_user_id(user),
                image_url,
                json.dumps(image_urls) if image_urls else None,
                pdf_url,
            ),
        )
        notice_id = cur.lastrowid

        parsed_area_ids = _parse_json_list(area_ids)

        for area_id in parsed_area_ids:
            try:
                area_id = int(area_id)
            except Exception:
                continue

            cur.execute(
                """
                INSERT INTO notice_areas (notice_id, area_id)
                VALUES (%s, %s)
                """,
                (notice_id, area_id),
            )

        db.commit()
        return {"ok": True, "id": notice_id}
    except Exception:
        db.rollback()
        _delete_file(image_url)
        _delete_file(pdf_url)
        _delete_multiple_files(image_urls)
        raise
    finally:
        cur.close()


@router.put("/notices/{notice_id}")
def update_notice(
    notice_id: int,
    title: Optional[str] = Form(None),
    body: Optional[str] = Form(None),
    plant: Optional[str] = Form(None),
    active: Optional[bool] = Form(None),
    area_ids: Optional[str] = Form(None),
    replace_main_image: Optional[bool] = Form(False),
    remove_main_image: Optional[bool] = Form(False),
    replace_pdf: Optional[bool] = Form(False),
    remove_pdf: Optional[bool] = Form(False),
    remove_extra_images: Optional[str] = Form(None),
    image: Optional[UploadFile] = File(None),
    images: Optional[list[UploadFile]] = File(None),
    pdf: Optional[UploadFile] = File(None),
    db=Depends(get_db),
    user=Depends(get_current_user),
):
    require_admin_or_rh(user)

    cur = db.cursor(dictionary=True)
    new_main_image_url = None
    new_pdf_url = None
    new_extra_image_urls = []

    try:
        cur.execute("SELECT * FROM notices WHERE id = %s", (notice_id,))
        row = cur.fetchone()
        if not row:
            raise HTTPException(status_code=404, detail="Aviso no encontrado")

        current_main_image = row.get("image_url")
        current_pdf = row.get("pdf_url")
        current_extra_images = _parse_json_list(row.get("image_urls"))

        fields = []
        values = []

        if title is not None:
            fields.append("title = %s")
            values.append(title)

        if body is not None:
            fields.append("body = %s")
            values.append(body)

        if active is not None:
            fields.append("active = %s")
            values.append(1 if active else 0)

        if plant is not None:
            fields.append("plant = %s")
            values.append(plant)

        # Imagen principal
        if remove_main_image:
            _delete_file(current_main_image)
            current_main_image = None

        if replace_main_image and image and image.filename:
            new_main_image_url = _save_upload(image, "images")
            if current_main_image:
                _delete_file(current_main_image)
            current_main_image = new_main_image_url
        elif image and image.filename and not current_main_image:
            # Si no hay imagen actual, acepta nueva aunque no venga replace_main_image
            new_main_image_url = _save_upload(image, "images")
            current_main_image = new_main_image_url

        fields.append("image_url = %s")
        values.append(current_main_image)

        # PDF
        if remove_pdf:
            _delete_file(current_pdf)
            current_pdf = None

        if replace_pdf and pdf and pdf.filename:
            new_pdf_url = _save_upload(pdf, "pdf")
            if current_pdf:
                _delete_file(current_pdf)
            current_pdf = new_pdf_url
        elif pdf and pdf.filename and not current_pdf:
            new_pdf_url = _save_upload(pdf, "pdf")
            current_pdf = new_pdf_url

        fields.append("pdf_url = %s")
        values.append(current_pdf)

        # Imágenes extra a eliminar
        to_remove = _parse_json_list(remove_extra_images)
        if to_remove:
            remaining = []
            for url in current_extra_images:
                if url in to_remove:
                    _delete_file(url)
                else:
                    remaining.append(url)
            current_extra_images = remaining

        # Imágenes extra nuevas
        if images:
            for img in images:
                if img and img.filename:
                    saved = _save_upload(img, "images")
                    new_extra_image_urls.append(saved)
                    current_extra_images.append(saved)

        fields.append("image_urls = %s")
        values.append(json.dumps(current_extra_images) if current_extra_images else None)

        if fields:
            values.append(notice_id)
            cur.execute(
                f"""
                UPDATE notices
                SET {", ".join(fields)}
                WHERE id = %s
                """,
                tuple(values),
            )

        if area_ids is not None:
            parsed_area_ids = _parse_json_list(area_ids)

            cur.execute(
                "DELETE FROM notice_areas WHERE notice_id = %s",
                (notice_id,),
            )

            for area_id in parsed_area_ids:
                try:
                    area_id = int(area_id)
                except Exception:
                    continue

                cur.execute(
                    """
                    INSERT INTO notice_areas (notice_id, area_id)
                    VALUES (%s, %s)
                    """,
                    (notice_id, area_id),
                )

        db.commit()
        return {"ok": True}
    except Exception:
        db.rollback()

        # Limpia archivos recién subidos si algo falló
        _delete_file(new_main_image_url)
        _delete_file(new_pdf_url)
        _delete_multiple_files(new_extra_image_urls)

        raise
    finally:
        cur.close()


@router.delete("/notices/{notice_id}")
def delete_notice(
    notice_id: int,
    db=Depends(get_db),
    user=Depends(get_current_user),
):
    require_admin_or_rh(user)

    cur = db.cursor(dictionary=True)
    try:
        cur.execute("SELECT * FROM notices WHERE id = %s", (notice_id,))
        notice = cur.fetchone()
        if not notice:
            raise HTTPException(status_code=404, detail="Aviso no encontrado")

        _delete_file(notice.get("pdf_url"))
        _delete_file(notice.get("image_url"))
        _delete_multiple_files(notice.get("image_urls"))

        cur.execute("DELETE FROM notice_areas WHERE notice_id = %s", (notice_id,))
        cur.execute("DELETE FROM notice_views WHERE notice_id = %s", (notice_id,))
        cur.execute("DELETE FROM notices WHERE id = %s", (notice_id,))

        db.commit()
        return {"ok": True}
    except Exception:
        db.rollback()
        raise
    finally:
        cur.close()


@router.post("/notices/{notice_id}/view")
def mark_notice_viewed(
    notice_id: int,
    db=Depends(get_db),
    user=Depends(get_current_user),
):
    user_id = _get_user_id(user)
    role_id = _get_role_id(user)

    cur = db.cursor()
    try:
        if role_id in (1, 2):
            cur.execute("SELECT id FROM notices WHERE id = %s", (notice_id,))
        else:
            cur.execute(
                "SELECT id FROM notices WHERE id = %s AND active = 1",
                (notice_id,),
            )

        row = cur.fetchone()
        if not row:
            raise HTTPException(status_code=404, detail="Aviso no encontrado")

        cur.execute(
            """
            SELECT 1
            FROM notice_views
            WHERE notice_id = %s
              AND user_id = %s
            LIMIT 1
            """,
            (notice_id, user_id),
        )
        exists = cur.fetchone()

        if not exists:
            cur.execute(
                """
                INSERT INTO notice_views (notice_id, user_id, viewed_at)
                VALUES (%s, %s, NOW())
                """,
                (notice_id, user_id),
            )
            db.commit()

        return {"ok": True}
    except Exception:
        db.rollback()
        raise
    finally:
        cur.close()