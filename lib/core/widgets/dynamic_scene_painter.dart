import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';

// ── Enums ─────────────────────────────────────────────────────────────────

enum SceneTime {
  earlyMorning, // 04:00 – 06:00  sunrise
  morning,      // 06:00 – 11:00  clear blue
  hotAfternoon, // 11:00 – 15:00  blazing sun
  afternoon,    // 15:00 – 17:00  warm afternoon
  sunset,       // 17:00 – 19:30  orange/purple
  night,        // 19:30 – 04:00  stars + moon
}

enum WeatherType {
  clear,  // gunakan waktu
  rainy,  // hujan + mendung
  hot,    // terik + shimmer
  cloudy, // berawan
}

// ── Internal data classes ─────────────────────────────────────────────────

class _Cloud {
  final double x, y, size, speed;
  const _Cloud(this.x, this.y, this.size, this.speed);
}

class _Star {
  final double x, y, size, phase;
  const _Star(this.x, this.y, this.size, this.phase);
}

// ── Widget ────────────────────────────────────────────────────────────────

class DynamicSceneWidget extends StatefulWidget {
  final WeatherType weather;
  const DynamicSceneWidget({super.key, this.weather = WeatherType.clear});

  @override
  State<DynamicSceneWidget> createState() => _DynamicSceneWidgetState();
}

class _DynamicSceneWidgetState extends State<DynamicSceneWidget>
    with TickerProviderStateMixin {
  late final AnimationController _waveCtrl;
  late final AnimationController _cloudCtrl;
  late final AnimationController _twinkleCtrl;
  late final AnimationController _rainCtrl;
  late final AnimationController _shimmerCtrl;

  late SceneTime _sceneTime;
  late final List<_Cloud> _clouds;
  late final List<_Star> _stars;
  Timer? _sceneTimer;

  @override
  void initState() {
    super.initState();
    _sceneTime = _fromClock();
    _clouds = _genClouds();
    _stars = _genStars();

    _waveCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 3))
      ..repeat();
    _cloudCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 50))
      ..repeat();
    _twinkleCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000))
      ..repeat(reverse: true);
    _rainCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600))
      ..repeat();
    _shimmerCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);

    // Refresh scene type every minute
    _sceneTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      final t = _fromClock();
      if (t != _sceneTime) setState(() => _sceneTime = t);
    });
  }

  @override
  void dispose() {
    _waveCtrl.dispose();
    _cloudCtrl.dispose();
    _twinkleCtrl.dispose();
    _rainCtrl.dispose();
    _shimmerCtrl.dispose();
    _sceneTimer?.cancel();
    super.dispose();
  }

  static SceneTime _fromClock() {
    final h = DateTime.now().hour;
    if (h >= 4 && h < 6) return SceneTime.earlyMorning;
    if (h >= 6 && h < 11) return SceneTime.morning;
    if (h >= 11 && h < 15) return SceneTime.hotAfternoon;
    if (h >= 15 && h < 17) return SceneTime.afternoon;
    if (h >= 17 && h < 20) return SceneTime.sunset;
    return SceneTime.night;
  }

  static List<_Cloud> _genClouds() {
    final r = math.Random(7);
    return List.generate(6, (i) => _Cloud(
      r.nextDouble(),
      0.04 + r.nextDouble() * 0.22,
      0.14 + r.nextDouble() * 0.16,
      0.002 + r.nextDouble() * 0.004,
    ));
  }

  static List<_Star> _genStars() {
    final r = math.Random(42);
    return List.generate(90, (i) => _Star(
      r.nextDouble(),
      r.nextDouble() * 0.58,
      0.8 + r.nextDouble() * 2.4,
      r.nextDouble() * math.pi * 2,
    ));
  }

  // Effective scene considering weather override
  SceneTime get _effectiveScene {
    if (widget.weather == WeatherType.hot) return SceneTime.hotAfternoon;
    return _sceneTime;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _waveCtrl, _cloudCtrl, _twinkleCtrl, _rainCtrl, _shimmerCtrl
      ]),
      builder: (_, _) => CustomPaint(
        painter: _ScenePainter(
          scene: _effectiveScene,
          weather: widget.weather,
          wave: _waveCtrl.value * math.pi * 2,
          cloud: _cloudCtrl.value,
          twinkle: _twinkleCtrl.value,
          rain: _rainCtrl.value,
          shimmer: _shimmerCtrl.value,
          clouds: _clouds,
          stars: _stars,
        ),
      ),
    );
  }
}

// ── CustomPainter ─────────────────────────────────────────────────────────

class _ScenePainter extends CustomPainter {
  final SceneTime scene;
  final WeatherType weather;
  final double wave, cloud, twinkle, rain, shimmer;
  final List<_Cloud> clouds;
  final List<_Star> stars;

  const _ScenePainter({
    required this.scene,
    required this.weather,
    required this.wave,
    required this.cloud,
    required this.twinkle,
    required this.rain,
    required this.shimmer,
    required this.clouds,
    required this.stars,
  });

  // ── Sky ─────────────────────────────────────────────────────────────────
  static const _skyPalettes = {
    SceneTime.earlyMorning: [Color(0xFF1A1A2E), Color(0xFF6B2D8B), Color(0xFFFF8A50), Color(0xFFFFD09E)],
    SceneTime.morning:      [Color(0xFF4FACFE), Color(0xFF00D2FF), Color(0xFFFFF9C4)],
    SceneTime.hotAfternoon: [Color(0xFF0077B6), Color(0xFF0096C7), Color(0xFF48CAE4), Color(0xFFE3F4FD)],
    SceneTime.afternoon:    [Color(0xFF1976D2), Color(0xFF42A5F5), Color(0xFFBBDEFB)],
    SceneTime.sunset:       [Color(0xFF1A0533), Color(0xFF8E1A5C), Color(0xFFFF4E00), Color(0xFFFFB347)],
    SceneTime.night:        [Color(0xFF020912), Color(0xFF08152B), Color(0xFF0F2040)],
  };

  static const _rainSky = [Color(0xFF1C2A35), Color(0xFF2E4050), Color(0xFF4A6070)];
  static const _cloudySky = [Color(0xFF4A5568), Color(0xFF718096), Color(0xFFCBD5E0)];

  List<Color> get _skyColors {
    if (weather == WeatherType.rainy) return _rainSky;
    if (weather == WeatherType.cloudy) return _cloudySky;
    return _skyPalettes[scene]!;
  }

  // ── Main paint ───────────────────────────────────────────────────────────
  @override
  void paint(Canvas canvas, Size size) {
    _drawSky(canvas, size);

    if (scene == SceneTime.night && weather != WeatherType.rainy) {
      _drawStars(canvas, size);
      _drawMoon(canvas, size);
    } else if (weather != WeatherType.rainy) {
      _drawSun(canvas, size);
    }

    if (weather == WeatherType.rainy) {
      _drawStormClouds(canvas, size);
    } else if (scene != SceneTime.night) {
      _drawClouds(canvas, size);
    }

    _drawBackMountains(canvas, size);
    _drawOcean(canvas, size);
    _drawWaves(canvas, size);
    _drawFrontHills(canvas, size);
    _drawTrees(canvas, size);

    if (scene == SceneTime.morning) _drawBirds(canvas, size);
    if (scene == SceneTime.hotAfternoon && weather != WeatherType.rainy) {
      _drawHeatShimmer(canvas, size);
    }

    if (weather == WeatherType.rainy) {
      _drawRainOverlay(canvas, size);
      _drawRainDrops(canvas, size);
    }
  }

  // ── Sky layer ─────────────────────────────────────────────────────────────
  void _drawSky(Canvas canvas, Size size) {
    final colors = _skyColors;
    final stops = List.generate(colors.length, (i) => i / (colors.length - 1));
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors,
          stops: stops,
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );
  }

  // ── Stars ────────────────────────────────────────────────────────────────
  void _drawStars(Canvas canvas, Size size) {
    for (final s in stars) {
      // Twinkle animation: natural brightness variation
      final bright = 0.5 + 0.5 * math.sin(twinkle * math.pi + s.phase);
      final starX = s.x * size.width;
      final starY = s.y * size.height * 0.72;

      // Star glow (outer halo)
      canvas.drawCircle(
        Offset(starX, starY),
        s.size * bright * 1.8,
        Paint()..color = Colors.white.withValues(alpha: bright * 0.3),
      );

      // Star body (bright core)
      canvas.drawCircle(
        Offset(starX, starY),
        s.size * bright,
        Paint()..color = Colors.white.withValues(alpha: bright * 0.95),
      );

      // Star sparkle (cross pattern untuk effect)
      if (bright > 0.65) {
        final sparkleSize = s.size * 0.3;
        final sparkleOpacity = (bright - 0.65) * 1.4;
        // Vertical
        canvas.drawLine(
          Offset(starX, starY - sparkleSize),
          Offset(starX, starY + sparkleSize),
          Paint()
            ..color = Colors.white.withValues(alpha: sparkleOpacity * 0.4)
            ..strokeWidth = 0.5,
        );
        // Horizontal
        canvas.drawLine(
          Offset(starX - sparkleSize, starY),
          Offset(starX + sparkleSize, starY),
          Paint()
            ..color = Colors.white.withValues(alpha: sparkleOpacity * 0.4)
            ..strokeWidth = 0.5,
        );
      }
    }
  }

  // ── Moon ─────────────────────────────────────────────────────────────────
  void _drawMoon(Canvas canvas, Size size) {
    final cx = size.width * 0.78, cy = size.height * 0.45;
    final r = size.width * 0.075;

    // Outer glow (soft, diffuse)
    canvas.drawCircle(
      Offset(cx, cy), r * 2.8,
      Paint()
        ..color = const Color(0xFFD4E8FF).withValues(alpha: 0.15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 32),
    );
    // Inner glow (brighter)
    canvas.drawCircle(
      Offset(cx, cy), r * 1.5,
      Paint()
        ..color = const Color(0xFFE8E4D0).withValues(alpha: 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );

    // Moon body
    canvas.drawCircle(
      Offset(cx, cy), r,
      Paint()..color = const Color(0xFFFFFAF0),
    );

    // Crescent shadow (waning moon effect)
    canvas.drawCircle(
      Offset(cx + r * 0.35, cy - r * 0.05), r * 0.92,
      Paint()..color = const Color(0xFF0F2040),
    );

    // Moon craters untuk detail (realistis seperti Google Weather)
    _drawMoonCraters(canvas, cx, cy, r);

    // Moonlight reflection di ocean (atmospheric)
    final reflPaint = Paint()
      ..color = const Color(0xFFD4E8FF).withValues(alpha: 0.12)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(cx, size.height * 0.72),
        width: r * 3.2,
        height: size.height * 0.20,
      ),
      reflPaint,
    );
  }

  // ── Moon craters (detail untuk realism) ────────────────────────────────
  void _drawMoonCraters(Canvas canvas, double cx, double cy, double r) {
    // Small craters pattern
    const craters = [
      (0.25, -0.15, 0.08),
      (-0.20, -0.10, 0.06),
      (-0.10, 0.25, 0.07),
      (0.30, 0.10, 0.05),
      (-0.30, 0.15, 0.06),
    ];

    for (final (dx, dy, size) in craters) {
      final crx = cx + dx * r;
      final cry = cy + dy * r;
      final csize = r * size;

      // Shadow inside crater (depth)
      canvas.drawCircle(
        Offset(crx + csize * 0.2, cry + csize * 0.2), csize * 0.6,
        Paint()..color = const Color(0xFF0F2040).withValues(alpha: 0.15),
      );
      // Crater rim (highlight)
      canvas.drawCircle(
        Offset(crx, cry), csize,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = csize * 0.15
          ..color = const Color(0xFFF5F0DC).withValues(alpha: 0.5),
      );
    }
  }

  // ── Sun ──────────────────────────────────────────────────────────────────
  void _drawSun(Canvas canvas, Size size) {
    double cx, cy, r;
    Color sunColor;

    switch (scene) {
      case SceneTime.earlyMorning:
        cx = size.width * 0.15; cy = size.height * 0.45;
        r = size.width * 0.065; sunColor = const Color(0xFFFF9A42);
        break;
      case SceneTime.morning:
        cx = size.width * 0.72; cy = size.height * 0.22;
        r = size.width * 0.08; sunColor = const Color(0xFFFFD700);
        break;
      case SceneTime.hotAfternoon:
        cx = size.width * 0.50; cy = size.height * 0.18;
        r = size.width * 0.115; sunColor = const Color(0xFFFFF176);
        break;
      case SceneTime.afternoon:
        cx = size.width * 0.65; cy = size.height * 0.26;
        r = size.width * 0.09; sunColor = const Color(0xFFFFD54F);
        break;
      case SceneTime.sunset:
        cx = size.width * 0.22; cy = size.height * 0.43;
        r = size.width * 0.12; sunColor = const Color(0xFFFF5722);
        break;
      default:
        return;
    }

    // Outer glow
    canvas.drawCircle(
      Offset(cx, cy), r * 2.8,
      Paint()
        ..color = sunColor.withValues(alpha: 0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 32),
    );
    // Mid glow
    canvas.drawCircle(
      Offset(cx, cy), r * 1.6,
      Paint()
        ..color = sunColor.withValues(alpha: 0.28)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
    );
    // Sun body
    canvas.drawCircle(Offset(cx, cy), r, Paint()..color = sunColor);

    if (scene == SceneTime.hotAfternoon) {
      _drawSunRays(canvas, Offset(cx, cy), r, sunColor);
    }

    // Sunset reflection on ocean
    if (scene == SceneTime.sunset) {
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset(cx, size.height * 0.64),
          width: r * 3.5, height: size.height * 0.14,
        ),
        Paint()
          ..color = sunColor.withValues(alpha: 0.22)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22),
      );
    }
  }

  void _drawSunRays(Canvas canvas, Offset c, double r, Color col) {
    final p = Paint()
      ..color = col.withValues(alpha: 0.45)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < 12; i++) {
      final a = (i / 12) * math.pi * 2 + wave * 0.25;
      canvas.drawLine(
        Offset(c.dx + math.cos(a) * r * 1.5, c.dy + math.sin(a) * r * 1.5),
        Offset(c.dx + math.cos(a) * r * 2.2, c.dy + math.sin(a) * r * 2.2),
        p,
      );
    }
  }

  // ── Heat shimmer ─────────────────────────────────────────────────────────
  void _drawHeatShimmer(Canvas canvas, Size size) {
    final y = size.height * 0.56;
    canvas.drawRect(
      Rect.fromLTWH(0, y - 20, size.width, 40),
      Paint()
        ..color = const Color(0xFFFFF9C4).withValues(alpha: 0.07 + shimmer * 0.05)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
  }

  // ── Fluffy clouds ─────────────────────────────────────────────────────────
  void _drawClouds(Canvas canvas, Size size) {
    Color col;
    switch (scene) {
      case SceneTime.sunset:
      case SceneTime.earlyMorning:
        col = const Color(0xFFFFCCBC).withValues(alpha: 0.85);
        break;
      case SceneTime.night:
        col = Colors.white.withValues(alpha: 0.15);
        break;
      default:
        col = Colors.white.withValues(alpha: 0.88);
    }
    for (final c in clouds) {
      final x = ((c.x + cloud * c.speed * 4.5) % 1.25 - 0.12) * size.width;
      final y = c.y * size.height;
      _puffyCloud(canvas, Offset(x, y), c.size * size.width, col);
    }
  }

  void _drawStormClouds(Canvas canvas, Size size) {
    for (final c in clouds) {
      final x = ((c.x + cloud * c.speed * 3) % 1.25 - 0.12) * size.width;
      final y = c.y * 0.7 * size.height;
      _puffyCloud(canvas, Offset(x, y), c.size * 1.6 * size.width,
          const Color(0xFF455A64).withValues(alpha: 0.92));
    }
    // Dense overcast layer
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height * 0.30),
      Paint()
        ..color = const Color(0xFF37474F).withValues(alpha: 0.55)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30),
    );
  }

  void _puffyCloud(Canvas canvas, Offset center, double w, Color col) {
    final h = w * 0.36;
    final p = Paint()
      ..color = col
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    for (final (dx, dy, r) in [
      (0.0, 0.0, h * 0.9),
      (-w * 0.25, h * 0.18, h * 0.70),
      (w * 0.25, h * 0.18, h * 0.70),
      (-w * 0.12, -h * 0.1, h * 0.62),
      (w * 0.12, -h * 0.1, h * 0.62),
    ]) {
      canvas.drawCircle(Offset(center.dx + dx, center.dy + dy), r, p);
    }
  }

  // ── Back mountains ────────────────────────────────────────────────────────
  void _drawBackMountains(Canvas canvas, Size size) {
    final yBase = size.height * 0.52;
    Color col;
    switch (scene) {
      case SceneTime.night:
        col = const Color(0xFF071525).withValues(alpha: 0.9);
        break;
      case SceneTime.sunset:
        col = const Color(0xFF4A1942).withValues(alpha: 0.75);
        break;
      case SceneTime.earlyMorning:
        col = const Color(0xFF2D3A2D).withValues(alpha: 0.7);
        break;
      default:
        col = weather == WeatherType.rainy
            ? const Color(0xFF3A4A55).withValues(alpha: 0.8)
            : const Color(0xFF558B2F).withValues(alpha: 0.55);
    }

    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, yBase + size.height * 0.06)
      ..cubicTo(size.width * 0.12, yBase - size.height * 0.06,
          size.width * 0.28, yBase + size.height * 0.04, size.width * 0.42, yBase)
      ..cubicTo(size.width * 0.56, yBase - size.height * 0.08,
          size.width * 0.72, yBase + size.height * 0.02, size.width * 0.88, yBase - size.height * 0.03)
      ..lineTo(size.width, yBase + size.height * 0.04)
      ..lineTo(size.width, size.height)
      ..close();

    canvas.drawPath(path, Paint()..color = col);
  }

  // ── Ocean ─────────────────────────────────────────────────────────────────
  void _drawOcean(Canvas canvas, Size size) {
    final top = size.height * 0.58;
    Color shallow, deep;

    switch (scene) {
      case SceneTime.night:
        shallow = const Color(0xFF0D2440); deep = const Color(0xFF050E1C);
        break;
      case SceneTime.sunset:
        shallow = const Color(0xFF8B2500); deep = const Color(0xFF5C1A00);
        break;
      case SceneTime.earlyMorning:
        shallow = const Color(0xFF1A3A5C); deep = const Color(0xFF0A1E35);
        break;
      case SceneTime.hotAfternoon:
        shallow = const Color(0xFF0288D1); deep = const Color(0xFF01579B);
        break;
      default:
        shallow = weather == WeatherType.rainy
            ? const Color(0xFF2C3E50) : const Color(0xFF0277BD);
        deep = weather == WeatherType.rainy
            ? const Color(0xFF1A252F) : const Color(0xFF01579B);
    }

    canvas.drawRect(
      Rect.fromLTWH(0, top, size.width, size.height - top),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [shallow, deep],
        ).createShader(Rect.fromLTWH(0, top, size.width, size.height - top)),
    );
  }

  // ── Ocean waves ────────────────────────────────────────────────────────────
  void _drawWaves(Canvas canvas, Size size) {
    final waveColor = weather == WeatherType.rainy
        ? Colors.white.withValues(alpha: 0.18)
        : Colors.white.withValues(alpha: 0.28);
    final wavePaint = Paint()
      ..color = waveColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;

    for (int layer = 0; layer < 4; layer++) {
      final phase = wave + layer * math.pi * 0.55;
      final amplitude = (weather == WeatherType.rainy ? 7.0 : 4.5) - layer * 0.7;
      final yBase = size.height * 0.58 + layer * 11.0;

      final path = Path();
      for (double x = 0; x <= size.width + 8; x += 2) {
        final y = yBase + amplitude * math.sin((x / size.width) * math.pi * 5 + phase);
        if (x == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(path, wavePaint);
    }
  }

  // ── Front hills ───────────────────────────────────────────────────────────
  void _drawFrontHills(Canvas canvas, Size size) {
    Color col;
    switch (scene) {
      case SceneTime.night:
        col = const Color(0xFF060F1E);
        break;
      case SceneTime.sunset:
      case SceneTime.earlyMorning:
        col = const Color(0xFF1B3520);
        break;
      default:
        col = weather == WeatherType.rainy
            ? const Color(0xFF263238) : const Color(0xFF2E7D32);
    }

    final path = Path()
      ..moveTo(-10, size.height)
      ..lineTo(-10, size.height * 0.72)
      ..cubicTo(size.width * 0.08, size.height * 0.59,
          size.width * 0.18, size.height * 0.61, size.width * 0.32, size.height * 0.69)
      // Ocean opening in middle
      ..cubicTo(size.width * 0.45, size.height * 0.73,
          size.width * 0.55, size.height * 0.72, size.width * 0.68, size.height * 0.68)
      ..cubicTo(size.width * 0.78, size.height * 0.61,
          size.width * 0.90, size.height * 0.58, size.width + 10, size.height * 0.65)
      ..lineTo(size.width + 10, size.height)
      ..close();

    canvas.drawPath(path, Paint()..color = col);
  }

  // ── Trees ─────────────────────────────────────────────────────────────────
  void _drawTrees(Canvas canvas, Size size) {
    Color trunkCol, leafCol;
    switch (scene) {
      case SceneTime.night:
        trunkCol = const Color(0xFF0A0A12);
        leafCol = const Color(0xFF0A1A0A);
        break;
      case SceneTime.sunset:
      case SceneTime.earlyMorning:
        trunkCol = const Color(0xFF1A0A00);
        leafCol = const Color(0xFF1B3A10);
        break;
      default:
        trunkCol = const Color(0xFF5D4037);
        leafCol = weather == WeatherType.rainy
            ? const Color(0xFF1B4A1B) : const Color(0xFF1B5E20);
    }

    final treeData = [
      (size.width * 0.04, size.height * 0.64, 0.030),
      (size.width * 0.10, size.height * 0.61, 0.035),
      (size.width * 0.17, size.height * 0.62, 0.028),
      (size.width * 0.24, size.height * 0.66, 0.025),
      (size.width * 0.77, size.height * 0.66, 0.025),
      (size.width * 0.84, size.height * 0.62, 0.030),
      (size.width * 0.91, size.height * 0.60, 0.035),
      (size.width * 0.96, size.height * 0.63, 0.028),
    ];

    for (final (tx, ty, ts) in treeData) {
      _drawFirTree(canvas, Offset(tx, ty), ts * size.width, leafCol, trunkCol);
    }
  }

  void _drawFirTree(Canvas canvas, Offset base, double sz,
      Color leafCol, Color trunkCol) {
    // Trunk
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(base.dx, base.dy + sz * 0.4),
        width: sz * 0.28, height: sz * 0.7,
      ),
      Paint()..color = trunkCol,
    );
    // Three stacked triangles for layered fir look
    for (int layer = 0; layer < 3; layer++) {
      final yTop = base.dy - sz * (2.4 - layer * 0.6);
      final halfW = sz * (0.8 + layer * 0.25);
      final p = Paint()..color = Color.lerp(
        leafCol, const Color(0xFF4CAF50),
        layer * 0.2,
      )!;
      final path = Path()
        ..moveTo(base.dx, yTop)
        ..lineTo(base.dx - halfW, base.dy - sz * (0.2 - layer * 0.5).clamp(0, 2))
        ..lineTo(base.dx + halfW, base.dy - sz * (0.2 - layer * 0.5).clamp(0, 2))
        ..close();
      canvas.drawPath(path, p);
    }
  }

  // ── Birds ─────────────────────────────────────────────────────────────────
  void _drawBirds(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Colors.white.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final offset = cloud * 30.0;
    final birdData = [
      Offset(size.width * 0.28 + offset, size.height * 0.17),
      Offset(size.width * 0.35 + offset, size.height * 0.13),
      Offset(size.width * 0.22 + offset, size.height * 0.20),
    ];
    for (final pos in birdData) {
      final path = Path()
        ..moveTo(pos.dx - 7, pos.dy)
        ..quadraticBezierTo(pos.dx - 3, pos.dy - 4, pos.dx, pos.dy)
        ..quadraticBezierTo(pos.dx + 3, pos.dy - 4, pos.dx + 7, pos.dy);
      canvas.drawPath(path, p);
    }
  }

  // ── Rain ─────────────────────────────────────────────────────────────────
  void _drawRainOverlay(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFF101E28).withValues(alpha: 0.38),
    );
  }

  void _drawRainDrops(Canvas canvas, Size size) {
    final p = Paint()
      ..color = const Color(0xFF90CAF9).withValues(alpha: 0.42)
      ..strokeWidth = 1.1
      ..strokeCap = StrokeCap.round;

    final rng = math.Random(9999);
    const count = 130;
    for (int i = 0; i < count; i++) {
      final bx = rng.nextDouble() * size.width;
      final by = rng.nextDouble() * size.height;
      final speed = 0.35 + rng.nextDouble() * 0.55;
      final len = 13.0 + rng.nextDouble() * 12;

      final cy = (by + rain * size.height * speed) % size.height;
      canvas.drawLine(
        Offset(bx - len * 0.1, cy),
        Offset(bx + len * 0.1, cy + len),
        p,
      );
    }
  }

  @override
  bool shouldRepaint(_ScenePainter old) =>
      old.wave != wave ||
      old.cloud != cloud ||
      old.twinkle != twinkle ||
      old.rain != rain ||
      old.shimmer != shimmer ||
      old.scene != scene ||
      old.weather != weather;
}
