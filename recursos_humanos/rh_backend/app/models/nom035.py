# rh_backend/app/models/nom035.py
from sqlalchemy import (Column, Integer, String, Text, DateTime, Enum, ForeignKey,
    UniqueConstraint, Index, JSON, SmallInteger)
from sqlalchemy.orm import relationship, declarative_base
from datetime import datetime

Base = declarative_base()

class Nom035Cycle(Base):
    
    __tablename__ = "nom035_cycles"

    id = Column(Integer, primary_key=True, autoincrement=True)
    year = Column(Integer, nullable=False)
    title = Column(String(255), nullable=False)
    start_at = Column(DateTime, nullable=True)
    due_at = Column(DateTime, nullable=True)
    status = Column(Enum("draft", "active", "closed", name="nom035_cycle_status"), default="draft", nullable=False)

    created_by_user_id = Column(Integer, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False)

    questions = relationship("Nom035CycleQuestion", back_populates="cycle", cascade="all, delete-orphan")
    submissions = relationship("Nom035Submission", back_populates="cycle")


class Nom035Question(Base):
    __tablename__ = "nom035_questions"

    id = Column(Integer, primary_key=True, autoincrement=True)
    guide = Column(Enum("I", "II", "III", name="nom035_guide"), nullable=False)
    category = Column(String(255), nullable=True)
    question_text = Column(Text, nullable=False)
    response_type = Column(Enum("likert", "yes_no", "multiple", "open", name="nom035_response_type"), nullable=False)
    options_json = Column(JSON, nullable=True)
    order_no = Column(Integer, default=1, nullable=False)
    is_active = Column(SmallInteger, default=1, nullable=False)

    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False)

    cycles = relationship("Nom035CycleQuestion", back_populates="question", cascade="all, delete-orphan")


class Nom035CycleQuestion(Base):
    __tablename__ = "nom035_cycle_questions"

    cycle_id = Column(Integer, ForeignKey("nom035_cycles.id", ondelete="CASCADE"), primary_key=True)
    question_id = Column(Integer, ForeignKey("nom035_questions.id", ondelete="CASCADE"), primary_key=True)
    order_no = Column(Integer, default=1, nullable=False)

    cycle = relationship("Nom035Cycle", back_populates="questions")
    question = relationship("Nom035Question", back_populates="cycles")


class Nom035Submission(Base):
    __tablename__ = "nom035_submissions"
    __table_args__ = (
        UniqueConstraint("cycle_id", "employee_id", name="uq_nom035_cycle_employee"),
        Index("ix_nom035_employee_status", "employee_id", "status"),
        Index("ix_nom035_cycle_status", "cycle_id", "status"),
    )

    id = Column(Integer, primary_key=True, autoincrement=True)
    cycle_id = Column(Integer, ForeignKey("nom035_cycles.id", ondelete="CASCADE"), nullable=False)
    employee_id = Column(Integer, nullable=False)

    status = Column(Enum("available", "in_progress", "submitted", name="nom035_submission_status"), default="available", nullable=False)
    started_at = Column(DateTime, nullable=True)
    submitted_at = Column(DateTime, nullable=True)

    score_total = Column(Integer, nullable=True)
    risk_level = Column(String(50), nullable=True)
    observations = Column(Text, nullable=True)

    locked = Column(SmallInteger, default=0, nullable=False)

    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False)

    cycle = relationship("Nom035Cycle", back_populates="submissions")
    answers = relationship("Nom035Answer", back_populates="submission", cascade="all, delete-orphan")


class Nom035Answer(Base):
    __tablename__ = "nom035_answers"
    __table_args__ = (
        UniqueConstraint("submission_id", "question_id", name="uq_nom035_submission_question"),
        Index("ix_nom035_submission_id", "submission_id"),
    )

    id = Column(Integer, primary_key=True, autoincrement=True)
    submission_id = Column(Integer, ForeignKey("nom035_submissions.id", ondelete="CASCADE"), nullable=False)
    question_id = Column(Integer, ForeignKey("nom035_questions.id", ondelete="CASCADE"), nullable=False)

    answer_value = Column(Text, nullable=True)

    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False)

    submission = relationship("Nom035Submission", back_populates="answers")