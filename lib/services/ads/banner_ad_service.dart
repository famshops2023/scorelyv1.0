import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../core/config/ad_config.dart';
import 'ad_service.dart';

/// Helper service for creating and managing Banner Ads.
class BannerAdService {
  BannerAdService._();
  static final BannerAdService instance = BannerAdService._();

  /// Loads an adaptive or standard banner ad.
  ///
  /// Returns a loaded [BannerAd], or null if ads are disabled,
  /// configuration is incomplete, or the load fails.
  Future<BannerAd?> loadBannerAd({
    required int width,
    required void Function(BannerAd ad) onAdLoaded,
    required void Function(LoadAdError error) onAdFailedToLoad,
  }) async {
    final adUnitId = AdConfig.bannerAdUnitId;
    if (adUnitId == null || adUnitId.isEmpty) {
      debugPrint('[BannerAdService] Banner ad skipped: unit ID is null or empty.');
      return null;
    }

    // Ensure SDK is initialized
    if (!AdService.instance.isInitialized) {
      await AdService.instance.initialize();
      if (!AdService.instance.isInitialized) {
        debugPrint('[BannerAdService] SDK failed to initialize; skipping banner load.');
        return null;
      }
    }

    // Resolve adaptive size
    AdSize size = AdSize.banner;
    if (width > 0) {
      final adaptiveSize =
          await AdSize.getLargeAnchoredAdaptiveBannerAdSize(width);
      if (adaptiveSize != null) {
        size = adaptiveSize;
      }
    }

    BannerAd? bannerAd;
    bannerAd = BannerAd(
      adUnitId: adUnitId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (Ad ad) {
          debugPrint('[BannerAdService] Banner ad loaded successfully.');
          onAdLoaded(ad as BannerAd);
        },
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          debugPrint('[BannerAdService] Banner failed to load: ${error.message} (${error.code})');
          ad.dispose();
          onAdFailedToLoad(error);
        },
        onAdOpened: (Ad ad) => debugPrint('[BannerAdService] Banner opened.'),
        onAdClosed: (Ad ad) => debugPrint('[BannerAdService] Banner closed.'),
        onAdImpression: (Ad ad) => debugPrint('[BannerAdService] Banner impression logged.'),
      ),
    );

    await bannerAd.load();
    return bannerAd;
  }
}
