import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'database.dart';

class InsforgeSyncService {
  static const _url = 'https://ip53vj9s.ap-southeast.insforge.app/api/database/records';
  static const _headers = {
    'apikey': 'ik_d23aa9a406864853f254a0722fc1e56b',
    'Authorization': 'Bearer ik_d23aa9a406864853f254a0722fc1e56b',
    'Content-Type': 'application/json',
    'Prefer': 'return=representation',
  };

  /// Attempts to sync a local match to InsForge.
  /// Returns `true` on success, `false` if any HTTP step fails.
  static Future<bool> trySyncMatch(AppDatabase db, int localMatchId, String creatorId) async {
    try {
      final match = await (db.select(db.matches)..where((m) => m.id.equals(localMatchId))).getSingleOrNull();
      if (match == null) return false;

      final matchUuid = const Uuid().v4();

      // 1. Insert Match
      final matchBody = {
        'id': matchUuid,
        'creator_id': creatorId.isEmpty ? 'anonymous' : creatorId,
        'venue': match.venue,
        'match_date': match.createdAt.toIso8601String(),
        'total_overs': match.totalOvers,
        'status': 'completed',
        'match_result_summary': '${match.teamARuns}/${match.teamAWickets} vs ${match.teamBRuns}/${match.teamBWickets}',
        'win_margin_type': 'runs',
      };

      final matchRes = await http.post(
        Uri.parse('$_url/matches'),
        headers: _headers,
        body: jsonEncode(matchBody),
      );
      if (matchRes.statusCode != 200 && matchRes.statusCode != 201) {
        debugPrint('InsforgeSyncService: match insert failed (${matchRes.statusCode})');
        return false;
      }

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
          'commentary': '${b.batterName} vs ${b.bowlerName}',
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

      return true;
    } catch (e) {
      debugPrint('Error syncing match to Insforge: $e');
      return false;
    }
  }
}
