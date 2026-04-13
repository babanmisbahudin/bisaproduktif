import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/content_validator.dart';
import '../../core/services/firebase_service.dart';
import '../models/habit_model.dart';

class HabitProvider extends ChangeNotifier with WidgetsBindingObserver {
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
    _isLoaded = true; // harus di-set SEBELUM _loadHabits() agar tidak return early
    await _loadCoins();
    await _resetIfNewDay();
    _loadHabits();
    // Pantau lifecycle agar reset harian berjalan saat app kembali dari background
    WidgetsBinding.instance.addObserver(this);
    notifyListeners();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _resetIfNewDay().then((_) {
        _loadHabits();
        notifyListeners();
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
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
    if (!_isLoaded) {
      debugPrint('[Habit] _loadHabits called before init() - ignoring');
      return;
    }
    _habits = _box.values.toList()
      ..sort((a, b) => a.order.compareTo(b.order));
    // No auto-seed: user baru mulai dengan habit kosong, buat goal untuk auto-generate
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

  Future<ValidationResult> addHabit({
    required String title,
    required int coins,
    required Color color,
    int? durationDays,
    HabitCategory category = HabitCategory.sedang,
    String? goalId,
  }) async {
    // 1. Validate title content
    final existingTitles = _habits.map((h) => h.title).toList();
    final titleResult = ContentValidator.validateTitle(
      title,
      existingTitles: existingTitles,
    );

    if (!titleResult.isValid) {
      if (titleResult.trustPenalty > 0) {
        await _applyTrustPenalty(titleResult.trustPenalty, 'Judul habit tidak valid');
      }
      return titleResult;
    }

    // 2. Rate limit check
    final rateResult = await ContentValidator.checkHabitRateLimit();
    if (!rateResult.isValid) {
      await _applyTrustPenalty(rateResult.trustPenalty, 'Rate limit habit terlampaui');
      return rateResult;
    }

    // 3. If suspicious but valid — apply trust penalty but continue
    if (titleResult.isSuspicious && titleResult.trustPenalty > 0) {
      await _applyTrustPenalty(titleResult.trustPenalty, 'Judul habit mencurigakan');
    }

    // 4. Koin ditentukan oleh kategori (bukan user)
    final habitCoins = category.baseCoins;

    // 5. Proceed with creation
    final habit = HabitModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      coins: habitCoins,
      colorValue: color.toARGB32(),
      createdAt: DateTime.now(),
      order: _habits.length,
      durationDays: durationDays,
      category: category,
      goalId: goalId,
    );
    await _box.put(habit.id, habit);
    _habits.add(habit);
    notifyListeners();

    return titleResult;
  }

  /// Buat habit baru yang langsung terkunci ke goal
  Future<String?> addHabitToGoal({
    required String title,
    required HabitCategory category,
    required Color color,
    required String goalId,
  }) async {
    final result = await addHabit(
      title: title,
      coins: category.baseCoins,
      color: color,
      category: category,
      goalId: goalId,
    );
    if (!result.isValid) return null;
    // Kembalikan id habit yang baru dibuat
    return _habits.last.id;
  }

  Future<void> editHabit({
    required String id,
    required String title,
    required Color color,
    HabitCategory? category,
  }) async {
    final habit = _box.get(id);
    if (habit == null) return;
    habit.title = title;
    if (category != null) {
      habit.category = category;
      habit.coins = category.baseCoins;
    }
    habit.colorValue = color.toARGB32();
    await _box.put(habit.id, habit);
    _loadHabits();
    notifyListeners();
  }

  /// Set goalId di habit (lock habit ke goal)
  Future<void> setHabitGoalId(String habitId, String goalId) async {
    final habit = _box.get(habitId);
    if (habit == null) return;
    habit.goalId = goalId;
    await _box.put(habit.id, habit);
    _loadHabits();
    notifyListeners();
  }

  /// Lepas goalId dari habit (dipanggil saat goal dihapus atau habit di-unlink)
  Future<void> unlinkHabitFromGoal(String habitId) async {
    final habit = _box.get(habitId);
    if (habit == null) return;
    habit.goalId = null;
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

  Future<bool> completeHabit(String id, {dynamic goalProvider}) async {
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
      await _applyTrustPenalty(15, 'Penyelesaian terlalu cepat (< 30 detik sejak app dibuka)');
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
      await _applyTrustPenalty(5, 'Terlalu banyak habit per jam (max 10)');
      return false;
    }

    // Anti-fraud level 2: max 20 habit per hari
    final todayCompletions = _habits.where((h) => h.isCompletedOnDate).length;
    if (todayCompletions >= 20) {
      await _applyTrustPenalty(8, 'Terlalu banyak habit per hari (max 20)');
      return false;
    }

    // Tandai selesai
    habit.isCompletedToday = true;
    habit.lastCompletedDate = _todayKey();
    habit.streak += 1;
    habit.completionTimestamps.add(timestamp);

    // Simpan max 365 hari terakhir (1 entri per hari, cukup untuk goal 1 tahun)
    if (habit.completionTimestamps.length > 365) {
      habit.completionTimestamps.removeAt(0);
    }

    await _box.put(habit.id, habit);

    // Sync goal progress jika habit ini terikat ke goal
    // Pass `this` sebagai habitProvider agar bonus koin deadline bisa dikreditkan
    if (habit.goalId != null && goalProvider != null) {
      await goalProvider.syncProgressFromHabits(
        habit.goalId,
        _habits,
        habitProvider: this,
      );
    }

    // Tambah koin: kategori × streak × durasi goal (jika linked ke goal)
    final durationMultiplier = (habit.goalId != null && goalProvider != null)
        ? (goalProvider.getDurationMultiplier(habit.goalId!) as double)
        : 1.0;
    final earnedCoins = _computeCoinsWithStreak(habit, durationMultiplier: durationMultiplier);
    habit.coins = earnedCoins; // simpan supaya report bisa baca nilai real
    await _box.put(habit.id, habit);
    _totalCoins += earnedCoins;
    await _saveCoins();

    // Trust score naik perlahan saat perilaku wajar
    if (_trustScore < 100) {
      _trustScore = (_trustScore + 1).clamp(0, 100);
      await _saveTrustScore();
    }

    // Sync ke Firebase (fire-and-forget, tidak block UI)
    FirebaseService.syncCoins(_totalCoins);
    FirebaseService.syncTrustScore(_trustScore);
    FirebaseService.logActivity(type: 'habit_complete', data: {
      'habitId': habit.id,
      'habitTitle': habit.title,
      'coinsEarned': earnedCoins,
      'streak': habit.streak,
      'totalCoins': _totalCoins,
      'trustScore': _trustScore,
    });

    _loadHabits();
    notifyListeners();
    return true;
  }

  // ── Anti-Fraud ────────────────────────────────────────────────────────────

  Future<void> _applyTrustPenalty(int penalty, String reason) async {
    _trustScore = (_trustScore - penalty).clamp(0, 100);
    await _saveTrustScore(); // await agar tidak hilang saat app di-kill
    debugPrint('[Anti-Fraud] Trust score -$penalty: $reason (score: $_trustScore)');

    // Log fraud event ke Firebase agar admin bisa lihat (fire-and-forget ok di sini)
    FirebaseService.syncTrustScore(_trustScore);
    FirebaseService.logActivity(type: 'fraud_detected', data: {
      'penalty': penalty,
      'reason': reason,
      'trustScoreAfter': _trustScore,
      'totalCoins': _totalCoins,
    });

    notifyListeners();
  }

  /// Public so other providers (GoalProvider) can apply trust penalties
  Future<void> applyTrustPenaltyPublic(int penalty, String reason) async {
    await _applyTrustPenalty(penalty, reason);
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
    FirebaseService.syncCoins(_totalCoins);
    notifyListeners();
    return true;
  }

  // Dipanggil oleh RewardProvider saat reject redemption (refund)
  Future<bool> addCoins(int amount) async {
    _totalCoins += amount;
    await _saveCoins();
    FirebaseService.syncCoins(_totalCoins);
    notifyListeners();
    return true;
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Hitung koin berdasarkan kategori × streak × durasi goal
  int _computeCoinsWithStreak(HabitModel habit, {double durationMultiplier = 1.0}) {
    final base = habit.category.baseCoins;
    double streakMultiplier;
    if (habit.streak >= 30) {
      streakMultiplier = 2.0;
    } else if (habit.streak >= 14) {
      streakMultiplier = 1.5;
    } else if (habit.streak >= 7) {
      streakMultiplier = 1.2;
    } else {
      streakMultiplier = 1.0;
    }
    return (base * streakMultiplier * durationMultiplier).round();
  }

  String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  String _yesterdayKey() {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';
  }

  // ── Auto-Habits from Goals ────────────────────────────────────────────────

  /// Generate daily habits otomatis dari goal dengan coins scalable berdasarkan durasi
  Future<void> addHabitsFromGoal(
    String goalId,
    String goalTitle,
    String goalDesc,
    Color goalColor, {
    DateTime? deadline,
  }) async {
    final combined = '$goalTitle $goalDesc'.toLowerCase();

    final templates = <String>[];
    if (combined.contains('nabung') ||
        combined.contains('hemat') ||
        combined.contains('keuangan') ||
        combined.contains('investasi') ||
        combined.contains('uang')) {
      templates.addAll([
        'Catat pengeluaran hari ini',
        'Hindari pengeluaran impulsif',
        'Sisihkan uang ke tabungan',
      ]);
    } else if (combined.contains('bisnis') ||
        combined.contains('karir') ||
        combined.contains('freelance') ||
        combined.contains('startup') ||
        combined.contains('proyek')) {
      templates.addAll([
        'Kerjakan 1 task bisnis',
        'Kirim proposal / follow-up',
        'Review progres project',
      ]);
    } else if (combined.contains('olahraga') ||
        combined.contains('gym') ||
        combined.contains('diet') ||
        combined.contains('fitness') ||
        combined.contains('lari')) {
      templates.addAll([
        'Olahraga 20 menit',
        'Minum 8 gelas air',
        'Tidur sebelum jam 23',
      ]);
    } else if (combined.contains('belajar') ||
        combined.contains('skill') ||
        combined.contains('kursus') ||
        combined.contains('coding') ||
        combined.contains('bahasa')) {
      templates.addAll([
        'Belajar 30 menit',
        'Buat catatan materi',
        'Review materi kemarin',
      ]);
    } else {
      templates.addAll([
        'Kerjakan 1 langkah kecil',
        'Catat progres hari ini',
        'Review tujuan utama',
      ]);
    }

    for (int i = 0; i < templates.length; i++) {
      final habit = HabitModel(
        id: '${goalId}_${DateTime.now().millisecondsSinceEpoch}_$i',
        title: templates[i],
        coins: HabitCategory.sedang.baseCoins,
        colorValue: goalColor.toARGB32(),
        createdAt: DateTime.now(),
        order: _habits.length + i,
        goalId: goalId,
        category: HabitCategory.sedang,
      );
      await _box.put(habit.id, habit);
      _habits.add(habit);
    }

    notifyListeners();
  }

  /// Delete all habits yang di-generate dari goal
  Future<void> deleteHabitsForGoal(String goalId) async {
    final habitsToDelete = _habits.where((h) => h.goalId == goalId).toList();
    for (final h in habitsToDelete) {
      await _box.delete(h.id);
    }
    _habits.removeWhere((h) => h.goalId == goalId);

    // Re-order
    for (int i = 0; i < _habits.length; i++) {
      _habits[i].order = i;
      await _box.put(_habits[i].id, _habits[i]);
    }

    notifyListeners();
  }

  // Simpan waktu app dibuka untuk anti-fraud
  Future<void> recordAppOpen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_open_time', DateTime.now().toIso8601String());
  }

  /// Sync coins dari Firebase setelah login
  Future<void> syncCoinsFromFirebase(int firebaseCoins) async {
    _totalCoins = firebaseCoins;
    await _saveCoins();
    notifyListeners();
  }

  /// Clear semua user data saat logout
  Future<void> clearUserData() async {
    _totalCoins = 0;
    _trustScore = 70;
    _habits.clear();

    // Clear dari SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_coinsKey);
    await prefs.remove(_trustScoreKey);

    // Clear dari Hive
    await _box.clear();

    notifyListeners();
  }
}
