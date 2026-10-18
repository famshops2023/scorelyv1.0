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
    // Determine team names from match title if teams are null
    final titleParts = match.matchTitle.split(' vs ');
    final defaultTeamAName = titleParts.isNotEmpty && titleParts[0].trim().isNotEmpty
        ? titleParts[0].trim()
        : 'Team A';
    final defaultTeamBName = titleParts.length > 1 && titleParts[1].trim().isNotEmpty
        ? titleParts[1].trim()
        : 'Team B';

    final teamAName = teamA?.name.isNotEmpty == true ? teamA!.name : defaultTeamAName;
    final teamBName = teamB?.name.isNotEmpty == true ? teamB!.name : defaultTeamBName;

    // --- Determine which team batted in which innings ---
    final innings1Balls = balls.where((b) => b.inningsNumber == 1).toList();
    final innings2Balls = balls.where((b) => b.inningsNumber == 2).toList();
    final bool hasInningsData = innings1Balls.isNotEmpty || innings2Balls.isNotEmpty;

    final teamAPlayerIds = teamAPlayers.map((e) => e.id).toSet();
    final teamBPlayerIds = teamBPlayers.map((e) => e.id).toSet();

    String innings1TeamName;
    String innings2TeamName;

    if (hasInningsData && innings1Balls.isNotEmpty) {
      final firstBatterName = innings1Balls.first.batterName;
      final firstBatterId = innings1Balls.first.batterId;

      bool teamABattedFirst = true;
      if (teamAPlayers.any((p) => p.name == firstBatterName) || teamAPlayerIds.contains(firstBatterId)) {
        teamABattedFirst = true;
      } else if (teamBPlayers.any((p) => p.name == firstBatterName) || teamBPlayerIds.contains(firstBatterId)) {
        teamABattedFirst = false;
      } else {
        teamABattedFirst = true;
      }

      innings1TeamName = teamABattedFirst ? teamAName : teamBName;
      innings2TeamName = teamABattedFirst ? teamBName : teamAName;
    } else {
      bool teamABattedFirst = true;
      if (balls.isNotEmpty) {
        if (teamBPlayerIds.contains(balls.first.batterId) ||
            teamBPlayers.any((p) => p.name == balls.first.batterName)) {
          teamABattedFirst = false;
        }
      }
      innings1TeamName = teamABattedFirst ? teamAName : teamBName;
      innings2TeamName = teamABattedFirst ? teamBName : teamAName;
    }

    final teamName = isFirstInnings ? innings1TeamName : innings2TeamName;
    final isTeamABatting = isFirstInnings
        ? (innings1TeamName == teamAName)
        : (innings2TeamName == teamAName);
    final battingTeamPlayers = isTeamABatting ? teamAPlayers : teamBPlayers;
    final bowlingTeamPlayers = isTeamABatting ? teamBPlayers : teamAPlayers;

    // Player ID -> name lookup
    final Map<int, String> playerNameById = {};
    for (var p in battingTeamPlayers) { playerNameById[p.id] = p.name; }
    for (var p in bowlingTeamPlayers) { playerNameById[p.id] = p.name; }

    final Map<String, BatterStats> batterStatsMap = {};
    final Map<String, BowlerStats> bowlerStatsMap = {};
    final List<FallOfWicket> fallOfWickets = [];

    int totalRuns = 0;
    int totalWickets = 0;
    int totalBalls = 0; // legal balls
    int extrasWides = 0;
    int extrasNoBalls = 0;
    int extrasByes = 0;
    int extrasLegByes = 0;

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

    // Process balls in chronological order
    inningsBalls.sort((a, b) {
      final overCmp = a.overNumber.compareTo(b.overNumber);
      if (overCmp != 0) return overCmp;
      final ballCmp = a.ballNumber.compareTo(b.ballNumber);
      if (ballCmp != 0) return ballCmp;
      return a.id.compareTo(b.id);
    });

    for (var ball in inningsBalls) {
      final batterName = ball.batterName.isNotEmpty && ball.batterName != 'Unknown'
          ? ball.batterName
          : (playerNameById[ball.batterId] ?? (ball.batterName.isNotEmpty ? ball.batterName : 'Batter #${ball.batterId}'));
      final bowlerName = ball.bowlerName.isNotEmpty && ball.bowlerName != 'Unknown'
          ? ball.bowlerName
          : (playerNameById[ball.bowlerId] ?? (ball.bowlerName.isNotEmpty ? ball.bowlerName : 'Bowler #${ball.bowlerId}'));

      batterStatsMap.putIfAbsent(batterName, () => BatterStats(name: batterName));
      bowlerStatsMap.putIfAbsent(bowlerName, () => BowlerStats(name: bowlerName));

      final bStat = batterStatsMap[batterName]!;
      final bwStat = bowlerStatsMap[bowlerName]!;

      final isExtra = ball.isExtra;

      if (isExtra) {
        if (ball.extraType == 'Wide') {
          extrasWides += ball.runs;
          bwStat.runsConceded += ball.runs;
          totalRuns += ball.runs;
        } else if (ball.extraType == 'NoBall') {
          extrasNoBalls += 1;
          final batterRuns = (ball.runs > 1) ? (ball.runs - 1) : 0;
          if (batterRuns > 0) {
            bStat.runs += batterRuns;
            if (batterRuns == 4) bStat.fours += 1;
            if (batterRuns == 6) bStat.sixes += 1;
          }
          bStat.balls += 1;
          bwStat.runsConceded += ball.runs;
          totalRuns += ball.runs;
        } else if (ball.extraType == 'LegBye') {
          extrasLegByes += ball.runs;
          totalRuns += ball.runs;
          totalBalls += 1;
          bStat.balls += 1;
          bwStat.ballsBowled += 1;
        } else {
          // Bye
          extrasByes += ball.runs;
          totalRuns += ball.runs;
          totalBalls += 1;
          bStat.balls += 1;
          bwStat.ballsBowled += 1;
        }
      } else {
        bStat.runs += ball.runs;
        bStat.balls += 1;
        if (ball.runs == 4) bStat.fours += 1;
        if (ball.runs == 6) bStat.sixes += 1;

        bwStat.runsConceded += ball.runs;
        bwStat.ballsBowled += 1;
        totalRuns += ball.runs;
        totalBalls += 1;
      }

      if (ball.isWicket) {
        totalWickets += 1;
        bStat.isOut = true;
        bStat.dismissalInfo = ball.wicketType ?? 'out';

        final wType = ball.wicketType?.toLowerCase() ?? '';
        if (wType != 'run out' && wType != 'retired hurt' && wType != 'timed out') {
          bwStat.wickets += 1;
        }

        fallOfWickets.add(FallOfWicket(
          wicketNumber: totalWickets,
          playerName: batterName,
          score: totalRuns,
          overInfo: '${totalBalls ~/ 6}.${totalBalls % 6} Ov',
        ));
      }
    }

    // Calculate Maidens per bowler
    final Map<String, Map<int, List<BallEvent>>> bowlerOvers = {};
    for (var ball in inningsBalls) {
      final bowlerName = ball.bowlerName.isNotEmpty && ball.bowlerName != 'Unknown'
          ? ball.bowlerName
          : (playerNameById[ball.bowlerId] ?? (ball.bowlerName.isNotEmpty ? ball.bowlerName : 'Bowler #${ball.bowlerId}'));
      bowlerOvers.putIfAbsent(bowlerName, () => {}).putIfAbsent(ball.overNumber, () => []).add(ball);
    }

    bowlerOvers.forEach((bowlerName, overs) {
      int maidens = 0;
      overs.forEach((overNum, ballsInOver) {
        int legalBallsInOver = 0;
        int bowlerRunsInOver = 0;
        for (var b in ballsInOver) {
          final isLegal = !b.isExtra || b.extraType == 'Bye' || b.extraType == 'LegBye';
          if (isLegal) legalBallsInOver++;

          if (!b.isExtra) {
            bowlerRunsInOver += b.runs;
          } else if (b.extraType == 'Wide' || b.extraType == 'NoBall') {
            bowlerRunsInOver += b.runs;
          }
        }
        if (legalBallsInOver >= 6 && bowlerRunsInOver == 0) {
          maidens++;
        }
      });
      if (bowlerStatsMap.containsKey(bowlerName)) {
        bowlerStatsMap[bowlerName]!.maidens = maidens;
      }
    });

    String totalOversStr;
    if (inningsBalls.isEmpty) {
      // No balls stored — use match aggregate columns
      final aBatted = innings1TeamName == teamAName;
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
      totalOversStr = '${totalBalls ~/ 6}.${totalBalls % 6}';
    }

    final totalExtras = extrasWides + extrasNoBalls + extrasByes + extrasLegByes;
    final List<String> extrasBreakdown = [];
    if (extrasWides > 0) extrasBreakdown.add('wd $extrasWides');
    if (extrasNoBalls > 0) extrasBreakdown.add('nb $extrasNoBalls');
    if (extrasByes > 0) extrasBreakdown.add('b $extrasByes');
    if (extrasLegByes > 0) extrasBreakdown.add('lb $extrasLegByes');
    final breakdownStr = extrasBreakdown.isNotEmpty ? ' (${extrasBreakdown.join(', ')})' : '';
    final extrasInfo = '$totalExtras$breakdownStr';

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
