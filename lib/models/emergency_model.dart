/// JARVIS — Emergency Model
/// Emergency alert data for the safety system.

class EmergencyAlert {
  final String type;
  final String severity;
  final String message;
  final DateTime timestamp;
  final List<String> suggestedActions;
  final double? latitude;
  final double? longitude;

  EmergencyAlert({
    required this.type,
    required this.severity,
    required this.message,
    DateTime? timestamp,
    this.suggestedActions = const [],
    this.latitude,
    this.longitude,
  }) : timestamp = timestamp ?? DateTime.now();

  bool get isCritical => severity == 'CRITICAL';
  bool get isHigh => severity == 'HIGH';

  String get severityEmoji {
    switch (severity) {
      case 'CRITICAL':
        return '🚨';
      case 'HIGH':
        return '⚠️';
      default:
        return '❗';
    }
  }

  String get typeLabel {
    switch (type) {
      case 'FIRE_EMERGENCY':
        return '🔥 Fire Emergency';
      case 'MEDICAL_EMERGENCY':
        return '🏥 Medical Emergency';
      case 'SAFETY_EMERGENCY':
        return '🛡️ Safety Emergency';
      case 'SOS_EMERGENCY':
        return '🆘 SOS Emergency';
      default:
        return '🚨 Emergency';
    }
  }

  Map<String, dynamic> toJson() => {
        'type': type,
        'severity': severity,
        'message': message,
        'timestamp': timestamp.toIso8601String(),
        'suggested_actions': suggestedActions,
        'latitude': latitude,
        'longitude': longitude,
      };

  factory EmergencyAlert.fromJson(Map<String, dynamic> json) => EmergencyAlert(
        type: json['type'] as String,
        severity: json['severity'] as String,
        message: json['message'] as String,
        suggestedActions: List<String>.from(json['suggested_actions'] ?? []),
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
      );
}
