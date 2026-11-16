import 'package:drift/drift.dart';

// Conditional import: uses drift_web.dart on web, drift_native.dart elsewhere
import 'drift_native.dart'
    if (dart.library.html) 'drift_web.dart' as db_connect;

part 'database.g.dart';

@DataClassName('CricketMatch')
class Matches extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get matchTitle => text()();
  IntColumn get totalOvers => integer()();
  TextColumn get matchType => text().withDefault(const Constant('T20'))();
  TextColumn get ballType => text().withDefault(const Constant('Leather'))();
  TextColumn get venue => text().withDefault(const Constant('Local Ground'))();
  BoolColumn get isQuickMatch => boolean().withDefault(const Constant(false))();

  IntColumn get teamAId => integer().nullable()();
  IntColumn get teamBId => integer().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  TextColumn get winnerTeamName => text().nullable()();
  IntColumn get currentInnings => integer().withDefault(const Constant(1))();
  /// True when this match has NOT yet been successfully pushed to InsForge.
  BoolColumn get syncPending => boolean().withDefault(const Constant(true))();

  /// InsForge-assigned clean match id (e.g. SM-10001) used to manage matches.
  TextColumn get matchAppId => text().nullable()();

  IntColumn get teamARuns => integer().withDefault(const Constant(0))();
  IntColumn get teamAWickets => integer().withDefault(const Constant(0))();
  IntColumn get teamAOvers => integer().withDefault(const Constant(0))();
  IntColumn get teamABalls => integer().withDefault(const Constant(0))();

  IntColumn get teamBRuns => integer().withDefault(const Constant(0))();
  IntColumn get teamBWickets => integer().withDefault(const Constant(0))();
  IntColumn get teamBOvers => integer().withDefault(const Constant(0))();
  IntColumn get teamBBalls => integer().withDefault(const Constant(0))();
}

@DataClassName('Team')
class Teams extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
}

@DataClassName('Player')
class Players extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  IntColumn get teamId => integer().nullable()();

  IntColumn get runsConceded => integer().withDefault(const Constant(0))();
  IntColumn get wicketsTaken => integer().withDefault(const Constant(0))();
  IntColumn get runsScored => integer().withDefault(const Constant(0))();
  IntColumn get ballsFaced => integer().withDefault(const Constant(0))();
  IntColumn get fours => integer().withDefault(const Constant(0))();
  IntColumn get sixes => integer().withDefault(const Constant(0))();
}

@DataClassName('BallEvent')
class BallEvents extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get matchId => integer()();

  // 1 = first innings, 2 = second innings
  IntColumn get inningsNumber => integer().withDefault(const Constant(1))();

  IntColumn get overNumber => integer().withDefault(const Constant(0))();
  IntColumn get ballNumber => integer().withDefault(const Constant(0))();
  IntColumn get runs => integer().withDefault(const Constant(0))();
  BoolColumn get isWicket => boolean().withDefault(const Constant(false))();
  TextColumn get wicketType => text().nullable()();
  BoolColumn get isExtra => boolean().withDefault(const Constant(false))();
  TextColumn get extraType => text().nullable()();

  // Name stored directly for display (reliable even when player ID is 0)
  TextColumn get batterName => text().withDefault(const Constant(''))();
  TextColumn get bowlerName => text().withDefault(const Constant(''))();

  IntColumn get batterId => integer()();
  IntColumn get bowlerId => integer()();

  DateTimeColumn get timestamp => dateTime().withDefault(currentDateAndTime)();
}

@DriftDatabase(tables: [Matches, Teams, Players, BallEvents])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(db_connect.connect());

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.addColumn(matches, matches.ballType);
        await m.addColumn(matches, matches.venue);
        await m.addColumn(matches, matches.isQuickMatch);
      }
      if (from < 3) {
        await m.addColumn(ballEvents, ballEvents.inningsNumber);
        await m.addColumn(ballEvents, ballEvents.batterName);
        await m.addColumn(ballEvents, ballEvents.bowlerName);
      }
      if (from < 4) {
        await m.addColumn(matches, matches.syncPending);
      }
      if (from < 5) {
        await m.addColumn(matches, matches.matchAppId);
      }
    },
  );

  /// Mark a match as synced (syncPending = false).
  Future<void> markSynced(int matchId) {
    return (update(matches)..where((m) => m.id.equals(matchId)))
        .write(const MatchesCompanion(syncPending: Value(false)));
  }

  /// Store the InsForge-assigned clean match id (e.g. SM-10001) on a local match.
  /// Only assigns when [matchAppId] is not already set, so the id stays stable.
  Future<void> markMatchAppId(int matchId, String matchAppId) async {
    final match = await (select(matches)..where((m) => m.id.equals(matchId))).getSingleOrNull();
    if (match == null || match.matchAppId != null) return;
    await (update(matches)..where((m) => m.id.equals(matchId)))
        .write(MatchesCompanion(matchAppId: Value(matchAppId)));
  }

  /// Returns the next sequential match app id (SM-10001, SM-10002, ...) based on
  /// existing match_app_id values in the local matches table. The first match
  /// always starts at SM-10001 and increments by 1 for every new match,
  /// regardless of team, player, scorer, or creator.
  Future<String> nextMatchAppId() async {
    final all = await (select(matches)).get();
    int max = 10000; // base so the first match becomes SM-10001
    for (final m in all) {
      final id = m.matchAppId;
      if (id != null && id.startsWith('SM-')) {
        final n = int.tryParse(id.substring(3));
        if (n != null && n > max) max = n;
      }
    }
    return 'SM-${max + 1}';
  }

  /// Look up a local match by its InsForge-assigned [matchAppId] (e.g. SM-10001).
  /// Returns null if no such match exists or its matchAppId is null.
  Future<CricketMatch?> getMatchByMatchAppId(String matchAppId) async {
    return (select(matches)..where((m) => m.matchAppId.equals(matchAppId)))
        .getSingleOrNull();
  }

  /// Find an existing live (not completed) match with the given team names.
  /// Used to detect duplicates before creating a new live match at toss time.
  /// matchTitle is stored as "Team A vs Team B", so we check both orderings.
  Future<List<CricketMatch>> getLiveMatchByTeams(
      String teamAName, String teamBName) async {
    return (select(matches)
          ..where((m) =>
              m.isCompleted.equals(false) &
              ((m.matchTitle.contains(teamAName) & m.matchTitle.contains(teamBName)) |
                  (m.matchTitle.contains(teamBName) & m.matchTitle.contains(teamAName)))))
        .get();
  }

  /// Get all completed matches that still need to be pushed to InsForge.
  Future<List<CricketMatch>> getPendingSyncMatches() {
    return (select(matches)
          ..where((m) => m.isCompleted & m.syncPending))
        .get();
  }

  Future<List<CricketMatch>> getAllMatches() {
    return (select(matches)
          ..orderBy([
            (t) => OrderingTerm.desc(t.createdAt),
            (t) => OrderingTerm.desc(t.id),
          ]))
        .get();
  }

  Future<int> insertMatch(MatchesCompanion match) =>
      into(matches).insert(match);

  Future<void> deleteMatchById(int id) async {
    await (delete(matches)..where((m) => m.id.equals(id))).go();
    await (delete(ballEvents)..where((b) => b.matchId.equals(id))).go();
  }

  /// Prunes completed matches to keep only the most recent [limit] matches (FIFO).
  /// Associated ball events are removed to free local storage. Active in-progress matches are preserved.
  Future<int> pruneMatchesToLimit(int limit) async {
    if (limit <= 0) return 0;
    final completed = await (select(matches)
          ..where((m) => m.isCompleted)
          ..orderBy([
            (t) => OrderingTerm.desc(t.createdAt),
            (t) => OrderingTerm.desc(t.id),
          ]))
        .get();

    if (completed.length > limit) {
      final toDelete = completed.sublist(limit);
      final idsToDelete = toDelete.map((m) => m.id).toList();

      await (delete(ballEvents)..where((b) => b.matchId.isIn(idsToDelete))).go();
      await (delete(matches)..where((m) => m.id.isIn(idsToDelete))).go();
      return idsToDelete.length;
    }
    return 0;
  }
}

// Singleton pattern
class DatabaseService {
  static final AppDatabase instance = AppDatabase();
}
