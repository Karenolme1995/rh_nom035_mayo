# app/schemas/auth.py
from pydantic import BaseModel
from pydantic import BaseModel, EmailStr

class UserLogin(BaseModel):
    employee_number: str
    password: str

class LoginSchema(BaseModel):
    employee_number: str
    password: str

class ForgotPasswordSchema(BaseModel):
    employee_number: str
    email: EmailStr

class VerifyCodeSchema(BaseModel):
    employee_number: str
    code: str

class ResetPasswordSchema(BaseModel):
    employee_number: str
    code: str
    new_password: str
