import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/habit_model.dart';
import '../../core/constants/app_colors.dart';

class HabitProvider extends ChangeNotifier {
  static const String _boxName = 'habits';
  static const String _coinsKey = 'user_coins';
  static const String _trustScoreKey = 'trust_score';

  late Box<HabitModel> _box;
  List<HabitModel> _habits = [];
  int _totalCoins = 0;
  int _trustScore = 70;
  bool _isLoaded = false;

  List<HabitModel> get habits => List.unmodifiable(_habits);
  int get totalCoins => _totalCoins;
  int get trustScore => _trustScore;
  bool get isLoaded => _isLoaded;

  int get completedToday =>
      _habits.where((h) => h.isCompletedOnDate).length;
  int get totalHabits => _habits.length;

  /// Total coins earned hari ini (dari habit yang diselesaikan)
  int get coinsEarnedToday {
    return _habits.where((h) => h.isCompletedOnDate).fold(0, (sum, h) => sum + h.coins);
  }

  // ── Init ──────────────────────────────────────────────────────────────────

  Future<void> init() async {
    _box = await Hive.openBox<HabitModel>(_boxName);
    await _loadCoins();
    await _resetIfNewDay();
    _loadHabits();
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> _loadCoins() async {
    final prefs = await SharedPreferences.getInstance();
    _totalCoins = prefs.getInt(_coinsKey) ?? 0;
    _trustScore = prefs.getInt(_trustScoreKey) ?? 70;
  }

  Future<void> _saveCoins() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_coinsKey, _totalCoins);
  }

  Future<void> _saveTrustScore() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_trustScoreKey, _trustScore);
  }

  void _loadHabits() {
    _habits = _box.values.toList()
      ..sort((a, b) => a.order.compareTo(b.order));
    // Seed default habits jika kosong
    if (_habits.isEmpty) {
      _seedDefaultHabits();
    }
  }

  // Reset isCompletedToday setiap hari baru
  Future<void> _resetIfNewDay() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _todayKey();
    final lastOpenDate = prefs.getString('last_open_date') ?? '';

    if (lastOpenDate != today) {
      // Hari baru — cek streak, reset completion
      for (final habit in _box.values) {
        final wasCompletedYesterday =
            habit.lastCompletedDate == _yesterdayKey();
        if (!wasCompletedYesterday && habit.streak > 0) {
          habit.streak = 0; // streak putus
        }
        habit.isCompletedToday = false;
        await _box.put(habit.id, habit);
      }
      await prefs.setString('last_open_date', today);
    }
  }

  // ── CRUD ─────────────────────────────────────────────────────────────────

  Future<void> addHabit({
    required String title,
    required int coins,
    required Color color,
  }) async {
    final habit = HabitModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      coins: coins,
      colorValue: color.toARGB32(),
      createdAt: DateTime.now(),
      order: _habits.length,
    );
    await _box.put(habit.id, habit);
    _habits.add(habit);
    notifyListeners();
  }

  Future<void> editHabit({
    required String id,
    required String title,
    required int coins,
    required Color color,
  }) async {
    final habit = _box.get(id);
    if (habit == null) return;
    habit.title = title;
    habit.coins = coins;
    habit.colorValue = color.toARGB32();
    await _box.put(habit.id, habit);
    _loadHabits();
    notifyListeners();
  }

  Future<void> deleteHabit(String id) async {
    await _box.delete(id);
    _habits.removeWhere((h) => h.id == id);
    // Re-order
    for (int i = 0; i < _habits.length; i++) {
      _habits[i].order = i;
      await _box.put(_habits[i].id, _habits[i]);
    }
    notifyListeners();
  }

  // ── Complete Habit ────────────────────────────────────────────────────────

  Future<bool> completeHabit(String id) async {
    final habit = _box.get(id);
    if (habit == null || habit.isCompletedOnDate) return false;

    final now = DateTime.now();
    final timestamp = now.toIso8601String();

    // Anti-fraud level 1: cek durasi minimum (30 detik sejak app dibuka)
    final prefs = await SharedPreferences.getInstance();
    final appOpenTime = prefs.getString('app_open_time') ?? timestamp;
    final appOpen = DateTime.tryParse(appOpenTime) ?? now;
    final secondsSinceOpen = now.difference(appOpen).inSeconds;

    if (secondsSinceOpen < 30) {
      _applyTrustPenalty(15, 'Penyelesaian terlalu cepat (< 30 detik sejak app dibuka)');
      return false;
    }

    // Anti-fraud level 1: max 10 habit per jam
    final recentTimestamps = habit.completionTimestamps
        .where((t) {
          final dt = DateTime.tryParse(t);
          return dt != null && now.difference(dt).inHours < 1;
        })
        .toList();

    if (recentTimestamps.length >= 10) {
      _applyTrustPenalty(5, 'Terlalu banyak habit per jam (max 10)');
      return false;
    }

    // Anti-fraud level 2: max 20 habit per hari
    final todayCompletions = _habits.where((h) => h.isCompletedOnDate).length;
    if (todayCompletions >= 20) {
      _applyTrustPenalty(8, 'Terlalu banyak habit per hari (max 20)');
      return false;
    }

    // Tandai selesai
    habit.isCompletedToday = true;
    habit.lastCompletedDate = _todayKey();
    habit.streak += 1;
    habit.completionTimestamps.add(timestamp);

    // Simpan max 30 hari terakhir
    if (habit.completionTimestamps.length > 30) {
      habit.completionTimestamps.removeAt(0);
    }

    await _box.put(habit.id, habit);

    // Tambah koin
    _totalCoins += habit.coins;
    await _saveCoins();

    // Trust score naik perlahan saat perilaku wajar
    if (_trustScore < 100) {
      _trustScore = (_trustScore + 1).clamp(0, 100);
      await _saveTrustScore();
    }

    _loadHabits();
    notifyListeners();
    return true;
  }

  // ── Anti-Fraud ────────────────────────────────────────────────────────────

  void _applyTrustPenalty(int penalty, String reason) {
    _trustScore = (_trustScore - penalty).clamp(0, 100);
    _saveTrustScore();
    debugPrint('[Anti-Fraud] Trust score -$penalty: $reason (score: $_trustScore)');
    notifyListeners();
  }

  String getTrustStatus() {
    if (_trustScore >= 80) return 'normal';
    if (_trustScore >= 60) return 'monitoring';
    if (_trustScore >= 40) return 'limited';
    return 'frozen';
  }

  bool canRedeemCoins() => _trustScore >= 40;

  // Dipanggil oleh RewardProvider saat tukar koin
  Future<bool> deductCoins(int amount) async {
    if (_totalCoins < amount) return false;
    _totalCoins -= amount;
    await _saveCoins();
    notifyListeners();
    return true;
  }

  // Dipanggil oleh RewardProvider saat reject redemption (refund)
  Future<bool> addCoins(int amount) async {
    _totalCoins += amount;
    await _saveCoins();
    notifyListeners();
    return true;
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  String _yesterdayKey() {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';
  }

  void _seedDefaultHabits() {
    final defaults = [
      {'title': 'Rapikan kamar dan kamar mandi', 'coins': 30, 'color': AppColors.taskOrange},
      {'title': 'Aktivitas fisik (olahraga, workout)', 'coins': 40, 'color': AppColors.taskYellow},
      {'title': 'Jaga kebersihan dan penampilan', 'coins': 50, 'color': AppColors.taskGray},
      {'title': 'Baca buku 20 menit', 'coins': 20, 'color': AppColors.taskOrangeLight},
      {'title': 'Minum 8 gelas air putih', 'coins': 15, 'color': AppColors.primaryLight},
    ];

    for (int i = 0; i < defaults.length; i++) {
      final d = defaults[i];
      final habit = HabitModel(
        id: 'default_$i',
        title: d['title'] as String,
        coins: d['coins'] as int,
        colorValue: (d['color'] as Color).toARGB32(),
        createdAt: DateTime.now(),
        order: i,
      );
      _box.put(habit.id, habit);
      _habits.add(habit);
    }
  }

  // Simpan waktu app dibuka untuk anti-fraud
  Future<void> recordAppOpen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_open_time', DateTime.now().toIso8601String());
  }
}
