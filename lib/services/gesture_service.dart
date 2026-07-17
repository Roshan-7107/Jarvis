/// JARVIS — Gesture Recognition Service
/// Processes camera frames and classifies sign-language gestures.
///
/// Pipeline:
///   CameraImage → HandLandmarkService → GestureClassifierService → GestureResult
///
/// Falls back to simulated gestures if models are not loaded (demo mode).

import 'dart:async';
import 'dart:math';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/logger.dart';
import '../models/gesture_model.dart';
import 'hand_landmark_service.dart';
import 'gesture_classifier_service.dart';

class GestureService extends ChangeNotifier {
  GestureResult? _currentGesture;
  bool _isProcessing = false;
  bool _isModelLoaded = false;
  bool _isInitializing = false;
  DateTime? _lastProcessedTime;
  final Random _random = Random(); // For simulation fallback

  // Real ML pipeline services
  final HandLandmarkService _landmarkService = HandLandmarkService();
  final GestureClassifierService _classifierService = GestureClassifierService();

  GestureResult? get currentGesture => _currentGesture;
  bool get isProcessing => _isProcessing;
  bool get isModelLoaded => _isModelLoaded;
  bool get isInitializing => _isInitializing;

  /// Hand landmark service (exposed for hand overlay drawing).
  HandLandmarkService get landmarkService => _landmarkService;

  /// Gesture classifier service (exposed for top-K queries).
  GestureClassifierService get classifierService => _classifierService;

  /// Initialize ML models for real gesture recognition.
  /// This loads the hand landmark model and gesture classifier model.
  /// If models fail to load, the service falls back to simulation mode.
  Future<void> initialize() async {
    if (_isModelLoaded || _isInitializing) return;

    _isInitializing = true;
    notifyListeners();

    try {
      AppLogger.info('GestureService', 'Initializing ML pipeline...');

      // Load both models in parallel
      await Future.wait([
        _landmarkService.initialize(),
        _classifierService.initialize(),
      ]);

      _isModelLoaded = _landmarkService.isLoaded && _classifierService.isLoaded;

      if (_isModelLoaded) {
        AppLogger.info('GestureService', '✅ ML pipeline ready (real mode)');
      } else {
        AppLogger.info('GestureService', '⚠️ ML models not available, using simulation mode');
      }
    } catch (e) {
      AppLogger.error('GestureService', 'ML initialization failed', e);
      _isModelLoaded = false;
    } finally {
      _isInitializing = false;
      notifyListeners();
    }
  }

  /// Process a camera frame for gesture recognition.
  ///
  /// If ML models are loaded, runs the real pipeline:
  ///   Frame → Hand Landmarks → Gesture Classification
  ///
  /// If models are not loaded, returns null (use simulateGesture for demo).
  Future<GestureResult?> processFrame(CameraImage image) async {
    // Throttle frame processing
    final now = DateTime.now();
    if (_lastProcessedTime != null &&
        now.difference(_lastProcessedTime!).inMilliseconds <
            AppConstants.frameProcessingIntervalMs) {
      return null;
    }

    if (_isProcessing) return null;

    _isProcessing = true;
    _lastProcessedTime = now;

    try {
      if (_isModelLoaded) {
        return await _processFrameReal(image);
      } else {
        // No simulation in processFrame — use simulateGesture() explicitly
        return null;
      }
    } catch (e) {
      AppLogger.error('GestureService', 'Frame processing error', e);
      return null;
    } finally {
      _isProcessing = false;
    }
  }

  /// Real ML pipeline: extract landmarks → classify gesture.
  Future<GestureResult?> _processFrameReal(CameraImage image) async {
    // Step 1: Extract hand landmarks
    final landmarkResult = await _landmarkService.processFrame(image);

    if (!landmarkResult.handDetected) {
      // No hand in frame — clear current gesture
      if (_currentGesture != null) {
        _currentGesture = null;
        notifyListeners();
      }
      return null;
    }

    // Step 2: Classify landmarks into gesture
    final gestureResult = _classifierService.classify(landmarkResult);

    if (gestureResult != null) {
      _currentGesture = gestureResult;
      AppLogger.gesture(gestureResult.label, gestureResult.confidence);
      notifyListeners();
      return gestureResult;
    }

    return null;
  }

  /// Manually trigger a gesture (for demo/testing without camera or models).
  GestureResult simulateGesture(String label, {double? confidence}) {
    final conf = confidence ?? (0.8 + _random.nextDouble() * 0.2);

    _currentGesture = GestureResult(
      label: label.toUpperCase(),
      confidence: conf,
    );

    AppLogger.gesture(label, conf);
    notifyListeners();
    return _currentGesture!;
  }

  /// Clear current gesture.
  void clearGesture() {
    _currentGesture = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _landmarkService.dispose();
    _classifierService.dispose();
    super.dispose();
  }
}
