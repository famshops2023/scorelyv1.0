import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists active in-progress match state so that crashes, incoming calls,
/// or app restarts do not lose any live match scoring progress.
class OngoingMatchService {
  OngoingMatchService._();
  static final OngoingMatchService instance = OngoingMatchService._();

  static const String _activeMatchKeyPrefix = 'ongoing_match_v1_';
  static const String _latestActiveMatchKey = 'latest_active_match_id';

  /// Save snapshot of an in-progress match to device storage
  Future<void> saveSnapshot(String matchId, Map<String, dynamic> snapshot) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_activeMatchKeyPrefix$matchId';
      final jsonString = jsonEncode(snapshot);
      await prefs.setString(key, jsonString);
      await prefs.setString(_latestActiveMatchKey, matchId);
    } catch (e) {
      debugPrint('OngoingMatchService.saveSnapshot error: $e');
    }
  }

  /// Retrieve the active snapshot for a specific matchId or the latest ongoing match
  Future<Map<String, dynamic>?> getSnapshot([String? matchId]) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? targetId = matchId;
      if (targetId == null || targetId.isEmpty) {
        targetId = prefs.getString(_latestActiveMatchKey);
      }
      if (targetId == null || targetId.isEmpty) return null;

      final key = '$_activeMatchKeyPrefix$targetId';
      final raw = prefs.getString(key);
      if (raw == null || raw.isEmpty) return null;

      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('OngoingMatchService.getSnapshot error: $e');
      return null;
    }
  }

  /// Check if there is an active ongoing match
  Future<bool> hasActiveMatch([String? matchId]) async {
    final snapshot = await getSnapshot(matchId);
    return snapshot != null && snapshot.isNotEmpty;
  }

  /// Clear the active match snapshot when match is finished and committed to DB
  Future<void> clearSnapshot(String matchId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_activeMatchKeyPrefix$matchId';
      await prefs.remove(key);

      final latest = prefs.getString(_latestActiveMatchKey);
      if (latest == matchId) {
        await prefs.remove(_latestActiveMatchKey);
      }
    } catch (e) {
      debugPrint('OngoingMatchService.clearSnapshot error: $e');
    }
  }
}
