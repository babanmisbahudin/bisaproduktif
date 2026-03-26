import 'dart:math';
import 'package:flutter/material.dart';

class SunraysPainter extends CustomPainter {
  final double animationValue; // 0.0 to 1.0

  SunraysPainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height * 0.3;

    // Draw rotating sun rays
    _drawSunrays(canvas, centerX, centerY, size);

    // Draw sun circle
    _drawSunCircle(canvas, centerX, centerY);

    // Draw shimmer effect
    _drawShimmer(canvas, size);
  }

  void _drawSunrays(Canvas canvas, double centerX, double centerY, Size size) {
    final rayPaint = Paint()
      ..color = Colors.yellow.withValues(alpha: 0.6)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    // 8 rays berputar
    for (int i = 0; i < 8; i++) {
      final angle = (i * pi / 4) + (animationValue * 2 * pi);
      final rayLength = 60.0;

      final startX = centerX + cos(angle) * 25;
      final startY = centerY + sin(angle) * 25;

      final endX = centerX + cos(angle) * (25 + rayLength);
      final endY = centerY + sin(angle) * (25 + rayLength);

      canvas.drawLine(Offset(startX, startY), Offset(endX, endY), rayPaint);
    }
  }

  void _drawSunCircle(Canvas canvas, double centerX, double centerY) {
    final sunPaint = Paint()
      ..color = Colors.yellow.withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;

    final glowPaint = Paint()
      ..color = Colors.yellow.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

    // Glow
    canvas.drawCircle(Offset(centerX, centerY), 28, glowPaint);

    // Sun circle
    canvas.drawCircle(Offset(centerX, centerY), 20, sunPaint);
  }

  void _drawShimmer(Canvas canvas, Size size) {
    // Shimmer lines yang bergerak
    final shimmerPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..strokeWidth = 2;

    // Horizontal shimmer lines
    for (int i = 0; i < 3; i++) {
      final offset = (animationValue * size.height) % (size.height + 40);
      final y = size.height * 0.4 + i * 60 - offset;

      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        shimmerPaint,
      );
    }
  }

  @override
  bool shouldRepaint(SunraysPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
