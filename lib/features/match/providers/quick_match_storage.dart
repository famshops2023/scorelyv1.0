import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../match_setup_screen.dart';

class QuickMatchStorage {
  static const _key = 'quick_matches_history';

  static Future<void> saveQuickMatch(MatchSetupData data, {int? storageLimit}) async {
    final prefs = await SharedPreferences.getInstance();
    final limit = storageLimit ?? prefs.getInt('settings_storage_limit') ?? 5;
    
    final jsonStr = prefs.getString(_key);
    List<MatchSetupData> matches = [];
    
    if (jsonStr != null) {
      final List<dynamic> jsonList = jsonDecode(jsonStr);
      matches = jsonList.map((e) => MatchSetupData.fromJson(e)).toList();
    }
    
    // Idempotent insertion: update in-place if match with same ID or creationRequestId exists
    final existingIndex = matches.indexWhere(
      (m) =>
          (data.id.isNotEmpty && m.id == data.id) ||
          (data.creationRequestId != null &&
              data.creationRequestId!.isNotEmpty &&
              m.creationRequestId == data.creationRequestId),
    );

    if (existingIndex >= 0) {
      matches[existingIndex] = data;
    } else {
      // Add new match at the beginning
      matches.insert(0, data);
    }
    
    // FIFO: Keep only the latest matches according to user configuration
    if (matches.length > limit) {
      matches = matches.sublist(0, limit);
    }
    
    final jsonListToSave = matches.map((m) => m.toJson()).toList();
    await prefs.setString(_key, jsonEncode(jsonListToSave));
  }

  static Future<void> pruneToLimit(int limit) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_key);
      if (jsonStr != null) {
        final List<dynamic> jsonList = jsonDecode(jsonStr);
        if (jsonList.length > limit) {
          final pruned = jsonList.sublist(0, limit);
          await prefs.setString(_key, jsonEncode(pruned));
        }
      }
    } catch (_) {}
  }

  static Future<List<MatchSetupData>> getAllMatches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_key);
      if (jsonStr != null) {
        final List<dynamic> jsonList = jsonDecode(jsonStr);
        return jsonList
            .whereType<Map<String, dynamic>>()
            .map((e) => MatchSetupData.fromJson(e))
            .toList();
      }
    } catch (e) {
      // ignore parsing errors
    }
    return [];
  }

  static Future<MatchSetupData?> getLastQuickMatch() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_key);
      if (jsonStr != null) {
        final List<dynamic> jsonList = jsonDecode(jsonStr);
        if (jsonList.isNotEmpty) {
          return MatchSetupData.fromJson(jsonList.first as Map<String, dynamic>);
        }
      }
    } catch (e) {
      // ignore parsing errors
    }
    return null;
  }

  /// Clears all stored quick match history
  static Future<void> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
    } catch (_) {}
  }
}
