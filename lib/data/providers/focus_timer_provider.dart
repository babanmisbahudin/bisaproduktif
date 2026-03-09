import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
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
    _currentSession = FocusSessionModel(
      id: const Uuid().v4(),
      activity: activity,
      durationSeconds: durationMinutes * 60,
      startedAt: DateTime.now(),
      category: category,
    );

    _remainingSeconds = _currentSession!.durationSeconds;
    _isActive = true;

    // Save session ke Hive
    await _box.put(_currentSession!.id, _currentSession!);
    _sessions.insert(0, _currentSession!);

    _startCountdown();
    notifyListeners();
  }

  void _startCountdown() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
        _currentSession?.elapsedSeconds++;

        // Update Hive setiap 5 detik
        if (_currentSession != null && _remainingSeconds % 5 == 0) {
          _box.put(_currentSession!.id, _currentSession!);
        }

        notifyListeners();
      } else {
        // Timer selesai
        _completeSession();
      }
    });
  }

  /// Pause timer
  void pauseTimer() {
    _isActive = false;
    _timer?.cancel();
    notifyListeners();
  }

  /// Resume timer
  void resumeTimer() {
    if (_currentSession != null) {
      _isActive = true;
      _startCountdown();
      notifyListeners();
    }
  }

  /// Stop dan complete session
  Future<void> completeSession() async {
    await _completeSession();
  }

  Future<void> _completeSession() async {
    _timer?.cancel();
    _isActive = false;

    if (_currentSession != null) {
      _currentSession!.isCompleted = true;
      _currentSession!.completedAt = DateTime.now();

      await _box.put(_currentSession!.id, _currentSession!);
    }

    notifyListeners();
  }

  /// Cancel timer
  Future<void> cancelSession() async {
    _timer?.cancel();
    _isActive = false;

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
    _musicService.dispose();
    super.dispose();
  }
}
