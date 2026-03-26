import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_responsive.dart';
import '../../../core/widgets/avatar_widget.dart';

class OnboardingGenderPage extends StatefulWidget {
  final VoidCallback onNext;

  const OnboardingGenderPage({super.key, required this.onNext});

  @override
  State<OnboardingGenderPage> createState() => _OnboardingGenderPageState();
}

class _OnboardingGenderPageState extends State<OnboardingGenderPage> {
  String? selectedGender;

  void _selectGender(String gender) {
    setState(() {
      selectedGender = gender;
    });

    // Auto proceed after 500ms
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted && selectedGender != null) {
        widget.onNext();
      }
    });
  }

  Matrix4 _getTransform(bool isSelected) {
    final matrix = Matrix4.identity();
    if (isSelected) matrix.scale(1.04, 1.04, 1.0);
    return matrix;
  }

  Color _getBorderColor(bool isSelected) {
    return isSelected ? AppColors.primary : Colors.transparent;
  }

  Color _getShadowColor(bool isSelected) {
    return isSelected
        ? AppColors.primary.withValues(alpha: 0.4)
        : Colors.black.withValues(alpha: 0.2);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF4A7C59),
              Color(0xFF6FA876),
              Color(0xFF8FBB8D),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: EdgeInsets.only(
                  top: context.padding(24),
                  bottom: context.padding(32),
                ),
                child: Text(
                  'Pilih Avatar Kamu',
                  style: GoogleFonts.poppins(
                    fontSize: context.fontSize(28),
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              // Gender Cards
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: context.padding(16)),
                  child: Row(
                    children: [
                      // Female Card
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _selectGender('female'),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOutCubic,
                            transform: _getTransform(selectedGender == 'female'),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.95),
                                borderRadius:
                                    BorderRadius.circular(context.radius(20)),
                                border: Border.all(
                                  color: _getBorderColor(selectedGender == 'female'),
                                  width: 3,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: _getShadowColor(selectedGender == 'female'),
                                    blurRadius: 12,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Avatar
                                  SizedBox(
                                    width: context.padding(100),
                                    height: context.padding(100),
                                    child: const AvatarWidget(
                                      gender: 'female',
                                    ),
                                  ),
                                  SizedBox(height: context.padding(16)),
                                  // Label
                                  Text(
                                    'Perempuan',
                                    style: GoogleFonts.poppins(
                                      fontSize: context.fontSize(16),
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  // Emoji
                                  Text(
                                    '👩',
                                    style:
                                        TextStyle(fontSize: context.fontSize(28)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      SizedBox(width: context.padding(16)),

                      // Male Card
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _selectGender('male'),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOutCubic,
                            transform: _getTransform(selectedGender == 'male'),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.95),
                                borderRadius:
                                    BorderRadius.circular(context.radius(20)),
                                border: Border.all(
                                  color: _getBorderColor(selectedGender == 'male'),
                                  width: 3,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: _getShadowColor(selectedGender == 'male'),
                                    blurRadius: 12,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Avatar
                                  SizedBox(
                                    width: context.padding(100),
                                    height: context.padding(100),
                                    child: const AvatarWidget(
                                      gender: 'male',
                                    ),
                                  ),
                                  SizedBox(height: context.padding(16)),
                                  // Label
                                  Text(
                                    'Laki-laki',
                                    style: GoogleFonts.poppins(
                                      fontSize: context.fontSize(16),
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  // Emoji
                                  Text(
                                    '👨',
                                    style:
                                        TextStyle(fontSize: context.fontSize(28)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom spacing
              SizedBox(height: context.padding(40)),
            ],
          ),
        ),
      ),
    );
  }
}
