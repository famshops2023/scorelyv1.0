import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../routes/app_router.dart';
import '../../../core/theme/colors.dart';
import '../../../models/scorer_assignment_request.dart';
import '../../../models/user_profile.dart';
import '../../../providers/profile_provider.dart';
import '../../../services/scorer_handover_service.dart';
import '../../match/match_setup_screen.dart';
import '../../scoring/widgets/scorer_request_dialog.dart';

class InAppRequestsSheet extends ConsumerStatefulWidget {
  const InAppRequestsSheet({super.key});

  @override
  ConsumerState<InAppRequestsSheet> createState() => _InAppRequestsSheetState();
}

class _InAppRequestsSheetState extends ConsumerState<InAppRequestsSheet> {
  bool _isLoading = true;
  List<ScorerAssignmentRequest> _requests = [];

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    final profile = ref.read(profileProvider);
    final userId = profile.id;
    final email = profile.email;
    if (userId.isEmpty && email.isEmpty) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    final list = await ScorerHandoverService.instance.getPendingRequestsForUser(
      userId,
      email: email,
      name: profile.name,
    );
    if (mounted) {
      setState(() {
        _requests = list;
        _isLoading = false;
      });
    }
  }

  void _openDecision(ScorerAssignmentRequest request) {
    final userId = ref.read(profileProvider).id;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ScorerRequestDialog(
        request: request,
        currentUserId: userId,
        onDecision: (accepted) {
          _loadRequests();
          if (accepted) {
            Navigator.pop(context); // Close requests sheet

            // Extract match setup from the payload embedded by the 1st scorer
            final payload = request.payload;
            final isHandover = payload != null &&
                payload['type'] == 'innings_break_handover';

            if (isHandover && payload['setupData'] is Map) {
              // Reconstruct MatchSetupData from the payload
              MatchSetupData setupData;
              try {
                setupData = MatchSetupData.fromJson(
                  Map<String, dynamic>.from(
                      payload['setupData'] as Map),
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

              // Navigate THIS device (recipient) to the 2nd innings
              // Opening Lineup screen — the correct screen.
              goRouter.push('/opening-lineup', extra: <String, dynamic>{
                'setupData': setupData,
                'isSecondInnings': payload['isSecondInnings'] ?? true,
                // isHandoverMode=true ensures Start Match goes to /scoring
                // directly (no innings_break_screen on the stack here).
                'isHandoverMode': true,
                // Forward 1st innings data so the target is set correctly
                'firstInningsRuns': payload['firstInningsRuns'] as int?,
                'firstInningsWickets': payload['firstInningsWickets'] as int?,
                'firstInningsBattingTeam': payload['firstInningsBattingTeam'] as String?,
                'firstInningsOvers': payload['firstInningsOvers'] as String?,
                'firstInningsBalls': payload['firstInningsBalls'] as int?,
                'target': payload['target'] as int?,
              });
            } else {
              // Fallback: go to scoring with whatever match this was
              goRouter.push('/scoring', extra: <String, dynamic>{
                'matchId': request.matchId,
              });
            }
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      'Notifications & Requests',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.lightTextPrimary,
                      ),
                    ),
                    if (_requests.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_requests.length}',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.lightTextSecondary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFECEEF1)),
          Flexible(
            child: _isLoading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(color: AppColors.primary),
                    ),
                  )
                : _requests.isEmpty
                    ? Container(
                        padding: const EdgeInsets.all(40),
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.notifications_none_outlined, size: 52, color: AppColors.lightBorder),
                            const SizedBox(height: 12),
                            Text(
                              'No Pending Requests',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.lightTextPrimary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'You have no pending scorer assignments or match invitations.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: AppColors.lightTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        shrinkWrap: true,
                        itemCount: _requests.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final req = _requests[index];
                          final requester = req.requestedByName ?? 'Match Official';

                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFECEEF1)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.sports_cricket, color: AppColors.primary, size: 22),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Scorer Request',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: AppColors.lightTextPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '$requester (${UserProfile.deriveDisplayId(req.requestedByUserId)}) requested you to score',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: AppColors.lightTextSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    elevation: 0,
                                  ),
                                  onPressed: () => _openDecision(req),
                                  child: Text(
                                    'Review',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
