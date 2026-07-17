/// JARVIS — Intent Card Widget
/// Displays the LLM-interpreted communication intent.

import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../models/intent_model.dart';
import 'confidence_indicator.dart';

class IntentCard extends StatelessWidget {
  final IntentResult intent;
  final VoidCallback? onSpeak;
  final VoidCallback? onTranslate;

  const IntentCard({
    super.key,
    required this.intent,
    this.onSpeak,
    this.onTranslate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: intent.isEmergency
              ? AppTheme.emergencyRed.withOpacity(0.5)
              : AppTheme.surfaceOverlay,
          width: intent.isEmergency ? 2 : 1,
        ),
        boxShadow: intent.isEmergency
            ? [
                BoxShadow(
                  color: AppTheme.emergencyRed.withOpacity(0.15),
                  blurRadius: 20,
                  spreadRadius: 0,
                ),
              ]
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: category emoji + urgency badge
            Row(
              children: [
                Text(
                  intent.categoryEmoji,
                  style: const TextStyle(fontSize: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    intent.category,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ),
                _UrgencyBadge(urgency: intent.urgency),
              ],
            ),

            const SizedBox(height: 16),

            // Main message
            Text(
              intent.message,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
                height: 1.4,
              ),
            ),

            const SizedBox(height: 16),

            // Intent + Confidence row
            Row(
              children: [
                // Intent label
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.primaryBlue.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    intent.intent,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryBlue,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const Spacer(),
                // Confidence indicator
                ConfidenceIndicator(
                  confidence: intent.confidence,
                  size: 52,
                  showLabel: false,
                ),
              ],
            ),

            // Suggested action
            if (intent.suggestedAction != null) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.lightbulb_outline,
                      size: 16,
                      color: AppTheme.warningAmber,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        intent.suggestedAction!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Action buttons
            const SizedBox(height: 16),
            Row(
              children: [
                if (onSpeak != null)
                  _ActionButton(
                    icon: Icons.volume_up_rounded,
                    label: 'Speak',
                    onTap: onSpeak!,
                    color: AppTheme.primaryCyan,
                  ),
                if (onSpeak != null && onTranslate != null)
                  const SizedBox(width: 8),
                if (onTranslate != null)
                  _ActionButton(
                    icon: Icons.translate_rounded,
                    label: 'Translate',
                    onTap: onTranslate!,
                    color: AppTheme.accentPurple,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _UrgencyBadge extends StatelessWidget {
  final String urgency;

  const _UrgencyBadge({required this.urgency});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withOpacity(0.4)),
      ),
      child: Text(
        urgency,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: _color,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Color get _color {
    switch (urgency) {
      case 'CRITICAL':
        return AppTheme.emergencyRed;
      case 'HIGH':
        return Colors.orange;
      case 'NORMAL':
        return AppTheme.primaryCyan;
      case 'LOW':
        return AppTheme.textMuted;
      default:
        return AppTheme.primaryCyan;
    }
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
