/// JARVIS — Avatar Widget
/// Displays sign-language sequence for reverse communication.

import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class AvatarWidget extends StatelessWidget {
  final List<String> signSequence;
  final List<String> descriptions;
  final int? activeIndex;

  const AvatarWidget({
    super.key,
    required this.signSequence,
    this.descriptions = const [],
    this.activeIndex,
  });

  @override
  Widget build(BuildContext context) {
    if (signSequence.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.sign_language_rounded,
              size: 64,
              color: AppTheme.textMuted.withOpacity(0.4),
            ),
            const SizedBox(height: 16),
            const Text(
              'Enter text to see sign sequence',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textMuted,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: signSequence.length,
      itemBuilder: (context, index) {
        final isActive = activeIndex == index;
        return _SignCard(
          index: index,
          label: signSequence[index],
          description: index < descriptions.length ? descriptions[index] : null,
          isActive: isActive,
          isLast: index == signSequence.length - 1,
        );
      },
    );
  }
}

class _SignCard extends StatelessWidget {
  final int index;
  final String label;
  final String? description;
  final bool isActive;
  final bool isLast;

  const _SignCard({
    required this.index,
    required this.label,
    this.description,
    this.isActive = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isActive
                ? AppTheme.primaryCyan.withOpacity(0.1)
                : AppTheme.surfaceCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isActive
                  ? AppTheme.primaryCyan.withOpacity(0.5)
                  : AppTheme.surfaceOverlay,
              width: isActive ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              // Step number
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: isActive
                      ? AppTheme.primaryGradient
                      : null,
                  color: isActive ? null : AppTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: isActive
                          ? AppTheme.surfaceDark
                          : AppTheme.textMuted,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Sign icon
              Text(
                _signEmoji(label),
                style: const TextStyle(fontSize: 28),
              ),
              const SizedBox(width: 12),
              // Label and description
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    if (description != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        description!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        // Arrow connector
        if (!isLast)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Icon(
              Icons.arrow_downward_rounded,
              size: 20,
              color: AppTheme.textMuted.withOpacity(0.4),
            ),
          ),
      ],
    );
  }

  String _signEmoji(String label) {
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
      case 'PLEASE':
        return '🙏';
      case 'WANT':
        return '👉';
      case 'NEED':
        return '💪';
      case 'I':
        return '👤';
      case 'YOU':
        return '👆';
      default:
        return '🤟';
    }
  }
}
