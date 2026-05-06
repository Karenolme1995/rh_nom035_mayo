# rh_backend/app/schemas/nom035.py
from pydantic import BaseModel, Field
from typing import Optional, Any, List, Literal
from datetime import datetime

class Nom035QuestionOut(BaseModel):
    id: int
    guide: str
    category: Optional[str] = None
    question_text: str
    response_type: str
    options_json: Optional[Any] = None
    order_no: int
    is_active: int

class Nom035CycleOut(BaseModel):
    id: int
    year: int
    title: str
    start_at: Optional[datetime] = None
    due_at: Optional[datetime] = None
    status: str

class Nom035CycleUpsert(BaseModel):
    year: int
    title: str
    start_at: Optional[str] = None  # "YYYY-MM-DD HH:MM:SS"
    due_at: Optional[str] = None
    status: str = Field(default="draft")

class Nom035QuestionUpsert(BaseModel):
    id: Optional[int] = None
    guide: Literal["I", "II", "III"]
    category: Optional[str] = None
    question_text: str
    response_type: Literal["likert", "yes_no", "multiple", "open"]
    options_json: Optional[Any] = None
    order_no: int = 1
    is_active: int = 1

class Nom035SetCycleQuestions(BaseModel):
    question_ids: List[int]

class Nom035StartOut(BaseModel):
    submission_id: int
    status: str

class Nom035FormItem(BaseModel):
    form_id: int
    title: str
    type: str = "nom035"
    status: str
    started_at: Optional[str] = None
    due_at: Optional[str] = None
    submission_id: Optional[int] = None

class Nom035FormDetail(BaseModel):
    form_id: int
    title: str
    type: str = "nom035"
    questions: List[dict]  

class Nom035AnswerIn(BaseModel):
    question_id: int
    answer_value: Any | None = None
    option_id: int | str | None = None
    option_ids: list[int | str] | None = None
    answer_text: str | None = None

class Nom035ResultOut(BaseModel):
    submission_id: int
    cycle_id: int
    employee_id: int
    status: str
    score_total: Optional[int] = None
    risk_level: Optional[str] = None
    observations: Optional[str] = None
    submitted_at: Optional[datetime] = None