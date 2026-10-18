import 'package:flutter_test/flutter_test.dart';
import 'package:scorely/models/match_stats.dart';

void main() {
  group('Cricket Scoring Logic & Stats Tests', () {
    test('BatterStats serialization preserves all metrics', () {
      final batter = BatterStats(
        name: 'Virat Kohli',
        runs: 82,
        balls: 53,
        fours: 6,
        sixes: 4,
        isOut: false,
        dismissalInfo: 'not out',
      );

      final json = batter.toJson();
      final restored = BatterStats.fromJson(json);

      expect(restored.name, 'Virat Kohli');
      expect(restored.runs, 82);
      expect(restored.balls, 53);
      expect(restored.fours, 6);
      expect(restored.sixes, 4);
      expect(restored.isOut, false);
      expect(restored.dismissalInfo, 'not out');
      expect(restored.strikeRate, closeTo(154.71, 0.01));
    });

    test('BowlerStats serialization preserves maidens and figures', () {
      final bowler = BowlerStats(
        name: 'Jasprit Bumrah',
        ballsBowled: 24, // 4 overs
        maidens: 1,
        runsConceded: 18,
        wickets: 3,
      );

      final json = bowler.toJson();
      final restored = BowlerStats.fromJson(json);

      expect(restored.name, 'Jasprit Bumrah');
      expect(restored.ballsBowled, 24);
      expect(restored.oversDisplay, '4.0');
      expect(restored.maidens, 1);
      expect(restored.runsConceded, 18);
      expect(restored.wickets, 3);
      expect(restored.economy, 4.5);
    });

    test('Wickets calculation never produces negative wickets', () {
      // Test when team has 11 players and 8 wickets lost
      int battingSquadLength = 11;
      int wickets = 8;
      int maxWickets = battingSquadLength > 0 ? battingSquadLength - 1 : 10;
      int wktsDiff = (maxWickets - wickets).clamp(0, 10);
      expect(wktsDiff, 2);

      // Test quick match with 0 players in list (edge case)
      battingSquadLength = 0;
      wickets = 0;
      maxWickets = battingSquadLength > 0 ? battingSquadLength - 1 : 10;
      wktsDiff = (maxWickets - wickets).clamp(0, 10);
      expect(wktsDiff, 10);
      expect(wktsDiff >= 0, isTrue);

      // Test when wickets lost is equal to max wickets
      wickets = 10;
      wktsDiff = (maxWickets - wickets).clamp(0, 10);
      expect(wktsDiff, 0);
    });

    test('Maiden over detection correctly identifies 0 runs conceded by bowler', () {
      bool isMaiden(List<String> thisOver) {
        if (thisOver.isEmpty) return false;
        for (final ball in thisOver) {
          if (ball.contains('Wd') || ball.contains('Nb')) return false;
          if (ball.endsWith('B') || ball.endsWith('LB') || ball == '.' || ball == 'W' || ball == '0') {
            continue;
          }
          final runs = int.tryParse(ball);
          if (runs != null && runs > 0) return false;
        }
        return true;
      }

      // 6 dot balls = Maiden
      expect(isMaiden(['.', '.', '.', '.', '.', '.']), isTrue);

      // Dots, Wicket, Byes = Maiden (byes do not charge bowler)
      expect(isMaiden(['.', 'W', '.', '1B', '.', '.']), isTrue);

      // Wide bowled = NOT a maiden
      expect(isMaiden(['.', 'Wd', '.', '.', '.', '.']), isFalse);

      // 1 run scored off bat = NOT a maiden
      expect(isMaiden(['.', '.', '1', '.', '.', '.']), isFalse);
    });

    test('Bowler quota limit detection', () {
      int maxOversPerBowler = 4;
      int ballsBowled = 24; // 4 overs
      int overs = ballsBowled ~/ 6;
      bool isQuotaReached = maxOversPerBowler > 0 && overs >= maxOversPerBowler;
      expect(isQuotaReached, isTrue);

      ballsBowled = 18; // 3 overs
      overs = ballsBowled ~/ 6;
      isQuotaReached = maxOversPerBowler > 0 && overs >= maxOversPerBowler;
      expect(isQuotaReached, isFalse);
    });
  });
}
