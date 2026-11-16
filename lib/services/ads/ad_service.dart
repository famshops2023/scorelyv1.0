import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../core/config/ad_config.dart';
import 'consent_service.dart';

/// Central Ad Service managing Google Mobile Ads SDK lifecycle.
///
/// Designed to initialize asynchronously without blocking main thread,
/// score-keeping, or app navigation.
class AdService {
  AdService._();
  static final AdService instance = AdService._();

  bool _isInitialized = false;
  bool _isInitializing = false;
  InitializationStatus? _initializationStatus;

  bool get isInitialized => _isInitialized;
  InitializationStatus? get initializationStatus => _initializationStatus;

  /// Initializes the Google Mobile Ads SDK and gathers user consent.
  ///
  /// Safe to call multiple times; subsequent calls return immediately.
  /// Failures are caught and logged without disrupting app startup.
  Future<void> initialize() async {
    if (_isInitialized || _isInitializing) return;
    if (kIsWeb) {
      _isInitialized = true;
      return;
    }

    if (!AdConfig.isAdsEnabled) {
      debugPrint('[AdService] Global ads are disabled via AdConfig.');
      return;
    }

    _isInitializing = true;

    try {
      // 1. Gather consent if required by UMP
      await ConsentService.instance.gatherConsent();

      // 2. Initialize the official Google Mobile Ads SDK
      final status = await MobileAds.instance.initialize();
      _initializationStatus = status;
      _isInitialized = true;
      debugPrint('[AdService] MobileAds SDK successfully initialized.');

      // 3. Configure test devices if in test mode
      if (AdConfig.isTestMode && kDebugMode) {
        final configuration = RequestConfiguration(
          testDeviceIds: <String>[], // Add real device hashes here if testing on physical devices
        );
        await MobileAds.instance.updateRequestConfiguration(configuration);
      }
    } catch (e, st) {
      debugPrint('[AdService] Failed to initialize MobileAds: $e\n$st');
      // Do not rethrow; the app must continue working normally even if ads fail
    } finally {
      _isInitializing = false;
    }
  }
}
