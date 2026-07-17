/// JARVIS — Confidence Indicator Widget
/// Animated circular gauge showing AI confidence level.

import 'dart:math';
import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class ConfidenceIndicator extends StatelessWidget {
  final double confidence;
  final double size;
  final bool showLabel;

  const ConfidenceIndicator({
    super.key,
    required this.confidence,
    this.size = 80,
    this.showLabel = true,
  });

  Color get _color {
    if (confidence >= 0.8) return AppTheme.successGreen;
    if (confidence >= 0.6) return AppTheme.warningAmber;
    return AppTheme.emergencyRed;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background arc
          CustomPaint(
            size: Size(size, size),
            painter: _ConfidenceArcPainter(
              progress: confidence,
              color: _color,
              backgroundColor: AppTheme.surfaceOverlay,
            ),
          ),
          // Center text
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${(confidence * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: size * 0.22,
                  fontWeight: FontWeight.w800,
                  color: _color,
                ),
              ),
              if (showLabel)
                Text(
                  _label,
                  style: TextStyle(
                    fontSize: size * 0.12,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textMuted,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String get _label {
    if (confidence >= 0.8) return 'HIGH';
    if (confidence >= 0.6) return 'MED';
    return 'LOW';
  }
}

class _ConfidenceArcPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color backgroundColor;

  _ConfidenceArcPainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;
    const strokeWidth = 6.0;

    // Background arc
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi,
      false,
      bgPaint,
    );

    // Progress arc
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ConfidenceArcPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}
