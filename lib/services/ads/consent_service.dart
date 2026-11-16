import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../core/config/ad_config.dart';

/// Service managing user privacy and consent via Google User Messaging Platform (UMP).
///
/// Complies with Google Play policy, GDPR, and ePrivacy Directive.
class ConsentService {
  ConsentService._();
  static final ConsentService instance = ConsentService._();

  bool _isConsentGathered = false;
  bool get isConsentGathered => _isConsentGathered;

  /// Gathers user consent if required by geography / policy.
  /// Does NOT throw errors or block app startup.
  Future<void> gatherConsent() async {
    if (kIsWeb || !AdConfig.isAdsEnabled) {
      _isConsentGathered = true;
      return;
    }

    final completer = Completer<void>();

    final params = ConsentRequestParameters(
      // In production, keep tagForUnderAgeOfConsent false unless targeting under 18.
      tagForUnderAgeOfConsent: false,
    );

    ConsentInformation.instance.requestConsentInfoUpdate(
      params,
      () async {
        try {
          ConsentForm.loadAndShowConsentFormIfRequired(
            (FormError? formError) {
              if (formError != null) {
                debugPrint(
                  '[ConsentService] Consent form error: ${formError.errorCode} - ${formError.message}',
                );
              }
              _isConsentGathered = true;
              if (!completer.isCompleted) completer.complete();
            },
          );
        } catch (e) {
          debugPrint('[ConsentService] Error loading/showing consent form: $e');
          _isConsentGathered = true;
          if (!completer.isCompleted) completer.complete();
        }
      },
      (FormError error) {
        debugPrint(
          '[ConsentService] Consent info update failed: ${error.errorCode} - ${error.message}',
        );
        _isConsentGathered = true;
        if (!completer.isCompleted) completer.complete();
      },
    );

    // Timeout after 3 seconds so slow or failed consent requests never stall the app
    return completer.future.timeout(
      const Duration(seconds: 3),
      onTimeout: () {
        debugPrint('[ConsentService] Consent gathering timed out. Continuing safely.');
        _isConsentGathered = true;
      },
    );
  }

  /// Determines whether the app has permission to request ads based on UMP status.
  Future<bool> canRequestAds() async {
    if (kIsWeb || !AdConfig.isAdsEnabled) return false;
    try {
      return await ConsentInformation.instance.canRequestAds();
    } catch (e) {
      debugPrint('[ConsentService] Error checking canRequestAds: $e');
      return true; // Fallback to allowing request in development/testing
    }
  }

  /// Allows the user to change or review their privacy choices (required in EU/EEA).
  /// Returns `true` if the native Google UMP form was presented, `false` otherwise.
  Future<bool> showPrivacyOptionsForm() async {
    if (kIsWeb) return false;
    try {
      final status =
          await ConsentInformation.instance.getPrivacyOptionsRequirementStatus();
      if (status == PrivacyOptionsRequirementStatus.required) {
        final completer = Completer<bool>();
        ConsentForm.showPrivacyOptionsForm((FormError? formError) {
          if (formError != null) {
            debugPrint(
              '[ConsentService] Privacy options error: ${formError.errorCode} - ${formError.message}',
            );
            completer.complete(false);
          } else {
            completer.complete(true);
          }
        });
        return await completer.future;
      }
      return false;
    } catch (e) {
      debugPrint('[ConsentService] Error checking privacy options status: $e');
      return false;
    }
  }
}
