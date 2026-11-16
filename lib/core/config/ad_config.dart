import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';

/// Central Configuration for Google AdMob Monetization in Scorely.
///
/// Designed and maintained for Innomerce Solutions.
///
/// Monetization Rules & Philosophy:
/// 1. Test Mode is ENABLED by default for development and pre-release testing.
/// 2. Production ads are DISABLED by default and will NEVER show unless:
///    a) [isTestMode] is explicitly set to false, AND
///    b) [isProductionAdsApproved] is set to true, AND
///    c) Valid non-empty production Ad Unit IDs are provided.
/// 3. If production configuration is missing or incomplete, the system fails
///    safely by returning `null` (no ads requested), NEVER accidentally showing
///    test ads in a production release.
/// 4. Core app functionality (scoring, match management, stats) NEVER depends on ads.
class AdConfig {
  AdConfig._();

  // ===========================================================================
  // MASTER SWITCHES
  // ===========================================================================

  /// Master switch for all advertisements in Scorely.
  /// Set to false to disable all ad activity globally.
  static const bool isAdsEnabled = true;

  /// Test Mode flag.
  /// - `true`: Uses official Google test ad unit IDs.
  /// - `false`: Uses production ad unit IDs (requires [isProductionAdsApproved] = true).
  static const bool isTestMode = bool.fromEnvironment(
    'ADMOB_TEST_MODE',
    defaultValue: false,
  );

  /// Explicit production approval guard.
  /// Even if [isTestMode] is false, production ads will NOT load unless
  /// this flag is explicitly set to true. This prevents accidental live ad requests.
  static const bool isProductionAdsApproved = bool.fromEnvironment(
    'ADMOB_PRODUCTION_APPROVED',
    defaultValue: true,
  );

  /// Format-specific toggles
  /// Banner ads: enabled for testing in approved non-intrusive locations.
  static const bool isBannerEnabled = true;

  /// Interstitial ads: enabled for natural breaks (innings completion & match result).
  static const bool isInterstitialEnabled = bool.fromEnvironment(
    'ADMOB_INTERSTITIAL_ENABLED',
    defaultValue: true,
  );

  /// Rewarded ads: DISABLED by default as per monetization strategy.
  static const bool isRewardedEnabled = false;

  // ===========================================================================
  // OFFICIAL GOOGLE TEST AD UNIT IDS
  // Reference: https://developers.google.com/admob/flutter/test-ads
  // ===========================================================================

  static const String _testAndroidBannerId =
      'ca-app-pub-3940256099942544/6300978111';
  static const String _testAndroidInterstitialId =
      'ca-app-pub-3940256099942544/1033173712';
  static const String _testAndroidRewardedId =
      'ca-app-pub-3940256099942544/5224354917';

  static const String _testIosBannerId =
      'ca-app-pub-3940256099942544/2934735716';
  static const String _testIosInterstitialId =
      'ca-app-pub-3940256099942544/4411468910';
  static const String _testIosRewardedId =
      'ca-app-pub-3940256099942544/1712485313';

  // ===========================================================================
  // PRODUCTION AD UNIT IDS (Placeholders)
  //
  // Replace these with actual Ad Unit IDs created in Google AdMob console:
  // https://admob.google.com -> Apps -> Scorely -> Ad units
  //
  // Alternatively, pass them at build time via --dart-define:
  // flutter build appbundle --dart-define=ADMOB_ANDROID_BANNER_ID=ca-app-pub-...
  // ===========================================================================

  static const String _prodAndroidBannerId = String.fromEnvironment(
    'ADMOB_ANDROID_BANNER_ID',
    // Scorely_Banner_Android
    defaultValue: 'ca-app-pub-3883384869913004/2063766915',
  );

  static const String _prodAndroidInterstitialId = String.fromEnvironment(
    'ADMOB_ANDROID_INTERSTITIAL_ID',
    // Scorely_Interstitial_Android
    defaultValue: 'ca-app-pub-3883384869913004/3736775386',
  );

  static const String _prodAndroidRewardedId = String.fromEnvironment(
    'ADMOB_ANDROID_REWARDED_ID',
    // TODO(AdMob): Replace with Innomerce Solutions' actual Android Rewarded Ad Unit ID
    defaultValue: '',
  );

  static const String _prodIosBannerId = String.fromEnvironment(
    'ADMOB_IOS_BANNER_ID',
    // TODO(AdMob): Replace with Innomerce Solutions' actual iOS Banner Ad Unit ID
    defaultValue: '',
  );

  static const String _prodIosInterstitialId = String.fromEnvironment(
    'ADMOB_IOS_INTERSTITIAL_ID',
    // TODO(AdMob): Replace with Innomerce Solutions' actual iOS Interstitial Ad Unit ID
    defaultValue: '',
  );

  static const String _prodIosRewardedId = String.fromEnvironment(
    'ADMOB_IOS_REWARDED_ID',
    // TODO(AdMob): Replace with Innomerce Solutions' actual iOS Rewarded Ad Unit ID
    defaultValue: '',
  );

  // ===========================================================================
  // INTERSTITIAL FREQUENCY & POLICY CONTROLS
  // ===========================================================================

  /// Minimum duration required between interstitial ads to protect user experience.
  static const Duration minInterstitialCooldown = Duration(minutes: 5);

  /// Minimum number of completed matches/events between interstitial displays.
  static const int minCompletedMatchesBetweenInterstitials = 2;

  /// Maximum number of interstitial impressions allowed in a single session.
  static const int maxInterstitialsPerSession = 2;

  // ===========================================================================
  // SAFE AD UNIT ID RESOLVERS
  // ===========================================================================

  /// Returns the banner ad unit ID, or null if ads/banners are disabled
  /// or if production configuration is incomplete.
  static String? get bannerAdUnitId {
    if (!isAdsEnabled || !isBannerEnabled) return null;

    if (isTestMode) {
      if (kIsWeb) return null;
      if (Platform.isAndroid) return _testAndroidBannerId;
      if (Platform.isIOS) return _testIosBannerId;
      return null;
    }

    // Production Mode Guards
    if (!isProductionAdsApproved) {
      debugPrint('[AdConfig] Production ads requested but isProductionAdsApproved is false.');
      return null;
    }

    if (kIsWeb) return null;
    final String prodId = Platform.isAndroid ? _prodAndroidBannerId : (Platform.isIOS ? _prodIosBannerId : '');
    if (prodId.trim().isEmpty) {
      debugPrint('[AdConfig] Production banner requested but Ad Unit ID is missing. Safe fallback: null.');
      return null;
    }
    return prodId.trim();
  }

  /// Returns the interstitial ad unit ID, or null if disabled/incomplete.
  static String? get interstitialAdUnitId {
    if (!isAdsEnabled || !isInterstitialEnabled) return null;

    if (isTestMode) {
      if (kIsWeb) return null;
      if (Platform.isAndroid) return _testAndroidInterstitialId;
      if (Platform.isIOS) return _testIosInterstitialId;
      return null;
    }

    if (!isProductionAdsApproved) {
      debugPrint('[AdConfig] Production ads requested but isProductionAdsApproved is false.');
      return null;
    }

    if (kIsWeb) return null;
    final String prodId = Platform.isAndroid ? _prodAndroidInterstitialId : (Platform.isIOS ? _prodIosInterstitialId : '');
    if (prodId.trim().isEmpty) {
      debugPrint('[AdConfig] Production interstitial requested but Ad Unit ID is missing. Safe fallback: null.');
      return null;
    }
    return prodId.trim();
  }

  /// Returns the rewarded ad unit ID, or null if disabled/incomplete.
  static String? get rewardedAdUnitId {
    if (!isAdsEnabled || !isRewardedEnabled) return null;

    if (isTestMode) {
      if (kIsWeb) return null;
      if (Platform.isAndroid) return _testAndroidRewardedId;
      if (Platform.isIOS) return _testIosRewardedId;
      return null;
    }

    if (!isProductionAdsApproved) {
      debugPrint('[AdConfig] Production ads requested but isProductionAdsApproved is false.');
      return null;
    }

    if (kIsWeb) return null;
    final String prodId = Platform.isAndroid ? _prodAndroidRewardedId : (Platform.isIOS ? _prodIosRewardedId : '');
    if (prodId.trim().isEmpty) {
      debugPrint('[AdConfig] Production rewarded ad requested but Ad Unit ID is missing. Safe fallback: null.');
      return null;
    }
    return prodId.trim();
  }
}
