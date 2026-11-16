/// Format-aware benchmarks and rating configurations for Turf and Ground cricket.
class RatingBenchmarkConfig {
  final double benchmarkBattingAvg;
  final double benchmarkStrikeRate;
  final double benchmarkRunsPerMatch;
  final double benchmarkWicketsPerMatch;
  final double benchmarkIdealEconomy;
  final double benchmarkWorstEconomy;
  final double benchmarkBowlingStrikeRate;

  // Badge Thresholds
  final double hardHitterMinStrikeRate;
  final double hardHitterMinBoundaryPct;
  final double anchorMinAverage;
  final double economyMasterMaxEconomy;

  const RatingBenchmarkConfig({
    required this.benchmarkBattingAvg,
    required this.benchmarkStrikeRate,
    required this.benchmarkRunsPerMatch,
    required this.benchmarkWicketsPerMatch,
    required this.benchmarkIdealEconomy,
    required this.benchmarkWorstEconomy,
    required this.benchmarkBowlingStrikeRate,
    required this.hardHitterMinStrikeRate,
    required this.hardHitterMinBoundaryPct,
    required this.anchorMinAverage,
    required this.economyMasterMaxEconomy,
  });

  /// Turf matches usually feature higher strike rates, boundaries, and faster pace
  static const turf = RatingBenchmarkConfig(
    benchmarkBattingAvg: 45.0,
    benchmarkStrikeRate: 160.0,
    benchmarkRunsPerMatch: 35.0,
    benchmarkWicketsPerMatch: 2.2,
    benchmarkIdealEconomy: 5.5,
    benchmarkWorstEconomy: 12.0,
    benchmarkBowlingStrikeRate: 14.0,
    hardHitterMinStrikeRate: 150.0,
    hardHitterMinBoundaryPct: 55.0,
    anchorMinAverage: 30.0,
    economyMasterMaxEconomy: 7.0,
  );

  /// Ground matches have bigger boundaries, longer innings, and traditional pacing
  static const ground = RatingBenchmarkConfig(
    benchmarkBattingAvg: 40.0,
    benchmarkStrikeRate: 130.0,
    benchmarkRunsPerMatch: 30.0,
    benchmarkWicketsPerMatch: 2.0,
    benchmarkIdealEconomy: 4.5,
    benchmarkWorstEconomy: 10.0,
    benchmarkBowlingStrikeRate: 18.0,
    hardHitterMinStrikeRate: 130.0,
    hardHitterMinBoundaryPct: 45.0,
    anchorMinAverage: 32.0,
    economyMasterMaxEconomy: 5.8,
  );

  static RatingBenchmarkConfig forMatchType(String matchType) {
    final t = matchType.toLowerCase().trim();
    if (t.contains('turf') || t.contains('box')) {
      return turf;
    }
    return ground;
  }
}
