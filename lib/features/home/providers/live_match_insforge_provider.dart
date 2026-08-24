import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../../models/live_match_data.dart';
import '../../../providers/profile_provider.dart';

// ============================================================
// INSFORGE CONFIG  (same project as pending_matches_provider)
// ============================================================
class _InsForge {
  static const baseUrl =
      'https://ip53vj9s.ap-southeast.insforge.app/api/database/records';
  static const apiKey = 'ik_d23aa9a406864853f254a0722fc1e56b';
  static const headers = {
    'apikey': apiKey,
    'Authorization': 'Bearer $apiKey',
    'Content-Type': 'application/json',
    'Prefer': 'return=representation',
  };
}

/// Fetches live matches from the [pending_matches] table where
/// status = 'live' and the current user is a player or scorer.
/// Auto-refreshes every 20 seconds.
final liveMatchInsforgeProvider =
    AsyncNotifierProvider<_LiveMatchNotifier, List<LiveMatchData>>(
  _LiveMatchNotifier.new,
);

class _LiveMatchNotifier extends AsyncNotifier<List<LiveMatchData>> {
  Timer? _refreshTimer;

  @override
  Future<List<LiveMatchData>> build() async {
    // Cancel any existing timer when provider rebuilds
    ref.onDispose(() => _refreshTimer?.cancel());

    // Schedule 20-second auto-refresh
    _refreshTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      ref.invalidateSelf();
    });

    return _fetch();
  }

  Future<List<LiveMatchData>> _fetch() async {
    try {
      final profile = ref.read(profileProvider);
      final myId = profile.id;

      final url =
          '${_InsForge.baseUrl}/pending_matches?status=eq.live&select=*';
      final res = await http.get(Uri.parse(url), headers: _InsForge.headers);

      if (res.statusCode != 200) return [];

      final List<dynamic> data = jsonDecode(res.body);
      final all = data
          .map((e) => LiveMatchData.fromInsForgeRow(e as Map<String, dynamic>))
          .toList();

      if (myId.isEmpty) return all; // If no profile yet, show all live matches

      // Filter to matches where the user is a scorer or player
      return all.where((m) {
        return m.scorerId == myId ||
            m.teamAPlayerIds.contains(myId) ||
            m.teamBPlayerIds.contains(myId);
      }).toList();
    } catch (e) {
      debugPrint('LiveMatchInsforgeProvider: fetch failed — $e');
      return [];
    }
  }
}
