import 'dart:math';
import 'package:flutter/material.dart';

class StarsAppearingPainter extends CustomPainter {
  final double animationValue; // 0.0 to 1.0

  StarsAppearingPainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    // Draw stars muncul secara bertahap (fade in)
    for (int i = 0; i < 12; i++) {
      _drawStar(canvas, size, i, animationValue);
    }
  }

  void _drawStar(Canvas canvas, Size size, int index, double progress) {
    final random = Random(index);

    // Position
    final x = random.nextDouble() * size.width;
    final y = random.nextDouble() * size.height * 0.8;

    // Stagger appearance: star i muncul at progress = i/12
    final starStartTime = index / 12.0;
    double starAlpha = 0.0;

    if (progress >= starStartTime) {
      starAlpha = ((progress - starStartTime) / (1 - starStartTime)).clamp(0, 1);
    }

    // Twinkle effect: bintang berkedip
    final twinkleIntensity = (sin(progress * 2 * pi * 2) + 1) / 2;
    final finalAlpha = starAlpha * twinkleIntensity;

    // Draw 5-pointed star
    _drawFivePointedStar(canvas, x, y, finalAlpha);
  }

  void _drawFivePointedStar(Canvas canvas, double x, double y, double alpha) {
    final starPaint = Paint()
      ..color = Colors.white.withValues(alpha: alpha.clamp(0, 1))
      ..style = PaintingStyle.fill;

    const outerRadius = 8.0;
    const innerRadius = 3.2;

    final path = Path();
    for (int i = 0; i < 10; i++) {
      final angle = (i * pi / 5) - (pi / 2);
      final radius = i.isEven ? outerRadius : innerRadius;
      final px = x + radius * cos(angle);
      final py = y + radius * sin(angle);

      if (i == 0) {
        path.moveTo(px, py);
      } else {
        path.lineTo(px, py);
      }
    }
    path.close();

    canvas.drawPath(path, starPaint);
  }

  @override
  bool shouldRepaint(StarsAppearingPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
