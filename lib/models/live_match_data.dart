import 'dart:convert';

/// Represents one live match record from InsForge (pending_matches table,
/// status = 'live'). The live scoring detail is stored in the [liveScoreData]
/// JSON column that is upserted on every ball by [ScoringScreen].
class LiveMatchData {
  final String id;
  final String teamAName;
  final String teamBName;
  final String teamAScore;    // e.g. "145/4"
  final String teamAOvers;    // e.g. "18.2"
  final String teamBScore;    // e.g. "yet to bat" or "88/3"
  final String teamBOvers;    // e.g. "" or "12.0"
  final String format;        // e.g. "T20"
  final String venue;
  final int innings;          // 1 or 2
  final String scorerId;      // From opening lineup scorer selection
  final List<String> teamAPlayerIds;
  final List<String> teamBPlayerIds;
  final String last6Balls;    // e.g. "0 4 W 1 6 2"
  final List<Map<String, dynamic>> currentBatters;
  final Map<String, dynamic> currentBowler;

  const LiveMatchData({
    required this.id,
    required this.teamAName,
    required this.teamBName,
    required this.teamAScore,
    required this.teamAOvers,
    required this.teamBScore,
    required this.teamBOvers,
    required this.format,
    required this.venue,
    required this.innings,
    required this.scorerId,
    required this.teamAPlayerIds,
    required this.teamBPlayerIds,
    required this.last6Balls,
    required this.currentBatters,
    required this.currentBowler,
  });

  /// Parses from the InsForge [pending_matches] row.
  /// The [live_score_data] column holds the live scoring JSON blob.
  factory LiveMatchData.fromInsForgeRow(Map<String, dynamic> row) {
    final raw = row['live_score_data'];
    final Map<String, dynamic> live =
        raw is String ? jsonDecode(raw) as Map<String, dynamic> : (raw as Map<String, dynamic>? ?? {});

    final matchData = row['match_data'] is String
        ? jsonDecode(row['match_data'] as String) as Map<String, dynamic>
        : (row['match_data'] as Map<String, dynamic>? ?? {});

    List<String> parseIds(dynamic val) {
      if (val == null) return [];
      if (val is List) return val.map((e) => e.toString()).toList();
      if (val is String) {
        try {
          final decoded = jsonDecode(val);
          if (decoded is List) return decoded.map((e) => e.toString()).toList();
        } catch (_) {}
      }
      return [];
    }

    return LiveMatchData(
      id: row['id']?.toString() ?? '',
      teamAName: matchData['teamAName'] as String? ?? 'Team A',
      teamBName: matchData['teamBName'] as String? ?? 'Team B',
      teamAScore: live['team_a_score'] as String? ?? '0/0',
      teamAOvers: live['team_a_overs'] as String? ?? '0.0',
      teamBScore: live['team_b_score'] as String? ?? 'yet to bat',
      teamBOvers: live['team_b_overs'] as String? ?? '',
      format: live['format'] as String? ?? matchData['matchType'] as String? ?? 'T20',
      venue: live['venue'] as String? ?? matchData['venue'] as String? ?? 'Local Ground',
      innings: (live['innings'] as num?)?.toInt() ?? 1,
      scorerId: live['scorer_id'] as String? ?? '',
      teamAPlayerIds: parseIds(live['team_a_player_ids']),
      teamBPlayerIds: parseIds(live['team_b_player_ids']),
      last6Balls: live['last_6_balls'] as String? ?? '',
      currentBatters: (live['current_batters'] as List?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          [],
      currentBowler: live['current_bowler'] as Map<String, dynamic>? ?? {},
    );
  }
}
