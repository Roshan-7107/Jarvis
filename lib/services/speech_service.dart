/// JARVIS — Speech Service
/// Text-to-Speech and Speech-to-Text integration.

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../core/constants/app_constants.dart';
import '../core/utils/logger.dart';

class SpeechService extends ChangeNotifier {
  final FlutterTts _tts = FlutterTts();
  final stt.SpeechToText _stt = stt.SpeechToText();

  bool _isSpeaking = false;
  bool _isListening = false;
  bool _sttAvailable = false;
  String _lastRecognizedText = '';

  bool get isSpeaking => _isSpeaking;
  bool get isListening => _isListening;
  bool get sttAvailable => _sttAvailable;
  String get lastRecognizedText => _lastRecognizedText;

  /// Initialize TTS and STT engines.
  Future<void> initialize() async {
    // TTS setup
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(AppConstants.defaultSpeechRate);
    await _tts.setPitch(AppConstants.defaultSpeechPitch);
    await _tts.setVolume(AppConstants.defaultSpeechVolume);

    _tts.setStartHandler(() {
      _isSpeaking = true;
      notifyListeners();
    });

    _tts.setCompletionHandler(() {
      _isSpeaking = false;
      notifyListeners();
    });

    _tts.setErrorHandler((msg) {
      _isSpeaking = false;
      AppLogger.error('TTS', 'Error: $msg');
      notifyListeners();
    });

    // STT setup
    _sttAvailable = await _stt.initialize(
      onError: (error) {
        AppLogger.error('STT', 'Error: ${error.errorMsg}');
        _isListening = false;
        notifyListeners();
      },
      onStatus: (status) {
        AppLogger.info('STT', 'Status: $status');
      },
    );

    AppLogger.info('Speech', 'TTS ready, STT available: $_sttAvailable');
  }

  /// Speak text aloud using TTS.
  Future<void> speak(String text, {String languageCode = 'en-US'}) async {
    if (text.isEmpty) return;

    await _tts.setLanguage(languageCode);
    await _tts.speak(text);
    AppLogger.info('TTS', 'Speaking: "${text.substring(0, text.length.clamp(0, 50))}..."');
  }

  /// Stop speaking.
  Future<void> stopSpeaking() async {
    await _tts.stop();
    _isSpeaking = false;
    notifyListeners();
  }

  /// Start listening for speech input.
  Future<void> startListening({
    required Function(String) onResult,
    String localeId = 'en_US',
  }) async {
    if (!_sttAvailable) {
      AppLogger.warning('STT', 'Speech recognition not available');
      return;
    }

    _isListening = true;
    _lastRecognizedText = '';
    notifyListeners();

    await _stt.listen(
      onResult: (result) {
        _lastRecognizedText = result.recognizedWords;
        if (result.finalResult) {
          _isListening = false;
          onResult(_lastRecognizedText);
        }
        notifyListeners();
      },
      localeId: localeId,
      listenMode: stt.ListenMode.confirmation,
    );

    AppLogger.info('STT', 'Listening started');
  }

  /// Stop listening.
  Future<void> stopListening() async {
    await _stt.stop();
    _isListening = false;
    notifyListeners();
  }

  /// Get available TTS languages.
  Future<List<String>> getAvailableLanguages() async {
    final languages = await _tts.getLanguages;
    return List<String>.from(languages ?? []);
  }

  @override
  void dispose() {
    _tts.stop();
    _stt.stop();
    super.dispose();
  }
}
