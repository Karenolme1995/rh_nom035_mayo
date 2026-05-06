# app/schemas/user.py

from datetime import date, datetime
from typing import Optional
from pydantic import BaseModel, EmailStr


class UserCreate(BaseModel):
    employee_number: Optional[str] = None
    name: Optional[str] = None
    email: Optional[EmailStr] = None
    curp: Optional[str] = None
    role_id: Optional[int] = None
    area: Optional[str] = None
    position: Optional[str] = None
    birthday: Optional[date] = None
    phone: Optional[str] = None
    entry_date: Optional[date] = None
    active: Optional[int] = 1
    avatar: Optional[str] = None
    allowed_ips: Optional[str] = None
    plant: Optional[str] = None
    password: Optional[str] = None  # 


class UserUpdate(BaseModel):
    employee_number: Optional[str] = None
    name: Optional[str] = None
    email: Optional[EmailStr] = None
    curp: Optional[str] = None
    role_id: Optional[int] = None
    area: Optional[str] = None
    position: Optional[str] = None
    birthday: Optional[date] = None
    phone: Optional[str] = None
    entry_date: Optional[date] = None
    active: Optional[int] = None
    avatar: Optional[str] = None
    allowed_ips: Optional[str] = None
    plant: Optional[str] = None
    
    password: Optional[str] = None  


class UserOut(BaseModel):
    id: int
    employee_number: Optional[str] = None
    name: Optional[str] = None
    email: Optional[EmailStr] = None
    curp: Optional[str] = None
    role_id: Optional[int] = None
    area: Optional[str] = None
    position: Optional[str] = None
    birthday: Optional[date] = None
    phone: Optional[str] = None
    entry_date: Optional[date] = None
    active: Optional[int] = None
    avatar: Optional[str] = None
    allowed_ips: Optional[str] = None
    plant: Optional[str] = None

    # ✅ Nuevo campo que agregaste en BD
    last_login: Optional[datetime] = None

    class Config:
        from_attributes = True
