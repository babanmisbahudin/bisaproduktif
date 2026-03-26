import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_responsive.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/admin_provider.dart';
import '../../../data/providers/user_profile_provider.dart';
import '../../../data/providers/habit_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  bool _isLoadingGoogle = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    _slideAnimation = Tween<double>(begin: 40.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward();
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoadingGoogle = true;
      _error = null;
    });

    final authProvider = context.read<AuthProvider>();
    final adminProvider = context.read<AdminProvider>();
    final profileProvider = context.read<UserProfileProvider>();
    final habitProvider = context.read<HabitProvider>();

    final success = await authProvider.signInWithGoogle();

    if (mounted) {
      if (success) {
        // Complete Google login setup
        await authProvider.completeGoogleLoginSetup(
          adminProvider: adminProvider,
          profileProvider: profileProvider,
          habitProvider: habitProvider,
        );

        // Mark as onboarded
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_onboarded', true);

        if (mounted) {
          context.go('/home');
        }
      } else {
        setState(() {
          _isLoadingGoogle = false;
          _error = authProvider.error ?? 'Gagal login dengan Google';
        });
      }
    }
  }


  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF7BAE7F),
              Color(0xFFB8D4B0),
              Color(0xFFE8EFE6),
            ],
          ),
        ),
        child: SafeArea(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value,
                child: Transform.translate(
                  offset: Offset(0, _slideAnimation.value),
                  child: child,
                ),
              );
            },
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: context.padding(24),
              ),
              child: SizedBox(
                height: MediaQuery.of(context).size.height - 100,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Top Section - Logo
                    Column(
                      children: [
                        SizedBox(height: context.padding(40)),
                        Center(child: _buildLogo()),
                      ],
                    ),

                    // Middle Section - Marketing Copy
                    Column(
                      children: [
                        // Main Headline
                        Text(
                          'Ubah Produktivitasmu',
                          style: GoogleFonts.poppins(
                            fontSize: context.fontSize(28),
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            height: 1.3,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: context.padding(16)),

                        // Subheadline
                        Text(
                          'Raih goals, kumpulkan koin, tukar dengan reward impianmu. Mulai perjalanan produktifmu hari ini! 🚀',
                          style: GoogleFonts.poppins(
                            fontSize: context.fontSize(15),
                            fontWeight: FontWeight.w400,
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: context.padding(32)),

                        // Quick Stats
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildStatCard('10K+', 'Users Aktif', context),
                            _buildStatCard('50K+', 'Rewards Ditukar', context),
                            _buildStatCard('4.8⭐', 'Rating', context),
                          ],
                        ),
                        SizedBox(height: context.padding(32)),

                        // Benefits Section
                        Container(
                          padding: EdgeInsets.all(context.padding(16)),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(context.radius(14)),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildBenefitItem(
                                  '✅', 'Tracking produktivitas real-time', context),
                              SizedBox(height: context.padding(12)),
                              _buildBenefitItem(
                                  '🎯', 'Goals tracker dengan AI tips', context),
                              SizedBox(height: context.padding(12)),
                              _buildBenefitItem(
                                  '🏆', 'Sistem reward yang menggiurkan', context),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // Bottom Section - Button + Error
                    Column(
                      children: [
                        // Error message
                        if (_error != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Colors.red.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Text('⚠️', style: TextStyle(fontSize: 16)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _error!,
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Colors.red[800],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        // Google Sign-In Button - CENTERED & PROMINENT
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.3),
                                blurRadius: 16,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: ElevatedButton.icon(
                            onPressed: _isLoadingGoogle ? null : _handleGoogleSignIn,
                            icon: _isLoadingGoogle
                                ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white,
                                    ),
                                  )
                                : Image.asset(
                                    'assets/images/google_icon.png',
                                    width: 20,
                                    height: 20,
                                    errorBuilder: (context, error, stackTrace) =>
                                        const Text('🔵', style: TextStyle(fontSize: 18)),
                                  ),
                            label: Text(
                              _isLoadingGoogle
                                  ? 'Sedang membuka Google...'
                                  : 'Mulai Sekarang dengan Google',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                vertical: 16,
                                horizontal: 24,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Trust Badge
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('🔒', style: TextStyle(fontSize: 14)),
                            const SizedBox(width: 6),
                            Text(
                              'Data kamu aman & terenkripsi',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String value, String label, BuildContext context) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: context.padding(12),
          horizontal: context.padding(8),
        ),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(context.radius(10)),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.15),
          ),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: context.fontSize(16),
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
            SizedBox(height: context.padding(4)),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: context.fontSize(11),
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitItem(String icon, String text, BuildContext context) {
    return Row(
      children: [
        Text(icon, style: TextStyle(fontSize: context.fontSize(20))),
        SizedBox(width: context.padding(12)),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: context.fontSize(13),
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLogo() {
    return Builder(
      builder: (context) => RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: 'bisa',
              style: GoogleFonts.poppins(
                fontSize: context.fontSize(40),
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                letterSpacing: -1,
              ),
            ),
            TextSpan(
              text: 'produktif',
              style: GoogleFonts.poppins(
                fontSize: context.fontSize(40),
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
                letterSpacing: -1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
