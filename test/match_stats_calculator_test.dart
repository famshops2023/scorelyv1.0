import 'package:flutter_test/flutter_test.dart';
import 'package:scorely/services/database.dart';
import 'package:scorely/services/match_stats_calculator.dart';

void main() {
  test('MatchStatsCalculator correctly computes Fall of Wickets and Bowling stats', () {
    final now = DateTime.now();
    final match = CricketMatch(
      id: 1,
      matchTitle: 'Warriors vs Titans',
      totalOvers: 20,
      matchType: 'T20',
      ballType: 'Leather',
      venue: 'Ground',
      isQuickMatch: true,
      isCompleted: true,
      currentInnings: 2,
      syncPending: false,
      teamARuns: 150,
      teamAWickets: 2,
      teamAOvers: 20,
      teamABalls: 0,
      teamBRuns: 0,
      teamBWickets: 0,
      teamBOvers: 0,
      teamBBalls: 0,
      createdAt: now,
    );

    final balls = <BallEvent>[
      // Over 0 by Bowler A (Maiden over with 1 wicket)
      // Ball 1: dot
      BallEvent(id: 1, matchId: 1, inningsNumber: 1, overNumber: 0, ballNumber: 1, runs: 0, isWicket: false, isExtra: false, batterId: 1, bowlerId: 10, batterName: 'Batter 1', bowlerName: 'Bowler A', timestamp: now),
      // Ball 2: dot
      BallEvent(id: 2, matchId: 1, inningsNumber: 1, overNumber: 0, ballNumber: 2, runs: 0, isWicket: false, isExtra: false, batterId: 1, bowlerId: 10, batterName: 'Batter 1', bowlerName: 'Bowler A', timestamp: now),
      // Ball 3: wicket
      BallEvent(id: 3, matchId: 1, inningsNumber: 1, overNumber: 0, ballNumber: 3, runs: 0, isWicket: true, wicketType: 'bowled', isExtra: false, batterId: 1, bowlerId: 10, batterName: 'Batter 1', bowlerName: 'Bowler A', timestamp: now),
      // Ball 4: dot
      BallEvent(id: 4, matchId: 1, inningsNumber: 1, overNumber: 0, ballNumber: 4, runs: 0, isWicket: false, isExtra: false, batterId: 2, bowlerId: 10, batterName: 'Batter 2', bowlerName: 'Bowler A', timestamp: now),
      // Ball 5: dot
      BallEvent(id: 5, matchId: 1, inningsNumber: 1, overNumber: 0, ballNumber: 5, runs: 0, isWicket: false, isExtra: false, batterId: 2, bowlerId: 10, batterName: 'Batter 2', bowlerName: 'Bowler A', timestamp: now),
      // Ball 6: dot
      BallEvent(id: 6, matchId: 1, inningsNumber: 1, overNumber: 0, ballNumber: 6, runs: 0, isWicket: false, isExtra: false, batterId: 2, bowlerId: 10, batterName: 'Batter 2', bowlerName: 'Bowler A', timestamp: now),

      // Over 1 by Bowler B
      // Ball 1: 4 runs
      BallEvent(id: 7, matchId: 1, inningsNumber: 1, overNumber: 1, ballNumber: 1, runs: 4, isWicket: false, isExtra: false, batterId: 2, bowlerId: 20, batterName: 'Batter 2', bowlerName: 'Bowler B', timestamp: now),
      // Ball 2: Wide (1 run)
      BallEvent(id: 8, matchId: 1, inningsNumber: 1, overNumber: 1, ballNumber: 2, runs: 1, isWicket: false, isExtra: true, extraType: 'Wide', batterId: 2, bowlerId: 20, batterName: 'Batter 2', bowlerName: 'Bowler B', timestamp: now),
      // Ball 3: 6 runs
      BallEvent(id: 9, matchId: 1, inningsNumber: 1, overNumber: 1, ballNumber: 2, runs: 6, isWicket: false, isExtra: false, batterId: 2, bowlerId: 20, batterName: 'Batter 2', bowlerName: 'Bowler B', timestamp: now),
      // Ball 4: wicket (caught)
      BallEvent(id: 10, matchId: 1, inningsNumber: 1, overNumber: 1, ballNumber: 3, runs: 0, isWicket: true, wicketType: 'caught', isExtra: false, batterId: 2, bowlerId: 20, batterName: 'Batter 2', bowlerName: 'Bowler B', timestamp: now),
    ];

    final stats = MatchStatsCalculator.computeInningsStats(
      match,
      null,
      null,
      [],
      [],
      balls,
      true,
    );

    // Verify Fall of Wickets
    expect(stats.fallOfWickets.length, 2);
    // 1st wicket: score 0/1 at 0.3 ov
    expect(stats.fallOfWickets[0].wicketNumber, 1);
    expect(stats.fallOfWickets[0].score, 0);
    expect(stats.fallOfWickets[0].playerName, 'Batter 1');
    expect(stats.fallOfWickets[0].overInfo, '0.3 Ov');

    // 2nd wicket: 0 + 4 + 1(wd) + 6 = 11 runs; legal balls: 6 + 1 + 1 + 1 = 9 balls (1.3 ov)
    expect(stats.fallOfWickets[1].wicketNumber, 2);
    expect(stats.fallOfWickets[1].score, 11);
    expect(stats.fallOfWickets[1].playerName, 'Batter 2');
    expect(stats.fallOfWickets[1].overInfo, '1.3 Ov');

    // Verify Bowler Stats
    expect(stats.bowlerStats.containsKey('Bowler A'), true);
    final bowlerA = stats.bowlerStats['Bowler A']!;
    expect(bowlerA.ballsBowled, 6);
    expect(bowlerA.oversDisplay, '1.0');
    expect(bowlerA.runsConceded, 0);
    expect(bowlerA.wickets, 1);
    expect(bowlerA.maidens, 1);

    expect(stats.bowlerStats.containsKey('Bowler B'), true);
    final bowlerB = stats.bowlerStats['Bowler B']!;
    expect(bowlerB.ballsBowled, 3);
    expect(bowlerB.oversDisplay, '0.3');
    expect(bowlerB.runsConceded, 11);
    expect(bowlerB.wickets, 1);
    expect(bowlerB.maidens, 0);
  });
}
