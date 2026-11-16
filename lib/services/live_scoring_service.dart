import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/config/insforge_config.dart';
import '../models/match_status.dart';

/// Manages real-time live score updates to InsForge for scheduled matches.
///
/// Behavior:
/// - On every ball, builds a JSON blob and PATCHes the pending_matches row.
/// - If offline, the blob is queued in SharedPreferences.
/// - On reconnect, all queued updates are flushed (only the latest is sent).
class LiveScoringService {
  static String get _baseUrl => InsforgeConfig.recordsUrl;
  static Map<String, String> get _headers => InsforgeConfig.headers;

  /// Returns the current time as an ISO-8601 string with the Indian Standard
  /// Time offset (+05:30).  Optionally accepts a base [dt].
  static String _istNow([DateTime? dt]) {
    final utc = (dt ?? DateTime.now()).toUtc();
    final ist = utc.add(const Duration(hours: 5, minutes: 30));
    final base = ist.toIso8601String();
    final withoutZ = base.endsWith('Z') ? base.substring(0, base.length - 1) : base;
    return '$withoutZ+05:30';
  }

  /// SharedPreferences key for the pending live payload queue.
  static const _queueKey = 'live_score_pending_queue';

  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  String? _matchId; // InsForge pending_matches row ID
  Map<String, dynamic>? _matchData;
  String? _createdByProfileId;
  String? _activeScorerId;
  String _status = MatchStatus.live;
  bool _isOnline = true;

  /// Call once when a match starts scoring.
  void init(
    String insForgeMatchId, {
    Map<String, dynamic>? matchData,
    String? createdByProfileId,
    String? activeScorerId,
    String status = MatchStatus.live,
  }) {
    _matchId = insForgeMatchId;
    _matchData = matchData;
    _createdByProfileId = createdByProfileId;
    _activeScorerId = activeScorerId;
    _status = MatchStatus.normalize(status);
    _connectivitySub = Connectivity()
        .onConnectivityChanged
        .listen(_onConnectivityChanged);
    // Attempt to flush any queued payloads from previous sessions
    _flushQueue();
  }

  void dispose() {
    _connectivitySub?.cancel();
  }

  /// Updates the scorer allowed to write this row.
  ///
  /// Called after the scoring screen re-reads the authoritative
  /// `active_scorer_id`, so a handover recipient pushes updates as the new
  /// scorer instead of the previous one.
  void setActiveScorer(String? scorerId) {
    _activeScorerId = scorerId;
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

  /// Mark the match as complete or abandoned in InsForge.
  Future<void> markMatchCompleted(
    String? winner, {
    String? resultSummary,
    DateTime? completedAt,
    String status = MatchStatus.completed,
  }) async {
    if (_matchId == null || _matchId!.isEmpty) return;
    _status = status;
    try {
      final now = _istNow(completedAt);
      final body = jsonEncode({
        'status': status,
        'winner': winner ?? '',
        if (resultSummary != null && resultSummary.isNotEmpty)
          'result_summary': resultSummary,
        'completed_at': now,
        'updated_at': now,
      });
      final res = await http.patch(
        Uri.parse('$_baseUrl/pending_matches?id=eq.$_matchId'),
        headers: _headers,
        body: body,
      );
      if (res.statusCode == 401) {
        await http.patch(
          Uri.parse('$_baseUrl/pending_matches?id=eq.$_matchId'),
          headers: InsforgeConfig.anonHeaders,
          body: body,
        );
      }
    } catch (e) {
      debugPrint('LiveScoringService.markCompleted error: $e');
    }
  }

  // ─────────────────────────────────────────────
  // Private helpers
  // ─────────────────────────────────────────────

  /// Signed-in players embedded in the setup, used for association-based RLS.
  List<String> _collectPlayerProfileIds() {
    final md = _matchData;
    final ids = <String>{};
    if (md != null) {
      for (final key in const ['teamAPlayers', 'teamBPlayers']) {
        final list = md[key];
        if (list is! List) continue;
        for (final player in list) {
          if (player is! Map) continue;
          final pid = player['profileId']?.toString();
          if (pid != null && pid.isNotEmpty) ids.add(pid);
        }
      }
    }
    // The active scorer is always associated with the row, even when they are
    // a squad member outside the playing XI. The INSERT policy checks that the
    // active scorer appears in this list.
    final scorer = _activeScorerId;
    if (scorer != null && scorer.isNotEmpty) ids.add(scorer);
    return ids.toList();
  }

  Future<bool> _sendPatch(String id, Map<String, dynamic> blob) async {
    try {
      final playerIds = _collectPlayerProfileIds();
      final body = {
        'id': id,
        'live_score_data': blob,
        'status': _status,
        if (_createdByProfileId != null && _createdByProfileId!.isNotEmpty)
          'created_by_profile_id': _createdByProfileId,
        // Required so a handover recipient can upsert the existing row: the
        // INSERT policy accepts the authenticated active scorer as well as the
        // creator.
        if (_activeScorerId != null && _activeScorerId!.isNotEmpty)
          'active_scorer_id': _activeScorerId,
        // Keeps associated players able to read the live row via RLS.
        if (playerIds.isNotEmpty) 'player_profile_ids': playerIds,
        if (_matchData != null)
          'match_data': _matchData,
      };
      var res = await http
          .post(
            Uri.parse('$_baseUrl/pending_matches'),
            headers: {
              ..._headers,
              'Prefer': 'resolution=merge-duplicates,return=representation',
            },
            body: jsonEncode([body]),
          )
          .timeout(const Duration(seconds: 8));
      if (res.statusCode == 401) {
        // Retry with anonHeaders to guarantee live update is not lost due to expired token
        res = await http
            .post(
              Uri.parse('$_baseUrl/pending_matches'),
              headers: {
                ...InsforgeConfig.anonHeaders,
                'Prefer': 'resolution=merge-duplicates,return=representation',
              },
              body: jsonEncode([body]),
            )
            .timeout(const Duration(seconds: 8));
      }
      if (res.statusCode == 200 || res.statusCode == 201 || res.statusCode == 204) {
        return true;
      }
      debugPrint(
          'LiveScoringService: upsert failed (${res.statusCode}): ${res.body}');
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
