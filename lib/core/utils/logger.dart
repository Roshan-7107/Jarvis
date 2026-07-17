/// JARVIS — Debug Logger Utility

import 'dart:developer' as developer;

class AppLogger {
  AppLogger._();

  static void info(String tag, String message) {
    developer.log('ℹ️ $message', name: 'JARVIS/$tag');
  }

  static void warning(String tag, String message) {
    developer.log('⚠️ $message', name: 'JARVIS/$tag');
  }

  static void error(String tag, String message, [Object? error]) {
    developer.log('❌ $message', name: 'JARVIS/$tag', error: error);
  }

  static void gesture(String gesture, double confidence) {
    developer.log(
      '🤟 Gesture: $gesture (${(confidence * 100).toStringAsFixed(1)}%)',
      name: 'JARVIS/Gesture',
    );
  }

  static void emergency(String type) {
    developer.log('🚨 EMERGENCY: $type', name: 'JARVIS/Emergency');
  }

  static void api(String endpoint, String method) {
    developer.log('🔗 $method $endpoint', name: 'JARVIS/API');
  }
}
