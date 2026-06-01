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
    bool isFirstInnings
  ) {
    // Determine which team batted first by checking the first ball's batterId
    final teamBPlayerIds = teamBPlayers.map((e) => e.id).toSet();
    
    bool teamABattedFirst = true;
    if (balls.isNotEmpty) {
      final firstBatterId = balls.first.batterId;
      if (teamBPlayerIds.contains(firstBatterId)) {
        teamABattedFirst = false;
      }
    }
    
    final isTeamABatting = isFirstInnings ? teamABattedFirst : !teamABattedFirst;
    final battingTeam = isTeamABatting ? teamA : teamB;
    final teamName = battingTeam?.name ?? 'Unknown Team';
    final battingTeamPlayers = isTeamABatting ? teamAPlayers : teamBPlayers;
    final bowlingTeamPlayers = isTeamABatting ? teamBPlayers : teamAPlayers;

    // Player name lookup
    final Map<int, String> playerNameMap = {};
    for (var p in battingTeamPlayers) {
      playerNameMap[p.id] = p.name;
    }
    for (var p in bowlingTeamPlayers) {
      playerNameMap[p.id] = p.name;
    }

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

    final battingTeamPlayerIds = battingTeamPlayers.map((e) => e.id).toSet();
    
    List<BallEvent> inningsBalls = [];
    if (battingTeamPlayerIds.isNotEmpty) {
      inningsBalls = balls.where((b) => battingTeamPlayerIds.contains(b.batterId)).toList();
    }

    for (var ball in inningsBalls) {
      final batterName = playerNameMap[ball.batterId] ?? 'Batter ${ball.batterId}';
      final bowlerName = playerNameMap[ball.bowlerId] ?? 'Bowler ${ball.bowlerId}';

      batterStatsMap.putIfAbsent(batterName, () => BatterStats(name: batterName));
      bowlerStatsMap.putIfAbsent(bowlerName, () => BowlerStats(name: bowlerName));

      final bStat = batterStatsMap[batterName]!;
      final bwStat = bowlerStatsMap[bowlerName]!;

      bool isExtra = ball.isExtra;
      bool countsAsBallForBatter = !isExtra || ball.extraType == 'Bye' || ball.extraType == 'LegBye';
      bool countsAsBallForBowler = !isExtra || ball.extraType == 'Bye' || ball.extraType == 'LegBye';

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
        bStat.runs = (bStat.runs) + ball.runs;
        bwStat.runsConceded = (bwStat.runsConceded) + ball.runs;
      }

      if (countsAsBallForBatter) bStat.balls = (bStat.balls) + 1;
      if (countsAsBallForBowler) bwStat.ballsBowled = (bwStat.ballsBowled) + 1;

      if (ball.runs == 4) bStat.fours = (bStat.fours) + 1;
      if (ball.runs == 6) bStat.sixes = (bStat.sixes) + 1;

      if (ball.isWicket) {
        bStat.isOut = true;
        bStat.dismissalInfo = ball.wicketType ?? 'out';
        if (ball.wicketType != 'run out') bwStat.wickets = (bwStat.wickets) + 1;
        
        fallOfWickets.add(FallOfWicket(
          wicketNumber: fallOfWickets.length + 1,
          playerName: batterName,
          score: bStat.runs,
          overInfo: '0.0 Ov',
        ));
      }
    }

    if (inningsBalls.isEmpty) {
      totalRuns = isTeamABatting ? match.teamARuns : match.teamBRuns;
      totalWickets = isTeamABatting ? match.teamAWickets : match.teamBWickets;
      int ov = isTeamABatting ? match.teamAOvers : match.teamBOvers;
      int bl = isTeamABatting ? match.teamABalls : match.teamBBalls;
      totalOversStr = '$ov.$bl';
    } else {
      for (var b in inningsBalls) {
        totalRuns += b.runs;
        if (b.isWicket) totalWickets++;
        if (!b.isExtra || b.extraType == 'Bye' || b.extraType == 'LegBye') totalBalls++;
      }
      int ov = totalBalls ~/ 6;
      int bl = totalBalls % 6;
      totalOversStr = '$ov.$bl';
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
