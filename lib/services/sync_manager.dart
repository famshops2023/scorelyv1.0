import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../core/config/insforge_config.dart';
import '../providers/career_stats_provider.dart';
import '../providers/history_provider.dart';
import 'database.dart';
import 'insforge_sync_service.dart';
import 'match_lifecycle_service.dart';

import '../providers/profile_provider.dart';

/// Global provider exposing the [SyncManager] singleton.
final syncManagerProvider = Provider<SyncManager>((ref) {
  final db = DatabaseService.instance;
  final manager = SyncManager(db, ref);
  ref.onDispose(manager.dispose);
  return manager;
});

/// Watches connectivity and retries pending match syncs whenever the
/// device comes back online. Also periodically pulls completed matches from
/// InsForge to keep stats, recent matches, and performance in sync across devices.
class SyncManager {
  final AppDatabase _db;
  final Ref _ref;
  StreamSubscription<List<ConnectivityResult>>? _sub;
  Timer? _pullTimer;
  bool _isSyncing = false;
  bool _isPulling = false;

  SyncManager(this._db, this._ref) {
    _sub = Connectivity().onConnectivityChanged.listen(_onConnectivityChanged);
    // Also try on startup in case we already have connectivity
    _trySync();
    MatchLifecycleService.flushPendingCompletions();
    pullCompletedMatchesFromRemote();

    // Check for newly completed remote matches every 15 seconds
    _pullTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      pullCompletedMatchesFromRemote();
    });
  }

  void dispose() {
    _sub?.cancel();
    _pullTimer?.cancel();
  }

  void _onConnectivityChanged(List<ConnectivityResult> results) {
    final isOnline = results.any((r) => r != ConnectivityResult.none);
    if (isOnline) {
      debugPrint('SyncManager: connectivity restored — retrying pending syncs.');
      _trySync();
      MatchLifecycleService.flushPendingCompletions();
      pullCompletedMatchesFromRemote();
    }
  }

  Future<void> _trySync() async {
    final profile = _ref.read(profileProvider);
    if (!profile.isLoggedIn || profile.id.isEmpty) {
      // Unauthorized players store in local only — never sync to InsForge
      return;
    }

    if (_isSyncing) return;
    _isSyncing = true;
    try {
      final pending = await _db.getPendingSyncMatches();
      if (pending.isEmpty) {
        debugPrint('SyncManager: no pending matches to sync.');
        return;
      }
      debugPrint('SyncManager: syncing ${pending.length} pending match(es) for creator ${profile.id}.');
      for (final match in pending) {
        final ok = await InsforgeSyncService.trySyncMatch(_db, match.id, profile.id);
        if (ok) {
          await _db.markSynced(match.id);
          debugPrint('SyncManager: match ${match.id} synced successfully.');
        } else {
          debugPrint('SyncManager: match ${match.id} sync failed — will retry later.');
        }
      }
    } catch (e) {
      debugPrint('SyncManager._trySync error: $e');
    } finally {
      _isSyncing = false;
    }
  }

  /// Pulls completed matches from InsForge where the authenticated user is either
  /// the creator or the active scorer. If any remote completed matches are missing
  /// from local SQLite, downloads them and invalidates history, recent matches,
  /// profile, and performance providers so the UI refreshes immediately.
  Future<void> pullCompletedMatchesFromRemote() async {
    final profile = _ref.read(profileProvider);
    if (!profile.isLoggedIn || profile.id.isEmpty) return;

    if (_isPulling) return;
    _isPulling = true;
    try {
      // A completion that failed offline is retried here as well, so the
      // scorer's device eventually publishes the final row for everybody.
      await MatchLifecycleService.flushPendingCompletions();
      final myId = profile.id;
      // Fetch matches where user is creator/scorer, as well as matches where user participated in squad
      final creatorUri = Uri.parse('${InsforgeConfig.recordsUrl}/matches').replace(queryParameters: {
        'or': '(creator_id.eq.$myId,active_scorer_id.eq.$myId)',
        'status': 'in.(completed,abandoned)',
        'order': 'match_date.desc',
        'limit': '15',
      });
      final playerUri = Uri.parse('${InsforgeConfig.recordsUrl}/matches').replace(queryParameters: {
        'player_profile_ids': 'cs.["$myId"]',
        'status': 'in.(completed,abandoned)',
        'order': 'match_date.desc',
        'limit': '15',
      });

      // Completed or abandoned matches that never made it into the synced `matches` table
      // (e.g. the scorer was offline) are still authoritative in
      // `pending_matches`. Pull them so Recent Matches and the result popup
      // catch up on the next sync.
      final pendingCompletedUri = Uri.parse('${InsforgeConfig.recordsUrl}/pending_matches').replace(queryParameters: {
        'status': 'in.(completed,abandoned)',
        'or': '(created_by_profile_id.eq.$myId,active_scorer_id.eq.$myId,player_profile_ids.cs.["$myId"])',
        'order': 'completed_at.desc',
        'limit': '15',
      });

      final responses = await Future.wait([
        http.get(creatorUri, headers: InsforgeConfig.headers).catchError((_) => http.Response('[]', 200)),
        http.get(playerUri, headers: InsforgeConfig.headers).catchError((_) => http.Response('[]', 200)),
        http.get(pendingCompletedUri, headers: InsforgeConfig.headers).catchError((_) => http.Response('[]', 200)),
      ]);

      final Map<String, dynamic> combinedMatches = {};
      for (var i = 0; i < responses.length; i++) {
        final res = responses[i];
        if (res.statusCode != 200) continue;
        try {
          final List list = jsonDecode(res.body);
          for (final item in list) {
            if (item is! Map) continue;
            final id = item['id']?.toString() ?? '';
            if (id.isEmpty) continue;
            // The third response is `pending_matches`: convert it into the
            // same shape used by the synced `matches` table.
            if (i == 2) {
              final converted = _completedPendingRowToMatch(item);
              if (converted != null) {
                combinedMatches[id] = converted;
              }
            } else {
              combinedMatches[id] = item;
            }
          }
        } catch (_) {}
      }

      final remoteMatches = combinedMatches.values.toList();
      if (remoteMatches.isEmpty) return;

      final localMatches = await _db.getAllMatches();
      bool hasNewMatch = false;

      for (final rm in remoteMatches) {
        final venueRaw = (rm['venue'] ?? '').toString();
        final summary = (rm['match_result_summary'] ?? '').toString();
        final matchDate = DateTime.tryParse(rm['match_date']?.toString() ?? '') ?? DateTime.now();

        // Extract clean SM-10001 code if present in summary, or assign a sequential id.
        String extractedCode = '';
        if (summary.contains('[') && summary.contains(']')) {
          final start = summary.indexOf('[');
          final end = summary.indexOf(']');
          if (end > start) {
            extractedCode = summary.substring(start + 1, end).trim();
          }
        }

        String matchTitle = 'Cricket Match ($extractedCode)';
        String venue = venueRaw;
        if (venueRaw.contains(' • ')) {
          final parts = venueRaw.split(' • ');
          matchTitle = parts[0].trim();
          venue = parts.length > 1 ? parts[1].trim() : venueRaw;
        } else if (venueRaw.contains(' vs ')) {
          matchTitle = venueRaw;
        }

        // Assign a sequential matchAppId (SM-10001, SM-10002, ...) when the
        // remote summary does not already carry one.
        final matchAppId = extractedCode.isNotEmpty
            ? extractedCode
            : await _db.nextMatchAppId();

        final alreadyExists = localMatches.any((lm) =>
            (lm.matchTitle.contains(extractedCode) || lm.matchTitle == matchTitle) &&
            lm.createdAt.difference(matchDate).inHours.abs() < 24);

        if (!alreadyExists) {
          int tARuns = 0, tAWickets = 0, tBRuns = 0, tBWickets = 0;
          if (summary.contains(' vs ')) {
            final parts = summary.split(' vs ');
            final aParts = parts[0].trim().split('/');
            final bParts = parts[1].trim().split('/');
            tARuns = int.tryParse(aParts[0]) ?? 0;
            tAWickets = aParts.length > 1 ? (int.tryParse(aParts[1]) ?? 0) : 0;
            tBRuns = int.tryParse(bParts[0]) ?? 0;
            tBWickets = bParts.length > 1 ? (int.tryParse(bParts[1]) ?? 0) : 0;
          }

          final totalOvers = (rm['total_overs'] as num?)?.toInt() ?? 20;

          String? winnerName;
          int? tAId;
          int? tBId;
          // Prefer the authoritative winner written at completion (e.g. an
          // abandoned match cannot be inferred from the scores).
          final remoteWinner =
              (rm['winner'] ?? rm['winner_team_name'] ?? '').toString().trim();
          if (matchTitle.contains(' vs ')) {
            final tParts = matchTitle.split(' vs ');
            final tA = tParts[0].trim();
            final tB = tParts.length > 1 ? tParts[1].trim() : 'Team B';
            if (remoteWinner.isNotEmpty) {
              winnerName = remoteWinner;
            } else if (tARuns > tBRuns) {
              winnerName = tA;
            } else if (tBRuns > tARuns) {
              winnerName = tB;
            } else {
              winnerName = 'Match Tied';
            }

            try {
              final existingA = await (_db.select(_db.teams)..where((t) => t.name.equals(tA))).getSingleOrNull();
              tAId = existingA?.id ?? await _db.into(_db.teams).insert(TeamsCompanion.insert(name: tA));
              final existingB = await (_db.select(_db.teams)..where((t) => t.name.equals(tB))).getSingleOrNull();
              tBId = existingB?.id ?? await _db.into(_db.teams).insert(TeamsCompanion.insert(name: tB));
            } catch (_) {}
          }

          await _db.insertMatch(MatchesCompanion.insert(
            matchTitle: matchTitle,
            totalOvers: totalOvers,
            venue: drift.Value(venue),
            winnerTeamName: drift.Value(winnerName),
            isCompleted: const drift.Value(true),
            syncPending: const drift.Value(false),
            createdAt: drift.Value(matchDate),
            teamAId: drift.Value(tAId),
            teamBId: drift.Value(tBId),
            teamARuns: drift.Value(tARuns),
            teamAWickets: drift.Value(tAWickets),
            teamBRuns: drift.Value(tBRuns),
            teamBWickets: drift.Value(tBWickets),
            matchAppId: drift.Value(matchAppId),
          ));
          hasNewMatch = true;
        }
      }

      if (hasNewMatch) {
        await _ref.read(matchHistoryProvider.notifier).loadMatches();
        _ref.invalidate(recentMatchesProvider);
        _ref.invalidate(homePersonalStatsProvider);
        _ref.invalidate(profileScorerStatsProvider);
        _ref.invalidate(careerStatsForCategoryProvider);
      }
    } catch (e) {
      debugPrint('SyncManager.pullCompletedMatchesFromRemote error: $e');
    } finally {
      _isPulling = false;
    }
  }

  Map<String, dynamic>? _completedPendingRowToMatch(Map item) {
    try {
      Map<String, dynamic> decode(dynamic raw) {
        if (raw is Map) return Map<String, dynamic>.from(raw);
        if (raw is String && raw.isNotEmpty) {
          final d = jsonDecode(raw);
          if (d is Map) return Map<String, dynamic>.from(d);
        }
        return <String, dynamic>{};
      }

      final md = decode(item['match_data']);
      final live = decode(item['live_score_data']);
      final teamA = (md['teamAName'] ?? 'Team A').toString();
      final teamB = (md['teamBName'] ?? 'Team B').toString();
      final ground = (live['venue'] ?? md['venue'] ?? 'Local Ground').toString();
      final aScore = (live['team_a_score'] ?? '0/0').toString();
      final bScore = (live['team_b_score'] ?? '0/0').toString();
      final code = (md['matchAppId'] ?? md['matchCode'] ?? '').toString();
      var summary = '$aScore vs $bScore';
      if (code.isNotEmpty && !summary.contains('[')) {
        summary = '$summary [$code]';
      }
      final completedAt = item['completed_at'] ??
          item['updated_at'] ??
          DateTime.now().toIso8601String();

      return {
        'id': item['id'],
        'venue': '$teamA vs $teamB • $ground',
        'match_result_summary': summary,
        'match_date': completedAt,
        'total_overs': md['overs'] ?? 20,
        'status': (item['status'] ?? 'completed').toString(),
        'winner': (item['winner'] ?? '').toString(),
      };
    } catch (e) {
      debugPrint('SyncManager._completedPendingRowToMatch error: $e');
      return null;
    }
  }

  /// Call after saving a new completed match so we attempt an immediate sync.
  ///
  /// [teamAScorerProfileId] — if the current user is the 2nd innings scorer,
  /// pass the 1st innings scorer's profile ID here so it gets stored on the
  /// InsForge match record for cross-scorer stats attribution.
  Future<void> onMatchCompleted(
    int localMatchId, {
    String? teamAScorerProfileId,
    String? setupMatchId,
    List<String>? participatingProfileIds,
  }) async {
    final profile = _ref.read(profileProvider);
    if (!profile.isLoggedIn || profile.id.isEmpty) {
      // Unauthorized players: do not sync to InsForge
      return;
    }
    // Attempt an immediate sync for this specific match (with scorer attribution and participating players),
    // then fall through to the general pending-sync pass.
    try {
      final ok = await InsforgeSyncService.trySyncMatch(
        _db,
        localMatchId,
        profile.id,
        teamAScorerProfileId: teamAScorerProfileId,
        setupMatchId: setupMatchId,
        participatingProfileIds: participatingProfileIds,
      );
      if (ok) {
        await _db.markSynced(localMatchId);
        debugPrint('SyncManager: match $localMatchId synced immediately (team_a_scorer: $teamAScorerProfileId, players: ${participatingProfileIds?.length}).');
        return;
      }
    } catch (e) {
      debugPrint('SyncManager.onMatchCompleted direct sync error: $e');
    }
    // Fallback: add to general retry queue
    _trySync();
  }
}
