import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_profile.dart';
import '../providers/profile_provider.dart';
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

/// Computes personal CareerStats for a given MatchCategory.
/// All batting stats come from BallEvent rows where batterName == profile.name.
/// All bowling stats come from BallEvent rows where bowlerName == profile.name.
final careerStatsForCategoryProvider =
    FutureProvider.family<CareerStats, MatchCategory>((ref, category) async {
  final db = ref.watch(databaseServiceProvider);
  ref.watch(matchHistoryProvider);

  final UserProfile profile = ref.watch(profileProvider);
  final myName = profile.name.trim().toLowerCase();

  // 1. Get all completed matches filtered by category
  final allMatches = await db.getAllMatches();
  final categoryMatches = allMatches
      .where((m) => m.isCompleted && _isMatchInCategory(m.matchType, m.venue, category))
      .toList();

  if (categoryMatches.isEmpty) return const CareerStats();

  final matchIdSet = categoryMatches.map((m) => m.id).toList();

  // 2. Load all ball events for those matches
  final allBalls = await (db.select(db.ballEvents)
        ..where((b) => b.matchId.isIn(matchIdSet)))
      .get();

  // 3. Separate personal batting / bowling balls
  final myBatBalls = allBalls
      .where((b) =>
          b.batterName.trim().toLowerCase() == myName &&
          (b.extraType ?? '').toLowerCase() != 'wide')
      .toList();

  final myBowlBalls = allBalls
      .where((b) => b.bowlerName.trim().toLowerCase() == myName)
      .toList();

  // 4. Matches where the user actually participated
  final participatedIds = <int>{
    ...myBatBalls.map((b) => b.matchId),
    ...myBowlBalls.map((b) => b.matchId),
  };

  // If no profile name set yet (first launch), fall back to match aggregates
  final bool noProfile = myName.isEmpty || myName == 'scorely user';
  if (noProfile) {
    int tRuns = 0, tWickets = 0, tFours = 0, tSixes = 0, tBalls = 0;
    int tOvers = 0, tConceded = 0;
    for (final m in categoryMatches) {
      tRuns += m.teamARuns + m.teamBRuns;
      tWickets += m.teamAWickets + m.teamBWickets;
      tOvers += m.teamAOvers + m.teamBOvers;
      tConceded += m.teamBRuns;
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
    );
  }

  // ── BATTING ────────────────────────────────────────────────────────────────

  // Group batting balls by match+innings to compute per-innings scores
  final Map<String, List<dynamic>> batInnings = {};
  for (final b in myBatBalls) {
    final key = '${b.matchId}_${b.inningsNumber}';
    batInnings.putIfAbsent(key, () => []).add(b);
  }

  final totalRuns = myBatBalls.fold(0, (s, b) => s + b.runs);
  final ballsFaced = myBatBalls.length;
  final totalFours = myBatBalls.where((b) => b.runs == 4).length;
  final totalSixes = myBatBalls.where((b) => b.runs == 6).length;

  int innings = 0;
  int highScore = 0;
  int fifties = 0;
  int hundreds = 0;
  int ducks = 0;
  final List<double> runsPerMatch = [];
  final List<Map<String, dynamic>> recentInnings = [];

  for (final entry in batInnings.entries) {
    innings++;
    final balls = entry.value;
    final ir = balls.fold<int>(0, (s, b) => s + (b.runs as int));
    final ib = balls.length;
    final ifours = balls.where((b) => b.runs == 4).length;
    final isixes = balls.where((b) => b.runs == 6).length;
    final sr = ib > 0 ? (ir / ib * 100) : 0.0;

    if (ir > highScore) highScore = ir;
    if (ir >= 100) {
      hundreds++;
    } else if (ir >= 50) {
      fifties++;
    }
    if (ir == 0) ducks++;

    runsPerMatch.add(ir.toDouble());
    recentInnings.add({
      'runs': ir,
      'balls': ib,
      'fours': ifours,
      'sixes': isixes,
      'sr': sr,
      'notOut': false,
    });
  }

  // ── BOWLING ────────────────────────────────────────────────────────────────

  bool isBowlerWicket(dynamic b) {
    if (!b.isWicket) return false;
    final wt = (b.wicketType ?? '').toLowerCase();
    return wt != 'run out' && wt != 'stumped';
  }

  final Map<String, List<dynamic>> bowlInnings = {};
  for (final b in myBowlBalls) {
    final key = '${b.matchId}_${b.inningsNumber}';
    bowlInnings.putIfAbsent(key, () => []).add(b);
  }

  final totalWickets = myBowlBalls.where(isBowlerWicket).length;
  final runsConceded = myBowlBalls.fold(0, (s, b) => s + b.runs);
  final legalBowlBalls = myBowlBalls
      .where((b) {
        final et = (b.extraType ?? '').toLowerCase();
        return et != 'wide' && et != 'noball';
      })
      .length;
  final overs = legalBowlBalls ~/ 6;
  final wides = myBowlBalls
      .where((b) => (b.extraType ?? '').toLowerCase() == 'wide')
      .length;
  final noBalls = myBowlBalls
      .where((b) => (b.extraType ?? '').toLowerCase() == 'noball')
      .length;

  int bestWickets = 0;
  int bestConceded = 9999;
  int fourWicketHauls = 0;
  int fiveWicketHauls = 0;
  final List<double> wicketsPerMatch = [];
  final List<Map<String, dynamic>> recentBowling = [];

  for (final entry in bowlInnings.entries) {
    final balls = entry.value;
    final iw = balls.where(isBowlerWicket).length;
    final ir = balls.fold<int>(0, (s, b) => s + (b.runs as int));
    final legalB = balls
        .where((b) {
          final et = (b.extraType ?? '').toLowerCase();
          return et != 'wide' && et != 'noball';
        })
        .length;
    final inningsOvers = legalB ~/ 6;

    if (iw >= 5) {
      fiveWicketHauls++;
    } else if (iw >= 4) {
      fourWicketHauls++;
    }

    if (iw > bestWickets || (iw == bestWickets && ir < bestConceded)) {
      bestWickets = iw;
      bestConceded = ir;
    }

    wicketsPerMatch.add(iw.toDouble());
    recentBowling.add({
      'overs': inningsOvers,
      'maidens': 0,
      'runs': ir,
      'wickets': iw,
    });
  }

  // ── RECENT FORM ────────────────────────────────────────────────────────────
  final matchById = <int, dynamic>{
    for (final m in categoryMatches) m.id: m,
  };
  final recentForm = <String>[];
  for (final id in participatedIds.take(5)) {
    final m = matchById[id];
    if (m == null) continue;
    final won = (m.winnerTeamName as String?) != null &&
        (m.winnerTeamName as String).isNotEmpty;
    // Simple heuristic: if teamA won and player batted for them
    final playerBattedInMatch = myBatBalls.any((b) => b.matchId == id);
    String form;
    if (!won) {
      form = 'D';
    } else if (playerBattedInMatch) {
      form = m.teamARuns > m.teamBRuns ? 'W' : 'L';
    } else {
      form = 'L';
    }
    recentForm.add(form);
  }

  final bestBowling = bestWickets > 0 ? '$bestWickets/$bestConceded' : '-';

  return CareerStats(
    matches: participatedIds.length,
    totalRuns: totalRuns,
    totalWickets: totalWickets,
    catches: 0,
    recentForm: recentForm,
    innings: innings,
    notOuts: 0,
    highScore: highScore,
    fifties: fifties,
    hundreds: hundreds,
    fours: totalFours,
    sixes: totalSixes,
    ballsFaced: ballsFaced,
    ducks: ducks,
    recentInnings: recentInnings.take(5).toList(),
    overs: overs,
    maidens: 0,
    runsConceded: runsConceded,
    wides: wides,
    noBalls: noBalls,
    fourWicketHauls: fourWicketHauls,
    fiveWicketHauls: fiveWicketHauls,
    bestBowling: bestBowling,
    recentBowling: recentBowling.take(5).toList(),
    catchesTaken: 0,
    runOutInvolvements: 0,
    stumpings: 0,
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
