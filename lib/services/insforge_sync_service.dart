import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import '../core/config/insforge_config.dart';
import 'database.dart';
import 'ratings/player_rating_repository.dart';

class InsforgeSyncService {
  static String get _url => InsforgeConfig.recordsUrl;
  static Map<String, String> get _headers => InsforgeConfig.headers;

  /// Attempts to sync a local match to InsForge.
  /// Returns `true` on success, `false` if any HTTP step fails.
  ///
  /// [teamAScorerProfileId] — optional profile ID of the 1st innings scorer.
  /// When provided and different from [creatorId] (the 2nd innings scorer),
  /// the match record is stored with `creator_id = teamAScorerProfileId`
  /// and `active_scorer_id = creatorId`. This ensures both scorers are
  /// permanently attributed on the match and both will see updated stats.
  static Future<bool> trySyncMatch(
    AppDatabase db,
    int localMatchId,
    String creatorId, {
    String? teamAScorerProfileId,
    String? setupMatchId,
    List<String>? participatingProfileIds,
  }) async {
    if (creatorId.isEmpty) return false;
    try {
      final match = await (db.select(db.matches)..where((m) => m.id.equals(localMatchId))).getSingleOrNull();
      if (match == null) return false;

      final bool isValidUuid = setupMatchId != null &&
          RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$')
              .hasMatch(setupMatchId);
      final matchUuid = isValidUuid ? setupMatchId : const Uuid().v4();

      final effectiveCreatorId = (teamAScorerProfileId != null && teamAScorerProfileId.isNotEmpty)
          ? teamAScorerProfileId
          : creatorId;
      final effectiveActiveScorerId = creatorId;

      // Extract participating player profile IDs (or recover from pending_matches if null)
      List<String> effectivePlayerProfileIds = participatingProfileIds ?? [];
      if (effectivePlayerProfileIds.isEmpty) {
        try {
          final pRes = await http.get(
            Uri.parse('$_url/pending_matches?id=eq.$matchUuid'),
            headers: _headers,
          );
          if (pRes.statusCode == 200) {
            final List pList = jsonDecode(pRes.body);
            if (pList.isNotEmpty) {
              final row = pList.first as Map<String, dynamic>;
              final mData = row['match_data'] is Map
                  ? row['match_data'] as Map<String, dynamic>
                  : (row['match_data'] is String ? jsonDecode(row['match_data']) as Map<String, dynamic> : {});
              final aPlayers = mData['teamAPlayers'] as List? ?? [];
              final bPlayers = mData['teamBPlayers'] as List? ?? [];
              final ids = <String>{};
              for (final p in [...aPlayers, ...bPlayers]) {
                if (p is Map) {
                  final pid = p['profileId']?.toString();
                  if (pid != null && pid.isNotEmpty) ids.add(pid);
                }
              }
              effectivePlayerProfileIds = ids.toList();
            }
          }
        } catch (_) {}
      }

      // Sequential match app id (SM-10001, SM-10002, ...) used to manage matches.
      // Reuses an existing id if already stamped, otherwise computes the next one.
      final existingAppId = match.matchAppId;
      final matchAppId = existingAppId ?? await db.nextMatchAppId();

      // 1. Insert or Upsert Match
      // Store actual ground / match type in venue prefixed with match title (team names)
      // so other players pulling this match retain team names and venue
      final cleanGround = match.venue.isNotEmpty ? match.venue : 'Local Ground';
      final cleanVenue = match.matchTitle.contains(' vs ')
          ? '${match.matchTitle} • $cleanGround'
          : cleanGround;
      final cleanSummary = '${match.teamARuns}/${match.teamAWickets} vs ${match.teamBRuns}/${match.teamBWickets} [$matchAppId]';

      final matchBody = <String, dynamic>{
        'id': matchUuid,
        'creator_id': effectiveCreatorId,
        'active_scorer_id': effectiveActiveScorerId,
        'venue': cleanVenue,
        'match_date': match.createdAt.toIso8601String(),
        'total_overs': match.totalOvers,
        'status': 'completed',
        'match_result_summary': cleanSummary,
        'win_margin_type': 'runs',
        'match_app_id': matchAppId,
        if (effectivePlayerProfileIds.isNotEmpty)
          'player_profile_ids': effectivePlayerProfileIds,
      };

      final upsertHeaders = {
        ..._headers,
        'Prefer': 'resolution=merge-duplicates,return=representation',
      };

      final matchRes = await http.post(
        Uri.parse('$_url/matches'),
        headers: upsertHeaders,
        body: jsonEncode(matchBody),
      );
      if (matchRes.statusCode != 200 && matchRes.statusCode != 201) {
        debugPrint('InsforgeSyncService: match insert/upsert failed (${matchRes.statusCode}): ${matchRes.body}');
        return false;
      }

      // Persist the sequential match id (SM-10001, ...) on the local record for management.
      await db.markMatchAppId(localMatchId, matchAppId);

      // 2. Insert Innings
      final innings1Uuid = const Uuid().v4();
      final innings2Uuid = const Uuid().v4();

      await http.post(
        Uri.parse('$_url/innings'),
        headers: _headers,
        body: jsonEncode([
          {
            'id': innings1Uuid,
            'match_id': matchUuid,
            'innings_number': 1,
            'total_runs': match.teamARuns,
            'total_wickets': match.teamAWickets,
            'is_completed': true,
          },
          {
            'id': innings2Uuid,
            'match_id': matchUuid,
            'innings_number': 2,
            'total_runs': match.teamBRuns,
            'total_wickets': match.teamBWickets,
            'is_completed': true,
          }
        ]),
      );

      // 3. Insert Balls
      final allBalls = await (db.select(db.ballEvents)..where((b) => b.matchId.equals(localMatchId))).get();

      List<Map<String, dynamic>> ballPayloads = [];
      for (var b in allBalls) {
        ballPayloads.add({
          'id': const Uuid().v4(),
          'innings_id': b.inningsNumber == 1 ? innings1Uuid : innings2Uuid,
          'over_number': b.overNumber,
          'ball_number': b.ballNumber,
          'runs_scored': b.runs,
          'extras': b.isExtra ? b.runs : 0,
          'extra_type': b.extraType?.toLowerCase(),
          'is_wicket': b.isWicket,
          'wicket_type': b.wicketType,
          'commentary': '${b.batterName} vs ${b.bowlerName} [$matchAppId]',
        });
      }

      if (ballPayloads.isNotEmpty) {
        for (var i = 0; i < ballPayloads.length; i += 100) {
          final end = (i + 100 < ballPayloads.length) ? i + 100 : ballPayloads.length;
          final chunk = ballPayloads.sublist(i, end);
          await http.post(
            Uri.parse('$_url/balls'),
            headers: _headers,
            body: jsonEncode(chunk),
          );
        }
      }

      // Non-blocking Pro Rating update trigger
      _triggerRatingUpdate(
        matchUuid: matchUuid,
        matchType: match.matchType,
        venue: match.venue,
        creatorId: creatorId,
      );

      return true;
    } catch (e) {
      debugPrint('Error syncing match to Insforge: $e');
      return false;
    }
  }

  static void _triggerRatingUpdate({
    required String matchUuid,
    required String matchType,
    required String venue,
    required String creatorId,
  }) {
    Future.microtask(() async {
      try {
        await PlayerRatingRepository.recalculateForCompletedMatch(
          matchId: matchUuid,
          matchType: matchType,
          venue: venue,
          playerUserId: creatorId,
          playerName: '',
          playerRole: 'BAT',
        );
      } catch (e) {
        debugPrint('InsforgeSyncService: rating recalculation error ($e)');
      }
    });
  }
}
