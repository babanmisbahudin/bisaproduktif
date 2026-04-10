import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/habit_model.dart';
import '../../../data/providers/focus_timer_provider.dart';
import '../../../data/providers/habit_provider.dart';
import '../../../data/providers/goal_provider.dart';
import 'focus_history_screen.dart';

class FocusTimerScreen extends StatefulWidget {
  /// Habit yang dihubungkan — form akan pre-fill & habit otomatis dicentang saat timer selesai
  final HabitModel? linkedHabit;

  const FocusTimerScreen({super.key, this.linkedHabit});

  @override
  State<FocusTimerScreen> createState() => _FocusTimerScreenState();
}

class _FocusTimerScreenState extends State<FocusTimerScreen> {
  late TextEditingController _activityCtrl;
  int _selectedDuration = 10;
  String _selectedCategory = 'reading';
  bool _enablePomodoro = false;

  // ── Helpers: deteksi durasi & kategori dari nama habit ────────────────────

  /// Deteksi durasi dari judul habit, fallback ke default per kategori
  static int _detectDuration(String title, HabitCategory cat) {
    final t = title.toLowerCase();
    final minMatch = RegExp(r'(\d+)\s*menit').firstMatch(t);
    if (minMatch != null) { return int.parse(minMatch.group(1)!).clamp(1, 120); }
    final jamMatch = RegExp(r'(\d+)\s*jam').firstMatch(t);
    if (jamMatch != null) { return (int.parse(jamMatch.group(1)!) * 60).clamp(1, 120); }
    return switch (cat) {
      HabitCategory.ringan      => 10,
      HabitCategory.sedang      => 20,
      HabitCategory.berat       => 30,
      HabitCategory.sangatBerat => 45,
    };
  }

  /// Petakan nama habit ke kategori timer
  static String _detectTimerCategory(String title) {
    final t = title.toLowerCase();
    if (['sholat', 'ngaji', 'quran', 'dzikir', 'puasa', 'tahajud', 'dhuha',
         'tarawih', 'doa', 'ibadah'].any(t.contains)) { return 'prayer'; }
    if (['belajar', 'baca buku', 'baca jurnal', 'coding', 'koding', 'nulis',
         'menulis', 'review materi', 'latihan soal'].any(t.contains)) { return 'study'; }
    if (['olahraga', 'gym', 'lari', 'jogging', 'push up', 'sit up', 'squat',
         'yoga', 'renang', 'sepeda', 'fitness', 'angkat'].any(t.contains)) { return 'exercise'; }
    if (['kerja', 'deadline', 'meeting', 'proyek', 'rapat',
         'presentasi', 'laporan'].any(t.contains)) { return 'work'; }
    return 'reading';
  }

  // ── Listener: auto-centang habit saat timer selesai ──────────────────────

  void _onTimerChanged() {
    if (!mounted) return;
    final focusProvider = context.read<FocusTimerProvider>();

    // Handle auto-centang habit (jika timer dari habit card)
    final completedHabitId = focusProvider.lastCompletedHabitId;
    if (completedHabitId != null) {
      focusProvider.consumeCompletedHabitId();
      _autoCompleteHabit(completedHabitId);
      return; // koin dari habit, tidak perlu kredit focus reward
    }

    // Handle kredit koin focus session (jika tidak ada linked habit)
    final focusReward = focusProvider.pendingFocusReward;
    if (focusReward > 0) {
      focusProvider.consumeFocusReward();
      _creditFocusReward(focusReward);
    }
  }

  Future<void> _autoCompleteHabit(String habitId) async {
    if (!mounted) return;
    final habitProvider = context.read<HabitProvider>();
    final goalProvider = context.read<GoalProvider>();
    final ok = await habitProvider.completeHabit(habitId, goalProvider: goalProvider);
    if (!mounted) return;

    final habitTitle = widget.linkedHabit?.title ?? 'Habit';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? '✅ "$habitTitle" otomatis dicentang!'
              : '⚠️ Habit sudah dicentang hari ini',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: ok ? Colors.green : Colors.orange,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _creditFocusReward(int coins) async {
    if (!mounted) return;
    final habitProvider = context.read<HabitProvider>();
    await habitProvider.addCoins(coins);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '🎉 Sesi fokus selesai! +$coins koin',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    final habit = widget.linkedHabit;
    if (habit != null) {
      _activityCtrl = TextEditingController(text: habit.title);
      _selectedDuration = _detectDuration(habit.title, habit.category);
      _selectedCategory = _detectTimerCategory(habit.title);
    } else {
      _activityCtrl = TextEditingController();
    }

    // Daftarkan listener untuk auto-centang habit & kredit koin saat timer selesai
    // Langsung di initState agar tidak ada race condition dengan dispose
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<FocusTimerProvider>().addListener(_onTimerChanged);
      }
    });
  }

  @override
  void dispose() {
    context.read<FocusTimerProvider>().removeListener(_onTimerChanged);
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
          // ── Banner linked habit ────────────────────────────────────────────
          if (widget.linkedHabit != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  const Text('⏱️', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Terhubung ke habit:',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          widget.linkedHabit!.title,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                        Text(
                          '✅ Habit otomatis dicentang saat timer selesai',
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
            ),
            const SizedBox(height: 20),
          ],

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
              _buildCategoryChip('🏃 Olahraga', 'exercise'),
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
                        linkedHabitId: widget.linkedHabit?.id,
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
    final totalSeconds = session.durationSeconds;
    final progress = totalSeconds > 0 ? (totalSeconds - remaining) / totalSeconds : 1.0;
    final isDone = remaining <= 0;

    final categoryEmoji = switch (session.category) {
      'prayer'   => '📿',
      'study'    => '📚',
      'work'     => '💼',
      'exercise' => '🏃',
      _          => '📖',
    };

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1A2E1A), Color(0xFF2C4A2C), Color(0xFF1A2E1A)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 24),

              // ── Header: kategori + nama aktivitas ──────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(categoryEmoji, style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        session.activity,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Status badge
              Text(
                isDone ? '🎉 Waktu Habis! Kamu Luar Biasa!' : '🔥 Mode Fokus Aktif',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: isDone
                      ? const Color(0xFFFFD700)
                      : Colors.white.withValues(alpha: 0.6),
                  fontWeight: isDone ? FontWeight.w700 : FontWeight.w400,
                ),
              ),

              const Spacer(),

              // ── Lingkaran progress ──────────────────────────────────────────
              SizedBox(
                width: 260,
                height: 260,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Arc progress background
                    SizedBox.expand(
                      child: CircularProgressIndicator(
                        value: 1.0,
                        strokeWidth: 10,
                        color: Colors.white.withValues(alpha: 0.08),
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    // Arc progress foreground
                    SizedBox.expand(
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: progress),
                        duration: const Duration(milliseconds: 800),
                        curve: Curves.easeOutCubic,
                        builder: (_, val, _) => CircularProgressIndicator(
                          value: val,
                          strokeWidth: 10,
                          color: isDone
                              ? const Color(0xFFFFD700)
                              : AppColors.primary,
                          strokeCap: StrokeCap.round,
                        ),
                      ),
                    ),
                    // Glowing inner circle
                    Container(
                      width: 220,
                      height: 220,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.04),
                        boxShadow: [
                          BoxShadow(
                            color: (isDone ? const Color(0xFFFFD700) : AppColors.primary)
                                .withValues(alpha: 0.25),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                    ),
                    // Countdown text
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _formatFocusTime(remaining),
                          style: GoogleFonts.poppins(
                            fontSize: remaining >= 3600 ? 44 : 56,
                            fontWeight: FontWeight.w800,
                            color: isDone
                                ? const Color(0xFFFFD700)
                                : Colors.white,
                            height: 1,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _getTimeLabel(remaining),
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Colors.white.withValues(alpha: 0.45),
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${(progress * 100).toInt()}% selesai',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // ── Info singkat ───────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildInfoChip('⏱️', '${session.durationSeconds ~/ 60} menit'),
                  const SizedBox(width: 10),
                  _buildInfoChip('📵', 'Mode Fokus'),
                  const SizedBox(width: 10),
                  _buildInfoChip('🪙', 'Reward menanti'),
                ],
              ),

              const SizedBox(height: 28),

              // ── Tombol aksi ────────────────────────────────────────────────
              Row(
                children: [
                  // Batalkan
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            title: Text('Batalkan sesi?', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
                            content: Text(
                              'Progres sesi ini akan hilang dan reward tidak akan didapat.',
                              style: GoogleFonts.poppins(fontSize: 13),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: Text('Lanjutkan', style: GoogleFonts.poppins(color: AppColors.primary, fontWeight: FontWeight.w700)),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: Text('Batalkan', style: GoogleFonts.poppins(color: Colors.red)),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await focusProvider.cancelSession();
                          if (mounted) setState(() {});
                        }
                      },
                      icon: const Icon(Icons.close, size: 18),
                      label: Text('Batalkan', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white70,
                        side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Selesai
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: isDone
                          ? () async {
                              await focusProvider.completeSession();
                              if (mounted) setState(() {});
                            }
                          : null,
                      icon: Icon(isDone ? Icons.emoji_events : Icons.lock_clock, size: 20),
                      label: Text(
                        isDone ? 'Ambil Reward!' : 'Menunggu selesai...',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDone ? const Color(0xFFFFD700) : Colors.white.withValues(alpha: 0.12),
                        foregroundColor: isDone ? Colors.black : Colors.white38,
                        disabledBackgroundColor: Colors.white.withValues(alpha: 0.08),
                        disabledForegroundColor: Colors.white24,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: isDone ? 4 : 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(String emoji, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.6),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
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
