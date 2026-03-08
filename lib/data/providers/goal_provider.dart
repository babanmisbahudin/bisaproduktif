import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/goal_model.dart';
import '../../core/constants/app_colors.dart';

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

  void _loadGoals() {
    _goals = _box.values.toList()
      ..sort((a, b) => a.order.compareTo(b.order));
    if (_goals.isEmpty) {
      _seedDefaultGoals();
    }
  }

  // ── CRUD ─────────────────────────────────────────────────────────────────

  Future<void> addGoal({
    required String title,
    required String targetDescription,
    required int coins,
    required Color color,
    DateTime? deadline,
    dynamic habitProvider,
  }) async {
    final goal = GoalModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      targetDescription: targetDescription,
      coins: coins,
      colorValue: color.toARGB32(),
      createdAt: DateTime.now(),
      deadline: deadline,
      order: _goals.length,
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
      );
    }

    notifyListeners();
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

  Future<void> updateProgress(String id, int newProgress) async {
    final goal = _box.get(id);
    if (goal == null || goal.status != GoalStatus.active) return;
    goal.currentProgress = newProgress.clamp(0, goal.targetProgress);
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

  /// Simulasi AI/admin review: approve goal → beri reward koin
  /// Mengembalikan jumlah koin yang diberikan
  Future<int> approveGoal(String id) async {
    final goal = _box.get(id);
    if (goal == null || goal.status != GoalStatus.sentForReview) return 0;
    goal.status = GoalStatus.approved;
    goal.reviewNotes = 'Goal diverifikasi dan disetujui!';
    await _box.put(goal.id, goal);

    // Simpan koin ke SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final currentCoins = prefs.getInt('user_coins') ?? 0;
    await prefs.setInt('user_coins', currentCoins + goal.coins);

    _loadGoals();
    notifyListeners();
    return goal.coins;
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

  // ── Default Goals ─────────────────────────────────────────────────────────

  void _seedDefaultGoals() {
    final defaults = [
      {
        'title': 'Baca 5 buku dalam sebulan',
        'desc': 'Baca setidaknya 5 buku non-fiksi dalam 30 hari',
        'coins': 500,
        'color': AppColors.primary,
      },
      {
        'title': 'Olahraga rutin 30 hari',
        'desc': 'Lakukan aktivitas fisik minimal 20 menit setiap hari',
        'coins': 750,
        'color': AppColors.taskOrange,
      },
      {
        'title': 'Hemat 500rb bulan ini',
        'desc': 'Kurangi pengeluaran tidak perlu dan tabung 500.000 rupiah',
        'coins': 1000,
        'color': AppColors.taskYellow,
      },
    ];

    for (int i = 0; i < defaults.length; i++) {
      final d = defaults[i];
      final goal = GoalModel(
        id: 'goal_default_$i',
        title: d['title'] as String,
        targetDescription: d['desc'] as String,
        coins: d['coins'] as int,
        colorValue: (d['color'] as Color).toARGB32(),
        createdAt: DateTime.now(),
        order: i,
      );
      _box.put(goal.id, goal);
      _goals.add(goal);
    }
  }
}
