import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:drift/drift.dart' as drift;
import '../../../core/config/insforge_config.dart';
import '../../../models/live_match_data.dart';
import '../../../models/user_profile.dart';
import '../../../providers/profile_provider.dart';
import '../../../providers/history_provider.dart';
import '../../../services/database.dart';
import '../../../services/ongoing_match_service.dart';

// ============================================================
// INSFORGE CONFIG  (same project as pending_matches_provider)
// ============================================================
class _InsForge {
  static String get baseUrl => InsforgeConfig.recordsUrl;
  static Map<String, String> get headers => InsforgeConfig.headers;
}

/// Fetches live matches from the [pending_matches] table where
/// status = 'live' and the current user is a scorer, creator, or player.
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
      final myId = profile.id.trim();
      final myDisplayId = profile.displayId.trim();
      final myDisplayIdNorm = myDisplayId.replaceAll(' ', '').toUpperCase();
      final myName = profile.name.trim().toLowerCase();

      // Only signed-in users can view their matches
      if (myId.isEmpty) return [];

      // Query both pending_matches (active scoring) and matches (synced live matches).
      // Use getWithFallback() so expired JWTs don't silently return empty.
      final pendingUri = Uri.parse('${_InsForge.baseUrl}/pending_matches').replace(queryParameters: {
        'status': 'eq.live',
        'select': '*',
      });
      final matchesUri = Uri.parse('${_InsForge.baseUrl}/matches').replace(queryParameters: {
        'status': 'eq.live',
        'select': '*',
      });

      final responses = await Future.wait([
        InsforgeConfig.getWithFallback(pendingUri)
            .catchError((_) => http.Response('[]', 200)),
        InsforgeConfig.getWithFallback(matchesUri)
            .catchError((_) => http.Response('[]', 200)),
      ]);

      final Map<String, LiveMatchData> matchMap = {};
      for (final res in responses) {
        if (res.statusCode == 200) {
          try {
            final List<dynamic> data = jsonDecode(res.body);
            for (final e in data) {
              if (e is Map<String, dynamic>) {
                // 1. Check if match has had no runs update for > 4 hours -> mark as Abandoned
                final lastUpdated = _extractLastUpdated(e);
                if (lastUpdated != null &&
                    DateTime.now().difference(lastUpdated) > const Duration(hours: 4)) {
                  _abandonMatch(e, ref);
                  continue; // Do not show abandoned match in live section
                }

                // 2. Requirement: Live match only starts/shows once the Toss is completed
                if (!_isTossCompleted(e)) {
                  continue; // Toss not completed yet -> do not show in live section
                }

                final match = LiveMatchData.fromInsForgeRow(e);
                if (match.id.isNotEmpty) {
                  matchMap[match.id] = match;
                }
              }
            }
          } catch (_) {}
        }
      }

      // ── matchAppId dedup safety net ──────────────────────────────────────
      // Even if UUID dedup passed, the same matchAppId may appear under
      // different UUIDs. Keep the first occurrence, drop subsequent duplicates.
      // Matches with null matchAppId fall back to UUID dedup only.
      final seenMatchAppIds = <String>{};
      final dedupedMap = <String, LiveMatchData>{};
      for (final m in matchMap.values) {
        final appId = m.matchAppId;
        if (appId != null && appId.isNotEmpty) {
          if (seenMatchAppIds.contains(appId)) {
            continue; // duplicate matchAppId — skip
          }
          seenMatchAppIds.add(appId);
        }
        dedupedMap[m.id] = m;
      }

      final all = dedupedMap.values.toList();

      // Filter to matches where current user is:
      //   1. MATCH SCORER (by profile UUID, SP-XXXX ID, or display name)
      //   2. CREATOR (by creator profile UUID or SP-XXXX ID)
      //   3. LOGGED-IN PLAYER in Team A or Team B (by SP-XXXX ID, profile UUID, or name)
      return all.where((m) {
        // 1. Check Match Scorer
        final isScorer = m.scorerId == myId ||
            (m.scorerId.isNotEmpty &&
                m.scorerId.replaceAll(' ', '').toUpperCase() == myDisplayIdNorm) ||
            (myName.isNotEmpty &&
                (m.scorerId.toLowerCase() == myName ||
                    m.scorerName.toLowerCase() == myName));

        // 2. Check Match Creator
        final isCreator = (m.creatorId.isNotEmpty && m.creatorId == myId) ||
            (m.creatorId.isNotEmpty &&
                m.creatorId.replaceAll(' ', '').toUpperCase() == myDisplayIdNorm);

        // 3. Check Logged-in Players in Team A or Team B (have SP - XXXX id or UUID)
        final allPlayerIds = [...m.teamAPlayerIds, ...m.teamBPlayerIds];
        final isPlayerInTeam = allPlayerIds.any((id) {
          final clean = id.trim();
          if (clean.isEmpty) return false;

          // Direct UUID match
          if (clean == myId) return true;

          // SP-XXXX display ID match (e.g. "SP-1042" or "SP - 1042")
          final cleanNorm = clean.replaceAll(' ', '').toUpperCase();
          if (cleanNorm == myDisplayIdNorm) return true;

          // If the player entry is a 36-char UUID, derive its SP-XXXX code and compare
          if (clean.length == 36 && clean.contains('-')) {
            final derived = UserProfile.deriveDisplayId(clean).replaceAll(' ', '').toUpperCase();
            if (derived == myDisplayIdNorm) return true;
          }

          // Player name match
          if (myName.isNotEmpty && clean.toLowerCase() == myName) return true;

          return false;
        });

        return isScorer || isCreator || isPlayerInTeam;
      }).toList();
    } catch (e) {
      debugPrint('LiveMatchInsforgeProvider: fetch failed — $e');
      return [];
    }
  }

  /// Extracts the latest activity/scoring timestamp from the match row
  static DateTime? _extractLastUpdated(Map<String, dynamic> row) {
    final raw = row['live_score_data'];
    if (raw is Map && raw['last_updated'] != null) {
      final dt = DateTime.tryParse(raw['last_updated'].toString());
      if (dt != null) return dt;
    } else if (raw is String) {
      try {
        final d = jsonDecode(raw);
        if (d is Map && d['last_updated'] != null) {
          final dt = DateTime.tryParse(d['last_updated'].toString());
          if (dt != null) return dt;
        }
      } catch (_) {}
    }

    // Fallbacks
    final u = DateTime.tryParse(row['updated_at']?.toString() ?? '');
    if (u != null) return u;
    final c = DateTime.tryParse(row['created_at']?.toString() ?? '');
    if (c != null) return c;
    final m = DateTime.tryParse(row['match_date']?.toString() ?? '');
    if (m != null) return m;
    return null;
  }

  /// Checks whether the toss has been completed for this match
  static bool _isTossCompleted(Map<String, dynamic> row) {
    final raw = row['live_score_data'];
    Map<String, dynamic> live = {};
    if (raw is Map) {
      live = raw as Map<String, dynamic>;
    } else if (raw is String) {
      try {
        final d = jsonDecode(raw);
        if (d is Map) live = d as Map<String, dynamic>;
      } catch (_) {}
    }

    final rawMatch = row['match_data'];
    Map<String, dynamic> matchData = {};
    if (rawMatch is Map) {
      matchData = rawMatch as Map<String, dynamic>;
    } else if (rawMatch is String) {
      try {
        final d = jsonDecode(rawMatch);
        if (d is Map) matchData = d as Map<String, dynamic>;
      } catch (_) {}
    }

    final tossCompleted = live['toss_completed'] == true ||
        (live['toss_won_by'] != null && live['toss_won_by'].toString().trim().isNotEmpty) ||
        (live['batting_first_team'] != null && live['batting_first_team'].toString().trim().isNotEmpty) ||
        (matchData['tossWonBy'] != null && matchData['tossWonBy'].toString().trim().isNotEmpty) ||
        (matchData['battingFirstTeam'] != null && matchData['battingFirstTeam'].toString().trim().isNotEmpty) ||
        (live['team_a_overs'] != null && live['team_a_overs'] != '0.0') ||
        (live['team_b_overs'] != null && live['team_b_overs'] != '0.0') ||
        (live['last_6_balls'] != null && live['last_6_balls'].toString().trim().isNotEmpty);

    return tossCompleted;
  }

  /// Abandons a live match that had no runs update for > 4 hours:
  /// Updates InsForge, commits to SQLite with 'Match Abandoned', clears ongoing snapshot,
  /// and updates History & Recent Matches.
  static Future<void> _abandonMatch(Map<String, dynamic> row, Ref ref) async {
    final matchId = row['id']?.toString() ?? '';
    if (matchId.isEmpty) return;

    try {
      final nowIso = DateTime.now().toUtc().toIso8601String();
      final patchBody = jsonEncode({
        // Abandonment is a terminal outcome, so it uses the canonical
        // `completed` lifecycle value (the check constraint rejects anything
        // else) while the result text records the abandonment.
        'status': 'completed',
        'winner': 'Match Abandoned',
        'result_summary': 'Match Abandoned',
        'completed_at': nowIso,
        'updated_at': nowIso,
      });

      // 1. Update pending_matches in InsForge
      await http.patch(
        Uri.parse('${_InsForge.baseUrl}/pending_matches?id=eq.$matchId'),
        headers: _InsForge.headers,
        body: patchBody,
      ).catchError((_) => http.Response('', 500));

      // 2. Also patch matches table if it exists
      await http.patch(
        Uri.parse('${_InsForge.baseUrl}/matches?id=eq.$matchId'),
        headers: _InsForge.headers,
        body: jsonEncode({
          'status': 'completed',
          'winnerTeamName': 'Match Abandoned',
          'match_result_summary': 'Match Abandoned',
        }),
      ).catchError((_) => http.Response('', 500));

      // 3. Local SQLite update / insert
      final db = ref.read(databaseServiceProvider);
      final liveMatch = LiveMatchData.fromInsForgeRow(row);
      final matchTitle = '${liveMatch.teamAName} vs ${liveMatch.teamBName}';

      final existing = await (db.select(db.matches)
            ..where((m) => m.matchTitle.contains(liveMatch.id) | m.matchTitle.equals(matchTitle)))
          .getSingleOrNull();

      if (existing != null) {
        await (db.update(db.matches)..where((m) => m.id.equals(existing.id))).write(
          const MatchesCompanion(
            isCompleted: drift.Value(true),
            winnerTeamName: drift.Value('Match Abandoned'),
            syncPending: drift.Value(false),
          ),
        );
      } else {
        final aParts = liveMatch.teamAScore.split('/');
        final bParts = liveMatch.teamBScore.split('/');
        final tARuns = int.tryParse(aParts[0]) ?? 0;
        final tAWickets = aParts.length > 1 ? (int.tryParse(aParts[1]) ?? 0) : 0;
        final tBRuns = int.tryParse(bParts[0]) ?? 0;
        final tBWickets = bParts.length > 1 ? (int.tryParse(bParts[1]) ?? 0) : 0;

        await db.into(db.matches).insert(
          MatchesCompanion.insert(
            matchTitle: matchTitle,
            totalOvers: 20,
            venue: drift.Value(liveMatch.venue.isNotEmpty ? liveMatch.venue : 'Local Ground'),
            winnerTeamName: const drift.Value('Match Abandoned'),
            isCompleted: const drift.Value(true),
            syncPending: const drift.Value(false),
            createdAt: drift.Value(DateTime.now()),
            teamARuns: drift.Value(tARuns),
            teamAWickets: drift.Value(tAWickets),
            teamBRuns: drift.Value(tBRuns),
            teamBWickets: drift.Value(tBWickets),
          ),
        );
      }

      // 4. Clear any ongoing local snapshot
      await OngoingMatchService.instance.clearSnapshot(matchId);

      // 5. Invalidate history & recent matches to update UI
      ref.invalidate(matchHistoryProvider);
      ref.invalidate(recentMatchesProvider);
    } catch (e) {
      debugPrint('LiveMatchInsforgeProvider._abandonMatch error: $e');
    }
  }
}
