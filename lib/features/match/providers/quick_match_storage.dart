import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../match_setup_screen.dart';

class QuickMatchStorage {
  static const _key = 'quick_matches_history';

  static Future<void> saveQuickMatch(MatchSetupData data) async {
    final prefs = await SharedPreferences.getInstance();
    final limit = prefs.getInt('settings_storage_limit') ?? 5;
    
    final jsonStr = prefs.getString(_key);
    List<MatchSetupData> matches = [];
    
    if (jsonStr != null) {
      final List<dynamic> jsonList = jsonDecode(jsonStr);
      matches = jsonList.map((e) => MatchSetupData.fromJson(e)).toList();
    }
    
    // Add new match at the beginning
    matches.insert(0, data);
    
    // FIFO: Keep only the latest matches according to user configuration
    if (matches.length > limit) {
      matches = matches.sublist(0, limit);
    }
    
    final jsonListToSave = matches.map((m) => m.toJson()).toList();
    await prefs.setString(_key, jsonEncode(jsonListToSave));
  }
}
