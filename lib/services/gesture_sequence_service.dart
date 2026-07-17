/// JARVIS — Gesture Sequence Service
/// Accumulates individual gestures into meaningful sequences.

import 'dart:async';
import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/logger.dart';
import '../models/gesture_model.dart';

class GestureSequenceService extends ChangeNotifier {
  final List<GestureResult> _sequence = [];
  Timer? _timeoutTimer;
  bool _isSequenceComplete = false;
  String? _lastGestureLabel;

  List<GestureResult> get sequence => List.unmodifiable(_sequence);
  List<String> get gestureLabels => _sequence.map((g) => g.label).toList();
  List<double> get confidenceScores =>
      _sequence.map((g) => g.confidence).toList();
  bool get isSequenceComplete => _isSequenceComplete;
  bool get isEmpty => _sequence.isEmpty;
  int get length => _sequence.length;

  /// Add a gesture to the current sequence.
  void addGesture(GestureResult gesture) {
    // Skip if below confidence threshold
    if (gesture.confidence < AppConstants.confidenceThreshold) return;

    // Skip consecutive duplicates
    if (_lastGestureLabel == gesture.label) return;

    // Enforce max sequence length
    if (_sequence.length >= AppConstants.maxSequenceLength) return;

    _sequence.add(gesture);
    _lastGestureLabel = gesture.label;
    _isSequenceComplete = false;

    AppLogger.info('Sequence', 'Added: ${gesture.label} → [${gestureLabels.join(" + ")}]');

    // Reset the timeout timer
    _resetTimeout();
    notifyListeners();
  }

  /// Reset the idle timeout timer.
  void _resetTimeout() {
    _timeoutTimer?.cancel();
    _timeoutTimer = Timer(
      Duration(milliseconds: AppConstants.gestureSequenceTimeoutMs),
      _onSequenceTimeout,
    );
  }

  /// Called when the user stops signing (idle timeout).
  void _onSequenceTimeout() {
    if (_sequence.isNotEmpty) {
      _isSequenceComplete = true;
      AppLogger.info(
        'Sequence',
        'Complete: [${gestureLabels.join(" + ")}]',
      );
      notifyListeners();
    }
  }

  /// Manually complete the current sequence.
  void completeSequence() {
    _timeoutTimer?.cancel();
    if (_sequence.isNotEmpty) {
      _isSequenceComplete = true;
      notifyListeners();
    }
  }

  /// Clear the sequence and reset.
  void reset() {
    _timeoutTimer?.cancel();
    _sequence.clear();
    _isSequenceComplete = false;
    _lastGestureLabel = null;
    AppLogger.info('Sequence', 'Reset');
    notifyListeners();
  }

  /// Check if the current sequence contains emergency gestures.
  bool get containsEmergency {
    final labels = gestureLabels.toSet();
    for (final combo in AppConstants.emergencyCombinations) {
      if (combo.toSet().intersection(labels).length == combo.length) {
        return true;
      }
    }
    return false;
  }

  /// Get a display-friendly string of the current sequence.
  String get displayString {
    if (_sequence.isEmpty) return 'No gestures detected';
    return gestureLabels.join(' + ');
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    super.dispose();
  }
}
