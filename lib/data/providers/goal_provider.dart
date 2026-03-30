import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/goal_model.dart';
import '../models/habit_model.dart';

class GoalProvider extends ChangeNotifier {
  static const String _boxName = 'goals';

  late Box<GoalModel> _box;
  List<GoalModel> _goals = [];
  bool _isLoaded = false;

  List<GoalModel> get goals => List.unmodifiable(_goals);
  bool get isLoaded => _isLoaded;

  List<GoalModel> get activeGoals =>
      _goals.where((g) => g.status == GoalStatus.active).toList();
  List<GoalModel> get completedGoals =>
      _goals.where((g) => g.isCompleted).toList();

  int get totalGoals => _goals.length;
  int get completedCount => completedGoals.length;

  // ── Init ──────────────────────────────────────────────────────────────────

  Future<void> init() async {
    _box = await Hive.openBox<GoalModel>(_boxName);
    _loadGoals();
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> clearUserData() async {
    _goals.clear();
    await _box.clear();
    _isLoaded = false;
    notifyListeners();
  }

  void _loadGoals() {
    _goals = _box.values.toList()
      ..sort((a, b) => a.order.compareTo(b.order));
  }

  // ── Add Goal ──────────────────────────────────────────────────────────────

  Future<void> addGoal({
    required String title,
    required Color color,
    DateTime? deadline,
  }) async {
    final goal = GoalModel(
      id: const Uuid().v4(),
      title: title,
      linkedHabitIds: [],
      coins: 50, // bonus tetap saat goal selesai
      status: GoalStatus.active,
      colorValue: color.toARGB32(),
      createdAt: DateTime.now(),
      deadline: deadline,
      order: _goals.length,
    );

    await _box.put(goal.id, goal);
    _goals.add(goal);
    _goals.sort((a, b) => a.order.compareTo(b.order));
    notifyListeners();
  }

  // ── Link / Unlink Habit ───────────────────────────────────────────────────

  /// Tambahkan habit ke goal (lock)
  Future<void> linkHabitToGoal({
    required String goalId,
    required String habitId,
  }) async {
    final goal = _goals.firstWhere((g) => g.id == goalId);
    if (goal.linkedHabitIds.contains(habitId)) return;
    goal.linkedHabitIds.add(habitId);
    await _box.put(goal.id, goal);
    notifyListeners();
  }

  /// Lepas habit dari goal (unlock)
  Future<void> unlinkHabitFromGoal({
    required String goalId,
    required String habitId,
  }) async {
    final goal = _goals.firstWhere((g) => g.id == goalId);
    goal.linkedHabitIds.remove(habitId);
    await _box.put(goal.id, goal);
    notifyListeners();
  }

  // ── Progress ─────────────────────────────────────────────────────────────

  /// Dipanggil oleh HabitProvider setiap kali habit dicentang
  Future<void> syncProgressFromHabits(
    String? goalId,
    List<HabitModel> allHabits, {
    dynamic habitProvider, // untuk beri bonus koin saat goal selesai
  }) async {
    if (goalId == null) return;

    GoalModel? goal;
    try {
      goal = _goals.firstWhere((g) => g.id == goalId);
    } catch (_) {
      return;
    }

    if (goal.isCompleted) return; // sudah selesai, tidak perlu update

    final progress = _calculateProgress(goal, allHabits);
    goal.progressPercent = progress;

    // Goal selesai hanya jika deadline sudah terlewat
    // (progress >= 1.0 hampir mustahil karena pakai total durasi penuh)
    final now = DateTime.now();
    final deadlinePassed =
        goal.deadline != null && now.isAfter(goal.deadline!);
    if (deadlinePassed && !goal.isCompleted) {
      goal.status = GoalStatus.completed;
      // Beri bonus koin proporsional berdasarkan progress akhir
      if (habitProvider != null && progress > 0) {
        final bonusCoins = (goal.coins * progress).round().clamp(10, goal.coins);
        await habitProvider.addCoins(bonusCoins);
      }
    }

    await _box.put(goal.id, goal);
    notifyListeners();
  }

  /// Hitung progress berdasarkan history centangan habit.
  ///
  /// Formula: actualCompletions / (totalDays × habitCount)
  /// - totalDays = selisih hari dari createdAt sampai deadline (atau 90 hari default)
  /// - Ini memastikan hari pertama cek = sebagian kecil %, bukan langsung 100%
  double _calculateProgress(GoalModel goal, List<HabitModel> allHabits) {
    if (goal.linkedHabitIds.isEmpty) return 0.0;

    final linkedHabits = allHabits
        .where((h) => goal.linkedHabitIds.contains(h.id))
        .toList();

    if (linkedHabits.isEmpty) return 0.0;

    // Target durasi penuh: creation → deadline (atau 90 hari jika tidak ada deadline)
    final effectiveDeadline =
        goal.deadline ?? goal.createdAt.add(const Duration(days: 90));
    final totalDays =
        effectiveDeadline.difference(goal.createdAt).inDays.clamp(1, 99999);

    final expectedTotal = totalDays * linkedHabits.length;

    // Hitung total centangan sejak goal dibuat (sampai hari ini)
    int actualTotal = 0;
    for (final habit in linkedHabits) {
      actualTotal += habit.completionTimestamps.where((ts) {
        final dt = DateTime.tryParse(ts);
        return dt != null && !dt.isBefore(goal.createdAt);
      }).length;
    }

    return (actualTotal / expectedTotal).clamp(0.0, 1.0);
  }

  // ── Edit Goal ─────────────────────────────────────────────────────────────

  Future<void> updateGoalTitle({
    required String goalId,
    required String newTitle,
  }) async {
    final goal = _goals.firstWhere((g) => g.id == goalId);
    goal.title = newTitle;
    await _box.put(goal.id, goal);
    notifyListeners();
  }

  Future<void> updateGoalDeadline({
    required String goalId,
    DateTime? deadline,
  }) async {
    final goal = _goals.firstWhere((g) => g.id == goalId);
    goal.deadline = deadline;
    await _box.put(goal.id, goal);
    notifyListeners();
  }

  Future<void> updateGoalColor({
    required String goalId,
    required Color color,
  }) async {
    final goal = _goals.firstWhere((g) => g.id == goalId);
    goal.colorValue = color.toARGB32();
    await _box.put(goal.id, goal);
    notifyListeners();
  }

  // ── Delete Goal ───────────────────────────────────────────────────────────

  Future<void> deleteGoal({
    required String goalId,
    dynamic habitProvider, // untuk unlink habits
  }) async {
    final goal = _goals.firstWhere((g) => g.id == goalId);

    // Unlink semua habit dari goal ini
    if (habitProvider != null) {
      for (final habitId in List<String>.from(goal.linkedHabitIds)) {
        await habitProvider.unlinkHabitFromGoal(habitId);
      }
    }

    _goals.removeWhere((g) => g.id == goalId);
    await _box.delete(goalId);

    // Reorder
    for (int i = 0; i < _goals.length; i++) {
      _goals[i].order = i;
      await _box.put(_goals[i].id, _goals[i]);
    }

    notifyListeners();
  }

  // ── Getters untuk UI ──────────────────────────────────────────────────────

  GoalModel? getGoalById(String id) {
    try {
      return _goals.firstWhere((g) => g.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Ambil duration multiplier koin untuk goal tertentu
  double getDurationMultiplier(String goalId) {
    return getGoalById(goalId)?.durationMultiplier ?? 1.0;
  }

  /// Cek apakah sebuah habit sudah di-lock ke goal manapun
  bool isHabitLinked(String habitId) {
    return _goals.any((g) => g.linkedHabitIds.contains(habitId));
  }

  /// Ambil goal yang meng-link habit tertentu
  GoalModel? getGoalForHabit(String habitId) {
    try {
      return _goals.firstWhere((g) => g.linkedHabitIds.contains(habitId));
    } catch (_) {
      return null;
    }
  }
}
