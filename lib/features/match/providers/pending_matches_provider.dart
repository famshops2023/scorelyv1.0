import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../match_setup_screen.dart';
import '../../../providers/profile_provider.dart';

class PendingMatchesNotifier extends Notifier<List<MatchSetupData>> {
  static const _key = 'pending_matches_v1';
  
  static const _url = 'https://ip53vj9s.ap-southeast.insforge.app/api/database/records/pending_matches';
  static const _headers = {
    'apikey': 'ik_d23aa9a406864853f254a0722fc1e56b',
    'Authorization': 'Bearer ik_d23aa9a406864853f254a0722fc1e56b',
    'Content-Type': 'application/json',
    'Prefer': 'return=representation',
  };

  @override
  List<MatchSetupData> build() {
    _loadFromPrefs();
    _fetchFromInsForge();
    return [];
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_key);
    if (jsonStr != null) {
      final List<dynamic> jsonList = jsonDecode(jsonStr);
      final matches = jsonList.map((e) => MatchSetupData.fromJson(e)).toList();
      state = matches;
    }
  }

  Future<void> _saveToPrefs(List<MatchSetupData> matches) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = matches.map((m) => m.toJson()).toList();
    await prefs.setString(_key, jsonEncode(jsonList));
  }

  Future<void> _fetchFromInsForge() async {
    final isLoggedIn = ref.read(profileProvider).isLoggedIn;
    if (!isLoggedIn) return;
    try {
      final res = await http.get(Uri.parse('$_url?select=*'), headers: _headers);
      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        final matches = data.map((e) {
          // Assuming InsForge stores the full JSON in a 'match_data' column
          final jsonMap = e['match_data'] as Map<String, dynamic>;
          return MatchSetupData.fromJson(jsonMap);
        }).toList();
        
        state = matches;
        await _saveToPrefs(matches);
      }
    } catch (e) {
      // If API fails (e.g. table doesn't exist yet), we fallback to local state loaded from prefs
      debugPrint('InsForge sync failed: $e');
    }
  }

  Future<void> addOrUpdateMatch(MatchSetupData match) async {
    // 1. Update local state immediately for fast UI
    final existingIndex = state.indexWhere((m) => m.id == match.id);
    List<MatchSetupData> newState;
    if (existingIndex >= 0) {
      newState = List.from(state)..[existingIndex] = match;
    } else {
      newState = [...state, match];
    }
    state = newState;
    await _saveToPrefs(newState);

    // 2. Sync to InsForge
    final isLoggedIn = ref.read(profileProvider).isLoggedIn;
    if (!isLoggedIn) return;
    try {
      final body = jsonEncode({
        'id': match.id,
        'status': match.status,
        'match_data': match.toJson(),
      });

      if (existingIndex >= 0) {
        // Update existing row
        await http.patch(
          Uri.parse('$_url?id=eq.${match.id}'),
          headers: _headers,
          body: body,
        );
      } else {
        // Insert new row
        await http.post(
          Uri.parse(_url),
          headers: _headers,
          body: body,
        );
      }
    } catch (e) {
      debugPrint('Failed to sync match to InsForge: $e');
    }
  }

  Future<void> removeMatch(String matchId) async {
    // 1. Update local state
    final newState = state.where((m) => m.id != matchId).toList();
    state = newState;
    await _saveToPrefs(newState);

    // 2. Delete from InsForge
    final isLoggedIn = ref.read(profileProvider).isLoggedIn;
    if (!isLoggedIn) return;
    try {
      await http.delete(
        Uri.parse('$_url?id=eq.$matchId'),
        headers: _headers,
      );
    } catch (e) {
      debugPrint('Failed to delete match from InsForge: $e');
    }
  }
}

final pendingMatchesProvider = NotifierProvider<PendingMatchesNotifier, List<MatchSetupData>>(() {
  return PendingMatchesNotifier();
});
