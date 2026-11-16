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
    // Clean team names helper
    String cleanTeamName(String raw) {
      final s = raw
          .replaceAll(RegExp(r'\[SM-\d+\]'), '')
          .replaceAll(RegExp(r'SM-\d+:?'), '')
          .replaceAll(RegExp(r'Cricket Match\s*(\(SM-\d+\))?', caseSensitive: false), '')
          .trim();
      return s.isNotEmpty ? s : raw.trim();
    }

    // Determine team names from match title if teams are null
    final titleParts = match.matchTitle.split(' vs ');
    final defaultTeamAName = titleParts.isNotEmpty && titleParts[0].trim().isNotEmpty
        ? cleanTeamName(titleParts[0])
        : 'Team A';
    final defaultTeamBName = titleParts.length > 1 && titleParts[1].trim().isNotEmpty
        ? cleanTeamName(titleParts[1])
        : 'Team B';

    final teamAName = teamA?.name.isNotEmpty == true ? teamA!.name : defaultTeamAName;
    final teamBName = teamB?.name.isNotEmpty == true ? teamB!.name : defaultTeamBName;

    // --- Determine which team batted in which innings ---
    final innings1Balls = balls.where((b) => b.inningsNumber == 1).toList();
    final innings2Balls = balls.where((b) => b.inningsNumber == 2).toList();

    final teamAPlayerIds = teamAPlayers.map((e) => e.id).toSet();
    final teamBPlayerIds = teamBPlayers.map((e) => e.id).toSet();
    final teamAPlayerNames = teamAPlayers
        .map((e) => e.name.trim().toLowerCase())
        .where((n) => n.isNotEmpty)
        .toSet();
    final teamBPlayerNames = teamBPlayers
        .map((e) => e.name.trim().toLowerCase())
        .where((n) => n.isNotEmpty)
        .toSet();

    bool? teamABattedFirst;

    // 1. Try resolving using Innings 1 balls
    if (innings1Balls.isNotEmpty) {
      int teamAVotes = 0;
      int teamBVotes = 0;
      for (var b in innings1Balls) {
        final bName = b.batterName.trim().toLowerCase();
        final bwName = b.bowlerName.trim().toLowerCase();
        if (teamAPlayerIds.contains(b.batterId) || teamAPlayerNames.contains(bName)) teamAVotes++;
        if (teamBPlayerIds.contains(b.batterId) || teamBPlayerNames.contains(bName)) teamBVotes++;
        // Bowler in Innings 1 is bowling (fielding team)
        if (teamAPlayerIds.contains(b.bowlerId) || teamAPlayerNames.contains(bwName)) teamBVotes++;
        if (teamBPlayerIds.contains(b.bowlerId) || teamBPlayerNames.contains(bwName)) teamAVotes++;
      }
      if (teamAVotes > teamBVotes) {
        teamABattedFirst = true;
      } else if (teamBVotes > teamAVotes) {
        teamABattedFirst = false;
      }
    }

    // 2. If not resolved yet (e.g. Scorer Handover where only Innings 2 balls were saved),
    // resolve using Innings 2 balls.
    // In Innings 2:
    // - Batters belong to the team batting SECOND.
    // - If Innings 2 batter is from Team B, then Team B batted 2nd -> Team A batted 1st!
    // - If Innings 2 batter is from Team A, then Team A batted 2nd -> Team B batted 1st!
    if (teamABattedFirst == null && innings2Balls.isNotEmpty) {
      int teamAVotes = 0;
      int teamBVotes = 0;
      for (var b in innings2Balls) {
        final bName = b.batterName.trim().toLowerCase();
        final bwName = b.bowlerName.trim().toLowerCase();
        if (teamAPlayerIds.contains(b.batterId) || teamAPlayerNames.contains(bName)) teamBVotes++; // A batting 2nd -> B batted 1st
        if (teamBPlayerIds.contains(b.batterId) || teamBPlayerNames.contains(bName)) teamAVotes++; // B batting 2nd -> A batted 1st
        if (teamAPlayerIds.contains(b.bowlerId) || teamAPlayerNames.contains(bwName)) teamAVotes++; // A bowling 2nd -> A batted 1st
        if (teamBPlayerIds.contains(b.bowlerId) || teamBPlayerNames.contains(bwName)) teamBVotes++; // B bowling 2nd -> B batted 1st
      }
      if (teamAVotes > teamBVotes) {
        teamABattedFirst = true;
      } else if (teamBVotes > teamAVotes) {
        teamABattedFirst = false;
      }
    }

    // 3. Fallback: default to Team A batting first
    teamABattedFirst ??= true;

    final innings1TeamName = teamABattedFirst ? teamAName : teamBName;
    final innings2TeamName = teamABattedFirst ? teamBName : teamAName;

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
    final targetInningsBalls = isFirstInnings ? innings1Balls : innings2Balls;
    if (targetInningsBalls.isNotEmpty) {
      inningsBalls = targetInningsBalls;
    } else if (innings1Balls.isNotEmpty || innings2Balls.isNotEmpty) {
      // Legacy: split by batter ownership (e.g. inningsNumber not populated for
      // one innings while the other has balls, such as scorer handover).
      final battingTeamPlayerIds = battingTeamPlayers.map((e) => e.id).toSet();
      inningsBalls = battingTeamPlayerIds.isNotEmpty
          ? balls.where((b) => battingTeamPlayerIds.contains(b.batterId)).toList()
          : [];
    } else {
      inningsBalls = [];
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
