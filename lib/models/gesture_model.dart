/// JARVIS — Gesture Model
/// Represents a recognized sign-language gesture with metadata.

class GestureResult {
  final String label;
  final double confidence;
  final DateTime timestamp;
  final List<List<double>>? landmarks;

  GestureResult({
    required this.label,
    required this.confidence,
    DateTime? timestamp,
    this.landmarks,
  }) : timestamp = timestamp ?? DateTime.now();

  bool get isHighConfidence => confidence >= 0.8;
  bool get isMediumConfidence => confidence >= 0.6 && confidence < 0.8;
  bool get isLowConfidence => confidence < 0.6;

  String get confidenceLabel {
    if (isHighConfidence) return 'High';
    if (isMediumConfidence) return 'Medium';
    return 'Low';
  }

  String get confidencePercentage => '${(confidence * 100).toStringAsFixed(0)}%';

  Map<String, dynamic> toJson() => {
        'label': label,
        'confidence': confidence,
        'timestamp': timestamp.toIso8601String(),
      };

  factory GestureResult.fromJson(Map<String, dynamic> json) => GestureResult(
        label: json['label'] as String,
        confidence: (json['confidence'] as num).toDouble(),
        timestamp: DateTime.parse(json['timestamp'] as String),
      );

  @override
  String toString() => 'GestureResult($label, ${confidencePercentage})';
}
