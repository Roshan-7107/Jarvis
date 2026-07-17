/// JARVIS — Translation Service
/// Wraps the API service for multilingual translation.

import 'package:flutter/material.dart';
import '../core/utils/logger.dart';
import '../models/translation_model.dart';
import 'api_service.dart';

class TranslationService extends ChangeNotifier {
  final ApiService _api;
  TranslationResult? _lastTranslation;
  bool _isTranslating = false;
  String? _error;

  TranslationService({ApiService? apiService})
      : _api = apiService ?? ApiService();

  TranslationResult? get lastTranslation => _lastTranslation;
  bool get isTranslating => _isTranslating;
  String? get error => _error;

  /// Translate text to a target language.
  Future<TranslationResult?> translate({
    required String text,
    String sourceLanguage = 'en',
    required String targetLanguage,
  }) async {
    _isTranslating = true;
    _error = null;
    notifyListeners();

    try {
      _lastTranslation = await _api.translate(
        text: text,
        sourceLanguage: sourceLanguage,
        targetLanguage: targetLanguage,
      );
      AppLogger.info('Translation', '${sourceLanguage} → ${targetLanguage}: done');
      return _lastTranslation;
    } catch (e) {
      _error = 'Translation failed: $e';
      AppLogger.error('Translation', _error!, e);
      return null;
    } finally {
      _isTranslating = false;
      notifyListeners();
    }
  }
}
