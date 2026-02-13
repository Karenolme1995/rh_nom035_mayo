from pydantic import BaseModel
from typing import Optional

class NoticeCreate(BaseModel):
    title: str
    body: str
    plant: Optional[str] = None
    active: Optional[bool] = True

class NoticeUpdate(BaseModel):
    title: Optional[str] = None
    body: Optional[str] = None
    plant: Optional[str] = None
    active: Optional[bool] = None

class NoticeOut(BaseModel):
    id: int
    title: str
    body: str
    plant: Optional[str] = None
    active: bool
    created_by: Optional[int] = None
    created_at: Optional[str] = None
    image_url: Optional[str] = None