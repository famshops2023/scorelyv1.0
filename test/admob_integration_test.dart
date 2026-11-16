import 'package:flutter_test/flutter_test.dart';
import 'package:scorely/core/config/ad_config.dart';
import 'package:scorely/services/ads/interstitial_ad_service.dart';
import 'package:scorely/services/ads/rewarded_ad_service.dart';

void main() {
  group('AdConfig Tests', () {
    test('Default configuration flags comply with production launch strategy', () {
      // 1. Ads globally enabled
      expect(AdConfig.isAdsEnabled, isTrue);

      // 2. Production mode enabled (test mode false)
      expect(AdConfig.isTestMode, isFalse);

      // 3. Production ads approved
      expect(AdConfig.isProductionAdsApproved, isTrue);

      // 4. Banner ads enabled for approved locations
      expect(AdConfig.isBannerEnabled, isTrue);

      // 5. Interstitials enabled for natural breaks, rewarded ads disabled by default
      expect(AdConfig.isInterstitialEnabled, isTrue);
      expect(AdConfig.isRewardedEnabled, isFalse);
    });

    test('In test mode, bannerAdUnitId returns official Google test ID on mobile', () {
      final bannerId = AdConfig.bannerAdUnitId;
      // On desktop/mobile test environment
      if (bannerId != null) {
        expect(bannerId, contains('ca-app-pub-3940256099942544'));
      }
    });

    test('Disabled ad formats safely return null ad unit IDs', () {
      // Rewarded is disabled by default
      expect(AdConfig.rewardedAdUnitId, isNull);
    });

    test('Frequency control defaults enforce conservative policies', () {
      expect(AdConfig.minInterstitialCooldown, const Duration(minutes: 5));
      expect(AdConfig.minCompletedMatchesBetweenInterstitials, 2);
      expect(AdConfig.maxInterstitialsPerSession, 2);
    });
  });

  group('InterstitialAdService Frequency & Safeguard Tests', () {
    test('canShowInterstitial is false initially when ad is not yet loaded', () {
      final service = InterstitialAdService.instance;
      expect(service.canShowInterstitial, isFalse);
    });

    test('showAdIfEligible immediately invokes onDismissed without stalling when not ready', () async {
      final service = InterstitialAdService.instance;
      bool dismissedCalled = false;

      await service.showAdIfEligible(
        onDismissed: () {
          dismissedCalled = true;
        },
      );

      expect(dismissedCalled, isTrue);
    });

    test('showInningsBreakAd immediately invokes onDismissed without stalling when not ready', () async {
      final service = InterstitialAdService.instance;
      bool dismissedCalled = false;

      await service.showInningsBreakAd(
        onDismissed: () {
          dismissedCalled = true;
        },
      );

      expect(dismissedCalled, isTrue);
    });

    test('recordMatchCompleted increments match count safely without crashing', () {
      final service = InterstitialAdService.instance;
      expect(() => service.recordMatchCompleted(), returnsNormally);
    });
  });

  group('RewardedAdService Safeguard Tests', () {
    test('showAd fails gracefully when rewarded ads are disabled', () async {
      final service = RewardedAdService.instance;
      bool rewardEarned = false;
      String? failureReason;

      await service.showAd(
        onUserEarnedReward: (reward) {
          rewardEarned = true;
        },
        onAdFailedToShow: (reason) {
          failureReason = reason;
        },
      );

      expect(rewardEarned, isFalse);
      expect(failureReason, isNotNull);
      expect(failureReason, contains('disabled'));
    });
  });
}
