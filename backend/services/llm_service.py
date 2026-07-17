"""
JARVIS Backend — LLM Service
Handles communication with Google Gemini for gesture interpretation.
"""

import json
import os
import google.generativeai as genai
from dotenv import load_dotenv
from models.schemas import IntentResponse, ReverseResponse, TranslateResponse, UrgencyLevel
from services.prompt_templates import (
    SYSTEM_PROMPT_INTERPRET,
    USER_PROMPT_INTERPRET,
    SYSTEM_PROMPT_REVERSE,
    USER_PROMPT_REVERSE,
    SYSTEM_PROMPT_TRANSLATE,
    USER_PROMPT_TRANSLATE,
)

load_dotenv()


class LLMService:
    """Manages LLM interactions for gesture interpretation, reverse communication, and translation."""

    def __init__(self):
        api_key = os.getenv("GEMINI_API_KEY")
        if not api_key or api_key == "your_gemini_api_key_here":
            raise ValueError(
                "GEMINI_API_KEY not configured. "
                "Copy .env.example to .env and add your API key."
            )
        genai.configure(api_key=api_key)
        model_name = os.getenv("LLM_MODEL", "gemini-2.0-flash")
        self.model = genai.GenerativeModel(model_name)

    def _parse_json_response(self, text: str) -> dict:
        """Extract JSON from LLM response, handling markdown code blocks."""
        cleaned = text.strip()
        # Strip markdown code fences if present
        if cleaned.startswith("```"):
            lines = cleaned.split("\n")
            # Remove first and last lines (code fence markers)
            lines = [l for l in lines[1:] if not l.strip().startswith("```")]
            cleaned = "\n".join(lines)
        return json.loads(cleaned)

    async def interpret_gestures(
        self, gestures: list[str], language: str = "en", confidence_scores: list[float] | None = None
    ) -> IntentResponse:
        """Interpret a gesture sequence using the LLM."""
        gesture_str = ", ".join(gestures)
        user_prompt = USER_PROMPT_INTERPRET.format(gestures=gesture_str, language=language)

        response = self.model.generate_content(
            [
                {"role": "user", "parts": [SYSTEM_PROMPT_INTERPRET]},
                {"role": "model", "parts": ["Understood. I will interpret sign-language gesture sequences and respond with structured JSON."]},
                {"role": "user", "parts": [user_prompt]},
            ]
        )

        try:
            data = self._parse_json_response(response.text)
            # Compute average confidence from gesture recognition if available
            if confidence_scores and "confidence" not in data:
                data["confidence"] = round(sum(confidence_scores) / len(confidence_scores), 2)
            return IntentResponse(**data)
        except (json.JSONDecodeError, Exception) as e:
            # Fallback: return a basic response
            return IntentResponse(
                message=response.text if response.text else "Could not interpret gestures.",
                intent="UNKNOWN",
                urgency=UrgencyLevel.NORMAL,
                category="GENERAL",
                confidence=0.5,
                suggested_action="Please repeat the gesture.",
                is_emergency=False,
            )

    async def reverse_communicate(self, text: str, language: str = "en") -> ReverseResponse:
        """Convert text to sign-language gesture sequence."""
        user_prompt = USER_PROMPT_REVERSE.format(text=text)

        response = self.model.generate_content(
            [
                {"role": "user", "parts": [SYSTEM_PROMPT_REVERSE]},
                {"role": "model", "parts": ["Understood. I will convert text to sign-language gesture sequences and respond with structured JSON."]},
                {"role": "user", "parts": [user_prompt]},
            ]
        )

        try:
            data = self._parse_json_response(response.text)
            return ReverseResponse(
                original_text=text,
                simplified_text=data.get("simplified_text", text),
                sign_sequence=data.get("sign_sequence", []),
                descriptions=data.get("descriptions", []),
            )
        except (json.JSONDecodeError, Exception):
            return ReverseResponse(
                original_text=text,
                simplified_text=text,
                sign_sequence=["UNKNOWN"],
                descriptions=["Could not map text to signs."],
            )

    async def translate_text(
        self, text: str, source_language: str = "en", target_language: str = "ta"
    ) -> TranslateResponse:
        """Translate text between languages."""
        language_names = {
            "en": "English", "ta": "Tamil", "hi": "Hindi",
            "te": "Telugu", "kn": "Kannada", "ml": "Malayalam",
            "mr": "Marathi", "bn": "Bengali", "gu": "Gujarati",
            "pa": "Punjabi", "ur": "Urdu", "es": "Spanish",
            "fr": "French", "de": "German", "ja": "Japanese",
            "zh": "Chinese", "ko": "Korean", "ar": "Arabic",
        }
        src_name = language_names.get(source_language, source_language)
        tgt_name = language_names.get(target_language, target_language)

        user_prompt = USER_PROMPT_TRANSLATE.format(
            text=text, source_language=src_name, target_language=tgt_name
        )

        response = self.model.generate_content(
            [
                {"role": "user", "parts": [SYSTEM_PROMPT_TRANSLATE]},
                {"role": "model", "parts": ["Understood. I will translate text accurately and respond with structured JSON."]},
                {"role": "user", "parts": [user_prompt]},
            ]
        )

        try:
            data = self._parse_json_response(response.text)
            return TranslateResponse(
                original_text=text,
                translated_text=data.get("translated_text", text),
                source_language=source_language,
                target_language=target_language,
            )
        except (json.JSONDecodeError, Exception):
            return TranslateResponse(
                original_text=text,
                translated_text=text,
                source_language=source_language,
                target_language=target_language,
            )
