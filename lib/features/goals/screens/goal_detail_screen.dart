import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/habit_difficulty_detector.dart';
import '../../../data/models/goal_model.dart';
import '../../../data/models/habit_model.dart';
import '../../../data/providers/goal_provider.dart';
import '../../../data/providers/habit_provider.dart';

class GoalDetailScreen extends StatefulWidget {
  final GoalModel goal;

  const GoalDetailScreen({super.key, required this.goal});

  @override
  State<GoalDetailScreen> createState() => _GoalDetailScreenState();
}

class _GoalDetailScreenState extends State<GoalDetailScreen> {
  final _habitNameCtrl = TextEditingController();
  bool _showAddForm = false;
  HabitCategory _detectedCategory = HabitCategory.sedang;

  @override
  void initState() {
    super.initState();
    _habitNameCtrl.addListener(_onTitleChanged);
  }

  void _onTitleChanged() {
    final detected = HabitDifficultyDetector.detect(_habitNameCtrl.text);
    if (detected != _detectedCategory) {
      setState(() => _detectedCategory = detected);
    }
  }

  @override
  void dispose() {
    _habitNameCtrl.removeListener(_onTitleChanged);
    _habitNameCtrl.dispose();
    super.dispose();
  }

  // Habit yang sudah linked ke goal ini
  List<HabitModel> _linkedHabits(HabitProvider habitProvider) {
    return habitProvider.habits
        .where((h) => widget.goal.linkedHabitIds.contains(h.id))
        .toList();
  }

  // Habit yang BELUM linked ke goal manapun (bisa dipilih)
  List<HabitModel> _availableHabits(
      HabitProvider habitProvider, GoalProvider goalProvider) {
    return habitProvider.habits
        .where((h) => h.goalId == null && !goalProvider.isHabitLinked(h.id))
        .toList();
  }

  Future<void> _addNewHabit() async {
    final title = _habitNameCtrl.text.trim();
    if (title.isEmpty) return;

    final habitProvider = context.read<HabitProvider>();
    final goalProvider = context.read<GoalProvider>();

    final habitId = await habitProvider.addHabitToGoal(
      title: title,
      category: _detectedCategory,
      color: widget.goal.color,
      goalId: widget.goal.id,
    );

    if (habitId != null) {
      await goalProvider.linkHabitToGoal(
        goalId: widget.goal.id,
        habitId: habitId,
      );
      _habitNameCtrl.clear();
      setState(() => _showAddForm = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"$title" ditambahkan ke goal',
                style: GoogleFonts.poppins()),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  Future<void> _linkExistingHabit(String habitId, String habitTitle) async {
    final habitProvider = context.read<HabitProvider>();
    final goalProvider = context.read<GoalProvider>();

    // Simpan goalId ke Hive lewat method khusus
    await habitProvider.setHabitGoalId(habitId, widget.goal.id);

    await goalProvider.linkHabitToGoal(
      goalId: widget.goal.id,
      habitId: habitId,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"$habitTitle" ditautkan ke goal',
              style: GoogleFonts.poppins()),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<void> _unlinkHabit(String habitId, String habitTitle) async {
    final habitProvider = context.read<HabitProvider>();
    final goalProvider = context.read<GoalProvider>();

    await habitProvider.unlinkHabitFromGoal(habitId);
    await goalProvider.unlinkHabitFromGoal(
        goalId: widget.goal.id, habitId: habitId);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"$habitTitle" dilepas dari goal',
              style: GoogleFonts.poppins()),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<HabitProvider, GoalProvider>(
      builder: (context, habitProvider, goalProvider, _) {
        // Ambil goal terbaru dari provider supaya progress selalu update
        final goal =
            goalProvider.getGoalById(widget.goal.id) ?? widget.goal;
        final linkedHabits = _linkedHabits(habitProvider);
        final availableHabits = _availableHabits(habitProvider, goalProvider);
        final percent = (goal.progressPercent * 100).round();

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: goal.color,
            foregroundColor: Colors.white,
            elevation: 0,
            title: Text(
              goal.title,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // ── Progress Card ─────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: goal.color,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Progress Goal',
                          style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: Colors.white70,
                              fontWeight: FontWeight.w500),
                        ),
                        Text(
                          '$percent%',
                          style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: Colors.white),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: goal.progressPercent,
                        minHeight: 10,
                        backgroundColor: Colors.white.withValues(alpha: 0.25),
                        valueColor:
                            const AlwaysStoppedAnimation(Colors.white),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${linkedHabits.length} habit aktif',
                          style: GoogleFonts.poppins(
                              fontSize: 11, color: Colors.white70),
                        ),
                        if (goal.deadline != null)
                          Text(
                            goal.isCompleted
                                ? '✅ Goal selesai!'
                                : '📅 ${goal.daysLeft} hari lagi',
                            style: GoogleFonts.poppins(
                                fontSize: 11, color: Colors.white70),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Info cara kerja ───────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: Colors.blue.withValues(alpha: 0.2)),
                ),
                child: Text(
                  '💡 Centang habit di tab Daily Habits setiap hari → progress goal naik otomatis + dapat koin!',
                  style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.blue.shade700,
                      height: 1.5),
                ),
              ),
              const SizedBox(height: 10),
              // ── Bonus durasi ──────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: goal.durationMultiplier > 1.0
                      ? Colors.amber.withValues(alpha: 0.1)
                      : Colors.grey.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: goal.durationMultiplier > 1.0
                        ? Colors.amber.withValues(alpha: 0.35)
                        : Colors.grey.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      goal.durationMultiplier > 1.0 ? '🎯' : '📅',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Bonus deadline: ${goal.durationBonusLabel}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: goal.durationMultiplier > 1.0
                              ? Colors.amber.shade800
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Habit Terkait ─────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Habit Terkait',
                    style: GoogleFonts.poppins(
                        fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  if (!goal.isCompleted)
                    TextButton.icon(
                      onPressed: () =>
                          setState(() => _showAddForm = !_showAddForm),
                      icon: Icon(
                          _showAddForm ? Icons.close : Icons.add,
                          size: 16),
                      label: Text(
                          _showAddForm ? 'Batal' : 'Tambah',
                          style: GoogleFonts.poppins(fontSize: 13)),
                      style: TextButton.styleFrom(
                          foregroundColor: goal.color),
                    ),
                ],
              ),
              const SizedBox(height: 8),

              // Form tambah habit baru
              if (_showAddForm && !goal.isCompleted) ...[
                _buildAddHabitForm(goal),
                const SizedBox(height: 16),
              ],

              // List habit terkait
              if (linkedHabits.isEmpty && !_showAddForm)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: Text(
                      'Belum ada habit. Tap "Tambah" untuk mulai.',
                      style: GoogleFonts.poppins(
                          fontSize: 13, color: AppColors.textSecondary),
                    ),
                  ),
                )
              else
                ...linkedHabits.map((habit) =>
                    _buildLinkedHabitTile(habit, goal)),

              // ── Pilih dari habit yang ada ─────────────────────────────────
              if (availableHabits.isNotEmpty && !goal.isCompleted) ...[
                const SizedBox(height: 20),
                Text(
                  'Atau Pilih Habit yang Ada',
                  style: GoogleFonts.poppins(
                      fontSize: 14, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                ...availableHabits.map((habit) =>
                    _buildAvailableHabitTile(habit)),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildAddHabitForm(GoalModel goal) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Nama Habit',
              style: GoogleFonts.poppins(
                  fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(
            controller: _habitNameCtrl,
            decoration: InputDecoration(
              hintText: 'Contoh: Sholat Subuh, Ngaji, Olahraga...',
              hintStyle: GoogleFonts.poppins(fontSize: 13),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
            ),
          ),
          const SizedBox(height: 12),
          // Auto-detect difficulty — tidak bisa dipilih manual
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _detectedCategory == HabitCategory.sangatBerat
                  ? Colors.purple.shade50
                  : _detectedCategory == HabitCategory.berat
                      ? Colors.orange.shade50
                      : _detectedCategory == HabitCategory.ringan
                          ? Colors.green.shade50
                          : Colors.blue.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Text(_detectedCategory.emoji,
                    style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tingkat: ${_detectedCategory.label}  ·  +${_detectedCategory.baseCoins} koin/hari',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Ditentukan otomatis berdasarkan nama kegiatan',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _addNewHabit,
              style: ElevatedButton.styleFrom(
                backgroundColor: goal.color,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: Text('Tambah Habit',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkedHabitTile(HabitModel habit, GoalModel goal) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      child: ListTile(
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: goal.color.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Center(
              child: Text(habit.category.emoji,
                  style: const TextStyle(fontSize: 18))),
        ),
        title: Text(
          habit.title,
          style: GoogleFonts.poppins(
              fontSize: 13, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${habit.category.label} · +${habit.category.baseCoins} koin/hari',
          style: GoogleFonts.poppins(
              fontSize: 11, color: AppColors.textSecondary),
        ),
        trailing: habit.isCompletedOnDate
            ? const Icon(Icons.check_circle_rounded,
                color: AppColors.success, size: 22)
            : IconButton(
                icon: const Icon(Icons.link_off_rounded,
                    color: AppColors.danger, size: 20),
                onPressed: goal.isCompleted
                    ? null
                    : () => _unlinkHabit(habit.id, habit.title),
                tooltip: 'Lepas dari goal',
              ),
      ),
    );
  }

  Widget _buildAvailableHabitTile(HabitModel habit) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ListTile(
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            shape: BoxShape.circle,
          ),
          child: Center(
              child: Text(habit.category.emoji,
                  style: const TextStyle(fontSize: 18))),
        ),
        title: Text(
          habit.title,
          style: GoogleFonts.poppins(
              fontSize: 13, fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          '${habit.category.label} · +${habit.category.baseCoins} koin/hari',
          style: GoogleFonts.poppins(
              fontSize: 11, color: AppColors.textSecondary),
        ),
        trailing: ElevatedButton(
          onPressed: () => _linkExistingHabit(habit.id, habit.title),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
          ),
          child:
              Text('Pilih', style: GoogleFonts.poppins(fontSize: 12)),
        ),
      ),
    );
  }
}
