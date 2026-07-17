"""
JARVIS Backend — Translation Router
POST /api/translate — Multilingual translation
"""

from fastapi import APIRouter, HTTPException
from models.schemas import TranslateInput, TranslateResponse
from services.llm_service import LLMService

router = APIRouter(prefix="/api", tags=["translate"])

llm_service = LLMService()


@router.post("/translate", response_model=TranslateResponse)
async def translate_text(payload: TranslateInput):
    """
    Translate text between languages.

    Supports: English, Tamil, Hindi, Telugu, Kannada, Malayalam,
    Marathi, Bengali, Gujarati, Punjabi, Urdu, Spanish, French,
    German, Japanese, Chinese, Korean, Arabic.
    """
    try:
        response = await llm_service.translate_text(
            text=payload.text,
            source_language=payload.source_language,
            target_language=payload.target_language,
        )
        return response
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Failed to translate: {str(e)}",
        )
