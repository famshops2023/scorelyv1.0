import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_profile.dart';
import '../providers/profile_provider.dart';
import '../services/insforge_stats_service.dart';
import 'history_provider.dart';

/// Performance match category for filtering career stats
enum MatchCategory {
  turfBox,
  ground,
}

/// Aggregated career stats computed from match data
class CareerStats {
  // Overview
  final int matches;
  final int totalRuns;
  final int totalWickets;
  final int catches;
  final List<String> recentForm; // 'W' or 'L'

  // Batting
  final int innings;
  final int notOuts;
  final int highScore;
  final int fifties;
  final int hundreds;
  final int fours;
  final int sixes;
  final int ballsFaced;
  final int ducks;
  final List<Map<String, dynamic>> recentInnings;

  // Bowling
  final int overs;
  final int maidens;
  final int runsConceded;
  final int wides;
  final int noBalls;
  final int fourWicketHauls;
  final int fiveWicketHauls;
  final String bestBowling;
  final List<Map<String, dynamic>> recentBowling;

  // Fielding
  final int catchesTaken;
  final int runOutInvolvements;
  final int stumpings;

  // Derived
  double get battingAvg => innings > notOuts ? totalRuns / (innings - notOuts) : totalRuns.toDouble();
  double get strikeRate => ballsFaced > 0 ? (totalRuns / ballsFaced) * 100 : 0;
  double get economy => overs > 0 ? runsConceded / overs : 0;
  double get bowlingAvg => totalWickets > 0 ? runsConceded / totalWickets : 0;
  double get boundaryPct => ballsFaced > 0 ? ((fours * 4 + sixes * 6) / totalRuns) * 100 : 0;

  // Chart data
  final List<double> runsPerMatch;
  final List<double> wicketsPerMatch;

  const CareerStats({
    this.matches = 0,
    this.totalRuns = 0,
    this.totalWickets = 0,
    this.catches = 0,
    this.recentForm = const [],
    this.innings = 0,
    this.notOuts = 0,
    this.highScore = 0,
    this.fifties = 0,
    this.hundreds = 0,
    this.fours = 0,
    this.sixes = 0,
    this.ballsFaced = 0,
    this.ducks = 0,
    this.recentInnings = const [],
    this.overs = 0,
    this.maidens = 0,
    this.runsConceded = 0,
    this.wides = 0,
    this.noBalls = 0,
    this.fourWicketHauls = 0,
    this.fiveWicketHauls = 0,
    this.bestBowling = '-',
    this.recentBowling = const [],
    this.catchesTaken = 0,
    this.runOutInvolvements = 0,
    this.stumpings = 0,
    this.runsPerMatch = const [],
    this.wicketsPerMatch = const [],
  });
}

class PerformanceCategoryNotifier extends Notifier<MatchCategory> {
  @override
  MatchCategory build() => MatchCategory.turfBox;

  void selectCategory(MatchCategory category) => state = category;
  set category(MatchCategory category) => state = category;
}

/// The currently selected match category on the Performance screen
final performanceCategoryProvider =
    NotifierProvider<PerformanceCategoryNotifier, MatchCategory>(
  PerformanceCategoryNotifier.new,
);

bool _isMatchInCategory(String matchType, String venue, MatchCategory category) {
  final t = matchType.toLowerCase().trim();
  final v = venue.toLowerCase().trim();
  final isTurf = t == 'box/turf' ||
      t.contains('turf') ||
      t.contains('box') ||
      v.contains('turf') ||
      v.contains('box');
  return category == MatchCategory.turfBox ? isTurf : !isTurf;
}

/// Sourced from InsForge ONLY for signed in players;
/// sourced from local DB as total scores of the match for unauthorized players.
final careerStatsForCategoryProvider =
    FutureProvider.family<CareerStats, MatchCategory>((ref, category) async {
  final UserProfile profile = ref.watch(profileProvider);

  if (profile.isLoggedIn && profile.id.isNotEmpty) {
    // SIGNED IN PLAYER: Details come from InsForge ONLY
    return await InsforgeStatsService.fetchCareerStats(
      profile.id,
      profile.name,
      category,
    );
  }

  // UNAUTHORIZED PLAYER: Sourced from local DB as "total scores of the Match"
  final db = ref.watch(databaseServiceProvider);
  ref.watch(matchHistoryProvider);
  final limit = ref.watch(storageLimitProvider);

  // 1. Get all completed matches filtered by category and scoped by storage limit
  final allMatches = await db.getAllMatches();
  final scopedMatches = allMatches.take(limit).toList();
  final categoryMatches = scopedMatches
      .where((m) =>
          m.isCompleted &&
          !(m.winnerTeamName?.toLowerCase().contains('abandon') ?? false) &&
          _isMatchInCategory(m.matchType, m.venue, category))
      .toList();

  if (categoryMatches.isEmpty) return const CareerStats();

  int tRuns = 0, tWickets = 0, tFours = 0, tSixes = 0, tBalls = 0;
  int tOvers = 0, tConceded = 0;
  final List<double> runsPerMatch = [];
  final List<double> wicketsPerMatch = [];

  for (final m in categoryMatches) {
    final mRuns = m.teamARuns + m.teamBRuns;
    final mWkts = m.teamAWickets + m.teamBWickets;
    tRuns += mRuns;
    tWickets += mWkts;
    tOvers += m.teamAOvers + m.teamBOvers;
    tConceded += m.teamBRuns;
    runsPerMatch.add(mRuns.toDouble());
    wicketsPerMatch.add(mWkts.toDouble());
  }

  return CareerStats(
    matches: categoryMatches.length,
    totalRuns: tRuns,
    totalWickets: tWickets,
    fours: tFours,
    sixes: tSixes,
    ballsFaced: tBalls,
    overs: tOvers,
    runsConceded: tConceded,
    runsPerMatch: runsPerMatch,
    wicketsPerMatch: wicketsPerMatch,
  );
});

/// Default career stats provider that dynamically resolves to the selected category
final careerStatsProvider = FutureProvider<CareerStats>((ref) async {
  final category = ref.watch(performanceCategoryProvider);
  return ref.watch(careerStatsForCategoryProvider(category).future);
});

/// Match count summary for Turf/Box vs Ground matches
final matchCategoryCountsProvider = FutureProvider<Map<MatchCategory, int>>((ref) async {
  final turfStats = await ref.watch(careerStatsForCategoryProvider(MatchCategory.turfBox).future);
  final groundStats = await ref.watch(careerStatsForCategoryProvider(MatchCategory.ground).future);
  return {
    MatchCategory.turfBox: turfStats.matches,
    MatchCategory.ground: groundStats.matches,
  };
});
