import 'dart:math';
import '../../core/config/rating_benchmark_config.dart';
import '../../models/player_pro_rating.dart';
import 'player_badge_engine.dart';

class CalculatedRatingResult {
  final int overallRating; // 0 to 1000
  final String level;
  final int battingRating; // 0 to 100
  final int bowlingRating; // 0 to 100
  final int fieldingRating; // 0 to 100
  final int matchImpactRating; // 0 to 100
  final List<String> badges;
  final String? topBadge;

  const CalculatedRatingResult({
    required this.overallRating,
    required this.level,
    required this.battingRating,
    required this.bowlingRating,
    required this.fieldingRating,
    required this.matchImpactRating,
    required this.badges,
    this.topBadge,
  });
}

/// Core rating computation engine for Scorely Pro Ratings.
class PlayerRatingEngine {
  /// Computes a player's Scorely Pro Rating from raw match statistics.
  static CalculatedRatingResult calculate({
    required String matchType, // 'turf' or 'ground'
    required String playerRole, // 'BAT', 'BOWL', 'ALL', 'WK', etc.
    required int matches,
    required int innings,
    required int totalRuns,
    required int notOuts,
    required int ballsFaced,
    required int fours,
    required int sixes,
    required int fifties,
    required int hundreds,
    required List<double> recentRuns,
    required int totalWickets,
    required int overs,
    required int runsConceded,
    required int dotBalls,
    required int fourWicketHauls,
    required int fiveWicketHauls,
    required List<double> recentWickets,
    required int catches,
    required int runOuts,
    required int stumpings,
    required int matchesWon,
  }) {
    if (matches <= 0) {
      return const CalculatedRatingResult(
        overallRating: 0,
        level: 'Novice',
        battingRating: 0,
        bowlingRating: 0,
        fieldingRating: 0,
        matchImpactRating: 0,
        badges: [],
      );
    }

    final config = RatingBenchmarkConfig.forMatchType(matchType);

    // 1. Compute Batting Metrics
    final dismissals = max(1, innings - notOuts);
    final battingAvg = innings > 0 ? (totalRuns / dismissals.toDouble()) : 0.0;
    final strikeRate = ballsFaced > 0 ? (totalRuns / ballsFaced.toDouble()) * 100.0 : 0.0;
    final runsPerMatch = matches > 0 ? (totalRuns / matches.toDouble()) : 0.0;
    final boundaryRuns = (fours * 4) + (sixes * 6);
    final boundaryPct = totalRuns > 0 ? (boundaryRuns / totalRuns.toDouble()) * 100.0 : 0.0;

    // Batting Consistency & Recent Form
    double recentBattingForm = 0.0;
    if (recentRuns.isNotEmpty) {
      final rAvg = recentRuns.reduce((a, b) => a + b) / recentRuns.length;
      recentBattingForm = min(100.0, (rAvg / max(1.0, config.benchmarkRunsPerMatch)) * 100.0);
    }

    // Normalized Batting Components (0-100 scale)
    final normBatAvg = min(100.0, (battingAvg / max(1.0, config.benchmarkBattingAvg)) * 100.0);
    final normSR = min(100.0, (strikeRate / max(1.0, config.benchmarkStrikeRate)) * 100.0);
    final normRPM = min(100.0, (runsPerMatch / max(1.0, config.benchmarkRunsPerMatch)) * 100.0);
    final normBoundary = min(100.0, boundaryPct * 1.5);
    final normConsistency = innings >= 3 ? min(100.0, (fifties * 30.0 + hundreds * 50.0 + (battingAvg > 20 ? 40.0 : 20.0))) : (innings > 0 ? 50.0 : 0.0);

    // Batting Score = 30% Batting Avg + 25% SR + 20% RPM + 10% Boundary + 10% Consistency + 5% Form
    final battingScore = (innings > 0 || totalRuns > 0)
        ? (0.30 * normBatAvg +
           0.25 * normSR +
           0.20 * normRPM +
           0.10 * normBoundary +
           0.10 * normConsistency +
           0.05 * recentBattingForm).clamp(0.0, 100.0)
        : 0.0;

    // 2. Compute Bowling Metrics
    final wktsPerMatch = matches > 0 ? (totalWickets / matches.toDouble()) : 0.0;
    final economy = overs > 0 ? (runsConceded / overs.toDouble()) : 0.0;
    final ballsBowled = overs * 6;
    final bowlingSR = totalWickets > 0 ? (ballsBowled / totalWickets.toDouble()) : 0.0;

    // Bowling normalization: lower economy & lower strike rate are better
    final normWkts = min(100.0, (wktsPerMatch / max(0.5, config.benchmarkWicketsPerMatch)) * 100.0);
    double normEcon = 50.0;
    if (overs > 0) {
      // Scale from worst to ideal economy
      final econRange = max(1.0, config.benchmarkWorstEconomy - config.benchmarkIdealEconomy);
      normEcon = ((config.benchmarkWorstEconomy - economy) / econRange * 100.0).clamp(0.0, 100.0);
    }
    double normBSR = 50.0;
    if (totalWickets > 0) {
      normBSR = max(0.0, 100.0 - (bowlingSR - 10.0) * 3.33).clamp(0.0, 100.0);
    }
    final normDots = overs > 0 ? min(100.0, (dotBalls / (overs * 3.0)) * 100.0) : 50.0;
    final normHauls = min(100.0, (fourWicketHauls * 35.0 + fiveWicketHauls * 60.0 + (totalWickets >= 3 ? 30.0 : 0.0)));

    double recentBowlingForm = 0.0;
    if (recentWickets.isNotEmpty) {
      final rW = recentWickets.reduce((a, b) => a + b) / recentWickets.length;
      recentBowlingForm = min(100.0, (rW / max(0.5, config.benchmarkWicketsPerMatch)) * 100.0);
    }

    // Bowling Score = 30% Wickets + 25% Economy + 20% Bowling SR + 10% Dot Balls + 10% Hauls + 5% Form
    final bowlingScore = (overs > 0 || totalWickets > 0)
        ? (0.30 * normWkts +
           0.25 * normEcon +
           0.20 * normBSR +
           0.10 * normDots +
           0.10 * normHauls +
           0.05 * recentBowlingForm).clamp(0.0, 100.0)
        : 0.0;

    // 3. Compute Fielding Metrics
    final totalDismissals = catches + runOuts + stumpings;
    final catchesPerMatch = matches > 0 ? (catches / matches.toDouble()) : 0.0;
    final normCatches = min(100.0, (catchesPerMatch / 1.0) * 80.0 + (catches >= 2 ? 20.0 : 0.0));
    final normRunOuts = min(100.0, ((runOuts + stumpings) * 30.0));
    final normReliability = totalDismissals > 0 ? min(100.0, totalDismissals * 25.0) : 40.0;

    final fieldingScore = (0.40 * normCatches + 0.35 * normRunOuts + 0.25 * normReliability).clamp(0.0, 100.0);

    // 4. Compute Match Impact
    double impactScore = 50.0; // Baseline
    if (matches > 0) {
      double milestonePts = (fifties * 15.0) + (hundreds * 30.0) + (fourWicketHauls * 20.0) + (fiveWicketHauls * 40.0);
      double winRatio = matchesWon / matches.toDouble();
      impactScore = (40.0 + min(40.0, milestonePts) + (winRatio * 20.0)).clamp(0.0, 100.0);
    }

    // 5. Apply Role-based Weights
    final normalizedRole = playerRole.toUpperCase().trim();
    double compositeScore;

    if (normalizedRole.contains('BAT') || normalizedRole == 'BATSMAN') {
      // Batter: Batting 70%, Fielding 15%, Match Impact 15%
      compositeScore = (0.70 * battingScore) + (0.15 * fieldingScore) + (0.15 * impactScore);
    } else if (normalizedRole.contains('BOWL') || normalizedRole == 'BOWLER') {
      // Bowler: Bowling 70%, Fielding 15%, Match Impact 15%
      compositeScore = (0.70 * bowlingScore) + (0.15 * fieldingScore) + (0.15 * impactScore);
    } else if (normalizedRole.contains('WK') || normalizedRole.contains('KEEPER')) {
      // Wicketkeeper: Batting 45%, Keeping/Fielding 35%, Match Impact 20%
      compositeScore = (0.45 * battingScore) + (0.35 * fieldingScore) + (0.20 * impactScore);
    } else {
      // Default / All-Rounder: Batting 40%, Bowling 40%, Fielding 10%, Match Impact 10%
      compositeScore = (0.40 * battingScore) + (0.40 * bowlingScore) + (0.10 * fieldingScore) + (0.10 * impactScore);
    }

    // Scale to 0 - 1000 and clamp safely
    final overallRating = (compositeScore * 10.0).round().clamp(0, 1000);
    final level = PlayerProRating.getPlayerLevel(overallRating);

    final finalBatRating = battingScore.round().clamp(0, 100);
    final finalBowlRating = bowlingScore.round().clamp(0, 100);
    final finalFieldRating = fieldingScore.round().clamp(0, 100);
    final finalImpactRating = impactScore.round().clamp(0, 100);

    // Evaluate badges
    final badges = PlayerBadgeEngine.evaluateBadges(
      matchType: matchType,
      matches: matches,
      innings: innings,
      totalRuns: totalRuns,
      ballsFaced: ballsFaced,
      battingAvg: battingAvg,
      strikeRate: strikeRate,
      fours: fours,
      sixes: sixes,
      wickets: totalWickets,
      overs: overs,
      economy: economy,
      bowlingStrikeRate: bowlingSR,
      catches: catches,
      runOuts: runOuts,
      stumpings: stumpings,
      battingRating: finalBatRating,
      bowlingRating: finalBowlRating,
      fieldingRating: finalFieldRating,
      matchImpactRating: finalImpactRating,
      recentRuns: recentRuns,
      recentWickets: recentWickets,
    );
    final topBadge = PlayerBadgeEngine.getTopBadge(badges);

    return CalculatedRatingResult(
      overallRating: overallRating,
      level: level,
      battingRating: finalBatRating,
      bowlingRating: finalBowlRating,
      fieldingRating: finalFieldRating,
      matchImpactRating: finalImpactRating,
      badges: badges,
      topBadge: topBadge,
    );
  }
}
