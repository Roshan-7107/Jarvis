/// JARVIS — Gesture Classifier Service
/// Classifies hand landmarks into gesture labels using a TFLite model.
///
/// Input: 21 normalized hand landmarks (63 features)
/// Output: GestureResult with label + confidence

import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import '../core/utils/logger.dart';
import '../core/constants/app_constants.dart';
import '../models/gesture_model.dart';
import 'hand_landmark_service.dart';

/// Service for classifying hand landmarks into gesture labels.
class GestureClassifierService extends ChangeNotifier {
  Interpreter? _interpreter;
  List<String> _labels = [];
  bool _isLoaded = false;

  // Model specs
  static const int _numFeatures = 63; // 21 landmarks × 3 coords
  static const String _modelAsset = 'assets/models/gesture_classifier.tflite';
  static const String _labelsAsset = 'assets/models/gesture_labels.json';

  bool get isLoaded => _isLoaded;
  List<String> get labels => _labels;

  /// Initialize the gesture classifier model and label map.
  Future<void> initialize() async {
    if (_isLoaded) return;

    try {
      AppLogger.info('Classifier', 'Loading gesture classifier...');

      // Load TFLite model
      _interpreter = await Interpreter.fromAsset(
        'models/gesture_classifier.tflite',
        options: InterpreterOptions()..threads = 2,
      );

      // Load label map
      final labelsJson = await rootBundle.loadString(_labelsAsset);
      _labels = List<String>.from(json.decode(labelsJson));

      _isLoaded = true;
      AppLogger.info(
        'Classifier',
        'Model loaded successfully with ${_labels.length} classes.',
      );
      notifyListeners();
    } catch (e) {
      _isLoaded = false;
      mlErrorMsg = 'Classifier Error: $e';
      AppLogger.error('Classifier', 'Failed to load model: $e');
    }
  }

  String? mlErrorMsg;
  /// Classify hand landmarks into a gesture label.
  ///
  /// Takes a [HandLandmarkResult] (already normalized), runs the TFLite
  /// classifier, and returns a [GestureResult] if confidence exceeds
  /// [AppConstants.confidenceThreshold].
  ///
  /// Returns null if:
  /// - Model not loaded
  /// - No hand detected
  /// - Confidence below threshold
  GestureResult? classify(HandLandmarkResult landmarkResult) {
    if (!_isLoaded || _interpreter == null) {
      AppLogger.error('Classifier', 'Model not loaded');
      return null;
    }

    if (!landmarkResult.handDetected) return null;

    try {
      // Normalize landmarks (wrist-relative, scale-invariant)
      final normalized = landmarkResult.normalized();

      // Flatten to 63-element feature vector
      final features = normalized.flatten();
      if (features.length != _numFeatures) {
        AppLogger.error(
          'Classifier',
          'Expected $_numFeatures features, got ${features.length}',
        );
        return null;
      }

      // Prepare input: [1, 63]
      final input = [features];

      // Prepare output: [1, num_classes]
      final output = List.generate(1, (_) => List.filled(_labels.length, 0.0));

      // Run inference
      _interpreter!.run(input, output);

      // Apply softmax (model output may be logits or already softmax)
      final probabilities = _softmax(output[0]);

      // Find top prediction
      int maxIndex = 0;
      double maxProb = probabilities[0];
      for (int i = 1; i < probabilities.length; i++) {
        if (probabilities[i] > maxProb) {
          maxProb = probabilities[i];
          maxIndex = i;
        }
      }

      // Check confidence threshold
      if (maxProb < AppConstants.confidenceThreshold) {
        return null;
      }

      final label = _labels[maxIndex];

      return GestureResult(
        label: label,
        confidence: maxProb,
        landmarks: normalized.landmarks,
      );
    } catch (e) {
      AppLogger.error('Classifier', 'Classification error', e);
      return null;
    }
  }

  /// Get top-K predictions with their probabilities.
  /// Useful for showing confidence alternatives to the user.
  List<MapEntry<String, double>> topK(
    HandLandmarkResult landmarkResult, {
    int k = 3,
  }) {
    if (!_isLoaded || _interpreter == null || !landmarkResult.handDetected) {
      return [];
    }

    try {
      final normalized = landmarkResult.normalized();
      final features = normalized.flatten();
      if (features.length != _numFeatures) return [];

      final input = [features];
      final output = List.generate(1, (_) => List.filled(_labels.length, 0.0));

      _interpreter!.run(input, output);
      final probabilities = _softmax(output[0]);

      // Create (label, probability) pairs and sort
      final entries = <MapEntry<String, double>>[];
      for (int i = 0; i < _labels.length; i++) {
        entries.add(MapEntry(_labels[i], probabilities[i]));
      }
      entries.sort((a, b) => b.value.compareTo(a.value));

      return entries.take(k).toList();
    } catch (e) {
      return [];
    }
  }

  /// Apply softmax to convert logits to probabilities.
  List<double> _softmax(List<double> logits) {
    final maxLogit = logits.reduce(max);
    final exps = logits.map((l) => exp(l - maxLogit)).toList();
    final sumExps = exps.reduce((a, b) => a + b);
    return exps.map((e) => e / sumExps).toList();
  }

  @override
  void dispose() {
    _interpreter?.close();
    super.dispose();
  }
}
