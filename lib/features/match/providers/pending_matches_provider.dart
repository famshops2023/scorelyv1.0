import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../../../core/config/insforge_config.dart';
import '../../../models/match_status.dart';
import '../../../services/match_lifecycle_service.dart';
import '../match_setup_screen.dart';
import 'quick_match_storage.dart';
import '../../../providers/profile_provider.dart';

class PendingMatchesNotifier extends Notifier<List<MatchSetupData>> {
  static const _key = 'pending_matches_v1';

  static String get _url => '${InsforgeConfig.recordsUrl}/pending_matches';
  static Map<String, String> get _headers => InsforgeConfig.headers;

  /// Returns the current time as an ISO-8601 string with the Indian Standard
  /// Time offset (+05:30).  Optionally accepts a base [dt].
  static String _istNow([DateTime? dt]) {
    final utc = (dt ?? DateTime.now()).toUtc();
    final ist = utc.add(const Duration(hours: 5, minutes: 30));
    final base = ist.toIso8601String();
    final withoutZ = base.endsWith('Z') ? base.substring(0, base.length - 1) : base;
    return '$withoutZ+05:30';
  }

  @override
  List<MatchSetupData> build() {
    _loadFromPrefs();
    _fetchFromInsForge();
    return [];
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_key);
    final matches = <MatchSetupData>[];
    if (jsonStr != null) {
      final List<dynamic> jsonList = jsonDecode(jsonStr);
      matches.addAll(jsonList
          .map((e) => MatchSetupData.fromJson(e))
          // Completed or abandoned matches belong in Recent Matches, not in this list.
          .where((m) => !m.isCompleted && !m.isAbandoned));
    }

    // Include locally stored guest quick matches in the Pending section (Point 15 Q15)
    final quickMatches = await QuickMatchStorage.getAllMatches();
    for (final qm in quickMatches) {
      if (qm.isPending &&
          !matches.any((m) =>
              (m.id.isNotEmpty && m.id == qm.id) ||
              (qm.creationRequestId != null &&
                  qm.creationRequestId!.isNotEmpty &&
                  m.creationRequestId == qm.creationRequestId))) {
        matches.add(qm);
      }
    }
    state = matches;
  }

  Future<void> _saveToPrefs(List<MatchSetupData> matches) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = matches.map((m) => m.toJson()).toList();
    await prefs.setString(_key, jsonEncode(jsonList));
  }

  /// Builds the association filter so pending matches are only visible to:
  /// creator, active scorer, or a signed-in player in either squad.
  String _associationFilter(String profileId) =>
      '(created_by_profile_id.eq.$profileId,'
      'active_scorer_id.eq.$profileId,'
      'player_profile_ids.cs.["$profileId"])';

  Future<void> _fetchFromInsForge() async {
    final profile = ref.read(profileProvider);
    if (!profile.isLoggedIn) return;
    final profileId = profile.id;
    if (profileId.isEmpty) return;

    try {
      final uri = Uri.parse(_url).replace(queryParameters: {
        'or': _associationFilter(profileId),
        'status': 'in.(pending,live)',
        'select': '*',
      });
      var res = await http.get(uri, headers: _headers);

      if (res.statusCode != 200) {
        // Older databases may not have the association columns yet. Fall back
        // to the previous owner/live query so the app keeps working.
        final fallback = Uri.parse(_url).replace(queryParameters: {
          'or': '(created_by_profile_id.eq.$profileId,status.eq.live)',
          'status': 'in.(pending,live)',
          'select': '*',
        });
        res = await http.get(fallback, headers: _headers);
      }

      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        final matches = data
            .whereType<Map>()
            .map((raw) => _fromRow(Map<String, dynamic>.from(raw)))
            .whereType<MatchSetupData>()
            .where((m) => !m.isCompleted)
            .toList();

        state = matches;
        await _saveToPrefs(matches);
      }
    } catch (e) {
      // If API fails (e.g. offline), fall back to the local prefs state.
      debugPrint('InsForge sync failed: $e');
    }
  }

  /// Converts a `pending_matches` row into [MatchSetupData], overlaying the
  /// authoritative lifecycle columns over the embedded match JSON.
  MatchSetupData? _fromRow(Map<String, dynamic> row) {
    try {
      final raw = row['match_data'];
      Map<String, dynamic> jsonMap;
      if (raw is Map) {
        jsonMap = Map<String, dynamic>.from(raw);
      } else if (raw is String && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is! Map) return null;
        jsonMap = Map<String, dynamic>.from(decoded);
      } else {
        jsonMap = <String, dynamic>{};
      }

      final rowId = row['id']?.toString();
      if (rowId != null && rowId.isNotEmpty) jsonMap['id'] = rowId;

      final creationReqId = row['creation_request_id']?.toString();
      if (creationReqId != null && creationReqId.isNotEmpty) {
        jsonMap['creationRequestId'] = creationReqId;
      }
      // Preserve the squad sub-state for legacy rows whose embedded status
      // still carries it before the lifecycle status is overlaid.
      final embeddedStatus = jsonMap['status']?.toString().toLowerCase();
      if (jsonMap['setupStage'] == null &&
          (embeddedStatus == 'waiting_for_team_b' ||
              embeddedStatus == 'waiting_for_squad')) {
        jsonMap['setupStage'] = MatchSetupStage.squadSelection;
      }
      jsonMap['status'] = MatchStatus.normalize(row['status']?.toString());
      final creator = row['created_by_profile_id']?.toString();
      if (creator != null && creator.isNotEmpty) {
        jsonMap['creatorProfileId'] = creator;
      }
      final activeScorer = row['active_scorer_id']?.toString();
      if (activeScorer != null && activeScorer.isNotEmpty) {
        jsonMap['activeScorerId'] = activeScorer;
      }
      final playerIds = row['player_profile_ids'];
      if (playerIds is List) {
        jsonMap['playerProfileIds'] =
            playerIds.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
      }
      final summary = row['result_summary']?.toString();
      if (summary != null && summary.isNotEmpty) {
        jsonMap['resultSummary'] = summary;
      }
      final completedAt = row['completed_at']?.toString();
      if (completedAt != null && completedAt.isNotEmpty) {
        jsonMap['completedAt'] = completedAt;
      }
      return MatchSetupData.fromJson(jsonMap);
    } catch (e) {
      debugPrint('PendingMatchesNotifier._fromRow error: $e');
      return null;
    }
  }

  Future<void> addOrUpdateMatch(MatchSetupData match) async {
    final canonical = match.copyWith(status: MatchStatus.normalize(match.status));

    // 1. Update local state immediately for fast UI.
    // Dedup by creationRequestId first, then matchAppId, then UUID:
    int existingIndex = -1;
    if (canonical.creationRequestId != null && canonical.creationRequestId!.isNotEmpty) {
      existingIndex = state.indexWhere((m) => m.creationRequestId == canonical.creationRequestId);
    }
    if (existingIndex < 0 && canonical.matchAppId != null && canonical.matchAppId!.isNotEmpty) {
      existingIndex = state.indexWhere((m) => m.matchAppId == canonical.matchAppId);
    }
    // Fall back to UUID-based dedup if no previous match found.
    if (existingIndex < 0) {
      existingIndex = state.indexWhere((m) => m.id == canonical.id);
    }

    final previousRowId = existingIndex >= 0 ? state[existingIndex].id : null;
    List<MatchSetupData> newState;
    if (existingIndex >= 0) {
      newState = List.from(state)..[existingIndex] = canonical;
    } else {
      newState = [...state, canonical];
    }
    state = newState;
    await _saveToPrefs(newState);

    // 2. Sync to InsForge.
    final profile = ref.read(profileProvider);
    if (!profile.isLoggedIn) return;
    try {
      final profileId = profile.id;
      final rowId = previousRowId ?? canonical.id;
      final creatorId = (canonical.creatorProfileId != null &&
              canonical.creatorProfileId!.isNotEmpty)
          ? canonical.creatorProfileId!
          : (profileId.isNotEmpty ? profileId : null);
      final playerIds = canonical.playerProfileIds.isNotEmpty
          ? canonical.playerProfileIds
          : _collectPlayerIds(canonical);

      final bodyMap = <String, dynamic>{
        'id': rowId,
        'status': canonical.status,
        'match_data': canonical.toJson(),
        if (canonical.creationRequestId != null &&
            canonical.creationRequestId!.isNotEmpty)
          'creation_request_id': canonical.creationRequestId,
        if (creatorId != null && creatorId.isNotEmpty)
          'created_by_profile_id': creatorId,
        if (canonical.activeScorerId != null &&
            canonical.activeScorerId!.isNotEmpty)
          'active_scorer_id': canonical.activeScorerId,
        if (playerIds.isNotEmpty) 'player_profile_ids': playerIds,
        if (canonical.resultSummary != null &&
            canonical.resultSummary!.isNotEmpty)
          'result_summary': canonical.resultSummary,
        if (canonical.completedAt != null)
          'completed_at': _istNow(canonical.completedAt),
        'updated_at': _istNow(),
      };

      if (existingIndex >= 0) {
        await http.patch(
          Uri.parse('$_url?id=eq.$rowId'),
          headers: _headers,
          body: jsonEncode(bodyMap),
        );
      } else {
        await http.post(
          Uri.parse(_url),
          headers: {
            ..._headers,
            'Prefer': 'resolution=merge-duplicates,return=representation',
          },
          body: jsonEncode([bodyMap]),
        );
      }
    } catch (e) {
      debugPrint('Failed to sync match to InsForge: $e');
    }
  }

  List<String> _collectPlayerIds(MatchSetupData match) {
    return match.teamAPlayers
        .followedBy(match.teamBPlayers)
        .map((p) => p.profileId)
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();
  }

  /// Applies a lifecycle transition locally and best-effort on the server.
  ///
  /// Local state is updated first so offline scoring keeps working; the
  /// server write is what other devices and RLS will trust.
  Future<bool> markLive(
    String matchId, {
    required String scorerId,
    String? scorerName,
  }) async {
    // The server is the source of truth for the live transition. Only update
    // local state once InsForge confirms this caller is the active scorer.
    final ok = await MatchLifecycleService.markLive(
      matchId: matchId,
      scorerId: scorerId,
      scorerName: scorerName,
    );
    if (!ok) return false;

    final index = state.indexWhere((m) => m.id == matchId);
    if (index >= 0) {
      final updated = state[index].copyWith(
        status: MatchStatus.live,
        activeScorerId: scorerId,
        teamAScorerName: scorerName ?? state[index].teamAScorerName,
      );
      final newState = List<MatchSetupData>.from(state)..[index] = updated;
      state = newState;
      await _saveToPrefs(newState);
    }
    return true;
  }

  /// Removes a completed or abandoned match from the pending/live list.
  Future<void> markCompleted(
    String matchId, {
    String? resultSummary,
    String? winner,
    String status = MatchStatus.completed,
  }) async {
    final newState = state.where((m) => m.id != matchId).toList();
    state = newState;
    await _saveToPrefs(newState);
    await MatchLifecycleService.markCompleted(
      matchId: matchId,
      resultSummary: resultSummary ?? 'Match completed',
      winner: winner,
      status: status,
    );
  }

  /// Re-reads the authoritative active scorer from InsForge.
  Future<String?> fetchActiveScorerId(String matchId) =>
      MatchLifecycleService.fetchActiveScorerId(matchId);

  Future<void> removeMatch(String matchId) async {
    // 1. Update local state
    final newState = state.where((m) => m.id != matchId).toList();
    state = newState;
    await _saveToPrefs(newState);

    // 2. Delete from InsForge
    final isLoggedIn = ref.read(profileProvider).isLoggedIn;
    if (!isLoggedIn) return;
    try {
      await http.delete(
        Uri.parse('$_url?id=eq.$matchId'),
        headers: _headers,
      );
    } catch (e) {
      debugPrint('Failed to delete match from InsForge: $e');
    }
  }

  /// Clears all local pending matches
  Future<void> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
      state = [];
    } catch (_) {}
  }
}

final pendingMatchesProvider = NotifierProvider<PendingMatchesNotifier, List<MatchSetupData>>(() {
  return PendingMatchesNotifier();
});
