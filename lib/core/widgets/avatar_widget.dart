import 'package:flutter/material.dart';
import 'dart:math' as math;

// ── AvatarWidget ──────────────────────────────────────────────────────────────
class AvatarWidget extends StatefulWidget {
  final String gender;
  final double size;

  const AvatarWidget({
    super.key,
    required this.gender,
    this.size = 150,
  });

  @override
  State<AvatarWidget> createState() => _AvatarWidgetState();
}

class _AvatarWidgetState extends State<AvatarWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _floatAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);
    _floatAnim = Tween<double>(begin: -5, end: 5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _floatAnim,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, _floatAnim.value),
        child: child,
      ),
      child: SizedBox(
        width: widget.size,
        height: widget.size * 1.15,
        child: CustomPaint(
          painter: widget.gender == 'female'
              ? _FemaleAvatarPainter()
              : _MaleAvatarPainter(),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// FEMALE AVATAR  (dark hair, big eyes, soft expression, cream sweater)
// ═════════════════════════════════════════════════════════════════════════════
class _FemaleAvatarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;

    // ── Drop shadow ─────────────────────────────────────────────────
    final shadowP = Paint()
      ..color = Colors.black.withValues(alpha: 0.18)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, h * 0.97), width: w * 0.6, height: h * 0.06),
      shadowP,
    );

    // ── Sweater / body  ─────────────────────────────────────────────
    // Sweater: warm cream (#E8D5B0)
    final sweaterGrad = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFEDD9A8), Color(0xFFD4BC85)],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    final bodyPath = Path()
      ..moveTo(cx - w * 0.38, h)
      ..lineTo(cx - w * 0.38, h * 0.76)
      ..quadraticBezierTo(cx - w * 0.34, h * 0.68, cx - w * 0.26, h * 0.63)
      ..quadraticBezierTo(cx - w * 0.14, h * 0.58, cx,             h * 0.57)
      ..quadraticBezierTo(cx + w * 0.14, h * 0.58, cx + w * 0.26, h * 0.63)
      ..quadraticBezierTo(cx + w * 0.34, h * 0.68, cx + w * 0.38, h * 0.76)
      ..lineTo(cx + w * 0.38, h)
      ..close();
    canvas.drawPath(bodyPath, sweaterGrad);

    // Sweater collar (V-neck)
    final collar = Paint()..color = const Color(0xFFC8A870);
    final collarPath = Path()
      ..moveTo(cx - w * 0.10, h * 0.57)
      ..lineTo(cx,             h * 0.63)
      ..lineTo(cx + w * 0.10, h * 0.57);
    canvas.drawPath(collarPath, collar..style = PaintingStyle.stroke ..strokeWidth = 1.5);

    // Sweater texture lines
    final texturePaint = Paint()
      ..color = const Color(0xFFC8A870).withValues(alpha: 0.4)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;
    for (int i = 0; i < 5; i++) {
      final y = h * (0.68 + i * 0.07);
      canvas.drawLine(
        Offset(cx - w * 0.30, y),
        Offset(cx + w * 0.30, y),
        texturePaint,
      );
    }

    // ── Neck ────────────────────────────────────────────────────────
    final skinPaint = Paint()..color = const Color(0xFFF2C8A0);
    final neckPath = Path()
      ..moveTo(cx - w * 0.09, h * 0.58)
      ..quadraticBezierTo(cx, h * 0.55, cx + w * 0.09, h * 0.58)
      ..lineTo(cx + w * 0.08, h * 0.46)
      ..quadraticBezierTo(cx, h * 0.44, cx - w * 0.08, h * 0.46)
      ..close();
    canvas.drawPath(neckPath, skinPaint);

    // ── Hair back layer ──────────────────────────────────────────────
    final hairDark = Paint()..color = const Color(0xFF1A1210);
    // Long side hair
    canvas.drawOval(Rect.fromCenter(
      center: Offset(cx - w * 0.30, h * 0.36),
      width: w * 0.22, height: h * 0.40,
    ), hairDark);
    canvas.drawOval(Rect.fromCenter(
      center: Offset(cx + w * 0.30, h * 0.36),
      width: w * 0.22, height: h * 0.40,
    ), hairDark);
    // Hair back blob
    canvas.drawOval(Rect.fromCenter(
      center: Offset(cx, h * 0.26),
      width: w * 0.70, height: h * 0.56,
    ), hairDark);

    // ── Face ────────────────────────────────────────────────────────
    final faceGrad = Paint()
      ..shader = const RadialGradient(
        center: Alignment(0, -0.3),
        radius: 0.7,
        colors: [Color(0xFFFBDEC0), Color(0xFFF2C8A0)],
      ).createShader(Rect.fromCenter(
        center: Offset(cx, h * 0.30),
        width: w * 0.62, height: h * 0.52,
      ));
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, h * 0.30),
        width: w * 0.60, height: h * 0.52,
      ),
      faceGrad,
    );

    // Face shading (subtle left shadow)
    final faceShade = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          const Color(0xFFF2C8A0).withValues(alpha: 0.3),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, h * 0.30), width: w * 0.60, height: h * 0.52),
      faceShade,
    );

    // ── Hair front + fringe ──────────────────────────────────────────
    final hairFront = Paint()..color = const Color(0xFF1E1612);
    // Main fringe arc
    final fringePath = Path()
      ..moveTo(cx - w * 0.30, h * 0.18)
      ..quadraticBezierTo(cx - w * 0.16, h * 0.06, cx, h * 0.09)
      ..quadraticBezierTo(cx + w * 0.16, h * 0.06, cx + w * 0.30, h * 0.18)
      ..quadraticBezierTo(cx + w * 0.32, h * 0.24, cx + w * 0.28, h * 0.28)
      ..lineTo(cx - w * 0.28, h * 0.28)
      ..quadraticBezierTo(cx - w * 0.32, h * 0.24, cx - w * 0.30, h * 0.18)
      ..close();
    canvas.drawPath(fringePath, hairFront);

    // Side swept fringe strand (left)
    final strandL = Path()
      ..moveTo(cx - w * 0.22, h * 0.20)
      ..quadraticBezierTo(cx - w * 0.14, h * 0.15, cx - w * 0.08, h * 0.22)
      ..quadraticBezierTo(cx - w * 0.12, h * 0.28, cx - w * 0.20, h * 0.28)
      ..close();
    canvas.drawPath(strandL, hairFront);

    // Hair highlight
    final hairHi = Paint()..color = const Color(0xFF3D2E24).withValues(alpha: 0.7);
    final hiPath = Path()
      ..moveTo(cx - w * 0.04, h * 0.08)
      ..quadraticBezierTo(cx + w * 0.10, h * 0.07, cx + w * 0.22, h * 0.14)
      ..quadraticBezierTo(cx + w * 0.18, h * 0.18, cx + w * 0.06, h * 0.16)
      ..quadraticBezierTo(cx - w * 0.02, h * 0.12, cx - w * 0.04, h * 0.08)
      ..close();
    canvas.drawPath(hiPath, hairHi);

    // ── Ears ────────────────────────────────────────────────────────
    canvas.drawOval(
        Rect.fromCenter(center: Offset(cx - w * 0.30, h * 0.31), width: w * 0.09, height: h * 0.10),
        skinPaint);
    canvas.drawOval(
        Rect.fromCenter(center: Offset(cx + w * 0.30, h * 0.31), width: w * 0.09, height: h * 0.10),
        skinPaint);

    // ── Blush ────────────────────────────────────────────────────────
    final blush = Paint()..color = const Color(0xFFFF9E9E).withValues(alpha: 0.38);
    canvas.drawOval(
        Rect.fromCenter(center: Offset(cx - w * 0.17, h * 0.36), width: w * 0.15, height: h * 0.07),
        blush);
    canvas.drawOval(
        Rect.fromCenter(center: Offset(cx + w * 0.17, h * 0.36), width: w * 0.15, height: h * 0.07),
        blush);

    // ── Eyebrows ─────────────────────────────────────────────────────
    final browPaint = Paint()
      ..color = const Color(0xFF2A1E18)
      ..strokeWidth = w * 0.024
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    // Left brow (slight arch)
    final browL = Path()
      ..moveTo(cx - w * 0.23, h * 0.245)
      ..quadraticBezierTo(cx - w * 0.14, h * 0.220, cx - w * 0.07, h * 0.242);
    canvas.drawPath(browL, browPaint);
    // Right brow
    final browR = Path()
      ..moveTo(cx + w * 0.07, h * 0.242)
      ..quadraticBezierTo(cx + w * 0.14, h * 0.220, cx + w * 0.23, h * 0.245);
    canvas.drawPath(browR, browPaint);

    // ── Eyes ─────────────────────────────────────────────────────────
    _drawEye(canvas, cx - w * 0.145, h * 0.300, w * 0.105, h * 0.075, w);
    _drawEye(canvas, cx + w * 0.145, h * 0.300, w * 0.105, h * 0.075, w);

    // ── Nose (subtle) ────────────────────────────────────────────────
    final nosePaint = Paint()
      ..color = const Color(0xFFE0A880).withValues(alpha: 0.8)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final nosePath = Path()
      ..moveTo(cx - w * 0.04, h * 0.375)
      ..quadraticBezierTo(cx, h * 0.390, cx + w * 0.04, h * 0.375);
    canvas.drawPath(nosePath, nosePaint);

    // ── Smile ────────────────────────────────────────────────────────
    final smilePaint = Paint()
      ..color = const Color(0xFFCC6844)
      ..strokeWidth = w * 0.022
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final smilePath = Path()
      ..moveTo(cx - w * 0.10, h * 0.42)
      ..quadraticBezierTo(cx, h * 0.465, cx + w * 0.10, h * 0.42);
    canvas.drawPath(smilePath, smilePaint);
    // Smile corners
    final cornerPaint = Paint()
      ..color = const Color(0xFFCC6844).withValues(alpha: 0.6)
      ..strokeWidth = w * 0.015
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(cx - w * 0.10, h * 0.42),
        Offset(cx - w * 0.12, h * 0.44), cornerPaint);
    canvas.drawLine(Offset(cx + w * 0.10, h * 0.42),
        Offset(cx + w * 0.12, h * 0.44), cornerPaint);
  }

  void _drawEye(Canvas canvas, double cx, double cy, double ew, double eh, double w) {
    // White
    final white = Paint()..color = const Color(0xFFFAF6F0);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy), width: ew, height: eh), white);
    // Iris
    final iris = Paint()
      ..shader = RadialGradient(
        colors: [const Color(0xFF7B4A30), const Color(0xFF3A2018)],
        center: Alignment(-0.2, -0.3),
      ).createShader(Rect.fromCenter(center: Offset(cx, cy), width: ew * 0.7, height: eh * 1.3));
    canvas.drawOval(
        Rect.fromCenter(center: Offset(cx, cy), width: ew * 0.62, height: eh * 1.25), iris);
    // Pupil
    final pupil = Paint()..color = const Color(0xFF180C08);
    canvas.drawOval(
        Rect.fromCenter(center: Offset(cx, cy + eh * 0.06), width: ew * 0.30, height: eh * 0.80),
        pupil);
    // Shine (large)
    final shine = Paint()..color = Colors.white.withValues(alpha: 0.95);
    canvas.drawOval(
        Rect.fromCenter(center: Offset(cx - ew * 0.14, cy - eh * 0.20), width: ew * 0.20, height: eh * 0.44),
        shine);
    // Shine (small)
    canvas.drawCircle(Offset(cx + ew * 0.12, cy + eh * 0.05), ew * 0.08, shine);
    // Lash top
    final lash = Paint()
      ..color = const Color(0xFF1A1210)
      ..strokeWidth = w * 0.018
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final lashPath = Path()
      ..moveTo(cx - ew * 0.50, cy)
      ..quadraticBezierTo(cx, cy - eh * 0.82, cx + ew * 0.50, cy);
    canvas.drawPath(lashPath, lash);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ═════════════════════════════════════════════════════════════════════════════
// MALE AVATAR  (shorter hair, slightly broader face, blue jacket)
// ═════════════════════════════════════════════════════════════════════════════
class _MaleAvatarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;

    // ── Drop shadow ─────────────────────────────────────────────────
    final shadowP = Paint()
      ..color = Colors.black.withValues(alpha: 0.18)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, h * 0.97), width: w * 0.62, height: h * 0.06),
      shadowP,
    );

    // ── Jacket / body ────────────────────────────────────────────────
    final jacketGrad = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF4A6E9A), Color(0xFF2E4E74)],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    final bodyPath = Path()
      ..moveTo(cx - w * 0.40, h)
      ..lineTo(cx - w * 0.40, h * 0.74)
      ..quadraticBezierTo(cx - w * 0.36, h * 0.66, cx - w * 0.28, h * 0.61)
      ..quadraticBezierTo(cx - w * 0.16, h * 0.56, cx,             h * 0.55)
      ..quadraticBezierTo(cx + w * 0.16, h * 0.56, cx + w * 0.28, h * 0.61)
      ..quadraticBezierTo(cx + w * 0.36, h * 0.66, cx + w * 0.40, h * 0.74)
      ..lineTo(cx + w * 0.40, h)
      ..close();
    canvas.drawPath(bodyPath, jacketGrad);

    // Jacket collar / shirt inside
    final shirt = Paint()..color = const Color(0xFFF0F0F0);
    final shirtPath = Path()
      ..moveTo(cx - w * 0.08, h * 0.55)
      ..lineTo(cx,             h * 0.62)
      ..lineTo(cx + w * 0.08, h * 0.55)
      ..lineTo(cx + w * 0.06, h * 0.55)
      ..lineTo(cx,             h * 0.60)
      ..lineTo(cx - w * 0.06, h * 0.55)
      ..close();
    canvas.drawPath(shirtPath, shirt);

    // Jacket zipper line
    final zipper = Paint()
      ..color = const Color(0xFF2A3D58).withValues(alpha: 0.5)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
        Offset(cx, h * 0.60), Offset(cx, h * 0.95), zipper);

    // ── Neck ────────────────────────────────────────────────────────
    final skinPaint = Paint()..color = const Color(0xFFF0C898);
    final neckPath = Path()
      ..moveTo(cx - w * 0.10, h * 0.56)
      ..quadraticBezierTo(cx, h * 0.53, cx + w * 0.10, h * 0.56)
      ..lineTo(cx + w * 0.09, h * 0.44)
      ..quadraticBezierTo(cx, h * 0.42, cx - w * 0.09, h * 0.44)
      ..close();
    canvas.drawPath(neckPath, skinPaint);

    // ── Hair back (short, dark brown) ────────────────────────────────
    final hairDark = Paint()..color = const Color(0xFF201610);
    // Short back hair (smaller than female)
    canvas.drawOval(Rect.fromCenter(
      center: Offset(cx, h * 0.22),
      width: w * 0.68, height: h * 0.48,
    ), hairDark);
    // Small side sideburns
    canvas.drawOval(Rect.fromCenter(
        center: Offset(cx - w * 0.28, h * 0.32), width: w * 0.12, height: h * 0.18),
        hairDark);
    canvas.drawOval(Rect.fromCenter(
        center: Offset(cx + w * 0.28, h * 0.32), width: w * 0.12, height: h * 0.18),
        hairDark);

    // ── Face ────────────────────────────────────────────────────────
    final faceGrad = Paint()
      ..shader = const RadialGradient(
        center: Alignment(0, -0.2),
        radius: 0.72,
        colors: [Color(0xFFFAD8B0), Color(0xFFF0C898)],
      ).createShader(Rect.fromCenter(
        center: Offset(cx, h * 0.30),
        width: w * 0.64, height: h * 0.52,
      ));
    // Slightly wider face than female
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, h * 0.30), width: w * 0.62, height: h * 0.50),
      faceGrad,
    );

    // ── Hair front (short, slightly spiky) ───────────────────────────
    final hairFront = Paint()..color = const Color(0xFF261A12);
    final fringePath = Path()
      ..moveTo(cx - w * 0.31, h * 0.16)
      ..quadraticBezierTo(cx - w * 0.10, h * 0.05, cx + w * 0.06, h * 0.07)
      ..quadraticBezierTo(cx + w * 0.20, h * 0.09, cx + w * 0.31, h * 0.16)
      ..quadraticBezierTo(cx + w * 0.33, h * 0.22, cx + w * 0.28, h * 0.26)
      ..lineTo(cx - w * 0.28, h * 0.26)
      ..quadraticBezierTo(cx - w * 0.33, h * 0.22, cx - w * 0.31, h * 0.16)
      ..close();
    canvas.drawPath(fringePath, hairFront);

    // Spiky highlights
    final spikeHi = Paint()..color = const Color(0xFF3A2A1A).withValues(alpha: 0.65);
    for (final d in [-0.16, -0.04, 0.10, 0.22]) {
      final sx = cx + w * d;
      final spikePath = Path()
        ..moveTo(sx, h * 0.08)
        ..lineTo(sx - w * 0.03, h * 0.16)
        ..lineTo(sx + w * 0.03, h * 0.16)
        ..close();
      canvas.drawPath(spikePath, spikeHi);
    }

    // ── Ears ────────────────────────────────────────────────────────
    canvas.drawOval(Rect.fromCenter(
        center: Offset(cx - w * 0.31, h * 0.30), width: w * 0.10, height: h * 0.11),
        skinPaint);
    canvas.drawOval(Rect.fromCenter(
        center: Offset(cx + w * 0.31, h * 0.30), width: w * 0.10, height: h * 0.11),
        skinPaint);

    // ── Blush (subtle, boyish) ───────────────────────────────────────
    final blush = Paint()..color = const Color(0xFFFF9090).withValues(alpha: 0.25);
    canvas.drawOval(Rect.fromCenter(
        center: Offset(cx - w * 0.18, h * 0.36), width: w * 0.14, height: h * 0.06),
        blush);
    canvas.drawOval(Rect.fromCenter(
        center: Offset(cx + w * 0.18, h * 0.36), width: w * 0.14, height: h * 0.06),
        blush);

    // ── Eyebrows (thicker, straighter) ───────────────────────────────
    final browPaint = Paint()
      ..color = const Color(0xFF281C10)
      ..strokeWidth = w * 0.028
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
        Offset(cx - w * 0.23, h * 0.240), Offset(cx - w * 0.07, h * 0.236), browPaint);
    canvas.drawLine(
        Offset(cx + w * 0.07, h * 0.236), Offset(cx + w * 0.23, h * 0.240), browPaint);

    // ── Eyes (slightly wider, same style) ────────────────────────────
    _drawEye(canvas, cx - w * 0.150, h * 0.295, w * 0.110, h * 0.072, w);
    _drawEye(canvas, cx + w * 0.150, h * 0.295, w * 0.110, h * 0.072, w);

    // ── Nose (slightly more defined) ─────────────────────────────────
    final nosePaint = Paint()
      ..color = const Color(0xFFD89A70).withValues(alpha: 0.85)
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final nosePath = Path()
      ..moveTo(cx - w * 0.045, h * 0.370)
      ..quadraticBezierTo(cx, h * 0.388, cx + w * 0.045, h * 0.370);
    canvas.drawPath(nosePath, nosePaint);
    // Nostrils hint
    canvas.drawArc(Rect.fromCenter(center: Offset(cx - w * 0.04, h * 0.374),
        width: w * 0.04, height: h * 0.022), math.pi, math.pi, false, nosePaint);
    canvas.drawArc(Rect.fromCenter(center: Offset(cx + w * 0.04, h * 0.374),
        width: w * 0.04, height: h * 0.022), 0, math.pi, false, nosePaint);

    // ── Smile (wide, cheerful) ────────────────────────────────────────
    final smilePaint = Paint()
      ..color = const Color(0xFFCC6844)
      ..strokeWidth = w * 0.024
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final smilePath = Path()
      ..moveTo(cx - w * 0.12, h * 0.416)
      ..quadraticBezierTo(cx, h * 0.464, cx + w * 0.12, h * 0.416);
    canvas.drawPath(smilePath, smilePaint);
    // Teeth hint
    final teeth = Paint()..color = Colors.white.withValues(alpha: 0.8);
    canvas.drawOval(Rect.fromCenter(
        center: Offset(cx, h * 0.440), width: w * 0.17, height: h * 0.022),
        teeth);
  }

  void _drawEye(Canvas canvas, double cx, double cy, double ew, double eh, double w) {
    final white = Paint()..color = const Color(0xFFFAF6F0);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy), width: ew, height: eh), white);
    final iris = Paint()
      ..shader = RadialGradient(
        colors: [const Color(0xFF5E8AC4), const Color(0xFF2A4A7A)],
        center: Alignment(-0.2, -0.3),
      ).createShader(Rect.fromCenter(center: Offset(cx, cy), width: ew * 0.68, height: eh * 1.3));
    canvas.drawOval(
        Rect.fromCenter(center: Offset(cx, cy), width: ew * 0.64, height: eh * 1.25), iris);
    final pupil = Paint()..color = const Color(0xFF10181E);
    canvas.drawOval(
        Rect.fromCenter(center: Offset(cx, cy + eh * 0.06), width: ew * 0.30, height: eh * 0.80),
        pupil);
    final shine = Paint()..color = Colors.white.withValues(alpha: 0.95);
    canvas.drawOval(Rect.fromCenter(
        center: Offset(cx - ew * 0.15, cy - eh * 0.20), width: ew * 0.22, height: eh * 0.46),
        shine);
    canvas.drawCircle(Offset(cx + ew * 0.12, cy + eh * 0.05), ew * 0.08, shine);
    final lash = Paint()
      ..color = const Color(0xFF18120C)
      ..strokeWidth = w * 0.016
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final lashPath = Path()
      ..moveTo(cx - ew * 0.50, cy)
      ..quadraticBezierTo(cx, cy - eh * 0.78, cx + ew * 0.50, cy);
    canvas.drawPath(lashPath, lash);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
