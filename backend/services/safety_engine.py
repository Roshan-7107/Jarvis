"""
JARVIS Backend — Safety Engine
Rule-based safety validation for emergency detection.
LLM = Understands. Rules = Control Safety Actions.
"""

from models.schemas import IntentResponse, UrgencyLevel


# Emergency gesture keywords — deterministic detection
EMERGENCY_GESTURES = {"EMERGENCY", "SOS", "DANGER"}

FIRE_GESTURES = {"FIRE", "BURN", "SMOKE"}
MEDICAL_GESTURES = {"HOSPITAL", "PAIN", "HURT", "SICK", "MEDICINE", "DOCTOR"}
POLICE_GESTURES = {"POLICE", "HELP", "STEAL", "ATTACK", "FIGHT"}

# Gesture combinations that auto-trigger emergency
EMERGENCY_COMBINATIONS = [
    ({"HELP", "FIRE"}, "FIRE_EMERGENCY", UrgencyLevel.CRITICAL),
    ({"HELP", "POLICE"}, "SAFETY_EMERGENCY", UrgencyLevel.CRITICAL),
    ({"HELP", "HOSPITAL"}, "MEDICAL_EMERGENCY", UrgencyLevel.HIGH),
    ({"HELP", "PAIN"}, "MEDICAL_ASSISTANCE", UrgencyLevel.HIGH),
    ({"EMERGENCY"}, "GENERAL_EMERGENCY", UrgencyLevel.CRITICAL),
    ({"SOS"}, "SOS_EMERGENCY", UrgencyLevel.CRITICAL),
]


class SafetyEngine:
    """
    Rule-based safety engine that overrides LLM output for emergency scenarios.
    Ensures deterministic, reliable emergency handling without depending on LLM judgment.
    """

    @staticmethod
    def check_emergency(gestures: list[str]) -> dict | None:
        """
        Check if gesture sequence matches any emergency pattern.
        Returns emergency info dict or None.
        """
        gesture_set = {g.upper() for g in gestures}

        # Check explicit emergency combinations
        for combo, emergency_type, urgency in EMERGENCY_COMBINATIONS:
            if combo.issubset(gesture_set):
                return {
                    "is_emergency": True,
                    "emergency_type": emergency_type,
                    "urgency": urgency,
                    "matched_pattern": list(combo),
                }

        # Check for any standalone emergency gesture
        if gesture_set & EMERGENCY_GESTURES:
            return {
                "is_emergency": True,
                "emergency_type": "GENERAL_EMERGENCY",
                "urgency": UrgencyLevel.CRITICAL,
                "matched_pattern": list(gesture_set & EMERGENCY_GESTURES),
            }

        return None

    @staticmethod
    def apply_safety_overrides(response: IntentResponse, gestures: list[str]) -> IntentResponse:
        """
        Apply rule-based safety overrides to LLM response.
        Emergency detection uses deterministic rules, not LLM judgment.
        """
        emergency = SafetyEngine.check_emergency(gestures)

        if emergency:
            response.is_emergency = True
            # Override urgency if rules detect higher urgency
            rule_urgency = emergency["urgency"]
            urgency_order = [UrgencyLevel.LOW, UrgencyLevel.NORMAL, UrgencyLevel.HIGH, UrgencyLevel.CRITICAL]

            if urgency_order.index(rule_urgency) > urgency_order.index(response.urgency):
                response.urgency = rule_urgency

            # Ensure category reflects emergency
            if response.urgency in (UrgencyLevel.HIGH, UrgencyLevel.CRITICAL):
                etype = emergency["emergency_type"]
                if "FIRE" in etype:
                    response.category = "SAFETY"
                elif "MEDICAL" in etype:
                    response.category = "HEALTHCARE"
                elif "SAFETY" in etype or "POLICE" in etype:
                    response.category = "SAFETY"
                else:
                    response.category = "EMERGENCY"

        return response

    @staticmethod
    def get_emergency_actions(emergency_type: str) -> list[str]:
        """Get recommended actions for an emergency type."""
        actions = {
            "FIRE_EMERGENCY": [
                "Capture device location",
                "Alert trusted contacts",
                "Display fire evacuation guidance",
                "Provide fire department contact",
            ],
            "MEDICAL_EMERGENCY": [
                "Capture device location",
                "Alert trusted contacts",
                "Display nearby hospitals",
                "Provide emergency medical number",
            ],
            "SAFETY_EMERGENCY": [
                "Capture device location",
                "Alert trusted contacts silently",
                "Provide police contact",
                "Log incident with timestamp",
            ],
            "GENERAL_EMERGENCY": [
                "Capture device location",
                "Alert all trusted contacts",
                "Provide emergency services number",
                "Generate emergency message",
            ],
            "SOS_EMERGENCY": [
                "Capture device location",
                "Alert all trusted contacts immediately",
                "Start emergency call workflow",
                "Log incident securely",
            ],
        }
        return actions.get(emergency_type, actions["GENERAL_EMERGENCY"])
