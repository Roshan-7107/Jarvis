/// JARVIS — Emergency Service
/// Client-side rule-based emergency detection and SOS workflows.

import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/logger.dart';
import '../models/emergency_model.dart';

class EmergencyService extends ChangeNotifier {
  EmergencyAlert? _activeAlert;
  final List<EmergencyAlert> _alertHistory = [];

  EmergencyAlert? get activeAlert => _activeAlert;
  List<EmergencyAlert> get alertHistory => List.unmodifiable(_alertHistory);
  bool get hasActiveAlert => _activeAlert != null;

  /// Check gesture sequence for emergency patterns.
  /// Uses deterministic rules — NOT LLM judgment.
  EmergencyAlert? checkForEmergency(List<String> gestures) {
    final gestureSet = gestures.map((g) => g.toUpperCase()).toSet();

    // Check emergency combinations
    if (gestureSet.contains('HELP') && gestureSet.contains('FIRE')) {
      return _triggerEmergency(
        type: 'FIRE_EMERGENCY',
        severity: 'CRITICAL',
        message: 'Fire-related assistance may be required.',
        actions: [
          'Capture device location',
          'Alert trusted contacts',
          'Display fire evacuation guidance',
          'Provide fire department contact',
        ],
      );
    }

    if (gestureSet.contains('HELP') && gestureSet.contains('POLICE')) {
      return _triggerEmergency(
        type: 'SAFETY_EMERGENCY',
        severity: 'CRITICAL',
        message: 'Safety assistance may be required.',
        actions: [
          'Capture device location',
          'Alert trusted contacts silently',
          'Provide police contact',
        ],
      );
    }

    if (gestureSet.contains('HELP') && gestureSet.contains('HOSPITAL')) {
      return _triggerEmergency(
        type: 'MEDICAL_EMERGENCY',
        severity: 'HIGH',
        message: 'Medical assistance may be required.',
        actions: [
          'Capture device location',
          'Display nearby hospitals',
          'Alert trusted contacts',
        ],
      );
    }

    if (gestureSet.contains('HELP') && gestureSet.contains('PAIN')) {
      return _triggerEmergency(
        type: 'MEDICAL_EMERGENCY',
        severity: 'HIGH',
        message: 'The user is in pain and may need medical help.',
        actions: [
          'Capture device location',
          'Alert trusted contacts',
          'Provide emergency medical number',
        ],
      );
    }

    if (gestureSet.contains('EMERGENCY') || gestureSet.contains('SOS')) {
      return _triggerEmergency(
        type: 'GENERAL_EMERGENCY',
        severity: 'CRITICAL',
        message: 'Emergency assistance required.',
        actions: [
          'Capture device location',
          'Alert all trusted contacts',
          'Start emergency call workflow',
        ],
      );
    }

    return null;
  }

  EmergencyAlert _triggerEmergency({
    required String type,
    required String severity,
    required String message,
    required List<String> actions,
  }) {
    final alert = EmergencyAlert(
      type: type,
      severity: severity,
      message: message,
      suggestedActions: actions,
    );

    _activeAlert = alert;
    _alertHistory.add(alert);
    AppLogger.emergency(type);
    notifyListeners();
    return alert;
  }

  /// Dismiss the active emergency alert.
  void dismissAlert() {
    _activeAlert = null;
    notifyListeners();
  }

  /// Simulate SOS workflow (hackathon prototype).
  Future<Map<String, dynamic>> simulateSOS() async {
    AppLogger.emergency('SOS_TRIGGERED');

    // Simulate location capture
    await Future.delayed(const Duration(milliseconds: 500));
    final sosResult = {
      'location_captured': true,
      'latitude': 13.0827,
      'longitude': 80.2707,
      'contacts_notified': 2,
      'emergency_message': _activeAlert?.message ?? 'Emergency assistance needed',
      'timestamp': DateTime.now().toIso8601String(),
    };

    AppLogger.info('Emergency', 'SOS simulation complete: $sosResult');
    return sosResult;
  }
}
