import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/config/insforge_config.dart';
import '../models/match_status.dart';

/// Server-authoritative helpers for the pending -> live -> completed lifecycle.
///
/// The client never decides on its own whether a match is live or completed:
/// these transitions are written to `pending_matches` (and mirrored onto
/// `matches` where that row exists) and the result is re-read by the scoring
/// screen before it allows any modification.
class MatchLifecycleService {
  MatchLifecycleService._();

  /// Returns the current time formatted as an ISO-8601 string with the
  /// Indian Standard Time offset (+05:30).  PostgREST / PostgreSQL
  /// TIMESTAMPTZ columns accept strings with an explicit offset and store
  /// them correctly, so callers never need to call `.toUtc()` themselves.
  ///
  /// Optionally accepts a base [dt] (e.g. a caller-supplied completedAt
  /// value) so the same IST-aware formatting is applied consistently.
  static String _istNow([DateTime? dt]) {
    final utc = (dt ?? DateTime.now()).toUtc();
    final ist = utc.add(const Duration(hours: 5, minutes: 30));
    // Produce "yyyy-MM-ddTHH:mm:ss.mmm+05:30"
    final base = ist.toIso8601String();
    // Replace the trailing 'Z' (UTC marker) that toIso8601String sometimes
    // adds for UTC instants, then append the IST offset.
    final withoutZ = base.endsWith('Z') ? base.substring(0, base.length - 1) : base;
    return '$withoutZ+05:30';
  }

  static String get _pendingUrl =>
      '${InsforgeConfig.recordsUrl}/pending_matches';
  static String get _matchesUrl => '${InsforgeConfig.recordsUrl}/matches';
  static Map<String, String> get _headers => InsforgeConfig.headers;

  /// Fetches the raw `pending_matches` row, or null when unavailable.
  static Future<Map<String, dynamic>?> fetchRow(String matchId) async {
    if (matchId.isEmpty) return null;
    try {
      final uri = Uri.parse(_pendingUrl).replace(queryParameters: {
        'id': 'eq.$matchId',
        'select': '*',
        'limit': '1',
      });
      final res = await InsforgeConfig.getWithFallback(uri)
          .timeout(const Duration(seconds: 6));
      if (res.statusCode != 200) return null;
      final data = jsonDecode(res.body);
      if (data is List && data.isNotEmpty) {
        return Map<String, dynamic>.from(data.first as Map);
      }
    } catch (e) {
      debugPrint('MatchLifecycleService.fetchRow error: $e');
    }
    return null;
  }

  static Future<String?> fetchActiveScorerId(String matchId) async {
    final row = await fetchRow(matchId);
    final id = row?['active_scorer_id']?.toString();
    if (id != null && id.isNotEmpty) return id;
    return null;
  }

  static Future<String?> fetchStatus(String matchId) async {
    final row = await fetchRow(matchId);
    if (row == null) return null;
    return MatchStatus.normalize(row['status']?.toString());
  }

  static Future<bool> isActiveScorer({
    required String matchId,
    required String profileId,
  }) async {
    if (matchId.isEmpty || profileId.isEmpty) return false;
    final active = await fetchActiveScorerId(matchId);
    return active != null && active == profileId;
  }

  /// Marks a pending match live and records the single active scorer.
  ///
  /// This must only be called from the Opening Lineup "Proceed to Score"
  /// action, by the signed-in official scorer.
  static Future<bool> markLive({
    required String matchId,
    required String scorerId,
    String? scorerName,
  }) async {
    if (matchId.isEmpty || scorerId.isEmpty) return false;
    try {
      final row = await fetchRow(matchId);
      final matchData = row?['match_data'];
      Map<String, dynamic>? merged;
      if (matchData is Map) {
        merged = Map<String, dynamic>.from(matchData);
      } else if (matchData is String && matchData.isNotEmpty) {
        try {
          final decoded = jsonDecode(matchData);
          if (decoded is Map) merged = Map<String, dynamic>.from(decoded);
        } catch (_) {}
      }
      if (merged != null) {
        merged['status'] = MatchStatus.live;
        merged['activeScorerId'] = scorerId;
        if (scorerName != null && scorerName.isNotEmpty) {
          // First innings uses the team A scorer slot; a second-innings
          // handover must not overwrite the first scorer's identity.
          final hasSecondScorer =
              (merged['teamBScorerId'] ?? '').toString().isNotEmpty;
          if (hasSecondScorer) {
            merged['teamBScorerName'] = scorerName;
          } else {
            merged['teamAScorerName'] = scorerName;
          }
        }
      }

      final body = <String, dynamic>{
        'status': MatchStatus.live,
        'active_scorer_id': scorerId,
        'updated_at': _istNow(),
        'match_data': ?merged,
      };
      final patched =
          await _patch(Uri.parse('$_pendingUrl?id=eq.$matchId'), body);
      if (!patched) return false;

      // A 204 from PostgREST also happens when RLS filtered the row out, so
      // confirm the transition really landed before letting scoring begin.
      final verified = await fetchRow(matchId);
      if (verified == null) return true; // best effort when offline/unreadable
      final status = MatchStatus.normalize(verified['status']?.toString());
      final active = verified['active_scorer_id']?.toString();
      return status == MatchStatus.live && active == scorerId;
    } catch (e) {
      debugPrint('MatchLifecycleService.markLive error: $e');
      return false;
    }
  }

  /// Marks a match completed with its final result metadata.
  ///
  /// When the device is offline the completion is queued and retried by
  /// [flushPendingCompletions] so associated players eventually see the
  /// result popup and Recent Matches entry.
  static Future<bool> markCompleted({
    required String matchId,
    required String resultSummary,
    String? winner,
    DateTime? completedAt,
    String status = MatchStatus.completed,
  }) async {
    if (matchId.isEmpty) return false;
    final now = _istNow(completedAt);
    final body = <String, dynamic>{
      'status': status,
      'result_summary': resultSummary,
      'completed_at': now,
      if (winner != null && winner.isNotEmpty) 'winner': winner,
      'updated_at': now,
    };
    var ok = false;
    try {
      ok = await _patch(Uri.parse('$_pendingUrl?id=eq.$matchId'), body);
    } catch (e) {
      debugPrint('MatchLifecycleService.markCompleted (pending) error: $e');
    }
    if (!ok) {
      await _enqueueCompletion(matchId, resultSummary, winner, now, status: status);
    } else {
      await _removeQueuedCompletion(matchId);
    }
    // Best-effort mirror onto the synced matches table. `matches` has no
    // `winner_team_name` column (only `winner_team_id`), so only the columns
    // that exist are written; an unknown column would reject the whole PATCH.
    try {
      await _patch(Uri.parse('$_matchesUrl?id=eq.$matchId'), {
        'status': status,
        'match_result_summary': resultSummary,
        'updated_at': now,
      });
    } catch (_) {}
    return ok;
  }

  static const _completionQueueKey = 'pending_match_completions_v1';

  static Future<void> _enqueueCompletion(
    String matchId,
    String resultSummary,
    String? winner,
    String completedAt, {
    String status = MatchStatus.completed,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final entries = _decodeQueue(prefs.getString(_completionQueueKey));
      entries.removeWhere((e) => e['id']?.toString() == matchId);
      entries.add({
        'id': matchId,
        'resultSummary': resultSummary,
        'winner': winner,
        'completedAt': completedAt,
        'status': status,
      });
      final bounded = entries.length > 50
          ? entries.sublist(entries.length - 50)
          : entries;
      await prefs.setString(_completionQueueKey, jsonEncode(bounded));
    } catch (e) {
      debugPrint('MatchLifecycleService._enqueueCompletion error: $e');
    }
  }

  static Future<void> _removeQueuedCompletion(String matchId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final entries = _decodeQueue(prefs.getString(_completionQueueKey));
      final before = entries.length;
      entries.removeWhere((e) => e['id']?.toString() == matchId);
      if (entries.length != before) {
        if (entries.isEmpty) {
          await prefs.remove(_completionQueueKey);
        } else {
          await prefs.setString(_completionQueueKey, jsonEncode(entries));
        }
      }
    } catch (e) {
      debugPrint('MatchLifecycleService._removeQueuedCompletion error: $e');
    }
  }

  static List<Map<String, dynamic>> _decodeQueue(String? raw) {
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return decoded
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Retries completions that could not be written while offline.
  static Future<void> flushPendingCompletions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final entries = _decodeQueue(prefs.getString(_completionQueueKey));
      if (entries.isEmpty) return;

      final remaining = <Map<String, dynamic>>[];
      for (final entry in entries) {
        final id = entry['id']?.toString() ?? '';
        if (id.isEmpty) continue;
        final now = entry['completedAt']?.toString().isNotEmpty == true
            ? entry['completedAt'].toString()
            : _istNow();
        final winner = entry['winner']?.toString();
        final summary = entry['resultSummary']?.toString() ?? 'Match completed';
        final status = entry['status']?.toString() ?? MatchStatus.completed;
        final ok = await _patch(Uri.parse('$_pendingUrl?id=eq.$id'), {
          'status': status,
          'result_summary': summary,
          'completed_at': now,
          if (winner != null && winner.isNotEmpty) 'winner': winner,
          'updated_at': now,
        });
        if (!ok) {
          remaining.add(entry);
          continue;
        }
        try {
          await _patch(Uri.parse('$_matchesUrl?id=eq.$id'), {
            'status': status,
            'match_result_summary': summary,
            'updated_at': now,
          });
        } catch (_) {}
      }

      if (remaining.isEmpty) {
        await prefs.remove(_completionQueueKey);
      } else {
        await prefs.setString(_completionQueueKey, jsonEncode(remaining));
      }
    } catch (e) {
      debugPrint('MatchLifecycleService.flushPendingCompletions error: $e');
    }
  }

  static Future<bool> _patch(Uri uri, Map<String, dynamic> body) async {
    final encoded = jsonEncode(body);
    var res = await http
        .patch(uri, headers: _headers, body: encoded)
        .timeout(const Duration(seconds: 8));
    if (res.statusCode == 401) {
      res = await http
          .patch(uri, headers: InsforgeConfig.anonHeaders, body: encoded)
          .timeout(const Duration(seconds: 8));
    }
    return res.statusCode == 200 || res.statusCode == 204;
  }
}
