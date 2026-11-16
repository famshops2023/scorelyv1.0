import '../../core/config/rating_benchmark_config.dart';

/// Evaluates player achievements and awards special skill badges based on authoritative statistics.
class PlayerBadgeEngine {
  /// Evaluates eligible badges for a player based on stats and component ratings
  static List<String> evaluateBadges({
    required String matchType,
    required int matches,
    required int innings,
    required int totalRuns,
    required int ballsFaced,
    required double battingAvg,
    required double strikeRate,
    required int fours,
    required int sixes,
    required int wickets,
    required int overs,
    required double economy,
    required double bowlingStrikeRate,
    required int catches,
    required int runOuts,
    required int stumpings,
    required int battingRating,
    required int bowlingRating,
    required int fieldingRating,
    required int matchImpactRating,
    required List<double> recentRuns,
    required List<double> recentWickets,
  }) {
    final List<String> badges = [];
    final config = RatingBenchmarkConfig.forMatchType(matchType);

    // If no matches, no badges
    if (matches <= 0) return badges;

    final boundaryRuns = (fours * 4) + (sixes * 6);
    final boundaryPct = totalRuns > 0 ? (boundaryRuns / totalRuns) * 100 : 0.0;
    final wktsPerMatch = matches > 0 ? wickets / matches.toDouble() : 0.0;

    // 1. 💥 HARD HITTER
    // Requires at least 3 innings (or matches), high strike rate, and strong boundary percentage
    final minInnings = matches >= 3 ? 3 : 1;
    if (innings >= minInnings &&
        strikeRate >= config.hardHitterMinStrikeRate &&
        boundaryPct >= config.hardHitterMinBoundaryPct) {
      badges.add('💥 Hard Hitter');
    }

    // 2. 🎯 WICKET TAKER
    // Requires strong wickets-per-match or bowling strike rate
    if (matches >= 2 && wickets >= 3 && (wktsPerMatch >= 1.2 || (bowlingStrikeRate > 0 && bowlingStrikeRate <= config.benchmarkBowlingStrikeRate))) {
      badges.add('🎯 Wicket Taker');
    }

    // 3. 🧱 ANCHOR
    // High batting average and reliability
    if (innings >= minInnings && battingAvg >= config.anchorMinAverage && totalRuns >= 50) {
      badges.add('🧱 Anchor');
    }

    // 4. 🎩 ALL-ROUNDER
    // Strong batting AND bowling rating
    if (battingRating >= 55 && bowlingRating >= 50) {
      badges.add('🎩 All-Rounder');
    }

    // 5. 🧤 SAFE HANDS
    // Good catching / fielding record
    final totalDismissals = catches + runOuts + stumpings;
    if (totalDismissals >= 3 || (matches >= 2 && totalDismissals / matches.toDouble() >= 0.8)) {
      badges.add('🧤 Safe Hands');
    }

    // 6. 🎯 ECONOMY MASTER
    // Strong bowling economy relative to match format
    if (overs >= 4 && economy > 0 && economy <= config.economyMasterMaxEconomy) {
      badges.add('🎯 Economy Master');
    }

    // 7. 🔥 MATCH WINNER
    // High match impact rating
    if (matchImpactRating >= 75 && matches >= 3) {
      badges.add('🔥 Match Winner');
    }

    // 8. 👑 CONSISTENT PERFORMER
    // At least 4 matches with low volatility across recent innings
    if (matches >= 4 && recentRuns.length >= 3) {
      final avg = recentRuns.reduce((a, b) => a + b) / recentRuns.length;
      if (avg >= 20.0) {
        badges.add('👑 Consistent Performer');
      }
    }

    // 9. ⚡ FINISHER
    // Extensible logic for high strike-rate innings
    if (innings >= 2 && strikeRate >= 165.0 && sixes >= 2) {
      badges.add('⚡ Finisher');
    }

    // 10. 🚀 RISING STAR
    // Recent form noticeably exceeds earlier performance
    if (matches >= 3 && recentRuns.length >= 2) {
      final recentAvg = recentRuns.reduce((a, b) => a + b) / recentRuns.length;
      final overallAvg = matches > 0 ? totalRuns / matches.toDouble() : 0.0;
      if (recentAvg >= overallAvg * 1.25 && recentAvg >= 25.0) {
        badges.add('🚀 Rising Star');
      }
    }

    return badges;
  }

  /// Selects the primary / top badge to display on compact cards
  static String? getTopBadge(List<String> badges) {
    if (badges.isEmpty) return null;
    // Priority order for badges
    const priority = [
      '🔥 Match Winner',
      '💥 Hard Hitter',
      '🎩 All-Rounder',
      '🎯 Wicket Taker',
      '👑 Consistent Performer',
      '🧱 Anchor',
      '🎯 Economy Master',
      '⚡ Finisher',
      '🧤 Safe Hands',
      '🚀 Rising Star',
    ];
    for (var p in priority) {
      if (badges.contains(p)) return p;
    }
    return badges.first;
  }
}
