#app/core/jwt.py
from datetime import datetime, timedelta
from jose import jwt
from app.core.config import settings

def create_access_token(data: dict, expires_minutes: int | None = None) -> str:
    to_encode = data.copy()

    minutes = expires_minutes if expires_minutes is not None else settings.access_token_expire_minutes
    expire = datetime.utcnow() + timedelta(days=365)
    to_encode.update({"exp": expire})

    # set sub si no viene
    if "sub" not in to_encode:
        if "user_id" in to_encode:
            to_encode["sub"] = str(to_encode["user_id"])
        elif "id" in to_encode:
            to_encode["sub"] = str(to_encode["id"])

    return jwt.encode(to_encode, settings.secret_key, algorithm=settings.algorithm)

def decode_token(token: str) -> dict:
    return jwt.decode(token, settings.secret_key, algorithms=[settings.algorithm])


