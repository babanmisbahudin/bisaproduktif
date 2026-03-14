import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
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
  final TextEditingController _nameController = TextEditingController();
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

  Future<void> _handleGuestContinue() async {
    if (_nameController.text.trim().isEmpty) {
      setState(() => _error = 'Nama tidak boleh kosong');
      return;
    }

    setState(() => _error = null);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', _nameController.text.trim());
    await prefs.setBool('is_onboarded', true);
    await prefs.setInt('user_coins', 0);
    await prefs.setInt('trust_score', 70);

    if (mounted) {
      context.go('/home');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
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
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),

                  // Logo
                  Center(child: _buildLogo()),
                  const SizedBox(height: 40),

                  // Headline
                  Text(
                    'Selamat Datang! 👋',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Login untuk memulai journey produktifmu',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Google Sign-In Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isLoadingGoogle ? null : _handleGoogleSignIn,
                      icon: _isLoadingGoogle
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('🔵'),
                      label: Text(
                        _isLoadingGoogle ? 'Sedang login...' : 'Masuk dengan Google',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Divider
                  Row(
                    children: [
                      Expanded(
                        child: Divider(
                          color: Colors.black.withValues(alpha: 0.15),
                          thickness: 1,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'atau',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          color: Colors.black.withValues(alpha: 0.15),
                          thickness: 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Guest Mode
                  Text(
                    'Lanjut tanpa akun',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _nameController,
                    enabled: !_isLoadingGoogle,
                    decoration: InputDecoration(
                      hintText: 'Masukkan nama kamu',
                      hintStyle: GoogleFonts.poppins(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _isLoadingGoogle ? null : _handleGuestContinue,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(
                          color: AppColors.primary.withValues(alpha: 0.5),
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Lanjut',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),

                  // Error message
                  if (_error != null) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.red.withValues(alpha: 0.3),
                        ),
                      ),
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

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: 'bisa',
            style: GoogleFonts.poppins(
              fontSize: 40,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: -1,
            ),
          ),
          TextSpan(
            text: 'produktif',
            style: GoogleFonts.poppins(
              fontSize: 40,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
              letterSpacing: -1,
            ),
          ),
        ],
      ),
    );
  }
}
