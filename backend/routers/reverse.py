"""
JARVIS Backend — Reverse Communication Router
POST /api/reverse — Text/Speech → Sign-language gesture sequence
"""

from fastapi import APIRouter, HTTPException
from models.schemas import ReverseInput, ReverseResponse
from services.llm_service import LLMService

router = APIRouter(prefix="/api", tags=["reverse"])

llm_service = LLMService()


@router.post("/reverse", response_model=ReverseResponse)
async def reverse_communicate(payload: ReverseInput):
    """
    Convert text to a sign-language gesture sequence.

    Pipeline:
    1. Receive text from hearing user
    2. LLM simplifies and maps to gesture tokens
    3. Return ordered sign sequence with descriptions
    """
    try:
        response = await llm_service.reverse_communicate(
            text=payload.text,
            language=payload.language,
        )
        return response
    except Exception as e:
        import traceback
        traceback.print_exc()
        raise HTTPException(
            status_code=500,
            detail=f"Failed to generate sign sequence: {str(e)}",
        )
