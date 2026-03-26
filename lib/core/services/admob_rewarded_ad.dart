import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdMobRewardedAd {
  static final AdMobRewardedAd _instance = AdMobRewardedAd._internal();

  AdMobRewardedAd._internal();

  factory AdMobRewardedAd() {
    return _instance;
  }

  RewardedAd? _rewardedAd;
  bool _isLoading = false;

  // Ad Unit ID untuk testing (ganti dengan production ID di build.gradle)
  static const String testAdUnitId = 'ca-app-pub-3940256099954163/5224354917';

  /// Load rewarded ad
  Future<void> loadAd({
    required Function(RewardedAd ad) onAdLoaded,
    required Function(LoadAdError error) onAdFailedToLoad,
  }) async {
    if (_isLoading || _rewardedAd != null) return;

    _isLoading = true;

    try {
      await RewardedAd.load(
        adUnitId: testAdUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (RewardedAd ad) {
            _rewardedAd = ad;
            _isLoading = false;
            onAdLoaded(ad);
          },
          onAdFailedToLoad: (LoadAdError error) {
            _isLoading = false;
            onAdFailedToLoad(error);
          },
        ),
      );
    } catch (e) {
      _isLoading = false;
      rethrow;
    }
  }

  /// Show rewarded ad dan track durasi menonton
  Future<int?> showAd({
    required Function(RewardItem rewardItem) onUserEarnedReward,
  }) async {
    if (_rewardedAd == null) return null;

    int watchDurationSeconds = 0;
    final adStartTime = DateTime.now();

    try {
      await _rewardedAd!.show(
        onUserEarnedReward: (AdWithoutView ad, RewardItem rewardItem) {
          // Hitung durasi menonton
          watchDurationSeconds =
              DateTime.now().difference(adStartTime).inSeconds;
          onUserEarnedReward(rewardItem);
        },
      );
    } catch (e) {
      rethrow;
    }

    // Cleanup
    _rewardedAd?.dispose();
    _rewardedAd = null;

    return watchDurationSeconds;
  }

  /// Dispose ad
  void dispose() {
    _rewardedAd?.dispose();
    _rewardedAd = null;
  }

  /// Check apakah ad ready
  bool get isAdReady => _rewardedAd != null;
}
