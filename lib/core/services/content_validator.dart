import 'package:shared_preferences/shared_preferences.dart';

/// Result of content validation
class ValidationResult {
  final bool isValid;
  final bool isSuspicious;
  final String? warningMessage;
  final int trustPenalty;

  const ValidationResult({
    required this.isValid,
    this.isSuspicious = false,
    this.warningMessage,
    this.trustPenalty = 0,
  });

  static const ValidationResult ok = ValidationResult(isValid: true);
}

class ContentValidator {
  // SharedPreferences keys for rate limiting
  static const _habitHourKey = 'habit_creation_hour_timestamps';
  static const _habitDayKey = 'habit_creation_day_timestamps';
  static const _goalHourKey = 'goal_creation_hour_timestamps';
  static const _goalDayKey = 'goal_creation_day_timestamps';

  // Filler words that are clearly nonsense input
  static const _fillerWords = {
    'test',
    'coba',
    'aaa',
    'xxx',
    'abc',
    'asdf',
    'qwerty',
    'tes',
    'try',
    'dummy',
    'sample',
    'contoh',
    'blah',
    'haha',
    'wkwk',
    'lol',
    'xd',
    'foo',
    'bar',
    'baz',
  };

  // Known keyboard-mash sequences (partial)
  static const _keyboardMash = [
    'asdfghjkl',
    'qwertyuiop',
    'zxcvbnm',
    'asdf',
    'qwer',
    'zxcv',
    '12345',
    '11111',
    '00000',
    'aaaaa',
    'bbbbb',
  ];

  /// Validate a title string for a habit or goal.
  /// Returns a ValidationResult: blocked, suspicious, or ok.
  static ValidationResult validateTitle(
    String rawTitle, {
    List<String> existingTitles = const [],
  }) {
    final title = rawTitle.trim();

    // ── Rule 1: Minimum length ────────────────────────────────────────────────
    if (title.length < 3) {
      return const ValidationResult(
        isValid: false,
        warningMessage: 'Judul terlalu pendek. Minimal 3 karakter ya!',
      );
    }

    // ── Rule 2: Must contain at least one real alphabetic word ─────────────────
    // A "real word" = 2+ consecutive letters
    final hasRealWord = RegExp(r'[a-zA-ZÀ-ÿ]{2,}').hasMatch(title);
    if (!hasRealWord) {
      return const ValidationResult(
        isValid: false,
        warningMessage: 'Judul harus mengandung kata yang bermakna.',
      );
    }

    // ── Rule 3: Repeated character (e.g. "aaaaaaa", "111111") ─────────────────
    // Flag if same character repeated more than 3x consecutively
    final repeatedChar = RegExp(r'(.)\1{3,}');
    if (repeatedChar.hasMatch(title.toLowerCase())) {
      return const ValidationResult(
        isValid: true,
        isSuspicious: true,
        warningMessage:
            'Judul terlihat tidak biasa (karakter berulang). Trust score akan dikurangi jika dilanjutkan.',
        trustPenalty: 5,
      );
    }

    // ── Rule 4: Keyboard mash detection ───────────────────────────────────────
    final lc = title.toLowerCase();
    for (final pattern in _keyboardMash) {
      if (lc.contains(pattern)) {
        return const ValidationResult(
          isValid: true,
          isSuspicious: true,
          warningMessage:
              'Judul terlihat seperti ketukan acak keyboard. Gunakan nama yang berarti ya!',
          trustPenalty: 5,
        );
      }
    }

    // ── Rule 5: Filler/nonsense single word check ──────────────────────────────
    // Check each word token
    final words = title.toLowerCase().split(RegExp(r'\s+'));
    if (words.length == 1 && _fillerWords.contains(words.first)) {
      return ValidationResult(
        isValid: true,
        isSuspicious: true,
        warningMessage: 'Judul "$title" terlihat seperti placeholder. Coba nama yang lebih spesifik.',
        trustPenalty: 5,
      );
    }

    // ── Rule 6: Exact duplicate detection ─────────────────────────────────────
    final normalizedTitle = title.toLowerCase();
    for (final existing in existingTitles) {
      if (existing.toLowerCase() == normalizedTitle) {
        return ValidationResult(
          isValid: true,
          isSuspicious: true,
          warningMessage:
              'Kamu sudah punya habit/goal dengan judul yang sama. Lanjut tetap bisa, tapi pertimbangkan untuk menggabungkan.',
          trustPenalty: 0,
        );
      }
    }

    return ValidationResult.ok;
  }

  // ── Rate Limiting ──────────────────────────────────────────────────────────

  /// Check & record a new habit creation. Returns a ValidationResult.
  /// maxPerHour = 5, maxPerDay = 10
  static Future<ValidationResult> checkHabitRateLimit() async {
    return _checkRateLimit(
      hourKey: _habitHourKey,
      dayKey: _habitDayKey,
      maxPerHour: 5,
      maxPerDay: 10,
      label: 'habit',
    );
  }

  /// Check & record a new goal creation. Returns a ValidationResult.
  /// maxPerHour = 3, maxPerDay = 5
  static Future<ValidationResult> checkGoalRateLimit() async {
    return _checkRateLimit(
      hourKey: _goalHourKey,
      dayKey: _goalDayKey,
      maxPerHour: 3,
      maxPerDay: 5,
      label: 'goal',
    );
  }

  static Future<ValidationResult> _checkRateLimit({
    required String hourKey,
    required String dayKey,
    required int maxPerHour,
    required int maxPerDay,
    required String label,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final todayStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    // Load and clean stale hour timestamps
    final hourList = (prefs.getStringList(hourKey) ?? [])
        .where((t) {
          final dt = DateTime.tryParse(t);
          return dt != null && now.difference(dt).inMinutes < 60;
        })
        .toList();

    // Load and clean stale day timestamps (keep today only)
    final dayList = (prefs.getStringList(dayKey) ?? [])
        .where((t) => t.startsWith(todayStr))
        .toList();

    if (hourList.length >= maxPerHour) {
      return ValidationResult(
        isValid: false,
        warningMessage:
            'Kamu sudah membuat $maxPerHour $label dalam 1 jam terakhir. Coba lagi nanti ya!',
        trustPenalty: 10,
      );
    }

    if (dayList.length >= maxPerDay) {
      return ValidationResult(
        isValid: false,
        warningMessage:
            'Batas pembuatan $label hari ini ($maxPerDay) sudah tercapai. Coba lagi besok!',
        trustPenalty: 10,
      );
    }

    // Record this creation
    final nowStr = now.toIso8601String();
    hourList.add(nowStr);
    dayList.add(nowStr);
    await prefs.setStringList(hourKey, hourList);
    await prefs.setStringList(dayKey, dayList);

    return ValidationResult.ok;
  }
}
