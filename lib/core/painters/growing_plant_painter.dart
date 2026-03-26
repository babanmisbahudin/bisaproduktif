import 'dart:math';
import 'package:flutter/material.dart';

class GrowingPlantPainter extends CustomPainter {
  final double growthProgress; // 0.0 to 1.0 (based on name.length / 10)

  GrowingPlantPainter({required this.growthProgress});

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final baseY = size.height * 0.7;

    // Draw soil
    _drawSoil(canvas, centerX, baseY, size);

    // Draw plant (seed → sprout → leaves → flower)
    if (growthProgress > 0) {
      _drawPlant(canvas, centerX, baseY, growthProgress);
    }
  }

  void _drawSoil(Canvas canvas, double centerX, double baseY, Size size) {
    final soilPaint = Paint()
      ..color = const Color(0xFF8B6F47)
      ..style = PaintingStyle.fill;

    // Soil mound
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(centerX, baseY + 20),
          width: 120,
          height: 40,
        ),
        const Radius.circular(10),
      ),
      soilPaint,
    );

    // Soil texture (small dots)
    final texturePaint = Paint()
      ..color = const Color(0xFF6B5436)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 8; i++) {
      final random = Random(i);
      final x = centerX - 50 + random.nextDouble() * 100;
      final y = baseY + 10 + random.nextDouble() * 20;
      canvas.drawCircle(Offset(x, y), 2, texturePaint);
    }
  }

  void _drawPlant(Canvas canvas, double centerX, double baseY, double progress) {
    final stemPaint = Paint()
      ..color = const Color(0xFF4A7C59)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    // Stem grows upward
    final stemHeight = 60 * progress;
    final stemTopY = baseY - stemHeight;

    canvas.drawLine(
      Offset(centerX, baseY),
      Offset(centerX, stemTopY),
      stemPaint,
    );

    // Stage 1 (0.0-0.3): Tiny sprout at base
    if (progress <= 0.3) {
      _drawSprout(canvas, centerX, baseY, progress / 0.3);
    }

    // Stage 2 (0.3-0.6): Growing leaves on stem
    if (progress > 0.3) {
      final leafProgress = ((progress - 0.3) / 0.3).clamp(0.0, 1.0);
      _drawLeaves(canvas, centerX, stemTopY, leafProgress);
    }

    // Stage 3 (0.6-1.0): Flower bud at top
    if (progress > 0.6) {
      final flowerProgress = ((progress - 0.6) / 0.4).clamp(0.0, 1.0);
      _drawFlower(canvas, centerX, stemTopY - 10.0, flowerProgress);
    }
  }

  void _drawSprout(Canvas canvas, double centerX, double baseY, double progress) {
    final sproutPaint = Paint()
      ..color = const Color(0xFF4A7C59)
      ..style = PaintingStyle.fill;

    // Tiny curled sprout
    const sproutRadius = 3.0;

    canvas.drawCircle(
      Offset(centerX - sproutRadius, baseY - (sproutRadius * progress)),
      sproutRadius * progress,
      sproutPaint,
    );
  }

  void _drawLeaves(
      Canvas canvas, double centerX, double stemTopY, double progress) {
    final leafPaint = Paint()
      ..color = const Color(0xFF5A9C6F)
      ..style = PaintingStyle.fill;

    // Left leaves
    for (int i = 0; i < 2; i++) {
      final leafY = stemTopY + (i * 15);
      if (leafY <= stemTopY) continue;

      final leafProgress = (progress - (i * 0.2)).clamp(0.0, 1.0);
      if (leafProgress <= 0) continue;

      final leafLength = 25 * leafProgress;
      _drawOvalLeaf(canvas, centerX - leafLength, leafY, leafLength, -20.0,
          leafPaint);
    }

    // Right leaves
    for (int i = 0; i < 2; i++) {
      final leafY = stemTopY + (i * 15);
      if (leafY <= stemTopY) continue;

      final leafProgress = (progress - (i * 0.2)).clamp(0.0, 1.0);
      if (leafProgress <= 0) continue;

      final leafLength = 25 * leafProgress;
      _drawOvalLeaf(canvas, centerX + leafLength, leafY, leafLength, 20.0,
          leafPaint);
    }
  }

  void _drawOvalLeaf(Canvas canvas, double x, double y, double length,
      double angle, Paint paint) {
    canvas.save();
    canvas.translate(x, y);
    canvas.rotate((angle * pi / 180).toDouble());

    final leafPath = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(length * 0.5, -6.0, length, 0)
      ..quadraticBezierTo(length * 0.5, 6.0, 0, 0)
      ..close();

    canvas.drawPath(leafPath, paint);
    canvas.restore();
  }

  void _drawFlower(Canvas canvas, double centerX, double flowerY, double progress) {
    const petalRadius = 6.0;
    const centerRadius = 4.0;

    // Petals (5 petals)
    final petalPaint = Paint()
      ..color = Color.lerp(
        const Color(0xFFFFC0CB),
        const Color(0xFFFF69B4),
        progress,
      )!
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 5; i++) {
      final angle = (i * 72 * pi / 180) - (pi / 2);
      final petalX = centerX + cos(angle).toDouble() * 12 * progress;
      final petalY = flowerY + sin(angle).toDouble() * 12 * progress;

      canvas.drawCircle(Offset(petalX, petalY), petalRadius * progress, petalPaint);
    }

    // Center of flower
    final centerPaint = Paint()
      ..color = const Color(0xFFFFD700)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(centerX, flowerY),
      centerRadius * progress,
      centerPaint,
    );
  }

  @override
  bool shouldRepaint(GrowingPlantPainter oldDelegate) {
    return oldDelegate.growthProgress != growthProgress;
  }
}
