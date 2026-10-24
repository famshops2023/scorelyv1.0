import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/database.dart';
import '../models/user_profile.dart';
import '../providers/profile_provider.dart';

final databaseServiceProvider = Provider<AppDatabase>((ref) {
  return DatabaseService.instance;
});

final matchHistoryProvider = NotifierProvider<MatchHistoryNotifier, List<CricketMatch>>(
  MatchHistoryNotifier.new,
);

class MatchHistoryNotifier extends Notifier<List<CricketMatch>> {
  late AppDatabase _db;

  @override
  List<CricketMatch> build() {
    _db = ref.watch(databaseServiceProvider);
    loadMatches();
    return [];
  }

  Future<void> loadMatches() async {
    state = await _db.getAllMatches();
  }

  Future<void> deleteMatch(int id) async {
    await _db.deleteMatchById(id);
    await loadMatches();
    ref.invalidate(recentMatchesProvider);
    ref.invalidate(liveMatchProvider);
  }

  Future<void> clearAllMatches() async {
    await _db.delete(_db.matches).go();
    await _db.delete(_db.ballEvents).go();
    await loadMatches();
    ref.invalidate(recentMatchesProvider);
    ref.invalidate(liveMatchProvider);
  }
}

/// Last 5 completed matches — for Recent Matches section on Home screen.
final recentMatchesProvider = FutureProvider<List<CricketMatch>>((ref) async {
  final history = ref.watch(matchHistoryProvider);
  if (history.isNotEmpty) {
    return history.where((m) => m.isCompleted).take(5).toList();
  }
  final db = ref.watch(databaseServiceProvider);
  final all = await db.getAllMatches();
  return all.where((m) => m.isCompleted).take(5).toList();
});

/// The latest in-progress (live) match — for Live Match section on Home screen.
final liveMatchProvider = FutureProvider<CricketMatch?>((ref) async {
  final history = ref.watch(matchHistoryProvider);
  if (history.isNotEmpty) {
    try {
      return history.firstWhere((m) => !m.isCompleted);
    } catch (_) {
      return null;
    }
  }
  final db = ref.watch(databaseServiceProvider);
  final all = await db.getAllMatches();
  try {
    return all.firstWhere((m) => !m.isCompleted);
  } catch (_) {
    return null;
  }
});

/// Team name lookup helper — fetches both team names for a given match.
final matchTeamNamesProvider =
    FutureProvider.family<(String, String), CricketMatch>((ref, match) async {
  final db = ref.watch(databaseServiceProvider);
  String teamA = 'Team A';
  String teamB = 'Team B';
  if (match.teamAId != null) {
    final t = await (db.select(db.teams)
          ..where((r) => r.id.equals(match.teamAId!)))
        .getSingleOrNull();
    if (t != null) teamA = t.name;
  }
  if (match.teamBId != null) {
    final t = await (db.select(db.teams)
          ..where((r) => r.id.equals(match.teamBId!)))
        .getSingleOrNull();
    if (t != null) teamB = t.name;
  }
  if (teamA == 'Team A' && teamB == 'Team B' && match.matchTitle.contains(' vs ')) {
    final parts = match.matchTitle.split(' vs ');
    if (parts.isNotEmpty) teamA = parts[0].trim();
    if (parts.length > 1) teamB = parts[1].trim();
  }
  return (teamA, teamB);
});

/// Count of completed matches not yet pushed to InsForge.
/// Watched by the History screen to show a "Sync Pending" badge.
final pendingSyncCountProvider = FutureProvider<int>((ref) async {
  final db = ref.watch(databaseServiceProvider);
  final pending = await db.getPendingSyncMatches();
  return pending.length;
});

// ─────────────────── Personal Home Stats ─────────────────────────────────────

/// Aggregated personal stats for the Home screen stats section.
/// Splits the current user's batting runs + bowling wickets by match category.
class HomePersonalStats {
  final int turfMatches;
  final int turfRuns;
  final int turfWickets;

  final int groundMatches;
  final int groundRuns;
  final int groundWickets;

  const HomePersonalStats({
    this.turfMatches = 0,
    this.turfRuns = 0,
    this.turfWickets = 0,
    this.groundMatches = 0,
    this.groundRuns = 0,
    this.groundWickets = 0,
  });
}

bool _isTurfMatch(String matchType, String venue) {
  final t = matchType.toLowerCase().trim();
  final v = venue.toLowerCase().trim();
  return t == 'box/turf' ||
      t.contains('turf') ||
      t.contains('box') ||
      v.contains('turf') ||
      v.contains('box');
}

/// Watches the current profile and all ball events to compute personal stats.
/// Runs are counted only for balls where the user was the batter (batterName).
/// Wickets are counted only for balls where the user was the bowler (bowlerName).
final homePersonalStatsProvider = FutureProvider<HomePersonalStats>((ref) async {
  final db = ref.watch(databaseServiceProvider);
  // Re-compute whenever match history changes
  ref.watch(matchHistoryProvider);

  final UserProfile profile = ref.watch(profileProvider);
  final myName = profile.name.trim().toLowerCase();

  // Empty name guard — no profile set up yet
  if (myName.isEmpty || myName == 'scorely user') {
    // Fall back to match-aggregate totals so something is shown
    final allMatches = await db.getAllMatches();
    final completed = allMatches.where((m) => m.isCompleted);

    int tM = 0, tR = 0, tW = 0, gM = 0, gR = 0, gW = 0;
    for (final m in completed) {
      if (_isTurfMatch(m.matchType, m.venue)) {
        tM++;
        tR += m.teamARuns + m.teamBRuns;
        tW += m.teamAWickets + m.teamBWickets;
      } else {
        gM++;
        gR += m.teamARuns + m.teamBRuns;
        gW += m.teamAWickets + m.teamBWickets;
      }
    }
    return HomePersonalStats(
      turfMatches: tM, turfRuns: tR, turfWickets: tW,
      groundMatches: gM, groundRuns: gR, groundWickets: gW,
    );
  }

  // Load all completed matches — keyed by id
  final allMatches = await db.getAllMatches();
  final completedById = <int, CricketMatch>{
    for (final m in allMatches.where((m) => m.isCompleted)) m.id: m,
  };

  if (completedById.isEmpty) return const HomePersonalStats();

  // Load all ball events for completed matches
  final allBalls = await (db.select(db.ballEvents)
        ..where((b) => b.matchId.isIn(completedById.keys.toList())))
      .get();

  // Track which matches the user actually participated in (to count match-count)
  final Set<int> turfMatchIds = {};
  final Set<int> groundMatchIds = {};

  int turfRuns = 0, turfWickets = 0;
  int groundRuns = 0, groundWickets = 0;

  for (final ball in allBalls) {
    final match = completedById[ball.matchId];
    if (match == null) continue;

    final isT = _isTurfMatch(match.matchType, match.venue);
    final bName = ball.batterName.trim().toLowerCase();
    final boName = ball.bowlerName.trim().toLowerCase();

    // Count batting runs (exclude wides — batter didn't hit those)
    final isWide = (ball.extraType ?? '').toLowerCase() == 'wide';
    if (bName == myName && !isWide) {
      final r = ball.runs;
      if (isT) {
        turfRuns += r;
        turfMatchIds.add(ball.matchId);
      } else {
        groundRuns += r;
        groundMatchIds.add(ball.matchId);
      }
    }

    // Count bowling wickets (stumpings/run-outs credited to fielder, not bowler)
    if (boName == myName && ball.isWicket) {
      final wType = (ball.wicketType ?? '').toLowerCase();
      final bowlerWicket = wType != 'run out' && wType != 'stumped';
      if (bowlerWicket) {
        if (isT) {
          turfWickets++;
          turfMatchIds.add(ball.matchId);
        } else {
          groundWickets++;
          groundMatchIds.add(ball.matchId);
        }
      }
    }
  }

  return HomePersonalStats(
    turfMatches: turfMatchIds.length,
    turfRuns: turfRuns,
    turfWickets: turfWickets,
    groundMatches: groundMatchIds.length,
    groundRuns: groundRuns,
    groundWickets: groundWickets,
  );
});
