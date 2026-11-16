import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/config/insforge_config.dart';
import '../features/match/match_setup_screen.dart';
import '../features/match/widgets/match_result_popup_dialog.dart';
import '../models/match_result_data.dart';
import '../models/match_status.dart';
import '../routes/app_router.dart';
import 'profile_provider.dart';

/// Shows the completed-match result popup to the active scorer and every
/// associated signed-in player. Seen match IDs are persisted so a popup is
/// never shown twice, even across restarts or an offline completion.
final matchResultPopupProvider =
    NotifierProvider<MatchResultPopupNotifier, MatchResultData?>(
  MatchResultPopupNotifier.new,
);

class MatchResultPopupNotifier extends Notifier<MatchResultData?> {
  static const _seenKey = 'seen_completed_match_ids';

  Timer? _timer;
  bool _isChecking = false;
  bool _isShowing = false;

  @override
  MatchResultData? build() {
    ref.onDispose(() => _timer?.cancel());
    ref.listen(profileProvider, (prev, next) {
      if (next.isLoggedIn && next.id.isNotEmpty) {
        _startPolling();
      } else {
        _stopPolling();
      }
    }, fireImmediately: true);
    return null;
  }

  void _startPolling() {
    _timer?.cancel();
    checkNow();
    _timer = Timer.periodic(const Duration(seconds: 20), (_) => checkNow());
  }

  void _stopPolling() {
    _timer?.cancel();
    _timer = null;
    state = null;
  }

  /// Marks a result as already presented (e.g. the scorer just landed on the
  /// full result screen). Prevents a duplicate popup.
  Future<void> markResultSeen(String matchId) async {
    if (matchId.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final seen = (prefs.getStringList(_seenKey) ?? const []).toSet()
        ..add(matchId);
      final trimmed = seen.toList();
      // Keep the list bounded.
      final bounded = trimmed.length > 100
          ? trimmed.sublist(trimmed.length - 100)
          : trimmed;
      await prefs.setStringList(_seenKey, bounded);
    } catch (e) {
      debugPrint('MatchResultPopupNotifier.markResultSeen error: $e');
    }
  }

  Future<void> checkNow() async {
    final profile = ref.read(profileProvider);
    if (!profile.isLoggedIn || profile.id.isEmpty) return;
    if (_isChecking || _isShowing) return;

    _isChecking = true;
    try {
      final myId = profile.id;
      final uri = Uri.parse('${InsforgeConfig.recordsUrl}/pending_matches')
          .replace(queryParameters: {
        'status': 'eq.completed',
        // Only matches completed by the current lifecycle write a timestamp.
        // Legacy completed rows (pre-migration) must not trigger a popup.
        'completed_at': 'not.is.null',
        'or': '(created_by_profile_id.eq.$myId,'
            'active_scorer_id.eq.$myId,'
            'player_profile_ids.cs.["$myId"])',
        'order': 'completed_at.desc',
        'limit': '10',
        'select': '*',
      });

      final res = await InsforgeConfig.getWithFallback(uri)
          .timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return;

      final decoded = jsonDecode(res.body);
      if (decoded is! List || decoded.isEmpty) return;

      final prefs = await SharedPreferences.getInstance();
      final seen = (prefs.getStringList(_seenKey) ?? const []).toSet();

      for (final raw in decoded) {
        if (raw is! Map) continue;
        final row = Map<String, dynamic>.from(raw);
        final matchId = row['id']?.toString() ?? '';
        if (matchId.isEmpty || seen.contains(matchId)) continue;

        final data = _buildResultData(row);
        if (data == null) continue;

        final ctx = rootNavigatorKey.currentContext;
        if (ctx == null || !ctx.mounted) return;

        // Mark before showing so a crash/kill cannot produce a duplicate.
        await markResultSeen(matchId);
        if (!ctx.mounted) return;
        await _show(ctx, data);
        // Show one popup per poll cycle.
        break;
      }
    } catch (e) {
      debugPrint('MatchResultPopupNotifier.checkNow error: $e');
    } finally {
      _isChecking = false;
    }
  }

  Future<void> _show(BuildContext context, MatchResultData data) async {
    _isShowing = true;
    try {
      state = data;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => MatchResultPopupDialog(
          data: data,
          onClose: () => Navigator.of(dialogContext).pop(),
          onViewScorecard: () {
            Navigator.of(dialogContext).pop();
            goRouter.push('/match-result', extra: data);
          },
        ),
      );
    } finally {
      _isShowing = false;
      state = null;
    }
  }

  MatchResultData? _buildResultData(Map<String, dynamic> row) {
    try {
      Map<String, dynamic> decode(dynamic raw) {
        if (raw is Map) return Map<String, dynamic>.from(raw);
        if (raw is String && raw.isNotEmpty) {
          final d = jsonDecode(raw);
          if (d is Map) return Map<String, dynamic>.from(d);
        }
        return <String, dynamic>{};
      }

      final md = decode(row['match_data']);
      final live = decode(row['live_score_data']);
      final teamA = (md['teamAName'] ?? 'Team A').toString();
      final teamB = (md['teamBName'] ?? 'Team B').toString();
      final aScore = (live['team_a_score'] ?? '0/0').toString();
      final bScore = (live['team_b_score'] ?? '0/0').toString();
      final aOvers = (live['team_a_overs'] ?? '').toString();
      final bOvers = (live['team_b_overs'] ?? '').toString();

      final firstTeam = (live['batting_first_team'] ??
              md['battingFirstTeam'] ??
              teamA)
          .toString();
      final secondTeam = firstTeam == teamA ? teamB : teamA;
      final firstScore = firstTeam == teamA ? aScore : bScore;
      final secondScore = firstTeam == teamA ? bScore : aScore;
      final firstOvers = firstTeam == teamA ? aOvers : bOvers;
      final secondOvers = firstTeam == teamA ? bOvers : aOvers;

      int runsOf(String score) => int.tryParse(score.split('/').first) ?? 0;

      var winner = (row['winner'] ?? '').toString().trim();
      if (winner.isEmpty) {
        if (runsOf(aScore) > runsOf(bScore)) {
          winner = teamA;
        } else if (runsOf(bScore) > runsOf(aScore)) {
          winner = teamB;
        } else {
          winner = 'Match Tied';
        }
      }

      final summary = (row['result_summary'] ?? '').toString().trim();
      final statusText = summary.isNotEmpty
          ? summary
          : (winner == 'Match Tied'
              ? 'Match Tied'
              : '$winner won the match');

      MatchSetupData? setup;
      try {
        setup = MatchSetupData.fromJson({
          ...md,
          'id': row['id']?.toString() ?? md['id'] ?? '',
          'status': MatchStatus.completed,
          'activeScorerId': row['active_scorer_id']?.toString(),
          'creatorProfileId': row['created_by_profile_id']?.toString(),
          'resultSummary': summary,
          'completedAt': row['completed_at']?.toString(),
        });
      } catch (_) {}

      return MatchResultData(
        matchCode: (md['matchCode'] ?? md['matchAppId'] ?? '').toString(),
        winningTeam: winner,
        matchStatusText: statusText,
        team1Name: teamA,
        team1Score: aScore,
        team1Overs: aOvers,
        team2Name: teamB,
        team2Score: bScore,
        team2Overs: bOvers,
        format: (md['matchType'] ?? live['format'] ?? 'T20').toString(),
        venue: (live['venue'] ?? md['venue'] ?? 'Local Ground').toString(),
        totalOvers: (md['overs'] as num?)?.toInt() ?? 20,
        innings1Team: firstTeam,
        innings1Score: firstScore,
        innings1Overs: firstOvers,
        innings2Team: secondTeam,
        innings2Score: secondScore,
        innings2Overs: secondOvers,
        ballType: (md['ballType'] ?? 'Leather').toString(),
        setupData: setup,
      );
    } catch (e) {
      debugPrint('MatchResultPopupNotifier._buildResultData error: $e');
      return null;
    }
  }
}
