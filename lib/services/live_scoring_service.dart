import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Manages real-time live score updates to InsForge for scheduled matches.
///
/// Behavior:
/// - On every ball, builds a JSON blob and PATCHes the pending_matches row.
/// - If offline, the blob is queued in SharedPreferences.
/// - On reconnect, all queued updates are flushed (only the latest is sent).
class LiveScoringService {
  static const _baseUrl =
      'https://ip53vj9s.ap-southeast.insforge.app/api/database/records';
  static const _apiKey = 'ik_d23aa9a406864853f254a0722fc1e56b';
  static const _headers = {
    'apikey': _apiKey,
    'Authorization': 'Bearer $_apiKey',
    'Content-Type': 'application/json',
    'Prefer': 'return=representation',
  };

  /// SharedPreferences key for the pending live payload queue.
  static const _queueKey = 'live_score_pending_queue';

  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  String? _matchId; // InsForge pending_matches row ID
  bool _isOnline = true;

  /// Call once when a scheduled match starts scoring.
  void init(String insForgeMatchId) {
    _matchId = insForgeMatchId;
    _connectivitySub = Connectivity()
        .onConnectivityChanged
        .listen(_onConnectivityChanged);
    // Attempt to flush any queued payloads from previous sessions
    _flushQueue();
  }

  void dispose() {
    _connectivitySub?.cancel();
  }

  /// Called after every ball for scheduled matches.
  ///
  /// [scoreBlob] is a Map with keys:
  ///   team_a_score, team_a_overs, team_b_score, team_b_overs,
  ///   innings, last_6_balls, current_batters, current_bowler,
  ///   scorer_id, team_a_player_ids, team_b_player_ids
  Future<void> pushLiveUpdate(Map<String, dynamic> scoreBlob) async {
    if (_matchId == null || _matchId!.isEmpty) return;

    if (_isOnline) {
      final ok = await _sendPatch(_matchId!, scoreBlob);
      if (!ok) {
        debugPrint('LiveScoringService: send failed — queuing update.');
        await _enqueue(_matchId!, scoreBlob);
      }
    } else {
      debugPrint('LiveScoringService: offline — queuing update.');
      await _enqueue(_matchId!, scoreBlob);
    }
  }

  /// Mark the match as complete in InsForge.
  Future<void> markMatchCompleted(String? winner) async {
    if (_matchId == null || _matchId!.isEmpty) return;
    try {
      final body = jsonEncode({
        'status': 'completed',
        'winner': winner ?? '',
      });
      await http.patch(
        Uri.parse('$_baseUrl/pending_matches?id=eq.$_matchId'),
        headers: _headers,
        body: body,
      );
    } catch (e) {
      debugPrint('LiveScoringService.markCompleted error: $e');
    }
  }

  // ─────────────────────────────────────────────
  // Private helpers
  // ─────────────────────────────────────────────

  Future<bool> _sendPatch(String id, Map<String, dynamic> blob) async {
    try {
      final body = jsonEncode({'live_score_data': blob, 'status': 'live'});
      final res = await http
          .patch(
            Uri.parse('$_baseUrl/pending_matches?id=eq.$id'),
            headers: _headers,
            body: body,
          )
          .timeout(const Duration(seconds: 8));
      if (res.statusCode == 200 || res.statusCode == 204) {
        return true;
      }
      debugPrint(
          'LiveScoringService: PATCH failed (${res.statusCode}): ${res.body}');
      return false;
    } catch (e) {
      debugPrint('LiveScoringService._sendPatch error: $e');
      return false;
    }
  }

  /// Persist only the LATEST payload per match (replaces older queue entry).
  Future<void> _enqueue(String id, Map<String, dynamic> blob) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // We store a map of matchId → latest blob so only the latest is resent.
      final raw = prefs.getString(_queueKey);
      final Map<String, dynamic> queue =
          raw != null ? jsonDecode(raw) as Map<String, dynamic> : {};
      queue[id] = blob;
      await prefs.setString(_queueKey, jsonEncode(queue));
    } catch (e) {
      debugPrint('LiveScoringService._enqueue error: $e');
    }
  }

  Future<void> _flushQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_queueKey);
      if (raw == null) return;
      final Map<String, dynamic> queue =
          jsonDecode(raw) as Map<String, dynamic>;
      if (queue.isEmpty) return;

      debugPrint(
          'LiveScoringService: flushing ${queue.length} queued update(s).');
      final toRemove = <String>[];
      for (final entry in queue.entries) {
        final ok = await _sendPatch(
            entry.key, entry.value as Map<String, dynamic>);
        if (ok) toRemove.add(entry.key);
      }
      for (final key in toRemove) {
        queue.remove(key);
      }
      await prefs.setString(_queueKey, jsonEncode(queue));
    } catch (e) {
      debugPrint('LiveScoringService._flushQueue error: $e');
    }
  }

  void _onConnectivityChanged(List<ConnectivityResult> results) {
    final online = results.any((r) => r != ConnectivityResult.none);
    _isOnline = online;
    if (online) {
      debugPrint('LiveScoringService: network restored — flushing queue.');
      _flushQueue();
    }
  }
}
