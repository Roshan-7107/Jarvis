/// JARVIS — Application Constants
/// Gesture labels, API endpoints, and configuration values.

class AppConstants {
  AppConstants._();

  // ── App Info ──
  static const String appName = 'JARVIS';
  static const String appTagline =
      'Just-in-time AI Recognition & Vision-based Interaction System';
  static const String appVersion = '1.0.0';

  // ── Backend API ──
  static const String defaultBaseUrl = 'http://10.214.43.84:8000'; // Wi-Fi Local IP
  static const String interpretEndpoint = '/api/interpret';
  static const String reverseEndpoint = '/api/reverse';
  static const String translateEndpoint = '/api/translate';
  static const String healthEndpoint = '/health';

  // ── Gesture Recognition ──
  static const int frameProcessingIntervalMs = 400; // Process every 400ms
  static const double confidenceThreshold = 0.65;
  static const int gestureSequenceTimeoutMs = 3000; // 3 sec idle = sequence complete
  static const int maxSequenceLength = 10;

  // ── Predefined Gesture Vocabulary ──
  static const List<String> gestureLabels = [
    'HELLO',
    'THANK_YOU',
    'YES',
    'NO',
    'HELP',
    'HOSPITAL',
    'POLICE',
    'FIRE',
    'WATER',
    'FOOD',
    'PAIN',
    'EMERGENCY',
    'PLEASE',
    'SORRY',
    'GOODBYE',
    'I',
    'YOU',
    'WANT',
    'NEED',
    'WHERE',
  ];

  // ── Emergency Gestures ──
  static const Set<String> emergencyGestures = {
    'EMERGENCY',
    'HELP',
    'FIRE',
    'POLICE',
  };

  static const List<List<String>> emergencyCombinations = [
    ['HELP', 'FIRE'],
    ['HELP', 'POLICE'],
    ['HELP', 'HOSPITAL'],
    ['HELP', 'PAIN'],
    ['EMERGENCY'],
  ];

  // ── Supported Languages ──
  static const Map<String, String> supportedLanguages = {
    'en': 'English',
    'ta': 'Tamil',
    'hi': 'Hindi',
    'te': 'Telugu',
    'kn': 'Kannada',
    'ml': 'Malayalam',
    'es': 'Spanish',
    'fr': 'French',
  };

  // ── TTS ──
  static const double defaultSpeechRate = 0.5;
  static const double defaultSpeechPitch = 1.0;
  static const double defaultSpeechVolume = 1.0;
}
