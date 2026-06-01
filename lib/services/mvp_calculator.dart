import '../services/database.dart';

class MVPResult {
  final String playerName;
  final int totalPoints;
  final String teamName;
  final String detailedStats;

  MVPResult({
    required this.playerName,
    required this.totalPoints,
    required this.teamName,
    required this.detailedStats,
  });
}

class MvpCalculator {
  static MVPResult calculateMVP(
    CricketMatch match, 
    Team? teamA, 
    Team? teamB, 
    List<Player> teamAPlayers, 
    List<Player> teamBPlayers, 
    List<BallEvent> balls
  ) {
    final Map<int, Player> playerMap = {};
    for (var p in teamAPlayers) {
      playerMap[p.id] = p;
    }
    for (var p in teamBPlayers) {
      playerMap[p.id] = p;
    }

    final Map<int, int> playerPoints = {};
    final Map<int, String> playerDetails = {};
    
    int maxPoints = -9999;
    int mvpId = -1;

    final battingTeamPlayerIds = teamAPlayers.map((e) => e.id).toSet();

    for (var pId in playerMap.keys) {
      int points = 0;
      final p = playerMap[pId]!;
      
      final playerBalls = balls.where((b) => b.batterId == p.id || b.bowlerId == p.id).toList();

      int runsScored = 0;
      int wicketsTaken = 0;
      int fours = 0;
      int sixes = 0;

      for (var b in playerBalls) {
        if (b.batterId == p.id) {
          if (!b.isExtra || b.extraType == 'Bye' || b.extraType == 'LegBye') {
            runsScored += b.runs;
            if (b.runs == 4) fours++;
            if (b.runs == 6) sixes++;
          }
        }
        if (b.bowlerId == p.id) {
          if (b.isWicket && b.wicketType != 'run out') {
            wicketsTaken++;
          }
        }
      }

      points += runsScored;
      points += (fours * 1);
      points += (sixes * 2);
      if (runsScored >= 50 && runsScored < 100) points += 10;
      if (runsScored >= 100) points += 25;
      
      points += (wicketsTaken * 20);
      if (wicketsTaken >= 3 && wicketsTaken < 5) points += 10;
      if (wicketsTaken >= 5) points += 25;

      playerPoints[pId] = points;
      
      if (runsScored > 0 || wicketsTaken > 0) {
        playerDetails[pId] = '$runsScored Runs ($fours x 4, $sixes x 6), $wicketsTaken Wickets';
      }

      if (points > maxPoints) {
        maxPoints = points;
        mvpId = pId;
      }
    }

    if (mvpId == -1 || maxPoints == 0) {
      return MVPResult(
        playerName: 'No MVP',
        totalPoints: 0,
        teamName: '-',
        detailedStats: 'Not enough data to calculate MVP.',
      );
    }

    final mvpPlayer = playerMap[mvpId]!;
    final mvpTeamName = battingTeamPlayerIds.contains(mvpId) ? teamA?.name : teamB?.name;

    return MVPResult(
      playerName: mvpPlayer.name,
      totalPoints: maxPoints,
      teamName: mvpTeamName ?? 'Unknown',
      detailedStats: playerDetails[mvpId] ?? '',
    );
  }
}
