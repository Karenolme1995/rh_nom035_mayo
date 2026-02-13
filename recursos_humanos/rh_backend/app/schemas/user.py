from pydantic import BaseModel, EmailStr
from typing import Optional

class UserCreate(BaseModel):
    employee_number: Optional[str] = None
    name: str
    email: EmailStr
    password: str
    role_id: int
    area: Optional[str] = None
    position: Optional[str] = None

class UserUpdate(BaseModel):
    name: Optional[str] = None
    email: Optional[EmailStr] = None
    role_id: Optional[int] = None
    area: Optional[str] = None
    position: Optional[str] = None
    active: Optional[bool] = None
