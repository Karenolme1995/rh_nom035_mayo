from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from pathlib import Path

from app.api.v1.auth import router as auth_router
from app.api.v1.users import router as users_router
from app.api.v1.birthdays import router as birthdays_router
from app.api.v1.positions import router as positions_router
from app.api.v1.areas import router as areas_router
from app.api.v1.profile import router as profile_router
from app.api.v1.forms import router as forms_router
from app.api.v1.submissions import router as submissions_router
from app.api.v1.nom035 import router as nom035_router
from app.api.v1.notices import router as notices_router
from app.api.v1.nom035_audit import router as nom035_audit_router
from app.api.v1.nom035_action_plan import router as nom035_action_plan_router
from app.api.v1.nom035_audit import download_router as nom035_audit_download_router
from app.api.v1.nom035_evidence import router as nom035_evidence_router
from app.api.v1.nom035_profile import router as nom035_profile_router
from app.api.v1.work_anniversaries import router as work_anniversaries_router
from app.api.v1.evaluations import router as evaluations_router


app = FastAPI(title="RH API", version="1.0.0")

BASE_DIR = Path(__file__).resolve().parents[1]

# Carpeta general de uploads
UPLOADS_DIR = BASE_DIR / "uploads"
UPLOADS_DIR.mkdir(parents=True, exist_ok=True)

# Carpeta específica para avatares
AVATARS_DIR = UPLOADS_DIR / "avatars"
AVATARS_DIR.mkdir(parents=True, exist_ok=True)

# Carpeta static real, por si la usas para otros recursos fijos
STATIC_DIR = BASE_DIR / "static"
STATIC_DIR.mkdir(parents=True, exist_ok=True)

# Montajes públicos
app.mount("/uploads", StaticFiles(directory=str(UPLOADS_DIR)), name="uploads")
app.mount("/static", StaticFiles(directory=str(STATIC_DIR)), name="static")

app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://127.0.0.1:8000",
        "http://localhost:8000",

        # VM / intranet
        "http://10.1.1.17",
        "http://10.1.1.17:80",
        "http://10.1.1.17:8080",
        "http://10.1.1.17:8000",

        # VPS si después lo usas
        "http://185.28.22.148",
    ],
    allow_origin_regex=r"http://(localhost|127\.0\.0\.1|10\.1\.1\.17|185\.28\.22\.148)(:\d+)?",
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/")
def root():
    return {"message": "API RH activa y funcionando correctamente 🚀"}

app.include_router(auth_router, prefix="/api/v1")
app.include_router(users_router, prefix="/api/v1")
app.include_router(birthdays_router, prefix="/api/v1")
app.include_router(positions_router, prefix="/api/v1")
app.include_router(areas_router, prefix="/api/v1")
app.include_router(notices_router, prefix="/api/v1")
app.include_router(profile_router, prefix="/api/v1")
app.include_router(forms_router, prefix="/api/v1")
app.include_router(submissions_router, prefix="/api/v1")
app.include_router(nom035_router, prefix="/api/v1", tags=["nom035"])
app.include_router(nom035_audit_router, prefix="/api/v1", tags=["nom035"])
app.include_router(nom035_action_plan_router, prefix="/api/v1", tags=["nom035"])
app.include_router(nom035_audit_download_router, prefix="/api/v1")
app.include_router(nom035_evidence_router, prefix="/api/v1")
app.include_router(nom035_profile_router, prefix="/api/v1")
app.include_router(work_anniversaries_router, prefix="/api/v1")
app.include_router(evaluations_router, prefix="/api/v1")