import 'package:flutter/material.dart';

class BirdsPainter extends CustomPainter {
  final double animationValue; // 0.0 to 1.0

  BirdsPainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF333333)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.fill;

    // 3 burung dengan trajectory berbeda
    _drawBird(canvas, size, paint, 1, animationValue);
    _drawBird(canvas, size, paint, 2, animationValue);
    _drawBird(canvas, size, paint, 3, animationValue);
  }

  void _drawBird(Canvas canvas, Size size, Paint paint, int birdIndex,
      double progress) {
    // Setiap burung mulai dari posisi berbeda dan terbang dengan trajectory berbeda
    final startX = size.width * (0.15 + birdIndex * 0.25);
    final startY = size.height * (0.2 + birdIndex * 0.15);

    // Trajectory: terbang ke atas-kanan dengan kurva
    final currentX = startX + (size.width * 0.4 * progress);
    final currentY = startY - (size.height * 0.3 * progress);

    // Draw sederhana: burung sebagai 2 oval + wings
    _drawSimpleBird(canvas, currentX, currentY, paint, birdIndex);
  }

  void _drawSimpleBird(
      Canvas canvas, double x, double y, Paint paint, int birdIndex) {
    // Body (oval)
    canvas.drawOval(
      Rect.fromCenter(center: Offset(x, y), width: 12, height: 8),
      paint,
    );

    // Head (smaller oval)
    canvas.drawOval(
      Rect.fromCenter(center: Offset(x + 8, y - 2), width: 6, height: 5),
      paint,
    );

    // Wings (2 curved lines)
    final wingPaint = Paint()
      ..color = const Color(0xFF333333)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    // Left wing
    canvas.drawArc(
      Rect.fromCenter(center: Offset(x - 2, y), width: 10, height: 6),
      0,
      3.14159,
      false,
      wingPaint,
    );

    // Right wing
    canvas.drawArc(
      Rect.fromCenter(center: Offset(x + 6, y), width: 10, height: 6),
      0,
      3.14159,
      false,
      wingPaint,
    );
  }

  @override
  bool shouldRepaint(BirdsPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
