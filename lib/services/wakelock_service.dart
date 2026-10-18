import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class WakelockService {
  WakelockService._();
  static final WakelockService instance = WakelockService._();

  bool _isWakelockActive = false;

  /// Enable wakelock if user preference allows it (defaults to true).
  Future<void> enableIfAllowed() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final allowed = prefs.getBool('settings_keep_awake') ?? true;
      if (allowed) {
        await WakelockPlus.enable();
        _isWakelockActive = true;
        debugPrint('WakelockService: Screen wakelock enabled.');
      } else {
        await WakelockPlus.disable();
        _isWakelockActive = false;
        debugPrint('WakelockService: Wakelock disabled by user setting.');
      }
    } catch (e) {
      debugPrint('WakelockService.enableIfAllowed error: $e');
    }
  }

  /// Disable wakelock when exiting the scoring screen.
  Future<void> disable() async {
    try {
      if (_isWakelockActive) {
        await WakelockPlus.disable();
        _isWakelockActive = false;
        debugPrint('WakelockService: Screen wakelock released.');
      }
    } catch (e) {
      debugPrint('WakelockService.disable error: $e');
    }
  }

  /// Called when user toggles the switch in Settings.
  Future<void> updateSetting(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('settings_keep_awake', enabled);
      if (!enabled && _isWakelockActive) {
        await WakelockPlus.disable();
        _isWakelockActive = false;
      }
    } catch (e) {
      debugPrint('WakelockService.updateSetting error: $e');
    }
  }
}
