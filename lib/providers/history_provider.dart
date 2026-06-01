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
