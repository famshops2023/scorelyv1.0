import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/database.dart';

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
  }
}

/// Last 5 completed matches — for Recent Matches section on Home screen.
final recentMatchesProvider = FutureProvider<List<CricketMatch>>((ref) async {
  final db = ref.watch(databaseServiceProvider);
  final all = await db.getAllMatches();
  return all.where((m) => m.isCompleted).take(5).toList();
});

/// The latest in-progress (live) match — for Live Match section on Home screen.
final liveMatchProvider = FutureProvider<CricketMatch?>((ref) async {
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
  return (teamA, teamB);
});
