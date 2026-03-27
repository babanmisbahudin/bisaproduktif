import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../services/consent_service.dart';

class ConsentDialog extends StatefulWidget {
  final VoidCallback? onConsentGiven;

  const ConsentDialog({
    super.key,
    this.onConsentGiven,
  });

  @override
  State<ConsentDialog> createState() => _ConsentDialogState();
}

class _ConsentDialogState extends State<ConsentDialog> {
  bool _analyticsConsent = true;
  bool _personalizedAdsConsent = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'Preferensi Privasi',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Kami menghormati privasi Anda',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 20),

              // Info text
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'BisaProduktif menggunakan cookies dan teknologi tracking untuk memberikan pengalaman terbaik. Anda dapat mengatur preferensi di bawah ini.',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Analytics consent
              _buildConsentOption(
                title: 'Analytics & Performance',
                description: 'Membantu kami memahami cara Anda menggunakan app',
                value: _analyticsConsent,
                onChanged: (val) => setState(() => _analyticsConsent = val),
              ),
              const SizedBox(height: 12),

              // Personalized ads consent
              _buildConsentOption(
                title: 'Iklan yang Dipersonalisasi',
                description: 'Tampilkan iklan yang relevan dengan minat Anda',
                value: _personalizedAdsConsent,
                onChanged: (val) => setState(() => _personalizedAdsConsent = val),
              ),
              const SizedBox(height: 24),

              // Info text untuk EEA
              Text(
                'ℹ️ Sesuai dengan GDPR, Anda memiliki hak untuk mengubah preferensi kapan saja di Pengaturan > Privasi',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        // Reject - hanya essential
                        _saveConsent(false);
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'Reject',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // Accept
                        _saveConsent(true);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'Accept',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConsentOption({
    required String title,
    required String description,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: value,
            onChanged: (val) => onChanged(val ?? false),
            activeColor: AppColors.primary,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveConsent(bool consent) async {
    await ConsentService.setConsent(consent);
    if (mounted) {
      Navigator.pop(context);
      widget.onConsentGiven?.call();
    }
  }
}
