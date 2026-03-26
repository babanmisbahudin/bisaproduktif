import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_responsive.dart';
import '../../../core/widgets/dynamic_scene_painter.dart';

class OnboardingWelcomePage extends StatefulWidget {
  final VoidCallback onNext;

  const OnboardingWelcomePage({super.key, required this.onNext});

  @override
  State<OnboardingWelcomePage> createState() => _OnboardingWelcomePageState();
}

class _OnboardingWelcomePageState extends State<OnboardingWelcomePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _logoFadeAnimation;
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _taglineSlideAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Logo fade in
    _logoFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    // Logo scale in
    _logoScaleAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    // Tagline slide up
    _taglineSlideAnimation = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background with dynamic scene
          const DynamicSceneWidget(weather: WeatherType.clear),

          // Content overlay
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Animated Logo
                        AnimatedBuilder(
                          animation: _controller,
                          builder: (context, child) {
                            return Opacity(
                              opacity: _logoFadeAnimation.value,
                              child: Transform.scale(
                                scale: _logoScaleAnimation.value,
                                child: RichText(
                                  text: TextSpan(
                                    children: [
                                      TextSpan(
                                        text: 'bisa',
                                        style: GoogleFonts.poppins(
                                          fontSize: context.fontSize(56),
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                          letterSpacing: -2,
                                          shadows: [
                                            const Shadow(
                                              color: Colors.black26,
                                              blurRadius: 8,
                                              offset: Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                      ),
                                      TextSpan(
                                        text: 'produktif',
                                        style: GoogleFonts.poppins(
                                          fontSize: context.fontSize(56),
                                          fontWeight: FontWeight.w800,
                                          color: const Color(0xFFFFC0CB),
                                          letterSpacing: -2,
                                          shadows: [
                                            const Shadow(
                                              color: Colors.black26,
                                              blurRadius: 8,
                                              offset: Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),

                        SizedBox(height: context.padding(32)),

                        // Animated Tagline
                        AnimatedBuilder(
                          animation: _taglineSlideAnimation,
                          builder: (context, child) {
                            return Opacity(
                              opacity: _taglineSlideAnimation.value > 25
                                  ? 1.0
                                  : _taglineSlideAnimation.value / 25,
                              child: Transform.translate(
                                offset: Offset(0, _taglineSlideAnimation.value),
                                child: child,
                              ),
                            );
                          },
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: context.padding(24),
                            ),
                            child: Text(
                              'Raih goals, kumpulkan poin, tukar dengan reward impianmu',
                              style: GoogleFonts.poppins(
                                fontSize: context.fontSize(16),
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                                height: 1.5,
                                shadows: [
                                  const Shadow(
                                    color: Colors.black26,
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Button
                Padding(
                  padding: EdgeInsets.only(
                    bottom: context.padding(40),
                    left: context.padding(24),
                    right: context.padding(24),
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: widget.onNext,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primary,
                        padding: EdgeInsets.symmetric(
                          vertical: context.padding(16),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(context.radius(12)),
                        ),
                        elevation: 8,
                        shadowColor: Colors.black26,
                      ),
                      child: Text(
                        'Mulai Sekarang',
                        style: GoogleFonts.poppins(
                          fontSize: context.fontSize(16),
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
