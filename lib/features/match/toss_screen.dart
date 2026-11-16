import 'package:flutter/material.dart';
import 'package:scorely/core/theme/colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';

import 'match_setup_screen.dart';
import 'widgets/official_scorer_section.dart';
import '../../services/database.dart';
import '../../services/scorer_handover_service.dart';
import '../../models/match_status.dart';
import '../../providers/profile_provider.dart';
import 'providers/pending_matches_provider.dart';
import 'providers/quick_match_storage.dart';
import '../../providers/history_provider.dart';
import '../scoring/widgets/scorer_request_waiting_sheet.dart';
import '../teams/providers/teams_provider.dart';

class TossScreen extends ConsumerStatefulWidget {
  final MatchSetupData setupData;

  const TossScreen({super.key, required this.setupData});

  @override
  ConsumerState<TossScreen> createState() => _TossScreenState();
}

class _TossScreenState extends ConsumerState<TossScreen> {
  late String _tossWonBy;
  String _tossDecision = 'BATTING';
  TeamMember? _officialScorer;

  @override
  void initState() {
    super.initState();
    _tossWonBy = widget.setupData.teamAName;
  }

  String get _battingFirstTeam {
    if (_tossWonBy == widget.setupData.teamAName) {
      return _tossDecision == 'BATTING'
          ? widget.setupData.teamAName
          : widget.setupData.teamBName;
    }
    return _tossDecision == 'BATTING'
        ? widget.setupData.teamBName
        : widget.setupData.teamAName;
  }

  Future<void> _startScoring() async {
    // Official scorer is mandatory — block navigation until one is selected.
    final scorer = _officialScorer;
    if (scorer == null) {
      await _showOfficialScorerRequiredDialog();
      return;
    }

    final battingFirstTeam = _battingFirstTeam;
    final profile = ref.read(profileProvider);

    final matchId = widget.setupData.id.isNotEmpty
        ? widget.setupData.id
        : const Uuid().v4();

    final db = DatabaseService.instance;

    // Reuse existing matchAppId if already assigned during setup, otherwise allocate next
    String matchAppId = widget.setupData.matchAppId ?? '';
    if (matchAppId.isEmpty) {
      try {
        matchAppId = await db.nextMatchAppId();
      } catch (e) {
        debugPrint('TossScreen: nextMatchAppId failed — $e');
        matchAppId = MatchSetupData.deriveMatchCode(matchId);
      }
    }

    // Sanitize scorer ID: map 'scorer_myself' to actual auth user id or null (never send sentinel to UUID columns)
    final String? effectiveScorerId = (scorer.profileId != null &&
            scorer.profileId!.isNotEmpty &&
            scorer.profileId != 'scorer_myself')
        ? scorer.profileId
        : (profile.isLoggedIn && profile.id.isNotEmpty ? profile.id : null);

    // Toss completion NEVER makes a match live. It stays pending until the
    // official scorer reaches Opening Lineup and clicks "Proceed to Score".
    final updatedData = widget.setupData.copyWith(
      id: matchId,
      status: MatchStatus.pending,
      setupStage: MatchSetupStage.readyForToss,
      tossWonBy: _tossWonBy,
      battingFirstTeam: battingFirstTeam,
      matchAppId: matchAppId,
      teamAScorerId: effectiveScorerId,
      teamAScorerName: scorer.name,
      activeScorerId: effectiveScorerId,
      creatorProfileId: profile.id.isNotEmpty
          ? profile.id
          : widget.setupData.creatorProfileId,
      // The scorer may be a squad member who is not in the playing XI. Add
      // them to the association list so RLS lets them read the pending row
      // (and so the INSERT check accepts the selected active scorer).
      playerProfileIds: {
        ...widget.setupData.playerProfileIds,
        if (effectiveScorerId != null && effectiveScorerId.isNotEmpty)
          effectiveScorerId,
      }.toList(),
    );

    // Persist the pending match (with toss details) for associated viewers.
    // For signed-in users (both quick and scheduled), this creates the 'pending' row in InsForge.
    if (profile.isLoggedIn && profile.id.isNotEmpty) {
      await ref.read(pendingMatchesProvider.notifier).addOrUpdateMatch(updatedData);
    }

    if (widget.setupData.isQuickMatch) {
      final storageLimit = ref.read(storageLimitProvider);
      QuickMatchStorage.saveQuickMatch(updatedData, storageLimit: storageLimit);
    }

    // The signed-in scorer must be the one who opens the lineup and proceeds.
    // If the creator selected somebody else, send them a handover request.
    final isSelfScorer = scorer.profileId == 'scorer_myself' ||
        !profile.isLoggedIn ||
        scorer.profileId == profile.id;
    if (!isSelfScorer) {
      await _requestOpeningLineupHandover(updatedData, scorer);
      return;
    }

    if (mounted) {
      context.pushReplacement('/opening-lineup', extra: updatedData);
    }
  }

  /// Sends a scorer request so the selected official scorer can open the
  /// Opening Lineup on their own device and start the match.
  Future<void> _requestOpeningLineupHandover(
    MatchSetupData data,
    TeamMember scorer,
  ) async {
    final profile = ref.read(profileProvider);
    final request = await ScorerHandoverService.instance.createRequest(
      matchId: data.id,
      requestedByUserId: profile.id,
      requestedByName: profile.name.isNotEmpty ? profile.name : 'Match Creator',
      requestedScorerUserId: scorer.profileId ?? scorer.id,
      requestedScorerName: scorer.name,
      currentScorerUserId: profile.id,
      matchTitle: '${data.teamAName} vs ${data.teamBName}',
      payload: {
        'type': 'opening_lineup_handover',
        'setupData': data.toJson(),
        'isSecondInnings': false,
      },
    );

    if (!mounted) return;

    if (request == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to send scorer request. Please try again.'),
          backgroundColor: AppColors.primary,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      backgroundColor: Colors.transparent,
      builder: (_) => ScorerRequestWaitingSheet(
        request: request,
        onAccepted: () {
          if (mounted) context.go('/home');
        },
        onChooseAnother: () {
          if (mounted) context.pop();
        },
      ),
    );
  }

  /// Small popup shown when the user taps NEXT without selecting a scorer.
  Future<void> _showOfficialScorerRequiredDialog() {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 40),
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 30,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person_search_outlined,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'OFFICIAL SCORER REQUIRED',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.lightTextSecondary,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Please select the official scorer to continue.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                    color: AppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'GOT IT',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBg,
      appBar: AppBar(
        backgroundColor: AppColors.lightTextPrimary,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'TOSS',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: 1.0,
          ),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20.0,
                    vertical: 24.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'COIN TOSS WINNER',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.lightTextSecondary,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTossCard(
                              widget.setupData.teamAName,
                              Icons.workspace_premium,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildTossCard(
                              widget.setupData.teamBName,
                              Icons.stadium_outlined,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      Center(
                        child: Text(
                          'DECIDED TO',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.lightTextSecondary,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _buildDecisionButton('BATTING')),
                          const SizedBox(width: 12),
                          Expanded(child: _buildDecisionButton('BOWLING')),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Center(
                        child: OfficialScorerSection(
                          setupData: widget.setupData,
                          scorer: _officialScorer,
                          teamName: _battingFirstTeam,
                          onChanged: (scorer) =>
                              setState(() => _officialScorer = scorer),
                        ),
                      ),
                      const Spacer(),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton.icon(
                          onPressed: () => _startScoring(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 4,
                            shadowColor:
                                AppColors.primary.withValues(alpha: 0.4),
                          ),
                          icon: const Icon(
                            Icons.sports_cricket,
                            color: Colors.white,
                            size: 20,
                          ),
                          label: Text(
                            'NEXT',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTossCard(String teamName, IconData icon) {
    bool isSelected = _tossWonBy == teamName;
    return GestureDetector(
      onTap: () => setState(() => _tossWonBy = teamName),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.lightTextPrimary : Colors.transparent,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFFECEEF1)
                    : AppColors.lightBg,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 28,
                color: isSelected
                    ? AppColors.lightTextPrimary
                    : const Color(0xFFBFC5E4),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              teamName,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isSelected
                    ? AppColors.lightTextPrimary
                    : const Color(0xFFBFC5E4),
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDecisionButton(String decision) {
    bool isSelected = _tossDecision == decision;
    return GestureDetector(
      onTap: () => setState(() => _tossDecision = decision),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : const Color(0xFFECEEF1),
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          decision,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : AppColors.lightTextSecondary,
          ),
        ),
      ),
    );
  }
}
