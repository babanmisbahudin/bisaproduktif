import 'package:flutter/material.dart';

// ── LandscapeWidget ───────────────────────────────────────────────────────────
class LandscapeWidget extends StatefulWidget {
  final double height;
  const LandscapeWidget({super.key, this.height = 280});

  @override
  State<LandscapeWidget> createState() => _LandscapeWidgetState();
}

class _LandscapeWidgetState extends State<LandscapeWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _cloudAnim;

  @override
  void initState() {
    super.initState();
    // Awan bergerak perlahan, loop terus-menerus
    _cloudAnim = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 25),
    )..repeat();
  }

  @override
  void dispose() {
    _cloudAnim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: widget.height,
      child: AnimatedBuilder(
        animation: _cloudAnim,
        builder: (_, _) => CustomPaint(
          painter: LandscapePainter(cloudOffset: _cloudAnim.value),
        ),
      ),
    );
  }
}

// ── LandscapePainter ─────────────────────────────────────────────────────────
class LandscapePainter extends CustomPainter {
  /// Nilai 0.0 → 1.0 dari AnimationController, dipakai untuk geser awan
  final double cloudOffset;

  const LandscapePainter({this.cloudOffset = 0.0});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    _drawSky(canvas, w, h);
    _drawFarHills(canvas, w, h);
    _drawMidHills(canvas, w, h);
    _drawClouds(canvas, w, h);   // ← awan bergerak
    _drawFrontHills(canvas, w, h);
    _drawPath(canvas, w, h);
    _drawTrees(canvas, w, h);
    _drawHouse(canvas, w, h);
    _drawGround(canvas, w, h);
  }

  // ── Sky: blue top → sage green bottom ──────────────────────────────
  void _drawSky(Canvas canvas, double w, double h) {
    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF8BB8C8), // muted sky blue
          Color(0xFF9EC4AB), // sage green mist
          Color(0xFFB8D4B0), // light green
        ],
        stops: [0.0, 0.55, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), paint);
  }

  // ── Far hills (lightest, most distant) ─────────────────────────────
  void _drawFarHills(Canvas canvas, double w, double h) {
    _ellipseHill(canvas, w * 0.10, h * 0.58, w * 0.48, h * 0.26,
        const Color(0xFFAFCFAA));
    _ellipseHill(canvas, w * 0.50, h * 0.52, w * 0.55, h * 0.28,
        const Color(0xFFA8C9A2));
    _ellipseHill(canvas, w * 0.88, h * 0.56, w * 0.44, h * 0.24,
        const Color(0xFFB2D2AC));
  }

  // ── Mid hills ───────────────────────────────────────────────────────
  void _drawMidHills(Canvas canvas, double w, double h) {
    _ellipseHill(canvas, -w * 0.02, h * 0.66, w * 0.55, h * 0.34,
        const Color(0xFF7DAF78));
    _ellipseHill(canvas, w * 0.48, h * 0.62, w * 0.60, h * 0.38,
        const Color(0xFF6FA86A));
    _ellipseHill(canvas, w * 1.02, h * 0.66, w * 0.50, h * 0.30,
        const Color(0xFF78B272));
  }

  // ── Front hills (darkest, closest) ──────────────────────────────────
  void _drawFrontHills(Canvas canvas, double w, double h) {
    _ellipseHill(canvas, -w * 0.05, h * 0.80, w * 0.52, h * 0.36,
        const Color(0xFF5A9E6A));
    _ellipseHill(canvas, w * 0.55, h * 0.76, w * 0.65, h * 0.40,
        const Color(0xFF52966A));
    _ellipseHill(canvas, w * 1.05, h * 0.82, w * 0.45, h * 0.32,
        const Color(0xFF4E9262));
  }

  // ── Ground strip at bottom ──────────────────────────────────────────
  void _drawGround(Canvas canvas, double w, double h) {
    final paint = Paint()..color = const Color(0xFF4A8C5C);
    final path = Path()
      ..moveTo(0, h * 0.87)
      ..quadraticBezierTo(w * 0.25, h * 0.84, w * 0.5, h * 0.87)
      ..quadraticBezierTo(w * 0.75, h * 0.90, w, h * 0.86)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(path, paint);
  }

  // ── Clouds (bergerak) ────────────────────────────────────────────────
  //
  // Tiga awan dengan kecepatan berbeda (parallax):
  //   Cloud 1 (besar, depan)  → speed 1.0  — paling cepat
  //   Cloud 2 (sedang, tengah) → speed 0.70
  //   Cloud 3 (kecil, jauh)   → speed 0.48 — paling lambat
  //
  void _drawClouds(Canvas canvas, double w, double h) {
    _cloud(canvas, _cx(0.12, 1.00, w), h * 0.10, 1.00, w);
    _cloud(canvas, _cx(0.58, 0.70, w), h * 0.07, 0.85, w);
    _cloud(canvas, _cx(0.83, 0.48, w), h * 0.14, 0.75, w);
  }

  /// Hitung posisi X awan yang bergerak ke kanan dan wraps seamlessly.
  ///
  /// [base]  = posisi awal sebagai fraksi lebar layar (0.0–1.0)
  /// [speed] = pengali kecepatan (1.0 = melewati layar dalam 1 loop penuh)
  /// [w]     = lebar canvas
  double _cx(double base, double speed, double w) {
    const bufferFrac = 0.10; // 10% buffer di kiri & kanan (off-screen)
    final loopW = w * (1.0 + bufferFrac * 2); // total loop width = 1.2 * w
    final startX = base * w + w * bufferFrac;  // geser start agar t=0 = posisi asli
    final x = (startX + cloudOffset * speed * loopW) % loopW;
    return x - w * bufferFrac; // kembalikan ke koordinat canvas
  }

  void _cloud(Canvas canvas, double x, double y, double s, double w) {
    final r = w * 0.028 * s;
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.88);
    final shadow = Paint()..color = const Color(0xFFD8E8F0).withValues(alpha: 0.5);
    // shadow pass
    for (final offset in [
      Offset(x, y + r * 0.3),
      Offset(x - r * 1.4, y + r * 0.5),
      Offset(x + r * 1.4, y + r * 0.5),
      Offset(x - r * 0.6, y - r * 0.4),
      Offset(x + r * 0.7, y - r * 0.5),
    ]) {
      canvas.drawCircle(offset, r * 0.95, shadow);
    }
    // white pass
    canvas.drawCircle(Offset(x, y), r * 1.1, paint);
    canvas.drawCircle(Offset(x - r * 1.4, y + r * 0.25), r * 0.85, paint);
    canvas.drawCircle(Offset(x + r * 1.4, y + r * 0.25), r * 0.9, paint);
    canvas.drawCircle(Offset(x - r * 0.6, y - r * 0.5), r * 0.75, paint);
    canvas.drawCircle(Offset(x + r * 0.7, y - r * 0.55), r * 0.80, paint);
  }

  // ── Dirt/grass path winding through center ──────────────────────────
  void _drawPath(Canvas canvas, double w, double h) {
    final shadow = Paint()
      ..color = const Color(0xFF3D7A48).withValues(alpha: 0.4)
      ..strokeWidth = w * 0.055
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final pathShape = Path()
      ..moveTo(w * 0.47, h * 1.02)
      ..cubicTo(
          w * 0.46, h * 0.90, w * 0.44, h * 0.82, w * 0.42, h * 0.74)
      ..cubicTo(
          w * 0.40, h * 0.66, w * 0.42, h * 0.60, w * 0.44, h * 0.56);
    canvas.drawPath(pathShape, shadow);

    final pathPaint = Paint()
      ..color = const Color(0xFFC8A96A)
      ..strokeWidth = w * 0.04
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(pathShape, pathPaint);
  }

  // ── Stylized fir/cone trees ─────────────────────────────────────────
  void _drawTrees(Canvas canvas, double w, double h) {
    _firTree(canvas, w * 0.06,  h * 0.74, w * 0.036, h);
    _firTree(canvas, w * 0.14,  h * 0.78, w * 0.028, h);
    _firTree(canvas, w * 0.20,  h * 0.82, w * 0.022, h);
    _firTree(canvas, w * 0.02,  h * 0.82, w * 0.024, h);
    _firTree(canvas, w * 0.26,  h * 0.68, w * 0.032, h);
    _firTree(canvas, w * 0.33,  h * 0.64, w * 0.025, h);
    _firTree(canvas, w * 0.76,  h * 0.70, w * 0.034, h);
    _firTree(canvas, w * 0.84,  h * 0.74, w * 0.028, h);
    _firTree(canvas, w * 0.91,  h * 0.72, w * 0.030, h);
    _firTree(canvas, w * 0.98,  h * 0.78, w * 0.026, h);
    _firTree(canvas, w * 0.68,  h * 0.62, w * 0.028, h);
    _firTree(canvas, w * 0.74,  h * 0.58, w * 0.022, h);
    _firTree(canvas, w * 0.38,  h * 0.60, w * 0.018, h);
    _firTree(canvas, w * 0.58,  h * 0.58, w * 0.020, h);
  }

  void _firTree(Canvas canvas, double x, double y, double r, double h) {
    final trunkH = r * 1.2;
    final trunk = Paint()..color = const Color(0xFF7A5230);
    canvas.drawRect(
      Rect.fromLTWH(x - r * 0.18, y, r * 0.36, trunkH),
      trunk,
    );
    final shadow = Paint()..color = const Color(0xFF2E6B38);
    _drawCone(canvas, x + r * 0.06, y - r * 0.2, r * 1.05, r * 2.8, shadow);
    final cone = Paint()..color = const Color(0xFF3A8A45);
    _drawCone(canvas, x, y - r * 0.3, r, r * 2.7, cone);
    final hi = Paint()..color = const Color(0xFF4EAA55).withValues(alpha: 0.6);
    _drawCone(canvas, x - r * 0.12, y - r * 0.3, r * 0.55, r * 1.8, hi);
    final snow = Paint()..color = Colors.white.withValues(alpha: 0.7);
    _drawCone(canvas, x, y - r * 2.4, r * 0.28, r * 0.8, snow);
  }

  void _drawCone(Canvas canvas, double x, double tip, double r, double height,
      Paint paint) {
    final base = tip + height;
    final path = Path()
      ..moveTo(x, tip)
      ..lineTo(x - r, base)
      ..quadraticBezierTo(x, base + r * 0.18, x + r, base)
      ..close();
    canvas.drawPath(path, paint);
  }

  // ── Cute small house ───────────────────────────────────────────────
  void _drawHouse(Canvas canvas, double w, double h) {
    final hx = w * 0.52;
    final hy = h * 0.65;
    final hs = w * 0.058;

    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.12)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(hx + hs * 0.3, hy + hs * 1.2),
          width: hs * 3.5,
          height: hs * 0.6),
      shadowPaint,
    );

    final wall = Paint()..color = const Color(0xFFF5ECD8);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(hx - hs, hy - hs * 0.8, hs * 2.0, hs * 1.8),
        const Radius.circular(4),
      ),
      wall,
    );

    final roof = Paint()..color = const Color(0xFFD4621A);
    final roofPath = Path()
      ..moveTo(hx - hs * 1.25, hy - hs * 0.8)
      ..lineTo(hx,              hy - hs * 2.2)
      ..lineTo(hx + hs * 1.25, hy - hs * 0.8)
      ..close();
    canvas.drawPath(roofPath, roof);

    final roofDark = Paint()..color = const Color(0xFFAF4A10);
    final roofDarkPath = Path()
      ..moveTo(hx,              hy - hs * 2.2)
      ..lineTo(hx + hs * 1.25, hy - hs * 0.8)
      ..lineTo(hx,              hy - hs * 0.8)
      ..close();
    canvas.drawPath(roofDarkPath, roofDark);

    final chimney = Paint()..color = const Color(0xFFAF4A10);
    canvas.drawRect(
      Rect.fromLTWH(hx + hs * 0.4, hy - hs * 2.05, hs * 0.28, hs * 0.65),
      chimney,
    );
    final smoke = Paint()..color = Colors.white.withValues(alpha: 0.5);
    canvas.drawCircle(Offset(hx + hs * 0.54, hy - hs * 2.2), hs * 0.10, smoke);
    canvas.drawCircle(Offset(hx + hs * 0.50, hy - hs * 2.38), hs * 0.08, smoke);

    final door = Paint()..color = const Color(0xFF7A4820);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(hx - hs * 0.22, hy + hs * 0.14, hs * 0.44, hs * 0.86),
        Radius.circular(hs * 0.22),
      ),
      door,
    );
    final knob = Paint()..color = const Color(0xFFD4A020);
    canvas.drawCircle(Offset(hx + hs * 0.10, hy + hs * 0.55), hs * 0.06, knob);

    _houseWindow(canvas, hx - hs * 0.65, hy - hs * 0.22, hs * 0.5, hs * 0.46);
    _houseWindow(canvas, hx + hs * 0.38, hy - hs * 0.22, hs * 0.5, hs * 0.46);
  }

  void _houseWindow(Canvas canvas, double x, double y, double w, double h) {
    final frame = Paint()..color = const Color(0xFFD4C48A);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, h), const Radius.circular(3)),
      frame,
    );
    final glass = Paint()..color = const Color(0xFFADD8F0).withValues(alpha: 0.8);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(x + w * 0.1, y + h * 0.1, w * 0.8, h * 0.8),
          const Radius.circular(2)),
      glass,
    );
    final div = Paint()
      ..color = const Color(0xFFD4C48A)
      ..strokeWidth = 1.5;
    canvas.drawLine(Offset(x + w * 0.5, y + h * 0.1),
        Offset(x + w * 0.5, y + h * 0.9), div);
    canvas.drawLine(Offset(x + w * 0.1, y + h * 0.5),
        Offset(x + w * 0.9, y + h * 0.5), div);
  }

  // ── Helper: draw elliptical hill ───────────────────────────────────
  void _ellipseHill(
      Canvas canvas, double cx, double cy, double w, double h, Color color) {
    final paint = Paint()..color = color;
    canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy), width: w, height: h),
        paint);
  }

  @override
  bool shouldRepaint(LandscapePainter oldDelegate) =>
      oldDelegate.cloudOffset != cloudOffset;
}
