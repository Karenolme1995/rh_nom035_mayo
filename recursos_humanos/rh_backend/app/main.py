from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from pathlib import Path

from app.api.v1.auth import router as auth_router
from app.api.v1.users import router as users_router
from app.api.v1.birthdays import router as birthdays_router
from app.api.v1.positions import router as positions_router
from app.api.v1.areas import router as areas_router
from app.dependencies.auth import get_current_user

app = FastAPI(title="RH API", version="1.0.0")

#  uploads absoluto y creado siempre
UPLOAD_DIR = Path(__file__).resolve().parents[1] / "uploads"  # rh_backend/uploads
UPLOAD_DIR.mkdir(parents=True, exist_ok=True)

app.mount("/uploads", StaticFiles(directory=str(UPLOAD_DIR)), name="uploads")

#  CORS (para Flutter Web)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/")
def root():
    return {"message": "API RH activa y funcionando correctamente 🚀"}

#  TODO en /api/v1
app.include_router(auth_router, prefix="/api/v1")
app.include_router(users_router, prefix="/api/v1")
app.include_router(birthdays_router, prefix="/api/v1")
app.include_router(positions_router, prefix="/api/v1")
app.include_router(areas_router, prefix="/api/v1")

