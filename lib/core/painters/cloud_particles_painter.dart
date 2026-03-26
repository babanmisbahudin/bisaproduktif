import 'dart:math';
import 'package:flutter/material.dart';

class CloudParticlesPainter extends CustomPainter {
  final double animationValue; // 0.0 to 1.0

  CloudParticlesPainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    // Draw floating cloud particles
    for (int i = 0; i < 8; i++) {
      _drawCloudParticle(canvas, size, i, animationValue);
    }
  }

  void _drawCloudParticle(
      Canvas canvas, Size size, int index, double progress) {
    final random = Random(index);

    // Starting position
    final startX = random.nextDouble() * size.width;
    final startY = random.nextDouble() * size.height * 0.7;

    // Horizontal drift
    final driftX = sin(progress * 2 * pi + index * 0.5) * 40;

    // Vertical float (gentle up and down)
    final floatY = cos(progress * 2 * pi + index * 0.3) * 20;

    final currentX = startX + driftX;
    final currentY = startY + floatY;

    // Draw cloud particle as multiple circles
    _drawCloudShape(canvas, currentX, currentY);
  }

  void _drawCloudShape(Canvas canvas, double x, double y) {
    final cloudPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;

    // Cloud made of 4 overlapping circles
    canvas.drawCircle(Offset(x, y), 18, cloudPaint);
    canvas.drawCircle(Offset(x - 15, y + 5), 14, cloudPaint);
    canvas.drawCircle(Offset(x + 15, y + 5), 14, cloudPaint);
    canvas.drawCircle(Offset(x - 8, y - 8), 10, cloudPaint);
    canvas.drawCircle(Offset(x + 8, y - 8), 10, cloudPaint);
  }

  @override
  bool shouldRepaint(CloudParticlesPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
