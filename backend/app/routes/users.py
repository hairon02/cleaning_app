"""User profile registration API."""

import sqlite3
from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Depends
from pydantic import BaseModel, StringConstraints, field_validator

from app.db import get_db

router = APIRouter(tags=["users"])


class UserRegistrationRequest(BaseModel):
    id: UUID
    display_name: Annotated[str, StringConstraints(min_length=1, max_length=40)]

    @field_validator("display_name", mode="before")
    @classmethod
    def normalize_display_name(cls, value: object) -> object:
        return value.strip() if isinstance(value, str) else value


class RegisteredUser(BaseModel):
    id: str
    display_name: str


@router.post("/users", response_model=RegisteredUser)
def register_user(
    payload: UserRegistrationRequest,
    conn: sqlite3.Connection = Depends(get_db),
) -> RegisteredUser:
    """Create or refresh the profile for a stable device-generated ID."""
    user_id = str(payload.id)
    conn.execute(
        """
        INSERT INTO users (id, display_name)
        VALUES (?, ?)
        ON CONFLICT(id) DO UPDATE SET display_name = excluded.display_name
        """,
        (user_id, payload.display_name),
    )
    conn.commit()
    return RegisteredUser(id=user_id, display_name=payload.display_name)
