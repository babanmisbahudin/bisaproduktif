import 'dart:math';
import 'package:flutter/material.dart';

class FirefliesPainter extends CustomPainter {
  final double animationValue; // 0.0 to 1.0

  FirefliesPainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    // 12 kunang-kunang berkedip dan bergerak perlahan
    for (int i = 0; i < 12; i++) {
      _drawFirefly(canvas, size, i, animationValue);
    }
  }

  void _drawFirefly(Canvas canvas, Size size, int index, double progress) {
    // Posisi statis dengan seed per firefly
    final random = Random(index);
    final baseX = random.nextDouble() * size.width;
    final baseY = random.nextDouble() * size.height * 0.8;

    // Gerakan melayang subtle: bergeser naik-turun
    final floatOffset = sin(progress * 2 * pi + index * 0.5) * 15;
    final currentX = baseX;
    final currentY = baseY + floatOffset;

    // Glow effect berkedip
    final glowIntensity = (sin(progress * 2 * pi * 3 + index * 0.3) + 1) / 2;

    // Draw glow (outer circle)
    final glowPaint = Paint()
      ..color = Color.fromARGB(
        (glowIntensity * 100).toInt(),
        255,
        200,
        50,
      )
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    canvas.drawCircle(Offset(currentX, currentY), 6, glowPaint);

    // Draw firefly body (inner circle)
    final bodyPaint = Paint()
      ..color = Color.fromARGB(
        (glowIntensity * 255).toInt(),
        255,
        220,
        80,
      );

    canvas.drawCircle(Offset(currentX, currentY), 3, bodyPaint);
  }

  @override
  bool shouldRepaint(FirefliesPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
