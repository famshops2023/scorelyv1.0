import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/config/insforge_config.dart';
import '../features/match/match_setup_screen.dart';
import '../features/match/providers/quick_match_storage.dart';
import '../models/live_match_data.dart';
import '../models/match_status.dart';
import '../models/player_setup.dart';
import '../providers/profile_provider.dart';

enum DuplicateCheckStatus { noDuplicate, sameSession, duplicateFound }

class DuplicateCheckResult {
  final DuplicateCheckStatus status;
  final MatchSetupData? existingMatch;

  const DuplicateCheckResult._({required this.status, this.existingMatch});

  factory DuplicateCheckResult.noDuplicate() =>
      const DuplicateCheckResult._(status: DuplicateCheckStatus.noDuplicate);

  factory DuplicateCheckResult.sameSession(MatchSetupData match) =>
      DuplicateCheckResult._(
        status: DuplicateCheckStatus.sameSession,
        existingMatch: match,
      );

  factory DuplicateCheckResult.duplicateFound(MatchSetupData match) =>
      DuplicateCheckResult._(
        status: DuplicateCheckStatus.duplicateFound,
        existingMatch: match,
      );

  bool get isDuplicate => status == DuplicateCheckStatus.duplicateFound;
  bool get isSameSession => status == DuplicateCheckStatus.sameSession;
}

class DuplicateMatchService {
  DuplicateMatchService._();
  static final DuplicateMatchService instance = DuplicateMatchService._();

  static String get _pendingMatchesUrl =>
      '${InsforgeConfig.recordsUrl}/pending_matches';

  /// In-flight submission lock to prevent rapid double-clicks
  bool _isChecking = false;
  bool get isChecking => _isChecking;

  /// Helper to normalize team names for comparison
  static String normalizeTeamName(String name) {
    return name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  /// 1. Primary duplicate check method
  Future<DuplicateCheckResult> checkForDuplicate({
    required String? creatorProfileId,
    required String teamAName,
    required String teamBName,
    required bool isQuickMatch,
    required DateTime matchDate,
    String? currentSessionMatchId,
    String? currentCreationRequestId,
  }) async {
    if (_isChecking) {
      // Already running a check
      return DuplicateCheckResult.noDuplicate();
    }
    _isChecking = true;

    try {
      final normA = normalizeTeamName(teamAName);
      final normB = normalizeTeamName(teamBName);

      if (normA.isEmpty || normB.isEmpty) {
        return DuplicateCheckResult.noDuplicate();
      }

      // Step A: Check local cache first (fastest)
      final localMatches = await _getLocalCandidateMatches(
        isQuickMatch: isQuickMatch,
      );

      for (final m in localMatches) {
        // If it matches current session ID or creation request ID, it's the SAME active session
        if ((currentSessionMatchId != null &&
                currentSessionMatchId.isNotEmpty &&
                m.id == currentSessionMatchId) ||
            (currentCreationRequestId != null &&
                currentCreationRequestId.isNotEmpty &&
                m.creationRequestId == currentCreationRequestId)) {
          return DuplicateCheckResult.sameSession(m);
        }

        // Check if it represents an existing pending or live match between the same teams
        if (_isMatchDuplicateCandidate(
          candidate: m,
          creatorProfileId: creatorProfileId,
          normA: normA,
          normB: normB,
          isQuickMatch: isQuickMatch,
          matchDate: matchDate,
        )) {
          return DuplicateCheckResult.duplicateFound(m);
        }
      }

      // Step B: Query remote InsForge pending_matches if creator is logged in
      if (creatorProfileId != null && creatorProfileId.isNotEmpty) {
        try {
          final queryParams = <String, String>{
            'status': 'in.(pending,live)',
            'created_by_profile_id': 'eq.$creatorProfileId',
            'select': '*',
            'order': 'created_at.desc',
            'limit': '15',
          };

          final uri = Uri.parse(
            _pendingMatchesUrl,
          ).replace(queryParameters: queryParams);
          final res = await InsforgeConfig.getWithFallback(
            uri,
          ).timeout(const Duration(seconds: 4));

          if (res.statusCode == 200) {
            final List<dynamic> rows = jsonDecode(res.body);
            for (final row in rows) {
              if (row is! Map) continue;
              final rowMap = Map<String, dynamic>.from(row);
              final match = _rowToMatchSetupData(rowMap);
              if (match == null) continue;

              // Check same session first
              if ((currentSessionMatchId != null &&
                      currentSessionMatchId.isNotEmpty &&
                      match.id == currentSessionMatchId) ||
                  (currentCreationRequestId != null &&
                      currentCreationRequestId.isNotEmpty &&
                      match.creationRequestId == currentCreationRequestId)) {
                return DuplicateCheckResult.sameSession(match);
              }

              // Check if duplicate candidate
              if (_isMatchDuplicateCandidate(
                candidate: match,
                creatorProfileId: creatorProfileId,
                normA: normA,
                normB: normB,
                isQuickMatch: isQuickMatch,
                matchDate: matchDate,
              )) {
                return DuplicateCheckResult.duplicateFound(match);
              }
            }
          }
        } catch (e) {
          debugPrint('DuplicateMatchService: Remote check timeout/error: $e');
        }
      }

      return DuplicateCheckResult.noDuplicate();
    } finally {
      _isChecking = false;
    }
  }

  /// Determines if a candidate match matches the creation parameters
  bool _isMatchDuplicateCandidate({
    required MatchSetupData candidate,
    required String? creatorProfileId,
    required String normA,
    required String normB,
    required bool isQuickMatch,
    required DateTime matchDate,
  }) {
    // Only pending or live matches can be duplicates
    final candStatus = candidate.status.toLowerCase();
    if (candStatus != 'pending' && candStatus != 'live') {
      return false;
    }

    // Must match the match archetype (Quick Match vs Schedule Match)
    if (candidate.isQuickMatch != isQuickMatch) {
      return false;
    }

    // Must match creator if creator is known
    if (creatorProfileId != null &&
        creatorProfileId.isNotEmpty &&
        candidate.creatorProfileId != null &&
        candidate.creatorProfileId!.isNotEmpty &&
        candidate.creatorProfileId != creatorProfileId) {
      return false;
    }

    // Compare team names
    final candA = normalizeTeamName(candidate.teamAName);
    final candB = normalizeTeamName(candidate.teamBName);

    final teamsMatch =
        (candA == normA && candB == normB) ||
        (candA == normB && candB == normA);

    if (!teamsMatch) return false;

    // For scheduled matches, check if the scheduled date is within the same time window (4 hours)
    if (!isQuickMatch) {
      final diff = candidate.matchDate.difference(matchDate).abs();
      if (diff > const Duration(hours: 4)) {
        return false;
      }
    }

    return true;
  }

  /// Retrieves local candidates from SharedPreferences
  Future<List<MatchSetupData>> _getLocalCandidateMatches({
    required bool isQuickMatch,
  }) async {
    final list = <MatchSetupData>[];
    try {
      final prefs = await SharedPreferences.getInstance();

      // 1. Pending matches local store
      final pendingStr = prefs.getString('pending_matches_v1');
      if (pendingStr != null) {
        final List<dynamic> decoded = jsonDecode(pendingStr);
        for (final item in decoded) {
          if (item is Map) {
            final m = MatchSetupData.fromJson(Map<String, dynamic>.from(item));
            if (!m.isCompleted) list.add(m);
          }
        }
      }

      // 2. Quick match history
      if (isQuickMatch) {
        final qm = await QuickMatchStorage.getLastQuickMatch();
        if (qm != null && !qm.isCompleted) {
          if (!list.any((x) => x.id == qm.id)) {
            list.add(qm);
          }
        }
      }
    } catch (_) {}
    return list;
  }

  /// Converts an InsForge row to MatchSetupData
  MatchSetupData? _rowToMatchSetupData(Map<String, dynamic> row) {
    try {
      final rawMatchData = row['match_data'];
      Map<String, dynamic> jsonMap = {};
      if (rawMatchData is Map) {
        jsonMap = Map<String, dynamic>.from(rawMatchData);
      } else if (rawMatchData is String && rawMatchData.isNotEmpty) {
        final d = jsonDecode(rawMatchData);
        if (d is Map) jsonMap = Map<String, dynamic>.from(d);
      }

      final rowId = row['id']?.toString();
      if (rowId != null && rowId.isNotEmpty) jsonMap['id'] = rowId;

      final creationReqId = row['creation_request_id']?.toString();
      if (creationReqId != null && creationReqId.isNotEmpty) {
        jsonMap['creationRequestId'] = creationReqId;
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

      return MatchSetupData.fromJson(jsonMap);
    } catch (e) {
      debugPrint('DuplicateMatchService._rowToMatchSetupData error: $e');
      return null;
    }
  }

  /// Player identifiers (profile IDs and names) for the live viewer fallback.
  List<String> _playerIdentifiers(List<PlayerSetupData> players) {
    final ids = <String>[];
    for (final player in players) {
      final pid = player.profileId?.trim();
      if (pid != null && pid.isNotEmpty && !ids.contains(pid)) ids.add(pid);
      final name = player.name.trim();
      if (name.isNotEmpty && !ids.contains(name)) ids.add(name);
    }
    return ids;
  }

  /// Status-based navigation when creator chooses "Continue Existing Match"
  void continueExistingMatch(
    BuildContext context,
    WidgetRef ref,
    MatchSetupData match,
  ) {
    final status = match.status.toLowerCase();
    final profile = ref.read(profileProvider);
    final myId = profile.id;

    if (status == 'pending') {
      if (match.isQuickMatch) {
        if (match.hasTossCompleted) {
          context.pushReplacement('/opening-lineup', extra: match);
        } else {
          context.push('/toss', extra: match);
        }
      } else {
        context.push('/match-details', extra: match);
      }
      return;
    }

    if (status == 'live') {
      final isScorer =
          match.isActiveScorer(myId) ||
          match.teamAScorerId == myId ||
          match.isCreator(myId);

      if (isScorer) {
        context.push('/scoring', extra: <String, dynamic>{'setupData': match});
      } else {
        // Associated viewer -> view live match
        final liveData = LiveMatchData(
          id: match.id,
          creatorId: match.creatorProfileId ?? '',
          teamAName: match.teamAName,
          teamBName: match.teamBName,
          teamAScore: '0/0',
          teamAOvers: '0.0',
          teamBScore: 'yet to bat',
          teamBOvers: '',
          format: match.matchType,
          venue: match.venue,
          innings: 1,
          scorerId: match.activeScorerId ?? match.teamAScorerId ?? '',
          scorerName: match.teamAScorerName ?? '',
          teamAPlayerIds: _playerIdentifiers(match.teamAPlayers),
          teamBPlayerIds: _playerIdentifiers(match.teamBPlayers),
          last6Balls: '',
          currentBatters: const [],
          currentBowler: const {},
          matchAppId: match.matchAppId,
        );
        context.push('/live-match', extra: liveData);
      }
      return;
    }

    if (status == 'completed') {
      context.push(
        '/match-stats',
        extra: <String, dynamic>{'setupData': match},
      );
    }
  }
}
