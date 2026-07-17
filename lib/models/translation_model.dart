/// JARVIS — Translation Model
/// Translation result data.

class TranslationResult {
  final String originalText;
  final String translatedText;
  final String sourceLanguage;
  final String targetLanguage;

  TranslationResult({
    required this.originalText,
    required this.translatedText,
    required this.sourceLanguage,
    required this.targetLanguage,
  });

  Map<String, dynamic> toJson() => {
        'original_text': originalText,
        'translated_text': translatedText,
        'source_language': sourceLanguage,
        'target_language': targetLanguage,
      };

  factory TranslationResult.fromJson(Map<String, dynamic> json) =>
      TranslationResult(
        originalText: json['original_text'] as String,
        translatedText: json['translated_text'] as String,
        sourceLanguage: json['source_language'] as String,
        targetLanguage: json['target_language'] as String,
      );
}

/// Reverse communication result — text to sign sequence.
class ReverseResult {
  final String originalText;
  final String simplifiedText;
  final List<String> signSequence;
  final List<String> descriptions;

  ReverseResult({
    required this.originalText,
    required this.simplifiedText,
    required this.signSequence,
    this.descriptions = const [],
  });

  factory ReverseResult.fromJson(Map<String, dynamic> json) => ReverseResult(
        originalText: json['original_text'] as String,
        simplifiedText: json['simplified_text'] as String,
        signSequence: List<String>.from(json['sign_sequence'] ?? []),
        descriptions: List<String>.from(json['descriptions'] ?? []),
      );
}
