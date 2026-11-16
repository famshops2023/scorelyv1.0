import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/scorer_assignment_request.dart';
import '../routes/app_router.dart';
import '../services/notification_service.dart';
import '../services/scorer_handover_service.dart';
import '../features/match/match_setup_screen.dart';
import '../features/scoring/widgets/scorer_request_dialog.dart';
import 'profile_provider.dart';

final pendingScorerRequestsProvider =
    NotifierProvider<PendingScorerRequestsNotifier, List<ScorerAssignmentRequest>>(
  PendingScorerRequestsNotifier.new,
);

class PendingScorerRequestsNotifier extends Notifier<List<ScorerAssignmentRequest>> {
  Timer? _pollTimer;
  final Set<String> _notifiedRequestIds = {};
  bool _isPrompting = false;

  @override
  List<ScorerAssignmentRequest> build() {
    ref.onDispose(() {
      _stopPolling();
    });

    ref.listen(profileProvider, (prev, next) {
      if (next.isLoggedIn && next.id.isNotEmpty) {
        _startPolling();
      } else {
        _stopPolling();
      }
    }, fireImmediately: true);

    return [];
  }

  void _startPolling() {
    _stopPolling();
    // Run immediate check
    checkRequests();
    // Poll every 4 seconds
    _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      checkRequests();
    });
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
    state = [];
  }

  Future<void> checkRequests() async {
    final profile = ref.read(profileProvider);
    if (!profile.isLoggedIn || profile.id.isEmpty) return;

    final requests = await ScorerHandoverService.instance.getPendingRequestsForUser(
      profile.id,
      email: profile.email,
      name: profile.name,
    );

    state = requests;

    // Check for newly received requests that haven't triggered notifications
    for (final req in requests) {
      if (!_notifiedRequestIds.contains(req.id)) {
        _notifiedRequestIds.add(req.id);
        _notifyNewRequest(req, profile.id);
      }
    }
  }

  Future<void> _notifyNewRequest(ScorerAssignmentRequest request, String currentUserId) async {
    final requester = request.requestedByName ?? 'Cricket Scorer';
    final match = request.matchTitle ?? 'Live Cricket Match';

    // 1. Show OS-level notification
    await NotificationService.instance.showScorerRequestNotification(
      requesterName: requester,
      matchTitle: match,
      requestId: request.id,
    );

    // 2. If app is currently active in foreground, pop up in-app request dialog
    final context = rootNavigatorKey.currentContext;
    if (context != null && !_isPrompting) {
      _isPrompting = true;
      try {
        if (!context.mounted) return;
        await showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => ScorerRequestDialog(
            request: request,
            currentUserId: currentUserId,
            onDecision: (accepted) {
              checkRequests();
              if (accepted) {
                final payload = request.payload;
                // Both first-innings scorer assignment and second-innings
                // handover carry the full setup so the recipient can open the
                // Opening Lineup on their own device.
                final hasSetupPayload =
                    payload != null && payload['setupData'] is Map;

                if (hasSetupPayload) {
                  MatchSetupData setupData;
                  try {
                    setupData = MatchSetupData.fromJson(
                      Map<String, dynamic>.from(payload['setupData'] as Map),
                    );
                  } catch (_) {
                    setupData = MatchSetupData.fromJson({
                      'teamAName': request.matchTitle ?? 'Match',
                      'teamBName': '',
                    });
                  }

                  if (setupData.teamAScorerId == null || setupData.teamAScorerId!.isEmpty) {
                    final fallbackFirstScorerId = (payload['firstInningsScorerId'] as String?) ?? request.requestedByUserId;
                    final fallbackFirstScorerName = (payload['firstInningsScorerName'] as String?) ?? request.requestedByName;
                    setupData = setupData.copyWith(
                      teamAScorerId: fallbackFirstScorerId,
                      teamAScorerName: setupData.teamAScorerName ?? fallbackFirstScorerName,
                    );
                  }

                  goRouter.push('/opening-lineup', extra: <String, dynamic>{
                    'setupData': setupData,
                    'isSecondInnings': payload['isSecondInnings'] ?? true,
                    'isHandoverMode': true,
                    'firstInningsRuns': payload['firstInningsRuns'] as int?,
                    'firstInningsWickets': payload['firstInningsWickets'] as int?,
                    'firstInningsBattingTeam': payload['firstInningsBattingTeam'] as String?,
                    'firstInningsOvers': payload['firstInningsOvers'] as String?,
                    'firstInningsBalls': payload['firstInningsBalls'] as int?,
                    'target': payload['target'] as int?,
                  });
                } else {
                  goRouter.push('/scoring', extra: <String, dynamic>{
                    'matchId': request.matchId,
                  });
                }
              }
            },
          ),
        );
      } catch (e) {
        debugPrint('Error showing ScorerRequestDialog in-app: $e');
      } finally {
        _isPrompting = false;
      }
    }
  }
}
