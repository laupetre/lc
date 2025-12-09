"""
Pydantic models for request/response schemas
"""
from typing import Optional
from pydantic import BaseModel


class ChatIn(BaseModel):
    """Input model for chat requests"""
    input: str
    system: Optional[str] = None


class ChatOut(BaseModel):
    """Output model for chat responses"""
    output: str
    model: str


class BoxFile(BaseModel):
    """Model for Box file information"""
    id: str
    name: str
    type: str
    size: Optional[int] = None
    modified_at: Optional[str] = None

