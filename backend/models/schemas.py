"""
JARVIS Backend — Pydantic Schemas
Request and response models for API endpoints.
"""

from pydantic import BaseModel, Field
from typing import Optional
from enum import Enum


class UrgencyLevel(str, Enum):
    LOW = "LOW"
    NORMAL = "NORMAL"
    HIGH = "HIGH"
    CRITICAL = "CRITICAL"


class IntentCategory(str, Enum):
    GREETING = "GREETING"
    REQUEST = "REQUEST"
    REQUEST_ASSISTANCE = "REQUEST_ASSISTANCE"
    MEDICAL_ASSISTANCE = "MEDICAL_ASSISTANCE"
    EMERGENCY = "EMERGENCY"
    ACKNOWLEDGMENT = "ACKNOWLEDGMENT"
    NEGATION = "NEGATION"
    GENERAL = "GENERAL"
    HEALTHCARE = "HEALTHCARE"
    SAFETY = "SAFETY"


class GestureInput(BaseModel):
    """Input payload from Flutter app — gesture sequence + language."""
    gestures: list[str] = Field(..., min_length=1, description="List of recognized gesture tokens")
    language: str = Field(default="en", description="Target language code (en, ta, hi, etc.)")
    confidence_scores: Optional[list[float]] = Field(default=None, description="Confidence for each gesture")


class IntentResponse(BaseModel):
    """Structured LLM interpretation of a gesture sequence."""
    message: str = Field(..., description="Natural language interpretation")
    intent: str = Field(..., description="Detected communication intent")
    urgency: UrgencyLevel = Field(default=UrgencyLevel.NORMAL, description="Urgency level")
    category: str = Field(default="GENERAL", description="Communication category")
    confidence: float = Field(default=0.0, ge=0.0, le=1.0, description="Overall confidence")
    suggested_action: Optional[str] = Field(default=None, description="Suggested follow-up action")
    is_emergency: bool = Field(default=False, description="Whether this is an emergency")


class ReverseInput(BaseModel):
    """Input for reverse communication — text/speech to sign sequence."""
    text: str = Field(..., min_length=1, description="Text to convert to sign sequence")
    language: str = Field(default="en", description="Source language code")


class ReverseResponse(BaseModel):
    """Sign sequence mapping from text input."""
    original_text: str
    simplified_text: str
    sign_sequence: list[str]
    descriptions: list[str] = Field(default_factory=list, description="Description for each sign")


class TranslateInput(BaseModel):
    """Translation request."""
    text: str = Field(..., min_length=1)
    source_language: str = Field(default="en")
    target_language: str = Field(default="ta")


class TranslateResponse(BaseModel):
    """Translation result."""
    original_text: str
    translated_text: str
    source_language: str
    target_language: str


class HealthResponse(BaseModel):
    """Health check response."""
    status: str = "ok"
    service: str = "jarvis-backend"
    version: str = "1.0.0"
