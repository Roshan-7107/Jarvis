/// JARVIS — Intent Model
/// Structured LLM interpretation of a gesture sequence.

class IntentResult {
  final String message;
  final String intent;
  final String urgency;
  final String category;
  final double confidence;
  final String? suggestedAction;
  final bool isEmergency;

  IntentResult({
    required this.message,
    required this.intent,
    this.urgency = 'NORMAL',
    this.category = 'GENERAL',
    this.confidence = 0.0,
    this.suggestedAction,
    this.isEmergency = false,
  });

  bool get isCritical => urgency == 'CRITICAL';
  bool get isHigh => urgency == 'HIGH';
  bool get isNormal => urgency == 'NORMAL';
  bool get isLow => urgency == 'LOW';

  String get urgencyEmoji {
    switch (urgency) {
      case 'CRITICAL':
        return '🚨';
      case 'HIGH':
        return '⚠️';
      case 'NORMAL':
        return '💬';
      case 'LOW':
        return 'ℹ️';
      default:
        return '💬';
    }
  }

  String get categoryEmoji {
    switch (category) {
      case 'HEALTHCARE':
        return '🏥';
      case 'SAFETY':
        return '🛡️';
      case 'EMERGENCY':
        return '🚨';
      case 'GREETING':
        return '👋';
      case 'REQUEST':
        return '🙏';
      case 'ACKNOWLEDGMENT':
        return '✅';
      default:
        return '💬';
    }
  }

  String get confidencePercentage => '${(confidence * 100).toStringAsFixed(0)}%';

  Map<String, dynamic> toJson() => {
        'message': message,
        'intent': intent,
        'urgency': urgency,
        'category': category,
        'confidence': confidence,
        'suggested_action': suggestedAction,
        'is_emergency': isEmergency,
      };

  factory IntentResult.fromJson(Map<String, dynamic> json) => IntentResult(
        message: json['message'] as String? ?? 'Unknown',
        intent: json['intent'] as String? ?? 'UNKNOWN',
        urgency: json['urgency'] as String? ?? 'NORMAL',
        category: json['category'] as String? ?? 'GENERAL',
        confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
        suggestedAction: json['suggested_action'] as String?,
        isEmergency: json['is_emergency'] as bool? ?? false,
      );

  @override
  String toString() => 'IntentResult($intent, urgency=$urgency)';
}
