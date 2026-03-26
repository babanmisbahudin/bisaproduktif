import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

enum AdPointTier {
  bronze(5, 10),     // < 15 detik
  silver(15, 25),    // 15-30 detik
  gold(30, 50),      // selesai penuh (~30+ detik)
  platinum(75, 100); // selesai + bonus engagement

  final int minPoints;
  final int maxPoints;

  const AdPointTier(this.minPoints, this.maxPoints);
}

class AdMobService {
  static final AdMobService _instance = AdMobService._internal();

  AdMobService._internal();

  factory AdMobService() {
    return _instance;
  }

  static const int maxAdsPerDay = 5;
  static const int cooldownMinutes = 10;

  /// Tentukan tier berdasarkan durasi menonton (dalam detik)
  AdPointTier _determineTier(int watchDurationSeconds) {
    if (watchDurationSeconds < 15) {
      return AdPointTier.bronze;
    } else if (watchDurationSeconds < 30) {
      return AdPointTier.silver;
    } else {
      // Asumsi iklan standar 30+ detik
      return AdPointTier.gold;
    }
  }

  /// Apply random variation ±20% pada point
  int _applyVariation(int basePoints) {
    final random = Random();
    // Variation: -20% sampai +20%
    final variationPercent = random.nextDouble() * 0.4 - 0.2; // -0.2 to 0.2
    final variation = (basePoints * variationPercent).toInt();
    final finalPoints = basePoints + variation;
    return finalPoints.clamp(1, 9999); // Minimal 1 poin
  }

  /// Generate poin untuk satu iklan
  /// `watchDurationSeconds` diukur dari saat iklan tampil sampai dismiss
  int _generatePoints(int watchDurationSeconds) {
    final tier = _determineTier(watchDurationSeconds);
    final basePoints = (tier.minPoints + tier.maxPoints) ~/ 2; // Rata-rata tier
    return _applyVariation(basePoints);
  }

  /// Hitung trust score penalty
  /// Trust score berkurang jika ada aktivitas mencurigakan
  Future<void> _updateTrustScore(
    SharedPreferences prefs,
    int penaltyPoints,
  ) async {
    final currentTrust = prefs.getInt('trust_score') ?? 70;
    final newTrust = (currentTrust - penaltyPoints).clamp(0, 100);
    await prefs.setInt('trust_score', newTrust);
  }

  /// Check kelayakan user untuk nonton iklan
  /// Return: (eligible, reason)
  Future<(bool, String)> checkEligibility() async {
    final prefs = await SharedPreferences.getInstance();

    // 1. Check trust score
    final trustScore = prefs.getInt('trust_score') ?? 70;
    if (trustScore < 40) {
      return (false, 'Akun Anda dibatasi (Trust Score rendah)');
    }

    // 2. Check daily quota
    final today = DateTime.now();
    final dateKey = 'ad_watch_date_${today.year}-${today.month}-${today.day}';
    final currentCount = prefs.getInt('ad_watch_count_$dateKey') ?? 0;

    if (currentCount >= maxAdsPerDay) {
      return (false, 'Quota harian sudah habis (Max $maxAdsPerDay/hari)');
    }

    // 3. Check cooldown antar iklan
    final lastAdTimestamp = prefs.getInt('last_ad_timestamp') ?? 0;
    final lastAdTime = DateTime.fromMillisecondsSinceEpoch(lastAdTimestamp);
    final timeSinceLastAd = DateTime.now().difference(lastAdTime);

    if (timeSinceLastAd.inMinutes < cooldownMinutes && lastAdTimestamp != 0) {
      final minutesLeft = cooldownMinutes - timeSinceLastAd.inMinutes;
      return (false, 'Tunggu $minutesLeft menit sebelum nonton iklan lagi');
    }

    return (true, '');
  }

  /// Award coins berdasarkan durasi iklan ditonton
  /// Dipanggil ketika user selesai atau dismiss iklan
  Future<int> awardPointsForAd(int watchDurationSeconds) async {
    final prefs = await SharedPreferences.getInstance();

    // 1. Validasi durasi (jangan biarkan > 60 detik untuk satu iklan)
    final validDuration = watchDurationSeconds.clamp(0, 60);

    // 2. Hitung poin
    final pointsAwarded = _generatePoints(validDuration);

    // 3. Update daily counter
    final today = DateTime.now();
    final dateKey = 'ad_watch_date_${today.year}-${today.month}-${today.day}';
    final currentCount = prefs.getInt('ad_watch_count_$dateKey') ?? 0;
    await prefs.setInt('ad_watch_count_$dateKey', currentCount + 1);

    // 4. Update last ad timestamp
    await prefs.setInt('last_ad_timestamp', DateTime.now().millisecondsSinceEpoch);

    // 5. Cek anti-fraud: jika user nonton 5 iklan dalam 30 menit = curigai
    final recentAdCountKey = 'recent_ad_count_30min';
    final recentAdTimestampKey = 'recent_ad_check_time';
    final lastCheckTime = prefs.getInt(recentAdTimestampKey) ?? 0;

    if (DateTime.now().millisecondsSinceEpoch - lastCheckTime > 1800000) {
      // Reset counter setiap 30 menit
      await prefs.setInt(recentAdCountKey, 0);
      await prefs.setInt(recentAdTimestampKey, DateTime.now().millisecondsSinceEpoch);
    }

    int recentCount = prefs.getInt(recentAdCountKey) ?? 0;
    recentCount++;

    if (recentCount > 5) {
      // Penalty jika ada pattern farming
      await _updateTrustScore(prefs, 5);
    }

    await prefs.setInt(recentAdCountKey, recentCount);

    return pointsAwarded;
  }

  /// Reset daily counter (utility untuk testing atau reset harian)
  Future<void> resetDailyCounter() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final dateKey = 'ad_watch_date_${today.year}-${today.month}-${today.day}';
    await prefs.remove('ad_watch_count_$dateKey');
  }

  /// Get remaining ads today
  Future<int> getRemainingAdsToday() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final dateKey = 'ad_watch_date_${today.year}-${today.month}-${today.day}';
    final currentCount = prefs.getInt('ad_watch_count_$dateKey') ?? 0;
    return (maxAdsPerDay - currentCount).clamp(0, maxAdsPerDay);
  }

  /// Get current trust score
  Future<int> getTrustScore() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('trust_score') ?? 70;
  }
}
