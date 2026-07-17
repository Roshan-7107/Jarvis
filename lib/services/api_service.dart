/// JARVIS — API Service
/// HTTP client for communication with the FastAPI backend.

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/app_constants.dart';
import '../core/utils/logger.dart';
import '../models/intent_model.dart';
import '../models/translation_model.dart';

class ApiService {
  final String baseUrl;
  final http.Client _client;

  ApiService({String? baseUrl})
      : baseUrl = baseUrl ?? AppConstants.defaultBaseUrl,
        _client = http.Client();

  /// Interpret a gesture sequence via the backend LLM.
  Future<IntentResult> interpretGestures({
    required List<String> gestures,
    String language = 'en',
    List<double>? confidenceScores,
  }) async {
    AppLogger.api(AppConstants.interpretEndpoint, 'POST');

    final body = {
      'gestures': gestures,
      'language': language,
      if (confidenceScores != null) 'confidence_scores': confidenceScores,
    };

    final response = await _post(AppConstants.interpretEndpoint, body);
    return IntentResult.fromJson(response);
  }

  /// Reverse communicate: text → sign sequence.
  Future<ReverseResult> reverseCommunicate({
    required String text,
    String language = 'en',
  }) async {
    AppLogger.api(AppConstants.reverseEndpoint, 'POST');

    final body = {
      'text': text,
      'language': language,
    };

    final response = await _post(AppConstants.reverseEndpoint, body);
    return ReverseResult.fromJson(response);
  }

  /// Translate text between languages.
  Future<TranslationResult> translate({
    required String text,
    String sourceLanguage = 'en',
    required String targetLanguage,
  }) async {
    AppLogger.api(AppConstants.translateEndpoint, 'POST');

    final body = {
      'text': text,
      'source_language': sourceLanguage,
      'target_language': targetLanguage,
    };

    final response = await _post(AppConstants.translateEndpoint, body);
    return TranslationResult.fromJson(response);
  }

  /// Check backend health.
  Future<bool> checkHealth() async {
    try {
      final uri = Uri.parse('$baseUrl${AppConstants.healthEndpoint}');
      final response = await _client.get(uri).timeout(
            const Duration(seconds: 5),
          );
      return response.statusCode == 200;
    } catch (e) {
      AppLogger.error('API', 'Health check failed', e);
      return false;
    }
  }

  /// Internal POST helper with error handling.
  Future<Map<String, dynamic>> _post(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      final response = await _client
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        AppLogger.error('API', 'Error ${response.statusCode}: ${response.body}');
        throw ApiException(
          'Server returned ${response.statusCode}',
          response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      AppLogger.error('API', 'Request failed: $endpoint', e);
      throw ApiException('Connection failed: $e', 0);
    }
  }

  void dispose() {
    _client.close();
  }
}

class ApiException implements Exception {
  final String message;
  final int statusCode;

  ApiException(this.message, this.statusCode);

  @override
  String toString() => 'ApiException($statusCode): $message';
}
