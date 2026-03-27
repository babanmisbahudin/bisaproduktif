import 'package:flutter/material.dart';
import '../../core/services/admob_service.dart';
import '../../core/services/admob_rewarded_ad.dart';

class AdMobProvider extends ChangeNotifier {
  final AdMobService _adMobService = AdMobService();
  final AdMobRewardedAd _rewardedAd = AdMobRewardedAd();

  bool _isAdLoading = false;
  bool _isAdShowing = false;
  String? _eligibilityError;
  int _remainingAdsToday = 5;
  int _trustScore = 70;

  bool get isAdLoading => _isAdLoading;
  bool get isAdShowing => _isAdShowing;
  String? get eligibilityError => _eligibilityError;
  int get remainingAdsToday => _remainingAdsToday;
  int get trustScore => _trustScore;
  bool get isAdReady => _rewardedAd.isAdReady;

  /// Check apakah user eligible nonton iklan
  /// Return: (eligible, error message)
  Future<(bool, String)> checkEligibility() async {
    final result = await _adMobService.checkEligibility();
    _eligibilityError = result.$2;
    if (_eligibilityError != null && _eligibilityError!.isNotEmpty) {
      notifyListeners();
      return result;
    }
    return result;
  }

  /// Load rewarded ad
  Future<void> loadAd() async {
    if (_isAdLoading || isAdReady) return;

    _isAdLoading = true;
    notifyListeners();

    try {
      await _rewardedAd.loadAd(
        onAdLoaded: (ad) {
          _isAdLoading = false;
          notifyListeners();
        },
        onAdFailedToLoad: (error) {
          _isAdLoading = false;
          _eligibilityError = 'Gagal load iklan: ${error.message}';
          notifyListeners();
        },
      );
    } catch (e) {
      _isAdLoading = false;
      _eligibilityError = 'Error loading ad: $e';
      notifyListeners();
    }
  }

  /// Show rewarded ad
  Future<int?> showAd() async {
    if (!isAdReady) return null;

    _isAdShowing = true;
    notifyListeners();

    try {
      final watchDurationSeconds = await _rewardedAd.showAd(
        onUserEarnedReward: (rewardItem) {
          // User earned reward
        },
      );

      _isAdShowing = false;
      notifyListeners();

      return watchDurationSeconds;
    } catch (e) {
      _isAdShowing = false;
      _eligibilityError = 'Error showing ad: $e';
      notifyListeners();
      return null;
    }
  }

  /// Award poin berdasarkan durasi menonton (dalam detik)
  /// Return: jumlah poin yang diberikan
  Future<int> awardPointsForAd(int watchDurationSeconds) async {
    final points = await _adMobService.awardPointsForAd(watchDurationSeconds);
    await refreshStats(); // Refresh counter dan trust score
    return points;
  }

  /// Refresh remaining ads dan trust score dari SharedPreferences
  Future<void> refreshStats() async {
    _remainingAdsToday = await _adMobService.getRemainingAdsToday();
    _trustScore = await _adMobService.getTrustScore();
    notifyListeners();
  }

  /// Initialize: load stats dari SharedPreferences
  Future<void> init() async {
    await refreshStats();
  }

  /// Reset (untuk testing atau development)
  Future<void> resetDailyCounter() async {
    await _adMobService.resetDailyCounter();
    await refreshStats();
  }

  @override
  void dispose() {
    _rewardedAd.dispose();
    super.dispose();
  }
}
