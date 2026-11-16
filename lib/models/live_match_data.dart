import 'dart:convert';
import 'user_profile.dart';

/// Represents one live match record from InsForge (pending_matches table,
/// status = 'live'). The live scoring detail is stored in the [liveScoreData]
/// JSON column that is upserted on every ball by [ScoringScreen].
class LiveMatchData {
  final String id;
  final String creatorId;     // Match creator profile ID
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
  final String scorerName;    // Display name of active scorer
  final List<String> teamAPlayerIds;
  final List<String> teamBPlayerIds;
  final String last6Balls;    // e.g. "0 4 W 1 6 2"
  final List<Map<String, dynamic>> currentBatters;
  final Map<String, dynamic> currentBowler;
  final String? matchAppId;

  const LiveMatchData({
    required this.id,
    this.creatorId = '',
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
    this.scorerName = '',
    required this.teamAPlayerIds,
    required this.teamBPlayerIds,
    required this.last6Balls,
    required this.currentBatters,
    required this.currentBowler,
    this.matchAppId,
  });

  /// Parses from the InsForge [pending_matches] or [matches] row.
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

    void addIdWithDerivedSp(List<String> list, String id) {
      final clean = id.trim();
      if (clean.isEmpty) return;
      if (!list.contains(clean)) list.add(clean);
      if (clean.length == 36 && clean.contains('-')) {
        final spId = UserProfile.deriveDisplayId(clean);
        if (!list.contains(spId)) list.add(spId);
      }
    }

    final teamAPlayerIds = <String>[];
    for (final id in parseIds(live['team_a_player_ids'])) {
      addIdWithDerivedSp(teamAPlayerIds, id);
    }
    if (matchData['teamAPlayers'] is List) {
      for (final p in (matchData['teamAPlayers'] as List)) {
        if (p is Map) {
          final pid = p['profileId']?.toString();
          final name = p['name']?.toString();
          if (pid != null && pid.isNotEmpty) {
            addIdWithDerivedSp(teamAPlayerIds, pid);
          }
          if (name != null && name.isNotEmpty && !teamAPlayerIds.contains(name)) {
            teamAPlayerIds.add(name);
          }
        }
      }
    }

    final teamBPlayerIds = <String>[];
    for (final id in parseIds(live['team_b_player_ids'])) {
      addIdWithDerivedSp(teamBPlayerIds, id);
    }
    if (matchData['teamBPlayers'] is List) {
      for (final p in (matchData['teamBPlayers'] as List)) {
        if (p is Map) {
          final pid = p['profileId']?.toString();
          final name = p['name']?.toString();
          if (pid != null && pid.isNotEmpty) {
            addIdWithDerivedSp(teamBPlayerIds, pid);
          }
          if (name != null && name.isNotEmpty && !teamBPlayerIds.contains(name)) {
            teamBPlayerIds.add(name);
          }
        }
      }
    }

    // Also support row from matches table
    if (row['player_profile_ids'] != null) {
      final pList = parseIds(row['player_profile_ids']);
      for (final pid in pList) {
        addIdWithDerivedSp(teamAPlayerIds, pid);
      }
    }

    String teamAName = matchData['teamAName'] as String? ?? '';
    String teamBName = matchData['teamBName'] as String? ?? '';
    final venueField = (live['venue'] as String?) ?? (matchData['venue'] as String?) ?? (row['venue'] as String?) ?? 'Local Ground';
    if (teamAName.isEmpty || teamBName.isEmpty) {
      if (venueField.contains(' vs ')) {
        final titlePart = venueField.contains(' • ') ? venueField.split(' • ').first : venueField;
        final vParts = titlePart.split(' vs ');
        if (vParts.isNotEmpty && teamAName.isEmpty) teamAName = vParts[0].trim();
        if (vParts.length > 1 && teamBName.isEmpty) teamBName = vParts[1].trim();
      }
    }
    if (teamAName.isEmpty) teamAName = 'Team A';
    if (teamBName.isEmpty) teamBName = 'Team B';

    final scorerName = live['scorer_name'] as String? ??
        matchData['teamAScorerName'] as String? ??
        (live['scorer_id'] as String?) ??
        '';

    final creatorId = (live['creator_id'] as String?) ??
        (row['created_by_profile_id'] as String?) ??
        (row['creator_id'] as String?) ??
        (matchData['creatorId'] as String?) ??
        '';

    final matchAppId = (row['match_app_id'] as String?) ??
        (matchData['matchAppId'] as String?) ??
        (matchData['match_app_id'] as String?);

    final activeScorerId = row['active_scorer_id']?.toString();
    final effectiveScorerId = (activeScorerId != null && activeScorerId.isNotEmpty)
        ? activeScorerId
        : (live['scorer_id'] as String? ??
            (matchData['teamAScorerId'] as String? ?? ''));

    return LiveMatchData(
      id: row['id']?.toString() ?? '',
      creatorId: creatorId,
      teamAName: teamAName,
      teamBName: teamBName,
      teamAScore: live['team_a_score'] as String? ?? '0/0',
      teamAOvers: live['team_a_overs'] as String? ?? '0.0',
      teamBScore: live['team_b_score'] as String? ?? 'yet to bat',
      teamBOvers: live['team_b_overs'] as String? ?? '',
      format: live['format'] as String? ?? matchData['matchType'] as String? ?? 'T20',
      venue: venueField.contains(' • ') ? venueField.split(' • ').last.trim() : venueField,
      innings: (live['innings'] as num?)?.toInt() ?? 1,
      scorerId: effectiveScorerId,
      scorerName: scorerName,
      teamAPlayerIds: teamAPlayerIds,
      teamBPlayerIds: teamBPlayerIds,
      last6Balls: live['last_6_balls'] as String? ?? '',
      currentBatters: (live['current_batters'] as List?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          [],
      currentBowler: live['current_bowler'] as Map<String, dynamic>? ?? {},
      matchAppId: matchAppId,
    );
  }
}
