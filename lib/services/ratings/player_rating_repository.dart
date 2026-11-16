import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../core/config/insforge_config.dart';
import '../../models/player_pro_rating.dart';
import '../../providers/career_stats_provider.dart';
import '../insforge_stats_service.dart';
import 'player_rating_engine.dart';

class PlayerRatingRepository {
  static String get _summaryUrl => '${InsforgeConfig.recordsUrl}/player_rating_summary';
  static String get _historyUrl => '${InsforgeConfig.recordsUrl}/player_rating_history';
  static Map<String, String> get _headers => InsforgeConfig.headers;

  /// In-memory cache for fast UI access
  static final Map<String, PlayerProRating> _cache = {};

  static String _cacheKey(String userId, String matchType) =>
      '${userId}_${matchType.toLowerCase().trim()}';

  /// Standardized Turf check matching the rest of the application
  static bool isTurfMatch(String matchType, String venue) {
    final t = matchType.toLowerCase().trim();
    final v = venue.toLowerCase().trim();
    return t == 'box/turf' ||
        t.contains('turf') ||
        t.contains('box') ||
        v.contains('turf') ||
        v.contains('box');
  }

  /// Fetches a player's Pro Rating for a specific match type ('turf' or 'ground').
  /// Sourced from InsForge. If not yet materialized in summary, calculates from authoritative InsForge stats.
  static Future<PlayerProRating> getPlayerRating({
    required String playerUserId,
    required String matchType, // 'turf' or 'ground'
    String playerName = '',
    String playerRole = 'BAT',
  }) async {
    if (playerUserId.isEmpty) {
      return PlayerProRating.unrated(
        playerUserId: playerUserId,
        matchType: matchType,
      );
    }

    final normType = matchType.toLowerCase().trim().contains('turf') ? 'turf' : 'ground';
    final key = _cacheKey(playerUserId, normType);

    // 1. Check in-memory cache
    if (_cache.containsKey(key)) {
      return _cache[key]!;
    }

    try {
      // 2. Query player_rating_summary from InsForge
      final res = await http.get(
        Uri.parse('$_summaryUrl?player_user_id=eq.$playerUserId&match_type=eq.$normType&limit=1'),
        headers: _headers,
      );

      if (res.statusCode == 200) {
        final List<dynamic> list = jsonDecode(res.body);
        if (list.isNotEmpty) {
          final rating = PlayerProRating.fromJson(list.first as Map<String, dynamic>);
          _cache[key] = rating;
          return rating;
        }
      }

      // 3. If summary record doesn't exist yet, calculate on-the-fly from InsForge career stats
      final careerCat = normType == 'turf' ? MatchCategory.turfBox : MatchCategory.ground;
      final stats = await InsforgeStatsService.fetchCareerStats(
        playerUserId,
        playerName,
        careerCat,
      );

      final calcResult = PlayerRatingEngine.calculate(
        matchType: normType,
        playerRole: playerRole,
        matches: stats.matches,
        innings: stats.innings,
        totalRuns: stats.totalRuns,
        notOuts: stats.notOuts,
        ballsFaced: stats.ballsFaced,
        fours: stats.fours,
        sixes: stats.sixes,
        fifties: stats.fifties,
        hundreds: stats.hundreds,
        recentRuns: stats.runsPerMatch,
        totalWickets: stats.totalWickets,
        overs: stats.overs,
        runsConceded: stats.runsConceded,
        dotBalls: 0,
        fourWicketHauls: stats.fourWicketHauls,
        fiveWicketHauls: stats.fiveWicketHauls,
        recentWickets: stats.wicketsPerMatch,
        catches: stats.catchesTaken,
        runOuts: stats.runOutInvolvements,
        stumpings: stats.stumpings,
        matchesWon: stats.recentForm.where((r) => r == 'W').length,
      );

      final computedRating = PlayerProRating(
        playerUserId: playerUserId,
        matchType: normType,
        rating: stats.matches > 0 ? calcResult.overallRating : 0,
        level: stats.matches > 0 ? calcResult.level : 'Novice',
        matchesPlayed: stats.matches,
        runs: stats.totalRuns,
        wickets: stats.totalWickets,
        battingRating: calcResult.battingRating,
        bowlingRating: calcResult.bowlingRating,
        fieldingRating: calcResult.fieldingRating,
        matchImpactRating: calcResult.matchImpactRating,
        badges: calcResult.badges,
        topBadge: calcResult.topBadge,
        updatedAt: DateTime.now(),
      );

      _cache[key] = computedRating;

      // Persist / cache to InsForge summary asynchronously if matches > 0
      if (stats.matches > 0) {
        _upsertSummaryRecord(computedRating);
      }

      return computedRating;
    } catch (e) {
      debugPrint('PlayerRatingRepository.getPlayerRating error: $e');
      return PlayerProRating.unrated(
        playerUserId: playerUserId,
        matchType: normType,
      );
    }
  }

  /// Batch fetches ratings for multiple signed-in players to avoid N+1 queries in Discovery.
  /// Returns a Map: playerUserId -> {'turf': PlayerProRating, 'ground': PlayerProRating}
  static Future<Map<String, Map<String, PlayerProRating>>> batchFetchRatings(
    List<String> playerUserIds,
  ) async {
    final Map<String, Map<String, PlayerProRating>> results = {};
    if (playerUserIds.isEmpty) return results;

    // Initialize map entries
    for (var id in playerUserIds) {
      results[id] = {
        'turf': PlayerProRating.unrated(playerUserId: id, matchType: 'turf'),
        'ground': PlayerProRating.unrated(playerUserId: id, matchType: 'ground'),
      };
    }

    try {
      // Chunk IDs to avoid query URL length issues (max 30 per chunk)
      for (var i = 0; i < playerUserIds.length; i += 30) {
        final end = (i + 30 < playerUserIds.length) ? i + 30 : playerUserIds.length;
        final chunk = playerUserIds.sublist(i, end);
        final url = '$_summaryUrl?player_user_id=in.(${chunk.join(',')})';

        final res = await http.get(Uri.parse(url), headers: _headers);
        if (res.statusCode == 200) {
          final List<dynamic> list = jsonDecode(res.body);
          for (var item in list) {
            final rating = PlayerProRating.fromJson(item as Map<String, dynamic>);
            final uid = rating.playerUserId;
            final mType = rating.matchType.toLowerCase().contains('turf') ? 'turf' : 'ground';
            if (results.containsKey(uid)) {
              results[uid]![mType] = rating;
              _cache[_cacheKey(uid, mType)] = rating;
            }
          }
        }
      }
    } catch (e) {
      debugPrint('PlayerRatingRepository.batchFetchRatings error: $e');
    }

    return results;
  }

  /// Recalculates rating after a completed match in an idempotent, non-blocking manner.
  static Future<void> recalculateForCompletedMatch({
    required String matchId,
    required String matchType,
    required String venue,
    required String playerUserId,
    required String playerName,
    required String playerRole,
  }) async {
    if (playerUserId.isEmpty || matchId.isEmpty) return;

    try {
      final normType = isTurfMatch(matchType, venue) ? 'turf' : 'ground';

      // 1. Idempotency Check: check if already recorded in history
      final histCheck = await http.get(
        Uri.parse('$_historyUrl?player_user_id=eq.$playerUserId&match_id=eq.$matchId&limit=1'),
        headers: _headers,
      );
      if (histCheck.statusCode == 200) {
        final List<dynamic> list = jsonDecode(histCheck.body);
        if (list.isNotEmpty) {
          debugPrint('PlayerRatingRepository: match $matchId already processed for player $playerUserId');
          return;
        }
      }

      // 2. Fetch existing rating to know previous score
      final prevRating = await getPlayerRating(
        playerUserId: playerUserId,
        matchType: normType,
        playerName: playerName,
        playerRole: playerRole,
      );

      // Invalidate memory cache
      _cache.remove(_cacheKey(playerUserId, normType));

      // 3. Recalculate using full authoritative statistics
      final careerCat = normType == 'turf' ? MatchCategory.turfBox : MatchCategory.ground;
      final stats = await InsforgeStatsService.fetchCareerStats(
        playerUserId,
        playerName,
        careerCat,
      );

      final calcResult = PlayerRatingEngine.calculate(
        matchType: normType,
        playerRole: playerRole,
        matches: stats.matches,
        innings: stats.innings,
        totalRuns: stats.totalRuns,
        notOuts: stats.notOuts,
        ballsFaced: stats.ballsFaced,
        fours: stats.fours,
        sixes: stats.sixes,
        fifties: stats.fifties,
        hundreds: stats.hundreds,
        recentRuns: stats.runsPerMatch,
        totalWickets: stats.totalWickets,
        overs: stats.overs,
        runsConceded: stats.runsConceded,
        dotBalls: 0,
        fourWicketHauls: stats.fourWicketHauls,
        fiveWicketHauls: stats.fiveWicketHauls,
        recentWickets: stats.wicketsPerMatch,
        catches: stats.catchesTaken,
        runOuts: stats.runOutInvolvements,
        stumpings: stats.stumpings,
        matchesWon: stats.recentForm.where((r) => r == 'W').length,
      );

      final newRating = PlayerProRating(
        playerUserId: playerUserId,
        matchType: normType,
        rating: stats.matches > 0 ? calcResult.overallRating : 0,
        level: stats.matches > 0 ? calcResult.level : 'Novice',
        matchesPlayed: stats.matches,
        runs: stats.totalRuns,
        wickets: stats.totalWickets,
        battingRating: calcResult.battingRating,
        bowlingRating: calcResult.bowlingRating,
        fieldingRating: calcResult.fieldingRating,
        matchImpactRating: calcResult.matchImpactRating,
        badges: calcResult.badges,
        topBadge: calcResult.topBadge,
        updatedAt: DateTime.now(),
      );

      _cache[_cacheKey(playerUserId, normType)] = newRating;

      // 4. Update Summary Cache in InsForge
      await _upsertSummaryRecord(newRating);

      // 5. Insert History Record
      final ratingChange = newRating.rating - prevRating.rating;
      await http.post(
        Uri.parse(_historyUrl),
        headers: _headers,
        body: jsonEncode([
          {
            'player_user_id': playerUserId,
            'match_id': matchId,
            'match_type': normType,
            'previous_rating': prevRating.rating,
            'rating_change': ratingChange,
            'new_rating': newRating.rating,
            'calculation_version': 'v1',
            'created_at': DateTime.now().toIso8601String(),
          }
        ]),
      );
    } catch (e) {
      debugPrint('PlayerRatingRepository.recalculateForCompletedMatch error: $e');
    }
  }

  /// Internal upsert into player_rating_summary
  static Future<void> _upsertSummaryRecord(PlayerProRating rating) async {
    try {
      final payload = rating.toJson();
      final res = await http.post(
        Uri.parse('$_summaryUrl?on_conflict=player_user_id,match_type'),
        headers: {
          ..._headers,
          'Prefer': 'resolution=merge-duplicates,return=representation',
        },
        body: jsonEncode([payload]),
      );
      if (res.statusCode != 200 && res.statusCode != 201) {
        debugPrint('PlayerRatingRepository._upsertSummaryRecord status: ${res.statusCode}');
      }
    } catch (e) {
      debugPrint('PlayerRatingRepository._upsertSummaryRecord error: $e');
    }
  }

  /// Clear repository in-memory cache
  static void clearCache() => _cache.clear();
}
