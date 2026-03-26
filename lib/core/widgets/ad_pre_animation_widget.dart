import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_responsive.dart';
import '../../core/painters/birds_painter.dart';
import '../../core/painters/fireflies_painter.dart';
import '../../core/painters/rain_ad_painter.dart';
import '../../core/painters/sunrays_painter.dart';
import '../../core/painters/cloud_particles_painter.dart';
import '../../core/painters/stars_appearing_painter.dart';
import '../../core/widgets/dynamic_scene_painter.dart';

class AdPreAnimationWidget extends StatefulWidget {
  final VoidCallback onAnimationComplete; // Callback saat animasi selesai / user klik
  final WeatherType weather;
  final SceneTime sceneTime;

  const AdPreAnimationWidget({
    super.key,
    required this.onAnimationComplete,
    required this.weather,
    required this.sceneTime,
  });

  @override
  State<AdPreAnimationWidget> createState() => _AdPreAnimationWidgetState();
}

class _AdPreAnimationWidgetState extends State<AdPreAnimationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    // Durasi animasi sesuai weather type
    final duration = _getDurationForWeather(widget.weather);

    _controller = AnimationController(
      vsync: this,
      duration: duration,
    );

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);

    // Auto-complete animasi setelah durasi
    _controller.forward().then((_) {
      if (mounted) {
        widget.onAnimationComplete();
      }
    });
  }

  Duration _getDurationForWeather(WeatherType weather) {
    return switch (weather) {
      WeatherType.clear => const Duration(milliseconds: 2500),
      WeatherType.rainy => const Duration(milliseconds: 2000),
      WeatherType.hot => const Duration(milliseconds: 2500),
      WeatherType.cloudy => const Duration(milliseconds: 2500),
    };
  }

  CustomPainter _getPainterForWeather(double progress) {
    return switch (widget.weather) {
      WeatherType.clear => _getClearWeatherPainter(progress),
      WeatherType.rainy => RainAdPainter(animationValue: progress),
      WeatherType.hot => SunraysPainter(animationValue: progress),
      WeatherType.cloudy => CloudParticlesPainter(animationValue: progress),
    };
  }

  CustomPainter _getClearWeatherPainter(double progress) {
    // Clear morning: birds
    // Clear night: fireflies
    // Clear sunset: stars
    return switch (widget.sceneTime) {
      SceneTime.earlyMorning ||
      SceneTime.morning =>
        BirdsPainter(animationValue: progress),
      SceneTime.night => FirefliesPainter(animationValue: progress),
      SceneTime.sunset => StarsAppearingPainter(animationValue: progress),
      _ => BirdsPainter(animationValue: progress),
    };
  }

  String _getAnimationLabel() {
    return switch (widget.weather) {
      WeatherType.clear => switch (widget.sceneTime) {
          SceneTime.night => '🌙 Malam yang indah',
          SceneTime.sunset => '🌅 Matahari terbenam',
          _ => '🌤️ Pagi yang cerah',
        },
      WeatherType.rainy => '🌧️ Hari yang hujan',
      WeatherType.hot => '☀️ Hari yang panas',
      WeatherType.cloudy => '☁️ Mendung',
    };
  }

  String _getClickText() {
    return 'Klik untuk dapatkan poin lebih banyak!';
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // User klik animasi → langsung stop dan trigger ad
        _controller.stop();
        widget.onAnimationComplete();
      },
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: _getBackgroundColor(),
        child: Stack(
          children: [
            // Animation canvas
            AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return CustomPaint(
                  painter: _getPainterForWeather(_animation.value),
                  size: Size.infinite,
                );
              },
            ),

            // Click overlay dengan bubble text
            Positioned.fill(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    _controller.stop();
                    widget.onAnimationComplete();
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Weather label
                      Text(
                        _getAnimationLabel(),
                        style: TextStyle(
                          fontSize: context.fontSize(24),
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          shadows: [
                            const Shadow(
                              color: Colors.black26,
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 40),

                      // Bubble text: click hint
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: context.padding(20),
                          vertical: context.padding(12),
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(context.radius(20)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Text(
                          _getClickText(),
                          style: TextStyle(
                            fontSize: context.fontSize(14),
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Pulse animation indicator
                      _buildPulseIndicator(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPulseIndicator() {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final scale = 0.8 + (_animation.value * 0.4);
        return Transform.scale(
          scale: scale,
          child: Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.8),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.6),
                  blurRadius: 8,
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getBackgroundColor() {
    return switch (widget.weather) {
      WeatherType.clear => switch (widget.sceneTime) {
          SceneTime.night => const Color(0xFF0B1B3D),
          SceneTime.sunset => const Color(0xFFFF8C42),
          _ => const Color(0xFF87CEEB),
        },
      WeatherType.rainy => const Color(0xFF556B7C),
      WeatherType.hot => const Color(0xFFFFF5E1),
      WeatherType.cloudy => const Color(0xFFD3D3D3),
    };
  }
}
