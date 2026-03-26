import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_responsive.dart';
import '../../../core/painters/growing_plant_painter.dart';

class OnboardingNamePage extends StatefulWidget {
  final VoidCallback onComplete;

  const OnboardingNamePage({super.key, required this.onComplete});

  @override
  State<OnboardingNamePage> createState() => _OnboardingNamePageState();
}

class _OnboardingNamePageState extends State<OnboardingNamePage> {
  late TextEditingController _nameController;
  String _name = '';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _nameController.addListener(() {
      setState(() {
        _name = _nameController.text;
      });
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveName() async {
    if (_name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mohon masukkan nama Anda')),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', _name);

    if (mounted) {
      widget.onComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final plantGrowth = (_name.length / 10.0).clamp(0.0, 1.0);

    return Scaffold(
      body: Container(
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
          child: Column(
            children: [
              // Header
              Padding(
                padding: EdgeInsets.only(
                  top: context.padding(24),
                  bottom: context.padding(16),
                ),
                child: Text(
                  'Siapa nama kamu?',
                  style: GoogleFonts.poppins(
                    fontSize: context.fontSize(28),
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              Text(
                'Ketik nama mu untuk melihat tanaman tumbuh!',
                style: GoogleFonts.poppins(
                  fontSize: context.fontSize(14),
                  fontWeight: FontWeight.w400,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),

              // Plant animation
              Expanded(
                child: Center(
                  child: SizedBox(
                    width: double.infinity,
                    height: 300,
                    child: CustomPaint(
                      painter: GrowingPlantPainter(growthProgress: plantGrowth),
                    ),
                  ),
                ),
              ),

              // Input section
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: context.padding(24),
                  vertical: context.padding(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nama Kamu',
                      style: GoogleFonts.poppins(
                        fontSize: context.fontSize(14),
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: context.padding(8)),
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        hintText: 'Masukkan nama kamu...',
                        hintStyle: GoogleFonts.poppins(
                          fontSize: context.fontSize(14),
                          color: AppColors.textSecondary,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(context.radius(12)),
                          borderSide: const BorderSide(
                            color: Color(0xFFDDD9D0),
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(context.radius(12)),
                          borderSide: BorderSide(
                            color: AppColors.primary,
                            width: 2,
                          ),
                        ),
                        contentPadding: EdgeInsets.all(context.padding(12)),
                      ),
                      style: GoogleFonts.poppins(
                        fontSize: context.fontSize(14),
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: context.padding(12)),
                    Text(
                      'Panjang nama: ${_name.length}/10',
                      style: GoogleFonts.poppins(
                        fontSize: context.fontSize(12),
                        fontWeight: FontWeight.w400,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
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
                    onPressed: _name.isEmpty ? null : _saveName,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _name.isEmpty
                          ? Colors.grey[300]
                          : AppColors.primary,
                      foregroundColor: Colors.white,
                      disabledForegroundColor: Colors.grey[500],
                      padding: EdgeInsets.symmetric(
                        vertical: context.padding(16),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(context.radius(12)),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Lanjutkan',
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
      ),
    );
  }
}
