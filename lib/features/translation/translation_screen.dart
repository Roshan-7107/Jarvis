/// JARVIS — Translation Screen
/// Multilingual translation of interpreted messages.

import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../services/api_service.dart';
import '../../services/speech_service.dart';
import '../../models/translation_model.dart';

class TranslationScreen extends StatefulWidget {
  final String? initialText;

  const TranslationScreen({super.key, this.initialText});

  @override
  State<TranslationScreen> createState() => _TranslationScreenState();
}

class _TranslationScreenState extends State<TranslationScreen> {
  final TextEditingController _textController = TextEditingController();
  final ApiService _apiService = ApiService();
  final SpeechService _speechService = SpeechService();

  String _targetLanguage = 'ta'; // Tamil by default
  TranslationResult? _result;
  bool _isTranslating = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _speechService.initialize();
    if (widget.initialText != null) {
      _textController.text = widget.initialText!;
      _translate();
    }
  }

  Future<void> _translate() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _isTranslating = true;
      _error = null;
    });

    try {
      final result = await _apiService.translate(
        text: text,
        targetLanguage: _targetLanguage,
      );
      if (mounted) {
        setState(() {
          _result = result;
          _isTranslating = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Translation failed: $e';
          _isTranslating = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _speechService.dispose();
    _apiService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              // ── App Bar ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_rounded,
                          color: AppTheme.textPrimary),
                    ),
                    const Expanded(
                      child: Text(
                        'TRANSLATION',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Source Input ──
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceCard,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppTheme.surfaceOverlay),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryCyan.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    '🇬🇧 ENGLISH',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.primaryCyan,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _textController,
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 18,
                                height: 1.4,
                              ),
                              maxLines: 4,
                              decoration: const InputDecoration(
                                hintText: 'Enter text to translate...',
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ── Language Selector ──
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceCard,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: AppTheme.surfaceOverlay),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.translate_rounded,
                                  size: 18, color: AppTheme.successGreen),
                              const SizedBox(width: 8),
                              const Text(
                                'Translate to:',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              DropdownButton<String>(
                                value: _targetLanguage,
                                dropdownColor: AppTheme.surfaceElevated,
                                underline: const SizedBox(),
                                style: const TextStyle(
                                  color: AppTheme.successGreen,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                                items: AppConstants.supportedLanguages.entries
                                    .where((e) => e.key != 'en')
                                    .map((e) => DropdownMenuItem(
                                          value: e.key,
                                          child: Text(e.value),
                                        ))
                                    .toList(),
                                onChanged: (value) {
                                  setState(() => _targetLanguage = value!);
                                },
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ── Translate Button ──
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isTranslating ? null : _translate,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.successGreen,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: _isTranslating
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppTheme.surfaceDark,
                                  ),
                                )
                              : const Text(
                                  'Translate',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ── Translation Result ──
                      if (_error != null)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.emergencyRed.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            _error!,
                            style: const TextStyle(color: AppTheme.emergencyRed),
                          ),
                        ),

                      if (_result != null)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceCard,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppTheme.successGreen.withOpacity(0.3),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color:
                                          AppTheme.successGreen.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      AppConstants.supportedLanguages[
                                              _targetLanguage]
                                          ?.toUpperCase() ?? _targetLanguage.toUpperCase(),
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.successGreen,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  // Speak button
                                  IconButton(
                                    onPressed: () => _speechService.speak(
                                      _result!.translatedText,
                                    ),
                                    icon: const Icon(
                                      Icons.volume_up_rounded,
                                      color: AppTheme.successGreen,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _result!.translatedText,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
