import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/providers/focus_timer_provider.dart';

class FocusTimerScreen extends StatefulWidget {
  const FocusTimerScreen({super.key});

  @override
  State<FocusTimerScreen> createState() => _FocusTimerScreenState();
}

class _FocusTimerScreenState extends State<FocusTimerScreen> {
  late TextEditingController _activityCtrl;
  int _selectedDuration = 10; // Default 10 minutes
  String _selectedCategory = 'reading';

  @override
  void initState() {
    super.initState();
    _activityCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _activityCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text(
          '⏱️ Focus Timer',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<FocusTimerProvider>(
        builder: (context, focusProvider, _) {
          if (focusProvider.isTimerActive && focusProvider.currentSession != null) {
            return _buildActiveTimer(context, focusProvider);
          }
          return _buildSetupScreen(context, focusProvider);
        },
      ),
    );
  }

  Widget _buildSetupScreen(BuildContext context, FocusTimerProvider focusProvider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Fokus Time Setup',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 24),

          // Activity input
          Text(
            'Aktivitas',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _activityCtrl,
            decoration: InputDecoration(
              hintText: 'Contoh: Baca Al-Quran, Baca Buku, Coding',
              hintStyle: GoogleFonts.poppins(fontSize: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Duration selector
          Text(
            'Durasi (${_selectedDuration} menit)',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Slider(
            value: _selectedDuration.toDouble(),
            min: 1,
            max: 120,
            divisions: 119,
            label: '$_selectedDuration min',
            activeColor: AppColors.primary,
            onChanged: (value) {
              setState(() => _selectedDuration = value.toInt());
            },
          ),
          const SizedBox(height: 20),

          // Category selection
          Text(
            'Kategori',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildCategoryChip('📖 Membaca', 'reading'),
              _buildCategoryChip('📿 Ibadah', 'prayer'),
              _buildCategoryChip('💼 Kerja', 'work'),
              _buildCategoryChip('📚 Belajar', 'study'),
            ],
          ),
          const SizedBox(height: 40),

          // Start button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _activityCtrl.text.isEmpty
                  ? null
                  : () async {
                      await focusProvider.startFocusSession(
                        activity: _activityCtrl.text,
                        durationMinutes: _selectedDuration,
                        category: _selectedCategory,
                      );
                      setState(() {});
                    },
              icon: const Icon(Icons.play_arrow),
              label: Text(
                'Mulai Fokus',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveTimer(
    BuildContext context,
    FocusTimerProvider focusProvider,
  ) {
    final session = focusProvider.currentSession!;
    final remaining = focusProvider.remainingSeconds;
    final minutes = remaining ~/ 60;
    final seconds = remaining % 60;

    return Stack(
      children: [
        // Full-screen semi-transparent overlay
        Container(
          color: Colors.black.withValues(alpha: 0.3),
        ),

        // Timer display
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                session.activity,
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 40),

              // Countdown
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.4),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                    style: GoogleFonts.poppins(
                      fontSize: 64,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 60),

              // Music toggle
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          focusProvider.isMusicEnabled
                              ? Icons.music_note
                              : Icons.music_off,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          focusProvider.isMusicEnabled
                              ? '🎵 Musik Produktif'
                              : '🔇 Musik Off',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    Switch(
                      value: focusProvider.isMusicEnabled,
                      onChanged: (_) => focusProvider.toggleMusic(),
                      activeThumbColor: Colors.amber,
                      activeTrackColor: Colors.amber.withValues(alpha: 0.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // Controls
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () async {
                      if (focusProvider.isTimerActive) {
                        focusProvider.pauseTimer();
                      } else {
                        focusProvider.resumeTimer();
                      }
                    },
                    icon: Icon(
                      focusProvider.isTimerActive
                          ? Icons.pause
                          : Icons.play_arrow,
                    ),
                    label: Text(
                      focusProvider.isTimerActive ? 'Pause' : 'Resume',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: () async {
                      await focusProvider.cancelSession();
                      if (mounted) setState(() {});
                    },
                    icon: const Icon(Icons.close),
                    label: Text(
                      'Stop',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.danger,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),

              // Info
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Text(
                      '📵 Semua notifikasi dimatikan saat fokus',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '🎵 Link musik: youtube.com/R1r9nLYcqBU',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.amber,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryChip(String label, String category) {
    return ChoiceChip(
      label: Text(
        label,
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          color: _selectedCategory == category ? Colors.white : AppColors.textPrimary,
        ),
      ),
      selected: _selectedCategory == category,
      onSelected: (selected) {
        if (selected) {
          setState(() => _selectedCategory = category);
        }
      },
      backgroundColor: Colors.white,
      selectedColor: AppColors.primary,
    );
  }
}
