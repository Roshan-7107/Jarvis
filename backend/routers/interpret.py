"""
JARVIS Backend — Interpret Router
POST /api/interpret — Gesture sequence → LLM → Intent + Context
"""

from fastapi import APIRouter, HTTPException
from models.schemas import GestureInput, IntentResponse
from services.llm_service import LLMService
from services.safety_engine import SafetyEngine

router = APIRouter(prefix="/api", tags=["interpret"])

llm_service = LLMService()
safety_engine = SafetyEngine()


@router.post("/interpret", response_model=IntentResponse)
async def interpret_gestures(payload: GestureInput):
    """
    Interpret a sign-language gesture sequence.

    Pipeline:
    1. Receive gesture tokens from Flutter
    2. Send to LLM for context + intent understanding
    3. Apply rule-based safety overrides for emergencies
    4. Return structured response
    """
    try:
        # Step 1: LLM interpretation
        response = await llm_service.interpret_gestures(
            gestures=payload.gestures,
            language=payload.language,
            confidence_scores=payload.confidence_scores,
        )

        # Step 2: Rule-based safety override (LLM understands, rules control safety)
        response = safety_engine.apply_safety_overrides(response, payload.gestures)

        # Step 3: Add emergency actions if needed
        if response.is_emergency:
            emergency_info = safety_engine.check_emergency(payload.gestures)
            if emergency_info:
                actions = safety_engine.get_emergency_actions(emergency_info["emergency_type"])
                response.suggested_action = "; ".join(actions[:2])  # Top 2 actions

        return response

    except ValueError as e:
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=str(e))
    except Exception as e:
        import traceback
        traceback.print_exc()
        raise HTTPException(
            status_code=500,
            detail=f"Failed to interpret gestures: {str(e)}",
        )
