import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'database.dart';
import 'insforge_sync_service.dart';

/// Global provider exposing the [SyncManager] singleton.
final syncManagerProvider = Provider<SyncManager>((ref) {
  final db = DatabaseService.instance;
  final manager = SyncManager(db);
  ref.onDispose(manager.dispose);
  return manager;
});

/// Watches connectivity and retries pending match syncs whenever the
/// device comes back online.
class SyncManager {
  final AppDatabase _db;
  StreamSubscription<List<ConnectivityResult>>? _sub;
  bool _isSyncing = false;

  SyncManager(this._db) {
    _sub = Connectivity().onConnectivityChanged.listen(_onConnectivityChanged);
    // Also try on startup in case we already have connectivity
    _trySync();
  }

  void dispose() {
    _sub?.cancel();
  }

  void _onConnectivityChanged(List<ConnectivityResult> results) {
    final isOnline = results.any((r) => r != ConnectivityResult.none);
    if (isOnline) {
      debugPrint('SyncManager: connectivity restored — retrying pending syncs.');
      _trySync();
    }
  }

  Future<void> _trySync() async {
    if (_isSyncing) return;
    _isSyncing = true;
    try {
      final pending = await _db.getPendingSyncMatches();
      if (pending.isEmpty) {
        debugPrint('SyncManager: no pending matches to sync.');
        return;
      }
      debugPrint('SyncManager: syncing ${pending.length} pending match(es).');
      for (final match in pending) {
        final ok = await InsforgeSyncService.trySyncMatch(_db, match.id, '');
        if (ok) {
          await _db.markSynced(match.id);
          debugPrint('SyncManager: match ${match.id} synced successfully.');
        } else {
          debugPrint('SyncManager: match ${match.id} sync failed — will retry later.');
        }
      }
    } catch (e) {
      debugPrint('SyncManager._trySync error: $e');
    } finally {
      _isSyncing = false;
    }
  }

  /// Call after saving a new completed match so we attempt an immediate sync.
  Future<void> onMatchCompleted(int localMatchId) async {
    _trySync();
  }
}
