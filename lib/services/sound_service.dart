import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SoundService {
  SoundService._();
  static final SoundService instance = SoundService._();

  final AudioPlayer _player = AudioPlayer();

  /// Play sound when a 4 is scored
  Future<void> playFour() async {
    await _playSound('sounds/boundary_four.wav');
  }

  /// Play sound when a 6 is scored
  Future<void> playSix() async {
    await _playSound('sounds/boundary_six.wav');
  }

  /// Play sound when a wicket falls
  Future<void> playWicket() async {
    await _playSound('sounds/wicket.wav');
  }

  /// Play sound on match victory
  Future<void> playMatchEnd() async {
    await _playSound('sounds/match_victory.wav');
  }

  /// Play short preview when user turns sounds ON in Settings
  Future<void> playPreview() async {
    await _playSound('sounds/boundary_four.wav', ignorePreference: true);
  }

  Future<void> _playSound(String assetPath, {bool ignorePreference = false}) async {
    try {
      if (!ignorePreference) {
        final prefs = await SharedPreferences.getInstance();
        final enabled = prefs.getBool('settings_sound_effects') ?? true;
        if (!enabled) return;
      }
      await _player.stop();
      await _player.play(AssetSource(assetPath));
    } catch (e) {
      debugPrint('SoundService._playSound error ($assetPath): $e');
    }
  }

  void dispose() {
    _player.dispose();
  }
}
