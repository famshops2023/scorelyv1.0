import 'package:flutter_test/flutter_test.dart';
import 'package:scorely/models/player_pro_rating.dart';
import 'package:scorely/services/ratings/player_rating_engine.dart';
import 'package:scorely/services/ratings/player_badge_engine.dart';

void main() {
  group('Scorely Pro Rating Engine Tests', () {
    test('Zero matches returns 0 rating and Novice level safely', () {
      final result = PlayerRatingEngine.calculate(
        matchType: 'turf',
        playerRole: 'BAT',
        matches: 0,
        innings: 0,
        totalRuns: 0,
        notOuts: 0,
        ballsFaced: 0,
        fours: 0,
        sixes: 0,
        fifties: 0,
        hundreds: 0,
        recentRuns: [],
        totalWickets: 0,
        overs: 0,
        runsConceded: 0,
        dotBalls: 0,
        fourWicketHauls: 0,
        fiveWicketHauls: 0,
        recentWickets: [],
        catches: 0,
        runOuts: 0,
        stumpings: 0,
        matchesWon: 0,
      );

      expect(result.overallRating, 0);
      expect(result.level, 'Novice');
      expect(result.badges, isEmpty);
    });

    test('High-performing Turf batter achieves Elite/Legend and Hard Hitter badge', () {
      final result = PlayerRatingEngine.calculate(
        matchType: 'turf',
        playerRole: 'BAT',
        matches: 10,
        innings: 10,
        totalRuns: 450,
        notOuts: 2,
        ballsFaced: 250, // SR = 180
        fours: 35,
        sixes: 20,
        fifties: 4,
        hundreds: 1,
        recentRuns: [45.0, 60.0, 75.0, 30.0, 50.0],
        totalWickets: 0,
        overs: 0,
        runsConceded: 0,
        dotBalls: 0,
        fourWicketHauls: 0,
        fiveWicketHauls: 0,
        recentWickets: [],
        catches: 4,
        runOuts: 1,
        stumpings: 0,
        matchesWon: 8,
      );

      expect(result.overallRating, greaterThanOrEqualTo(700));
      expect(result.overallRating, lessThanOrEqualTo(1000));
      expect(result.level, isIn(['Elite', 'Legend']));
      expect(result.badges, contains('💥 Hard Hitter'));
    });

    test('High-performing Ground bowler achieves strong bowling rating and Wicket Taker badge', () {
      final result = PlayerRatingEngine.calculate(
        matchType: 'ground',
        playerRole: 'BOWL',
        matches: 8,
        innings: 2,
        totalRuns: 15,
        notOuts: 1,
        ballsFaced: 12,
        fours: 1,
        sixes: 0,
        fifties: 0,
        hundreds: 0,
        recentRuns: [],
        totalWickets: 18,
        overs: 32,
        runsConceded: 160, // Economy = 5.0
        dotBalls: 80,
        fourWicketHauls: 2,
        fiveWicketHauls: 1,
        recentWickets: [3.0, 2.0, 4.0, 2.0, 3.0],
        catches: 3,
        runOuts: 0,
        stumpings: 0,
        matchesWon: 6,
      );

      expect(result.bowlingRating, greaterThanOrEqualTo(70));
      expect(result.overallRating, greaterThanOrEqualTo(650));
      expect(result.badges, contains('🎯 Wicket Taker'));
    });

    test('All-Rounder role properly balances batting and bowling performance', () {
      final result = PlayerRatingEngine.calculate(
        matchType: 'turf',
        playerRole: 'ALL',
        matches: 12,
        innings: 10,
        totalRuns: 300,
        notOuts: 2,
        ballsFaced: 200,
        fours: 20,
        sixes: 10,
        fifties: 2,
        hundreds: 0,
        recentRuns: [30.0, 40.0, 25.0],
        totalWickets: 14,
        overs: 30,
        runsConceded: 180,
        dotBalls: 60,
        fourWicketHauls: 1,
        fiveWicketHauls: 0,
        recentWickets: [2.0, 1.0, 2.0],
        catches: 5,
        runOuts: 2,
        stumpings: 0,
        matchesWon: 8,
      );

      expect(result.battingRating, greaterThan(50));
      expect(result.bowlingRating, greaterThan(50));
      expect(result.badges, contains('🎩 All-Rounder'));
    });

    test('Ratings are clamped within 0 to 1000 without NaN or Infinity', () {
      final result = PlayerRatingEngine.calculate(
        matchType: 'turf',
        playerRole: 'BAT',
        matches: 1,
        innings: 1,
        totalRuns: 500,
        notOuts: 1,
        ballsFaced: 100,
        fours: 50,
        sixes: 50,
        fifties: 0,
        hundreds: 1,
        recentRuns: [500.0],
        totalWickets: 10,
        overs: 4,
        runsConceded: 0,
        dotBalls: 24,
        fourWicketHauls: 1,
        fiveWicketHauls: 1,
        recentWickets: [10.0],
        catches: 10,
        runOuts: 5,
        stumpings: 5,
        matchesWon: 1,
      );

      expect(result.overallRating, lessThanOrEqualTo(1000));
      expect(result.overallRating, greaterThanOrEqualTo(0));
      expect(result.level, 'Legend');
    });

    test('PlayerProRating model correctly identifies levels based on score boundaries', () {
      expect(PlayerProRating.getPlayerLevel(150), 'Novice');
      expect(PlayerProRating.getPlayerLevel(250), 'Active');
      expect(PlayerProRating.getPlayerLevel(450), 'Aspirant');
      expect(PlayerProRating.getPlayerLevel(620), 'Senior');
      expect(PlayerProRating.getPlayerLevel(742), 'Elite');
      expect(PlayerProRating.getPlayerLevel(920), 'Legend');
    });

    test('PlayerBadgeEngine selects priority top badge correctly', () {
      final badges = ['🧤 Safe Hands', '💥 Hard Hitter', '🚀 Rising Star'];
      final topBadge = PlayerBadgeEngine.getTopBadge(badges);
      expect(topBadge, '💥 Hard Hitter');
    });
  });
}
