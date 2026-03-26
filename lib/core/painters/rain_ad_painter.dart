import 'dart:math';
import 'package:flutter/material.dart';

class RainAdPainter extends CustomPainter {
  final double animationValue; // 0.0 to 1.0

  RainAdPainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    // Draw rain drops + fog overlay
    _drawRainDrops(canvas, size);
    _drawFogOverlay(canvas, size);
  }

  void _drawRainDrops(Canvas canvas, Size size) {
    final rainPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.6)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    // 20 tetes hujan jatuh dari atas
    for (int i = 0; i < 20; i++) {
      final random = Random(i);
      final startX = random.nextDouble() * size.width;
      final yOffset = random.nextDouble() * size.height;

      // Tetes jatuh dari atas ke bawah
      final currentY = (animationValue - yOffset / size.height) * size.height;

      // Only draw jika visible
      if (currentY >= -10 && currentY <= size.height + 10) {
        // Sudut kemiringan angin (45 derajat)
        final endX = startX + 8;
        final endY = currentY + 20;

        canvas.drawLine(
          Offset(startX, currentY),
          Offset(endX, endY),
          rainPaint,
        );
      }
    }
  }

  void _drawFogOverlay(Canvas canvas, Size size) {
    // Fog overlay yang terlihat seperti kabut
    final fogPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;

    // Multiple layers of fog
    for (int i = 0; i < 3; i++) {
      final offsetX = (animationValue * 20) % size.width;
      final yPos = size.height * 0.3 + i * 40;

      // Draw wavy fog shapes
      final path = Path();
      path.moveTo(-size.width + offsetX, yPos);

      for (double x = -size.width + offsetX; x < size.width * 2; x += 30) {
        final waveY = yPos + sin((x + animationValue * 60) / 40) * 10;
        path.lineTo(x, waveY);
      }

      path.lineTo(size.width * 2, yPos + 50);
      path.lineTo(-size.width, yPos + 50);
      path.close();

      canvas.drawPath(path, fogPaint);
    }
  }

  @override
  bool shouldRepaint(RainAdPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
