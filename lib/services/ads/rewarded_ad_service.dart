import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../core/config/ad_config.dart';
import 'ad_service.dart';

/// Service managing Rewarded Ads for Scorely.
///
/// Monetization & Policy Guardrails:
/// - DISABLED by default ([AdConfig.isRewardedEnabled] = false).
/// - Essential cricket scoring and match functionality are ALWAYS free and never gated.
/// - Grants rewards ONLY upon verified completion via [onUserEarnedReward].
/// - Guarded against duplicate reward grants.
class RewardedAdService {
  RewardedAdService._();
  static final RewardedAdService instance = RewardedAdService._();

  RewardedAd? _rewardedAd;
  bool _isLoading = false;
  bool _isShowing = false;

  bool get isAdReady => _rewardedAd != null && !_isShowing;

  /// Preloads a rewarded ad asynchronously.
  Future<void> loadAd() async {
    if (kIsWeb || !AdConfig.isAdsEnabled || !AdConfig.isRewardedEnabled) {
      return;
    }

    final adUnitId = AdConfig.rewardedAdUnitId;
    if (adUnitId == null || _isLoading || _rewardedAd != null) {
      return;
    }

    _isLoading = true;

    // Ensure SDK is initialized
    if (!AdService.instance.isInitialized) {
      await AdService.instance.initialize();
      if (!AdService.instance.isInitialized) {
        _isLoading = false;
        return;
      }
    }

    try {
      await RewardedAd.load(
        adUnitId: adUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (RewardedAd ad) {
            debugPrint('[RewardedAdService] Rewarded ad loaded.');
            _rewardedAd = ad;
            _isLoading = false;
          },
          onAdFailedToLoad: (LoadAdError error) {
            debugPrint(
              '[RewardedAdService] Rewarded ad failed to load: ${error.message} (${error.code})',
            );
            _rewardedAd = null;
            _isLoading = false;
          },
        ),
      );
    } catch (e) {
      debugPrint('[RewardedAdService] Exception loading rewarded ad: $e');
      _isLoading = false;
    }
  }

  /// Displays the rewarded ad.
  ///
  /// Parameters:
  /// - [onUserEarnedReward]: Called strictly when the user earns the reward via SDK callback.
  ///   Guaranteed to only be called once per ad display.
  /// - [onAdDismissed]: Called when the ad is closed (regardless of whether reward was earned).
  /// - [onAdFailedToShow]: Called if the ad fails to show.
  Future<void> showAd({
    required void Function(RewardItem reward) onUserEarnedReward,
    VoidCallback? onAdDismissed,
    void Function(String reason)? onAdFailedToShow,
  }) async {
    if (kIsWeb || !AdConfig.isAdsEnabled || !AdConfig.isRewardedEnabled) {
      onAdFailedToShow?.call('Rewarded ads are currently disabled.');
      return;
    }

    if (_rewardedAd == null) {
      onAdFailedToShow?.call('Rewarded ad is not ready yet.');
      return;
    }

    if (_isShowing) {
      onAdFailedToShow?.call('An ad is already being displayed.');
      return;
    }

    _isShowing = true;
    bool rewardGranted = false;

    final ad = _rewardedAd!;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (RewardedAd ad) {
        debugPrint('[RewardedAdService] Rewarded ad opened.');
      },
      onAdDismissedFullScreenContent: (RewardedAd ad) {
        debugPrint('[RewardedAdService] Rewarded ad dismissed.');
        ad.dispose();
        _rewardedAd = null;
        _isShowing = false;
        onAdDismissed?.call();
      },
      onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
        debugPrint('[RewardedAdService] Failed to show rewarded ad: ${error.message}');
        ad.dispose();
        _rewardedAd = null;
        _isShowing = false;
        onAdFailedToShow?.call(error.message);
      },
    );

    try {
      await ad.show(
        onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
          if (!rewardGranted) {
            rewardGranted = true;
            debugPrint(
              '[RewardedAdService] User earned reward: ${reward.amount} ${reward.type}',
            );
            onUserEarnedReward(reward);
          }
        },
      );
    } catch (e) {
      debugPrint('[RewardedAdService] Exception showing rewarded ad: $e');
      ad.dispose();
      _rewardedAd = null;
      _isShowing = false;
      onAdFailedToShow?.call(e.toString());
    }
  }

  /// Disposes of any cached rewarded ad.
  void dispose() {
    _rewardedAd?.dispose();
    _rewardedAd = null;
    _isLoading = false;
    _isShowing = false;
  }
}
