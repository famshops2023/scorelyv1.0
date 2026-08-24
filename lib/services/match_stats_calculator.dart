import '../services/database.dart';
import '../models/match_stats.dart';

class MatchStatsCalculator {
  static InningsStats computeInningsStats(
    CricketMatch match,
    Team? teamA,
    Team? teamB,
    List<Player> teamAPlayers,
    List<Player> teamBPlayers,
    List<BallEvent> balls,
    bool isFirstInnings,
  ) {
    // --- Determine which team batted in which innings ---
    // Primary: use inningsNumber column (stamped since schema v3)
    // Fallback: use batterId to determine team

    final innings1Balls = balls.where((b) => b.inningsNumber == 1).toList();
    final innings2Balls = balls.where((b) => b.inningsNumber == 2).toList();

    // If inningsNumber distinction exists, use it directly
    final bool hasInningsData = innings1Balls.isNotEmpty || innings2Balls.isNotEmpty;
    
    // Determine batting team using match data
    // teamARuns > 0 indicates team A batted; use score columns from match to identify
    // which team batted first by checking if first ball's batterId belongs to team A or B
    String innings1TeamName;
    String innings2TeamName;

    final teamBPlayerIds = teamBPlayers.map((e) => e.id).toSet();

    if (hasInningsData && innings1Balls.isNotEmpty) {
      // Use batterName from first innings ball to determine batting team
      final firstBatterName = innings1Balls.first.batterName;
      final firstBatterId = innings1Balls.first.batterId;

      // Check if first batter belongs to team A or B
      bool teamABattedFirst;
      if (firstBatterName.isNotEmpty) {
        teamABattedFirst = teamAPlayers.any((p) => p.name == firstBatterName) ||
            (!teamBPlayers.any((p) => p.name == firstBatterName));
        // Fallback: use player IDs if names match IDs
        if (teamBPlayers.any((p) => p.name == firstBatterName)) {
          teamABattedFirst = false;
        }
        if (teamAPlayers.any((p) => p.name == firstBatterName)) {
          teamABattedFirst = true;
        }
      } else {
        teamABattedFirst = !teamBPlayerIds.contains(firstBatterId);
      }

      innings1TeamName = teamABattedFirst ? (teamA?.name ?? 'Team A') : (teamB?.name ?? 'Team B');
      innings2TeamName = teamABattedFirst ? (teamB?.name ?? 'Team B') : (teamA?.name ?? 'Team A');
    } else {
      // Old data: no inningsNumber — fallback to old logic using batterId
      bool teamABattedFirst = true;
      if (balls.isNotEmpty) {
        if (teamBPlayerIds.contains(balls.first.batterId)) teamABattedFirst = false;
      }
      innings1TeamName = teamABattedFirst ? (teamA?.name ?? 'Team A') : (teamB?.name ?? 'Team B');
      innings2TeamName = teamABattedFirst ? (teamB?.name ?? 'Team B') : (teamA?.name ?? 'Team A');
    }

    final teamName = isFirstInnings ? innings1TeamName : innings2TeamName;
    final isTeamABatting = isFirstInnings
        ? (innings1TeamName == (teamA?.name ?? ''))
        : (innings2TeamName == (teamA?.name ?? ''));
    final battingTeamPlayers = isTeamABatting ? teamAPlayers : teamBPlayers;
    final bowlingTeamPlayers = isTeamABatting ? teamBPlayers : teamAPlayers;

    // Player ID → name lookup
    final Map<int, String> playerNameById = {};
    for (var p in battingTeamPlayers) { playerNameById[p.id] = p.name; }
    for (var p in bowlingTeamPlayers) { playerNameById[p.id] = p.name; }

    final Map<String, BatterStats> batterStatsMap = {};
    final Map<String, BowlerStats> bowlerStatsMap = {};
    final List<FallOfWicket> fallOfWickets = [];

    int totalRuns = 0;
    int totalWickets = 0;
    int totalBalls = 0;
    int extrasWides = 0;
    int extrasNoBalls = 0;
    int extrasByes = 0;
    String totalOversStr = '0.0';

    // Pick the correct set of balls
    List<BallEvent> inningsBalls;
    if (hasInningsData) {
      inningsBalls = isFirstInnings ? innings1Balls : innings2Balls;
    } else {
      // Legacy: split by player IDs
      final battingTeamPlayerIds = battingTeamPlayers.map((e) => e.id).toSet();
      inningsBalls = battingTeamPlayerIds.isNotEmpty
          ? balls.where((b) => battingTeamPlayerIds.contains(b.batterId)).toList()
          : [];
    }

    for (var ball in inningsBalls) {
      // Resolve names: prefer stored name, fallback to ID lookup
      final batterName = ball.batterName.isNotEmpty
          ? ball.batterName
          : (playerNameById[ball.batterId] ?? 'Batter #${ball.batterId}');
      final bowlerName = ball.bowlerName.isNotEmpty
          ? ball.bowlerName
          : (playerNameById[ball.bowlerId] ?? 'Bowler #${ball.bowlerId}');

      batterStatsMap.putIfAbsent(batterName, () => BatterStats(name: batterName));
      bowlerStatsMap.putIfAbsent(bowlerName, () => BowlerStats(name: bowlerName));

      final bStat = batterStatsMap[batterName]!;
      final bwStat = bowlerStatsMap[bowlerName]!;

      final isExtra = ball.isExtra;
      final countsAsBallForBatter = !isExtra || ball.extraType == 'Bye' || ball.extraType == 'LegBye';
      final countsAsBallForBowler = !isExtra || ball.extraType == 'Bye' || ball.extraType == 'LegBye';

      if (isExtra) {
        if (ball.extraType == 'Wide') {
          extrasWides += ball.runs;
        } else if (ball.extraType == 'NoBall') {
          extrasNoBalls += ball.runs;
        } else {
          extrasByes += ball.runs;
        }
        bwStat.runsConceded += ball.runs;
      } else {
        bStat.runs += ball.runs;
        bwStat.runsConceded += ball.runs;
      }

      if (countsAsBallForBatter) bStat.balls += 1;
      if (countsAsBallForBowler) bwStat.ballsBowled += 1;

      if (ball.runs == 4) bStat.fours += 1;
      if (ball.runs == 6) bStat.sixes += 1;

      if (ball.isWicket) {
        bStat.isOut = true;
        bStat.dismissalInfo = ball.wicketType ?? 'out';
        if (ball.wicketType != 'run out') bwStat.wickets += 1;
        fallOfWickets.add(FallOfWicket(
          wicketNumber: fallOfWickets.length + 1,
          playerName: batterName,
          score: totalRuns + bStat.runs,
          overInfo: '${totalBalls ~/ 6}.${totalBalls % 6} Ov',
        ));
      }
    }

    if (inningsBalls.isEmpty) {
      // No balls stored — use match aggregate columns
      final aBatted = innings1TeamName == (teamA?.name ?? '');
      if (isFirstInnings) {
        totalRuns = aBatted ? match.teamARuns : match.teamBRuns;
        totalWickets = aBatted ? match.teamAWickets : match.teamBWickets;
        int ov = aBatted ? match.teamAOvers : match.teamBOvers;
        int bl = aBatted ? match.teamABalls : match.teamBBalls;
        totalOversStr = '$ov.$bl';
      } else {
        totalRuns = aBatted ? match.teamBRuns : match.teamARuns;
        totalWickets = aBatted ? match.teamBWickets : match.teamAWickets;
        int ov = aBatted ? match.teamBOvers : match.teamAOvers;
        int bl = aBatted ? match.teamBBalls : match.teamABalls;
        totalOversStr = '$ov.$bl';
      }
    } else {
      for (var b in inningsBalls) {
        totalRuns += b.runs;
        if (b.isWicket) totalWickets++;
        if (!b.isExtra || b.extraType == 'Bye' || b.extraType == 'LegBye') totalBalls++;
      }
      totalOversStr = '${totalBalls ~/ 6}.${totalBalls % 6}';
    }

    final totalExtras = extrasWides + extrasNoBalls + extrasByes;
    final extrasInfo = '$totalExtras (wd $extrasWides, nb $extrasNoBalls, b $extrasByes)';

    return InningsStats(
      teamName: teamName,
      batterStats: batterStatsMap,
      bowlerStats: bowlerStatsMap,
      fallOfWickets: fallOfWickets,
      totalRuns: totalRuns,
      totalWickets: totalWickets,
      totalOvers: totalOversStr,
      extrasInfo: extrasInfo,
    );
  }
}
