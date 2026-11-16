import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../core/config/ad_config.dart';
import 'ad_service.dart';

/// Service managing Interstitial Ads for Scorely.
///
/// Monetization & Policy Guardrails:
/// - DISABLED by default ([AdConfig.isInterstitialEnabled] = false).
/// - Enforces cooldown durations, match completion counts, and session caps.
/// - Only designed for natural breaks (e.g. match completion summary).
/// - NEVER blocks scoring, match saving, or critical user flows.
class InterstitialAdService {
  InterstitialAdService._();
  static final InterstitialAdService instance = InterstitialAdService._();

  InterstitialAd? _interstitialAd;
  bool _isLoading = false;
  bool _isShowing = false;

  DateTime? _lastShownTime;
  int _completedMatchesSinceLastAd = 0;
  int _sessionImpressionCount = 0;

  bool get isAdReady => _interstitialAd != null && !_isShowing;

  /// Call this when a match is completed to increment the policy counter.
  void recordMatchCompleted() {
    _completedMatchesSinceLastAd++;
    // Pre-load if interstitial is enabled and not already loaded
    if (AdConfig.isInterstitialEnabled && _interstitialAd == null && !_isLoading) {
      loadAd();
    }
  }

  /// Evaluates frequency and policy rules before displaying an interstitial.
  /// If [bypassMatchCount] is true (e.g. at 1st innings break), completed match threshold check is skipped.
  bool canShow({bool bypassMatchCount = false}) {
    if (kIsWeb || !AdConfig.isAdsEnabled || !AdConfig.isInterstitialEnabled) {
      return false;
    }

    if (AdConfig.interstitialAdUnitId == null) {
      return false;
    }

    if (_interstitialAd == null || _isShowing) {
      return false;
    }

    // Check session impression limit
    if (_sessionImpressionCount >= AdConfig.maxInterstitialsPerSession) {
      debugPrint('[InterstitialAdService] Session limit reached.');
      return false;
    }

    // Check completed match threshold (skipped during natural innings break)
    if (!bypassMatchCount &&
        _completedMatchesSinceLastAd < AdConfig.minCompletedMatchesBetweenInterstitials) {
      debugPrint(
        '[InterstitialAdService] Threshold not met: $_completedMatchesSinceLastAd / ${AdConfig.minCompletedMatchesBetweenInterstitials} matches.',
      );
      return false;
    }

    // Check cooldown duration
    if (_lastShownTime != null) {
      final elapsed = DateTime.now().difference(_lastShownTime!);
      if (elapsed < AdConfig.minInterstitialCooldown) {
        debugPrint(
          '[InterstitialAdService] Cooldown active. Elapsed: ${elapsed.inMinutes}m, required: ${AdConfig.minInterstitialCooldown.inMinutes}m.',
        );
        return false;
      }
    }

    return true;
  }

  /// Evaluates standard post-match rules before displaying an interstitial.
  bool get canShowInterstitial => canShow(bypassMatchCount: false);

  /// Preloads an interstitial ad asynchronously.
  Future<void> loadAd() async {
    if (kIsWeb || !AdConfig.isAdsEnabled || !AdConfig.isInterstitialEnabled) {
      return;
    }

    final adUnitId = AdConfig.interstitialAdUnitId;
    if (adUnitId == null || _isLoading || _interstitialAd != null) {
      return;
    }

    _isLoading = true;

    // Ensure SDK is ready
    if (!AdService.instance.isInitialized) {
      await AdService.instance.initialize();
      if (!AdService.instance.isInitialized) {
        _isLoading = false;
        return;
      }
    }

    try {
      await InterstitialAd.load(
        adUnitId: adUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (InterstitialAd ad) {
            debugPrint('[InterstitialAdService] Interstitial loaded successfully.');
            _interstitialAd = ad;
            _isLoading = false;

            _interstitialAd!.fullScreenContentCallback =
                FullScreenContentCallback(
              onAdShowedFullScreenContent: (InterstitialAd ad) {
                _isShowing = true;
                debugPrint('[InterstitialAdService] Interstitial displayed.');
              },
              onAdDismissedFullScreenContent: (InterstitialAd ad) {
                debugPrint('[InterstitialAdService] Interstitial dismissed.');
                ad.dispose();
                _interstitialAd = null;
                _isShowing = false;
                _lastShownTime = DateTime.now();
                _completedMatchesSinceLastAd = 0;
                _sessionImpressionCount++;
              },
              onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
                debugPrint(
                  '[InterstitialAdService] Failed to show interstitial: ${error.message}',
                );
                ad.dispose();
                _interstitialAd = null;
                _isShowing = false;
              },
            );
          },
          onAdFailedToLoad: (LoadAdError error) {
            debugPrint(
              '[InterstitialAdService] Interstitial failed to load: ${error.message} (${error.code})',
            );
            _interstitialAd = null;
            _isLoading = false;
          },
        ),
      );
    } catch (e) {
      debugPrint('[InterstitialAdService] Exception during interstitial load: $e');
      _isLoading = false;
    }
  }

  /// Displays the interstitial ad if policy conditions are met.
  ///
  /// [onDismissed] is guaranteed to be invoked so the app can proceed immediately,
  /// whether the ad is shown or not.
  Future<void> showAdIfEligible({
    VoidCallback? onDismissed,
    bool forceBypassMatchCount = false,
  }) async {
    if (!canShow(bypassMatchCount: forceBypassMatchCount)) {
      onDismissed?.call();
      return;
    }

    try {
      final ad = _interstitialAd;
      if (ad != null) {
        // Wrap original callback
        final previousCallback = ad.fullScreenContentCallback;
        ad.fullScreenContentCallback = FullScreenContentCallback(
          onAdShowedFullScreenContent: (ad) {
            previousCallback?.onAdShowedFullScreenContent?.call(ad);
          },
          onAdDismissedFullScreenContent: (ad) {
            previousCallback?.onAdDismissedFullScreenContent?.call(ad);
            onDismissed?.call();
          },
          onAdFailedToShowFullScreenContent: (ad, error) {
            previousCallback?.onAdFailedToShowFullScreenContent?.call(ad, error);
            onDismissed?.call();
          },
        );

        await ad.show();
      } else {
        onDismissed?.call();
      }
    } catch (e) {
      debugPrint('[InterstitialAdService] Exception displaying interstitial: $e');
      _interstitialAd?.dispose();
      _interstitialAd = null;
      _isShowing = false;
      onDismissed?.call();
    }
  }

  /// Displays an interstitial ad specifically after 1st innings completion (before starting the 2nd innings).
  ///
  /// This is a natural transition break compliant with Google AdMob policy.
  /// If the ad cannot be shown (e.g. not loaded, on cooldown, or disabled),
  /// [onDismissed] is called immediately so 2nd innings starts without delay.
  Future<void> showInningsBreakAd({VoidCallback? onDismissed}) async {
    await showAdIfEligible(
      onDismissed: () {
        onDismissed?.call();
        // Pre-load next interstitial for post-match
        loadAd();
      },
      forceBypassMatchCount: true,
    );
  }

  /// Disposes of any cached interstitial ad.
  void dispose() {
    _interstitialAd?.dispose();
    _interstitialAd = null;
    _isLoading = false;
    _isShowing = false;
  }
}
