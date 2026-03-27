import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/music_service.dart';
import '../models/focus_session_model.dart';

class FocusTimerProvider extends ChangeNotifier {
  static const String _boxName = 'focus_sessions';

  late Box<FocusSessionModel> _box;
  List<FocusSessionModel> _sessions = [];
  bool _isLoaded = false;

  // Current session state
  FocusSessionModel? _currentSession;
  Timer? _timer;
  bool _isActive = false;
  int _remainingSeconds = 0;
  int _lastRewardCoins = 0; // Last earned coins

  // Music state
  bool _isMusicEnabled = true;
  final MusicService _musicService = MusicService();

  List<FocusSessionModel> get sessions => List.unmodifiable(_sessions);
  bool get isLoaded => _isLoaded;
  FocusSessionModel? get currentSession => _currentSession;
  bool get isTimerActive => _isActive;
  int get remainingSeconds => _remainingSeconds;
  int get totalSessions => _sessions.length;
  int get completedSessions => _sessions.where((s) => s.isCompleted).length;
  bool get isMusicEnabled => _isMusicEnabled;
  int get lastRewardCoins => _lastRewardCoins;

  // ── Init ────────────────────────────────────────────────────────────────────

  Future<void> init() async {
    _box = await Hive.openBox<FocusSessionModel>(_boxName);
    _loadSessions();
    _isLoaded = true;
    notifyListeners();
  }

  void _loadSessions() {
    _sessions = _box.values.toList();
    _sessions.sort((a, b) => b.startedAt.compareTo(a.startedAt));
  }

  // ── Timer Control ───────────────────────────────────────────────────────────

  /// Start focus timer
  Future<void> startFocusSession({
    required String activity,
    required int durationMinutes,
    required String category,
  }) async {
    debugPrint('[FocusTimer] Starting session: $activity ($durationMinutes min)');

    final now = DateTime.now();
    _currentSession = FocusSessionModel(
      id: const Uuid().v4(),
      activity: activity,
      durationSeconds: durationMinutes * 60,
      startedAt: now,
      category: category,
    );

    _remainingSeconds = _currentSession!.durationSeconds;
    _isActive = true;

    debugPrint('[FocusTimer] Session created - duration: $_remainingSeconds secs, isActive: $_isActive');

    // Save session ke Hive
    await _box.put(_currentSession!.id, _currentSession!);
    _sessions.insert(0, _currentSession!);

    // Smart Timer: Simpan start time ke SharedPreferences untuk recovery
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('focus_session_id', _currentSession!.id);
    await prefs.setString('focus_start_time', now.toIso8601String());
    await prefs.setInt('focus_duration_seconds', _currentSession!.durationSeconds);

    _startCountdown();
    notifyListeners();

    debugPrint('[FocusTimer] Countdown started, notifyListeners called');
  }

  void _startCountdown() {
    _timer?.cancel();
    debugPrint('[FocusTimer] _startCountdown() called, starting timer.periodic');

    // Immediate first update
    notifyListeners();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_currentSession == null) {
        debugPrint('[FocusTimer] ERROR: _currentSession is null, canceling timer');
        timer.cancel();
        return;
      }

      // Smart Timer: Hitung elapsed time dari start time yang tersimpan
      final now = DateTime.now();
      final elapsedSeconds = now.difference(_currentSession!.startedAt).inSeconds;
      final prevRemaining = _remainingSeconds;
      _remainingSeconds = (_currentSession!.durationSeconds - elapsedSeconds).clamp(0, _currentSession!.durationSeconds);

      _currentSession?.elapsedSeconds = elapsedSeconds;

      // Save progress setiap detik untuk recovery
      _box.put(_currentSession!.id, _currentSession!);

      // Debug: log setiap 5 detik
      if (_remainingSeconds % 5 == 0 && prevRemaining != _remainingSeconds) {
        debugPrint('[FocusTimer] Countdown: $_remainingSeconds secs remaining (elapsed: $elapsedSeconds)');
      }

      // Always notify listeners untuk UI update
      notifyListeners();

      // Timer selesai
      if (_remainingSeconds <= 0) {
        debugPrint('[FocusTimer] Countdown complete! Calling _completeSessionSync()');
        timer.cancel();
        _completeSessionSync();
      }
    });

    debugPrint('[FocusTimer] Timer.periodic started successfully');
  }

  /// Synchronous version untuk timer callback (async ops happen in background)
  /// Returns reward coins earned
  int _completeSessionSync() {
    _isActive = false;
    int reward = 0;

    if (_currentSession != null) {
      _currentSession!.isCompleted = true;
      _currentSession!.completedAt = DateTime.now();

      // Anti-cheat: Check untuk manipulasi waktu
      final (isCheat, reason) = _detectTimerCheat(_currentSession!);

      if (isCheat) {
        debugPrint('[FocusTimer] CHEAT DETECTED: $reason - No reward given');
        reward = 0; // No reward para cheater
        _currentSession!.wasCheatDetected = true;
      } else {
        // Calculate reward coins (hanya jika tidak ada cheat)
        reward = calculateFocusReward(_currentSession!);
        _lastRewardCoins = reward;
      }

      _box.put(_currentSession!.id, _currentSession!);
    }
    _clearSessionPrefsSync();
    _currentSession = null;
    _remainingSeconds = 0;
    notifyListeners();
    return reward;
  }

  /// Restore session dari background (dipanggil saat app startup)
  Future<void> restoreSessionIfActive() async {
    final prefs = await SharedPreferences.getInstance();
    final sessionId = prefs.getString('focus_session_id');

    if (sessionId == null) {
      // Tidak ada session aktif
      return;
    }

    // Cek apakah session masih valid dan belum selesai
    final startTimeStr = prefs.getString('focus_start_time');
    final durationSeconds = prefs.getInt('focus_duration_seconds');

    if (startTimeStr != null && durationSeconds != null) {
      final startTime = DateTime.parse(startTimeStr);
      final elapsedSeconds = DateTime.now().difference(startTime).inSeconds;

      if (elapsedSeconds < durationSeconds) {
        // Session masih berlangsung, restore state
        debugPrint('[FocusTimer] Restoring session: $sessionId');

        // Load session dari Hive
        final session = _box.get(sessionId);
        if (session != null && !session.isCompleted) {
          _currentSession = session;
          _currentSession!.elapsedSeconds = elapsedSeconds;
          _remainingSeconds = (durationSeconds - elapsedSeconds).clamp(0, durationSeconds);
          _isActive = true;

          _startCountdown();
          notifyListeners();
        }
      } else {
        // Session sudah selesai
        await _clearSessionPrefs();
      }
    }
  }

  Future<void> _clearSessionPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('focus_session_id');
    await prefs.remove('focus_start_time');
    await prefs.remove('focus_duration_seconds');
  }

  /// Synchronous version for timer callback (prefs update happens in background)
  void _clearSessionPrefsSync() {
    SharedPreferences.getInstance().then((prefs) {
      prefs.remove('focus_session_id');
      prefs.remove('focus_start_time');
      prefs.remove('focus_duration_seconds');
    });
  }

  /// Deteksi manipulasi waktu sistem atau cheat pada fokus timer
  /// Returns (isCheat, reason)
  (bool, String) _detectTimerCheat(FocusSessionModel session) {
    // Cek 1: Elapsed time harus >= duration (jangan kurang)
    if (session.elapsedSeconds < session.durationSeconds) {
      // Jika elapsed kurang dari duration, berarti ada yang aneh
      // Tapi ini tidak akan terjadi karena timer hanya complete saat elapsed >= duration
      return (true, 'Elapsed time kurang dari duration');
    }

    // Cek 2: Clock jump detection
    // Jika elapsed >> duration (e.g., 2x lipat), suspect manipulasi waktu
    final ratio = session.elapsedSeconds / session.durationSeconds;
    if (ratio > 2.5) {
      // Clock mungkin di-set mundur lalu maju dengan cepat
      return (true, 'Clock jump terdeteksi (elapsed ${session.elapsedSeconds}s > duration ${session.durationSeconds}s)');
    }

    // Cek 3: Timing validation
    // Rekam timestamp sebelum & sesudah untuk validasi
    final now = DateTime.now();
    final actualDuration = now.difference(session.startedAt).inSeconds;
    final timeDiff = (actualDuration - session.elapsedSeconds).abs();

    // Jika beda time > 10 detik, ada yang aneh
    if (timeDiff > 10) {
      return (true, 'Time sync mismatch: actual=$actualDuration vs elapsed=${session.elapsedSeconds}');
    }

    // No cheat detected
    return (false, '');
  }

  /// Stop dan complete session, return reward coins
  Future<int> completeSession() async {
    final reward = await _completeSession();
    return reward;
  }

  Future<int> _completeSession() async {
    _timer?.cancel();
    _isActive = false;
    int reward = 0;

    if (_currentSession != null) {
      _currentSession!.isCompleted = true;
      _currentSession!.completedAt = DateTime.now();

      // Calculate reward coins
      reward = calculateFocusReward(_currentSession!);
      _lastRewardCoins = reward;

      await _box.put(_currentSession!.id, _currentSession!);
    }

    await _clearSessionPrefs();
    _currentSession = null;
    _remainingSeconds = 0;
    notifyListeners();
    return reward;
  }

  /// Cancel timer
  Future<void> cancelSession() async {
    _timer?.cancel();
    _isActive = false;
    await _clearSessionPrefs();

    if (_currentSession != null) {
      await _box.delete(_currentSession!.id);
      _sessions.removeWhere((s) => s.id == _currentSession!.id);
    }

    _currentSession = null;
    _remainingSeconds = 0;
    notifyListeners();
  }

  // ── Stats ───────────────────────────────────────────────────────────────────

  /// Total fokus time hari ini (dalam minutes)
  int getTodayFocusTime() {
    final today = DateTime.now();
    final todaySessions = _sessions.where((s) {
      final sameDay = s.startedAt.year == today.year &&
          s.startedAt.month == today.month &&
          s.startedAt.day == today.day &&
          s.isCompleted;
      return sameDay;
    });

    return todaySessions.fold(0, (sum, s) => sum + s.durationSeconds) ~/ 60;
  }

  /// Total fokus time bulan ini
  int getMonthFocusTime() {
    final today = DateTime.now();
    final monthSessions = _sessions.where((s) {
      final sameMonth = s.startedAt.year == today.year &&
          s.startedAt.month == today.month &&
          s.isCompleted;
      return sameMonth;
    });

    return monthSessions.fold(0, (sum, s) => sum + s.durationSeconds) ~/ 60;
  }

  /// Total fokus time minggu ini (7 hari terakhir)
  int getWeekFocusTime() {
    final today = DateTime.now();
    final sevenDaysAgo = today.subtract(const Duration(days: 7));
    final weekSessions = _sessions.where((s) {
      return s.isCompleted && s.startedAt.isAfter(sevenDaysAgo);
    });

    return weekSessions.fold(0, (sum, s) => sum + s.durationSeconds) ~/ 60;
  }

  /// Hitung fokus streak (consecutive days dengan minimal 1 session completed)
  int getFocusStreak() {
    if (_sessions.isEmpty) return 0;

    // Get unique days dengan completed sessions
    final completedDays = <DateTime>{};
    for (final session in _sessions) {
      if (session.isCompleted) {
        completedDays.add(DateTime(
          session.startedAt.year,
          session.startedAt.month,
          session.startedAt.day,
        ));
      }
    }

    if (completedDays.isEmpty) return 0;

    // Sort days descending
    final sortedDays = completedDays.toList()
      ..sort((a, b) => b.compareTo(a));

    // Hitung streak dari hari ini mundur
    int streak = 0;
    DateTime currentDate = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

    for (final day in sortedDays) {
      if (day.isAtSameMomentAs(currentDate) || day.isAfter(currentDate)) {
        // Skip future dates
        continue;
      }

      // Cek gap
      final expectedDate = currentDate.subtract(Duration(days: streak));
      if (day.isAtSameMomentAs(expectedDate)) {
        streak++;
      } else {
        break;
      }
    }

    // Jika ada session hari ini, include in streak
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    if (completedDays.contains(today) && streak == 0) {
      streak = 1;
    }

    return streak;
  }

  /// Get completed focus sessions dengan filter & sorting
  List<FocusSessionModel> getCompletedSessions({int limit = 20}) {
    final completed = _sessions
        .where((s) => s.isCompleted)
        .toList()
      ..sort((a, b) => b.completedAt!.compareTo(a.completedAt!));
    return completed.take(limit).toList();
  }

  /// Get average focus duration (minutes)
  int getAverageFocusTime() {
    if (_sessions.isEmpty) return 0;
    final completed = _sessions.where((s) => s.isCompleted).toList();
    if (completed.isEmpty) return 0;
    final totalSeconds = completed.fold(0, (sum, s) => sum + s.durationSeconds);
    return (totalSeconds / completed.length).round() ~/ 60;
  }

  /// Hitung reward coin untuk focus session
  int calculateFocusReward(FocusSessionModel session) {
    // Base: 1 coin per menit
    final durationMinutes = session.durationSeconds ~/ 60;
    int coins = durationMinutes;

    // Bonus untuk sesi panjang (>30 min)
    if (durationMinutes > 30) {
      coins = (coins * 1.5).toInt();
    }

    // Bonus Pomodoro
    if (session.isPomodoro) {
      coins = (coins * 1.25).toInt(); // 25% bonus
    }

    // Bonus kategori
    final categoryBonus = switch (session.category) {
      'prayer' => 1.3, // Ibadah: 30% bonus
      'study' => 1.2, // Belajar: 20% bonus
      'work' => 1.1, // Kerja: 10% bonus
      _ => 1.0,
    };
    coins = (coins * categoryBonus).toInt();

    // Minimal 5 coins
    return coins.clamp(5, 500);
  }

  // ── Clear Data ──────────────────────────────────────────────────────────────

  /// Toggle produktif music on/off
  void toggleMusic() {
    _isMusicEnabled = !_isMusicEnabled;
    if (_isMusicEnabled && _isActive) {
      _musicService.playFocusMusic();
    } else {
      _musicService.stopMusic();
    }
    notifyListeners();
  }

  /// Play focus music
  Future<void> playMusic() async {
    await _musicService.playFocusMusic();
    notifyListeners();
  }

  /// Stop music
  Future<void> stopMusicPlayback() async {
    await _musicService.stopMusic();
    notifyListeners();
  }

  Future<void> clearUserData() async {
    _timer?.cancel();
    _musicService.stopMusic();
    _sessions.clear();
    _currentSession = null;
    _isActive = false;
    await _box.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timer = null;
    _musicService.stopMusic();
    super.dispose();
  }
}
