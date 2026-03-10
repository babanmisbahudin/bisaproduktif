import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/content_validator.dart';
import '../models/goal_model.dart';

class GoalProvider extends ChangeNotifier {
  static const String _boxName = 'goals';

  late Box<GoalModel> _box;
  List<GoalModel> _goals = [];
  bool _isLoaded = false;

  List<GoalModel> get goals => List.unmodifiable(_goals);
  bool get isLoaded => _isLoaded;

  List<GoalModel> get activeGoals =>
      _goals.where((g) => g.status == GoalStatus.active).toList();
  List<GoalModel> get pendingReviewGoals =>
      _goals.where((g) => g.status == GoalStatus.sentForReview).toList();
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
    // Removed: new users start with empty goals
  }

  // ── CRUD ─────────────────────────────────────────────────────────────────

  Future<ValidationResult> addGoal({
    required String title,
    required String targetDescription,
    required int coins,
    required Color color,
    DateTime? deadline,
    int? durationMonths,
    dynamic habitProvider,
  }) async {
    // 1. Validate title
    final existingTitles = _goals.map((g) => g.title).toList();
    final titleResult = ContentValidator.validateTitle(
      title,
      existingTitles: existingTitles,
    );

    if (!titleResult.isValid) {
      if (titleResult.trustPenalty > 0 && habitProvider != null) {
        habitProvider.applyTrustPenaltyPublic(
          titleResult.trustPenalty,
          'Judul goal tidak valid',
        );
      }
      return titleResult;
    }

    // 2. Rate limit
    final rateResult = await ContentValidator.checkGoalRateLimit();
    if (!rateResult.isValid) {
      if (habitProvider != null) {
        habitProvider.applyTrustPenaltyPublic(
          rateResult.trustPenalty,
          'Rate limit goal terlampaui',
        );
      }
      return rateResult;
    }

    // 3. Suspicious but valid — apply penalty
    if (titleResult.isSuspicious && titleResult.trustPenalty > 0 && habitProvider != null) {
      habitProvider.applyTrustPenaltyPublic(
        titleResult.trustPenalty,
        'Judul goal mencurigakan',
      );
    }

    // 4. Proceed with creation
    final goal = GoalModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      targetDescription: targetDescription,
      coins: coins,
      colorValue: color.toARGB32(),
      createdAt: DateTime.now(),
      deadline: deadline,
      order: _goals.length,
      durationMonths: durationMonths,
    );
    await _box.put(goal.id, goal);
    _goals.add(goal);

    // Auto-generate daily habits dari goal (jika habitProvider tersedia)
    if (habitProvider != null) {
      await habitProvider.addHabitsFromGoal(
        goal.id,
        title,
        targetDescription,
        color,
        deadline: deadline,
      );
    }

    notifyListeners();
    return titleResult;
  }

  Future<void> editGoal({
    required String id,
    required String title,
    required String targetDescription,
    required int coins,
    required Color color,
    DateTime? deadline,
  }) async {
    final goal = _box.get(id);
    if (goal == null) return;
    goal.title = title;
    goal.targetDescription = targetDescription;
    goal.coins = coins;
    goal.colorValue = color.toARGB32();
    goal.deadline = deadline;
    await _box.put(goal.id, goal);
    _loadGoals();
    notifyListeners();
  }

  Future<void> deleteGoal(String id, {dynamic habitProvider}) async {
    // Delete associated habits
    if (habitProvider != null) {
      await habitProvider.deleteHabitsForGoal(id);
    }

    await _box.delete(id);
    _goals.removeWhere((g) => g.id == id);
    for (int i = 0; i < _goals.length; i++) {
      _goals[i].order = i;
      await _box.put(_goals[i].id, _goals[i]);
    }
    notifyListeners();
  }

  // ── Progress ──────────────────────────────────────────────────────────────

  /// Sync goal progress dari habits yang sudah diselesaikan hari ini
  /// Jika goal punya deadline: progress berbasis jumlah hari selesai
  /// Jika tidak ada deadline: progress dari percentage habit completion
  Future<void> syncProgressFromHabits(String goalId, List<dynamic> allHabits) async {
    final goal = _box.get(goalId);
    if (goal == null || goal.status != GoalStatus.active) return;

    // Hitung total dan completed habits untuk goal ini
    final goalsHabits =
        allHabits.where((h) => h.goalId == goalId).toList();
    if (goalsHabits.isEmpty) return;

    if (goal.deadline != null) {
      // Mode time-based: progress dari jumlah hari yang diselesaikan
      final allDoneToday = goalsHabits.every((h) => h.isCompletedOnDate == true);

      // Cek apakah hari ini sudah dihitung (simpan lastSyncDate untuk cegah double-count)
      final today = DateTime.now();
      final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      if (allDoneToday && goal.lastSyncDate != todayStr) {
        goal.completedDays = (goal.completedDays + 1).clamp(0, goal.totalExpectedDays);
        goal.lastSyncDate = todayStr; // track sudah dihitung hari ini
      }

      final newProgress = goal.totalExpectedDays > 0
          ? ((goal.completedDays / goal.totalExpectedDays) * 100).round()
          : 0;
      goal.currentProgress = newProgress.clamp(0, 100);
    } else {
      // Mode lama: progress dari percentage completion habit hari ini
      final completedHabits = goalsHabits
          .where((h) => h.isCompletedOnDate == true)
          .length;

      final newProgress =
          ((completedHabits / goalsHabits.length) * 100).round();
      goal.currentProgress = newProgress.clamp(0, 100);
    }

    await _box.put(goal.id, goal);
    _loadGoals();
    notifyListeners();
  }

  // ── Sent for Review ───────────────────────────────────────────────────────

  /// User menandai goal sebagai selesai, menunggu review/verifikasi
  Future<void> sendForReview(String id) async {
    final goal = _box.get(id);
    if (goal == null || goal.status != GoalStatus.active) return;
    goal.currentProgress = goal.targetProgress; // 100%
    goal.status = GoalStatus.sentForReview;
    await _box.put(goal.id, goal);
    _loadGoals();
    notifyListeners();
  }

  /// Simulasi AI/admin review: approve goal → beri reward koin scalable
  /// Mengembalikan jumlah koin yang diberikan
  Future<int> approveGoal(String id) async {
    final goal = _box.get(id);
    if (goal == null || goal.status != GoalStatus.sentForReview) return 0;
    goal.status = GoalStatus.approved;
    goal.reviewNotes = 'Goal diverifikasi dan disetujui!';
    await _box.put(goal.id, goal);

    // Hitung reward berdasarkan durasi goal
    final reward = _computeGoalReward(goal);

    // Simpan koin ke SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final currentCoins = prefs.getInt('user_coins') ?? 0;
    await prefs.setInt('user_coins', currentCoins + reward);

    _loadGoals();
    notifyListeners();
    return reward;
  }

  /// Reject goal (kirim kembali ke active)
  Future<void> rejectGoal(String id, String notes) async {
    final goal = _box.get(id);
    if (goal == null || goal.status != GoalStatus.sentForReview) return;
    goal.status = GoalStatus.active;
    goal.currentProgress = 0;
    goal.reviewNotes = notes;
    await _box.put(goal.id, goal);
    _loadGoals();
    notifyListeners();
  }

  // ── Helper: Compute reward coins berdasarkan durasi goal ──────────────────
  int _computeGoalReward(GoalModel goal) {
    if (goal.deadline == null) return goal.coins;
    final days = goal.deadline!.difference(goal.createdAt).inDays;
    if (days > 365) return 6000;
    if (days > 180) return 3000;
    if (days > 90) return 1500;
    if (days > 30) return 700;
    return 300;
  }

}
