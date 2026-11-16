import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/database.dart';
import '../models/user_profile.dart';
import '../providers/profile_provider.dart';
import '../services/insforge_stats_service.dart';

import '../features/match/providers/quick_match_storage.dart';

final databaseServiceProvider = Provider<AppDatabase>((ref) {
  return DatabaseService.instance;
});

/// Storage Limit Notifier:
/// - 5 matches max if guest / not logged in
/// - settings_storage_limit (default 5, up to 50: 5/10/20/50) if logged in
class StorageLimitNotifier extends Notifier<int> {
  @override
  int build() {
    final profile = ref.watch(profileProvider);
    if (!profile.isLoggedIn) {
      _ensureGuestLimitPruned();
      return 5;
    }
    _loadFromPrefs();
    return 5;
  }

  Future<void> _ensureGuestLimitPruned() async {
    await DatabaseService.instance.pruneMatchesToLimit(5);
    await QuickMatchStorage.pruneToLimit(5);
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final limit = prefs.getInt('settings_storage_limit') ?? 5;
    if (state != limit) {
      state = limit;
      await DatabaseService.instance.pruneMatchesToLimit(limit);
      await QuickMatchStorage.pruneToLimit(limit);
    }
  }

  Future<void> updateLimit(int newLimit) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('settings_storage_limit', newLimit);
    state = newLimit;
    await DatabaseService.instance.pruneMatchesToLimit(newLimit);
    await QuickMatchStorage.pruneToLimit(newLimit);
    await ref.read(matchHistoryProvider.notifier).loadMatches();
    ref.invalidate(homePersonalStatsProvider);
    ref.invalidate(recentMatchesProvider);
    ref.invalidate(liveMatchProvider);
    ref.invalidate(pendingSyncCountProvider);
  }
}

final storageLimitProvider = NotifierProvider<StorageLimitNotifier, int>(
  StorageLimitNotifier.new,
);

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
    final limit = ref.read(storageLimitProvider);
    await _db.pruneMatchesToLimit(limit);
    state = await _db.getAllMatches();
  }

  Future<void> deleteMatch(int id) async {
    await _db.deleteMatchById(id);
    await loadMatches();
    ref.invalidate(recentMatchesProvider);
    ref.invalidate(liveMatchProvider);
    ref.invalidate(homePersonalStatsProvider);
  }

  Future<void> clearAllMatches() async {
    await _db.delete(_db.matches).go();
    await _db.delete(_db.ballEvents).go();
    await loadMatches();
    ref.invalidate(recentMatchesProvider);
    ref.invalidate(liveMatchProvider);
    ref.invalidate(homePersonalStatsProvider);
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

/// Sourced from InsForge ONLY for signed in players;
/// sourced from local DB as total scores of the match for unauthorized players.
final homePersonalStatsProvider = FutureProvider<HomePersonalStats>((ref) async {
  final UserProfile profile = ref.watch(profileProvider);

  if (profile.isLoggedIn && profile.id.isNotEmpty) {
    // SIGNED IN PLAYER: Details come from InsForge ONLY
    return await InsforgeStatsService.fetchHomeStats(profile.id, profile.name);
  }

  // UNAUTHORIZED PLAYER: Sourced from local DB as "total scores of the Match"
  final db = ref.watch(databaseServiceProvider);
  ref.watch(matchHistoryProvider);
  final limit = ref.watch(storageLimitProvider);

  final allMatches = await db.getAllMatches();
  final scopedMatches = allMatches.take(limit).toList();
  // Exclude abandoned matches from Home Personal Stats
  final completedMatches = scopedMatches
      .where((m) =>
          m.isCompleted &&
          !(m.winnerTeamName?.toLowerCase().contains('abandon') ?? false))
      .toList();

  if (completedMatches.isEmpty) return const HomePersonalStats();

  int tM = 0, tR = 0, tW = 0, gM = 0, gR = 0, gW = 0;
  for (final m in completedMatches) {
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
    turfMatches: tM,
    turfRuns: tR,
    turfWickets: tW,
    groundMatches: gM,
    groundRuns: gR,
    groundWickets: gW,
  );
});

/// Profile Scorer Performance:
/// Sourced from InsForge ONLY for signed in players;
/// sourced from local DB as total scores of the match for unauthorized players.
final profileScorerStatsProvider = FutureProvider<InsforgeScorerStats>((ref) async {
  final UserProfile profile = ref.watch(profileProvider);

  if (profile.isLoggedIn && profile.id.isNotEmpty) {
    // SIGNED IN PLAYER: Details come from InsForge ONLY
    return await InsforgeStatsService.fetchScorerStats(profile.id);
  }

  // UNAUTHORIZED PLAYER: Sourced from local DB "total scores of the Match"
  final history = ref.watch(matchHistoryProvider);
  int totalMatches = 0;
  int totalRunsScored = 0;
  int totalWicketsTaken = 0;
  int thisMonthRuns = 0;
  int thisMonthWickets = 0;

  final now = DateTime.now();
  for (var match in history) {
    // Exclude abandoned matches from Scorer Stats
    if (match.isCompleted &&
        !(match.winnerTeamName?.toLowerCase().contains('abandon') ?? false)) {
      totalMatches++;
      final matchRuns = match.teamARuns + match.teamBRuns;
      final matchWkts = match.teamAWickets + match.teamBWickets;
      totalRunsScored += matchRuns;
      totalWicketsTaken += matchWkts;

      if (match.createdAt.year == now.year && match.createdAt.month == now.month) {
        thisMonthRuns += matchRuns;
        thisMonthWickets += matchWkts;
      }
    }
  }

  return InsforgeScorerStats(
    totalMatches: totalMatches,
    totalRunsScored: totalRunsScored,
    totalWicketsTaken: totalWicketsTaken,
    thisMonthRuns: thisMonthRuns,
    thisMonthWickets: thisMonthWickets,
  );
});


