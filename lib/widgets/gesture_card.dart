/// JARVIS — Gesture Card Widget
/// Displays a recognized gesture with confidence.

import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../models/gesture_model.dart';

class GestureCard extends StatelessWidget {
  final GestureResult gesture;
  final VoidCallback? onTap;
  final bool isActive;

  const GestureCard({
    super.key,
    required this.gesture,
    this.onTap,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isActive
              ? AppTheme.primaryCyan.withOpacity(0.15)
              : AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive
                ? AppTheme.primaryCyan.withOpacity(0.5)
                : AppTheme.surfaceOverlay,
            width: 1.5,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: AppTheme.primaryCyan.withOpacity(0.2),
                    blurRadius: 12,
                    spreadRadius: 0,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Gesture icon/emoji
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  _gestureEmoji(gesture.label),
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Label and confidence
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  gesture.label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: _confidenceColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      gesture.confidencePercentage,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: _confidenceColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color get _confidenceColor {
    if (gesture.isHighConfidence) return AppTheme.successGreen;
    if (gesture.isMediumConfidence) return AppTheme.warningAmber;
    return AppTheme.emergencyRed;
  }

  String _gestureEmoji(String label) {
    switch (label.toUpperCase()) {
      case 'HELLO':
        return '👋';
      case 'THANK_YOU':
        return '🙏';
      case 'YES':
        return '✅';
      case 'NO':
        return '❌';
      case 'HELP':
        return '🆘';
      case 'HOSPITAL':
        return '🏥';
      case 'POLICE':
        return '👮';
      case 'FIRE':
        return '🔥';
      case 'WATER':
        return '💧';
      case 'FOOD':
        return '🍽️';
      case 'PAIN':
        return '😣';
      case 'EMERGENCY':
        return '🚨';
      case 'PLEASE':
        return '🙏';
      case 'SORRY':
        return '😔';
      case 'GOODBYE':
        return '👋';
      default:
        return '🤟';
    }
  }
}

/// A small gesture chip for display in sequences.
class GestureChip extends StatelessWidget {
  final String label;
  final bool isEmergency;

  const GestureChip({
    super.key,
    required this.label,
    this.isEmergency = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isEmergency
            ? AppTheme.emergencyRed.withOpacity(0.2)
            : AppTheme.primaryCyan.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isEmergency
              ? AppTheme.emergencyRed.withOpacity(0.5)
              : AppTheme.primaryCyan.withOpacity(0.3),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: isEmergency ? AppTheme.emergencyRed : AppTheme.primaryCyan,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
