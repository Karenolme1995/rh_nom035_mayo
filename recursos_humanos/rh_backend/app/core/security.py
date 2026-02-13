import random
from passlib.context import CryptContext
from passlib.exc import UnknownHashError

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

def _normalize_bcrypt_input(p: str) -> str:
    p = (p or "").strip()
    b = p.encode("utf-8")[:72]
    return b.decode("utf-8", errors="ignore")

def hash_password(password: str) -> str:
    return pwd_context.hash(_normalize_bcrypt_input(password))

def verify_password(plain_password: str, hashed_password: str) -> bool:
    if not hashed_password:
        return False
    try:
        return pwd_context.verify(_normalize_bcrypt_input(plain_password), hashed_password)
    except UnknownHashError:
        return False

def generate_code() -> str:
    return str(random.randint(100000, 999999))
