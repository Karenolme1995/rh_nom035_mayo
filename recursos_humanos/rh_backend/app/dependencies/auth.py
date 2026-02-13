from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from jose import jwt, JWTError

from app.core.config import settings
from app.core.redis_client import redis_client

security = HTTPBearer()

def get_current_user(credentials: HTTPAuthorizationCredentials = Depends(security)):
    token = credentials.credentials

    # 1) Decodificar JWT
    try:
        payload = jwt.decode(
            token,
            settings.secret_key,              # ✅ antes: settings.JWT_SECRET
            algorithms=[settings.algorithm],  # ✅ antes: settings.JWT_ALGORITHM
        )
    except JWTError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token inválido o expirado",
        )

    # 2) Validar sesión en Redis (si está disponible)
    try:
        if redis_client is not None:
            if not redis_client.exists(token):
                raise HTTPException(
                    status_code=status.HTTP_401_UNAUTHORIZED,
                    detail="Sesión expirada o inválida",
                )
    except Exception:
        # En desarrollo no bloquea si Redis falla
        pass

    return payload
