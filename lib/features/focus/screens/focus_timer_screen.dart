import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/providers/focus_timer_provider.dart';
import 'focus_history_screen.dart';

class FocusTimerScreen extends StatefulWidget {
  const FocusTimerScreen({super.key});

  @override
  State<FocusTimerScreen> createState() => _FocusTimerScreenState();
}

class _FocusTimerScreenState extends State<FocusTimerScreen> {
  late TextEditingController _activityCtrl;
  int _selectedDuration = 10; // Default 10 minutes
  String _selectedCategory = 'reading';
  bool _enablePomodoro = false; // Pomodoro mode toggle

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
          // ── Focus Statistics Banner ────────────────────────────────────────
          _buildStatsCard(focusProvider),
          const SizedBox(height: 24),

          // ── Quick Start Presets ────────────────────────────────────────────
          Text(
            'Quick Start',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildQuickStartButton(15, '⚡ 15 min'),
              _buildQuickStartButton(25, '🍅 25 min'),
              _buildQuickStartButton(45, '💪 45 min'),
              _buildQuickStartButton(60, '🚀 60 min'),
            ],
          ),
          const SizedBox(height: 24),

          // ── View History Button ────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const FocusHistoryScreen()),
                );
              },
              icon: const Icon(Icons.history),
              label: Text(
                'Lihat History',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: const BorderSide(color: AppColors.primary),
              ),
            ),
          ),
          const SizedBox(height: 32),

          Text(
            'Setup Custom',
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
            'Durasi ($_selectedDuration menit)',
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
          const SizedBox(height: 24),

          // ── Pomodoro Toggle ────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _enablePomodoro ? AppColors.primary.withValues(alpha: 0.1) : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _enablePomodoro ? AppColors.primary : Colors.grey.shade300,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🍅 Pomodoro Technique',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '25 min fokus + 5 min istirahat',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                Switch(
                  value: _enablePomodoro,
                  onChanged: (value) {
                    setState(() {
                      _enablePomodoro = value;
                      if (value) {
                        _selectedDuration = 25; // Auto-set to 25 min
                      }
                    });
                  },
                  activeThumbColor: AppColors.primary,
                  activeTrackColor: AppColors.primary.withValues(alpha: 0.3),
                ),
              ],
            ),
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

  String _formatFocusTime(int totalSeconds) {
    final h = totalSeconds ~/ 3600;
    final m = (totalSeconds % 3600) ~/ 60;
    final s = totalSeconds % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String _getTimeLabel(int totalSeconds) {
    final h = totalSeconds ~/ 3600;
    if (h > 0) {
      return 'Jam:Menit:Detik';
    }
    return 'Menit:Detik';
  }

  Widget _buildActiveTimer(
    BuildContext context,
    FocusTimerProvider focusProvider,
  ) {
    final session = focusProvider.currentSession!;
    final remaining = focusProvider.remainingSeconds;

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

              // Countdown dengan progress ring
              Stack(
                alignment: Alignment.center,
                children: [
                  // Progress ring background
                  Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),

                  // Animated pulsing countdown
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: const Duration(seconds: 1),
                    onEnd: () {
                      // Loop animation every second
                    },
                    builder: (context, value, child) {
                      return Container(
                        width: 200 + (value * 10),
                        height: 200 + (value * 10),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.5 - (value * 0.2)),
                              blurRadius: 20 + (value * 10),
                              spreadRadius: 2 + (value * 3),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _formatFocusTime(remaining),
                                style: GoogleFonts.poppins(
                                  fontSize: 64,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _getTimeLabel(remaining),
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: Colors.white.withValues(alpha: 0.6),
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                '⏱️ Berjalan',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.white.withValues(alpha: 0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
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

              // Controls: Selesai (Complete) & Stop
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: remaining <= 0
                        ? () async {
                            await focusProvider.completeSession();
                            if (mounted) setState(() {});
                          }
                        : null,
                    icon: const Icon(Icons.check_circle),
                    label: Text(
                      'Selesai',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      disabledBackgroundColor: Colors.grey,
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
                      'Batalkan',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.danger,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),

              // Info & Anti-Cheat Warning
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Text(
                      '⏱️ Waktu harus selesai sepenuhnya untuk mendapat poin',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.yellow,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '⚠️ Manipulasi waktu sistem akan membatalkan reward',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 8),
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

  /// Stats card dengan streak, today focus time, dll
  Widget _buildStatsCard(FocusTimerProvider focusProvider) {
    final streak = focusProvider.getFocusStreak();
    final todayMinutes = focusProvider.getTodayFocusTime();
    final weekMinutes = focusProvider.getWeekFocusTime();
    final avgMinutes = focusProvider.getAverageFocusTime();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary.withValues(alpha: 0.9), AppColors.primaryLight.withValues(alpha: 0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🔥 Focus Streak',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$streak days',
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem('Hari Ini', '$todayMinutes min', '⏱️'),
              _buildStatItem('Minggu Ini', '$weekMinutes min', '📊'),
              _buildStatItem('Rata-rata', '$avgMinutes min', '📈'),
            ],
          ),
        ],
      ),
    );
  }

  /// Stat item untuk card
  Widget _buildStatItem(String label, String value, String emoji) {
    return Expanded(
      child: Column(
        children: [
          Text(
            emoji,
            style: const TextStyle(fontSize: 20),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: Colors.white.withValues(alpha: 0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Quick start button
  Widget _buildQuickStartButton(int minutes, String label) {
    return SizedBox(
      width: (MediaQuery.of(context).size.width - 60) / 2,
      child: OutlinedButton(
        onPressed: () {
          setState(() => _selectedDuration = minutes);
          // Auto-focus pada activity field
          FocusScope.of(context).requestFocus();
        },
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}
