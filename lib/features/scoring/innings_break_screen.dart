import 'package:flutter/material.dart';
import 'package:scorely/core/theme/colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../match/match_setup_screen.dart';
import '../match/opening_lineup_screen.dart';
import '../teams/providers/teams_provider.dart';
import '../../models/match_stats.dart';
import '../../providers/profile_provider.dart';
import '../../services/scorer_handover_service.dart';
import 'widgets/scorer_request_waiting_sheet.dart';

class InningsSummaryData {
  final MatchSetupData setupData;
  final String battingTeam;
  final String fieldingTeam;
  final int runs;
  final int wickets;
  final int ballsBowled;
  final int extraRuns;
  final int totalFours;
  final int totalSixes;
  final List<BatterStats> topBatters;
  final List<BowlerStats> topBowlers;

  InningsSummaryData({
    required this.setupData,
    required this.battingTeam,
    required this.fieldingTeam,
    required this.runs,
    required this.wickets,
    required this.ballsBowled,
    required this.extraRuns,
    required this.totalFours,
    required this.totalSixes,
    required this.topBatters,
    required this.topBowlers,
  });
}

class InningsBreakScreen extends ConsumerStatefulWidget {
  final InningsSummaryData data;

  const InningsBreakScreen({super.key, required this.data});

  @override
  ConsumerState<InningsBreakScreen> createState() => _InningsBreakScreenState();
}

class _InningsBreakScreenState extends ConsumerState<InningsBreakScreen> {
  String? _newScorerName;

  void _showAllBowlersDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'All Bowlers — ${widget.data.fieldingTeam}',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: AppColors.lightTextPrimary,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(
                        'BOWLER',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.lightTextSecondary,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'O',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.lightTextSecondary,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'M',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.lightTextSecondary,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'R',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.lightTextSecondary,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'W',
                        textAlign: TextAlign.right,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.lightTextSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 16),
                ...widget.data.topBowlers.map(
                  (b) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(
                            b.name,
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              color: AppColors.darkSurface,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            b.oversDisplay,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              color: AppColors.lightTextSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            '${b.maidens}',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              color: AppColors.lightTextSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            '${b.runsConceded}',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              color: AppColors.lightTextSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            '${b.wickets}',
                            textAlign: TextAlign.right,
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'CLOSE',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleAssignScorer() async {
    final setup = widget.data.setupData;
    final currentProfile = ref.read(profileProvider);
    final currentUserId = currentProfile.id;

    // Requirement: Assigning the scorer option is only enabled for signed-in players.
    // If playing without signing in, they can assign themselves to score 2nd innings,
    // but cannot handover to another player or scorer (preventing active_scorer_id = null in InsForge).
    if (!currentProfile.isLoggedIn || currentUserId.isEmpty) {
      final updatedSetup = setup.copyWith(
        teamBScorerName: setup.teamAScorerName ?? 'Scorer (Myself)',
        teamBScorerId: setup.teamAScorerId ?? 'scorer_myself',
      );
      setState(() {
        _newScorerName = updatedSetup.teamBScorerName;
      });

      final lineupResult = await context.push<OpeningLineupResult?>(
        '/opening-lineup',
        extra: {
          'setupData': updatedSetup,
          'isSecondInnings': true,
        },
      );

      if (lineupResult != null && mounted) {
        Navigator.pop(context, {
          'setupData': updatedSetup,
          'lineup': lineupResult,
        });
      }
      return;
    }

    final secondInningsBattingTeamName = widget.data.fieldingTeam;
    final teams = ref.read(teamsProvider).value ?? [];
    final team = teams.firstWhere(
      (t) =>
          t.name.toLowerCase() == secondInningsBattingTeamName.toLowerCase(),
      orElse: () => TeamData(
        id: '',
        name: secondInningsBattingTeamName,
        location: 'Local',
        dateActive: DateTime.now(),
        members: [],
      ),
    );

    // Navigate to Team Squad screen with signedUpOnly: true & singleSelectionMode: true
    final selectedScorer = await context.push<TeamMember?>(
      '/team-squad',
      extra: {
        'teamId': team.id,
        'readOnly': false,
        'singleSelectionMode': true,
        'setupData': setup,
        'teamType': secondInningsBattingTeamName,
        'signedUpOnly': true,
      },
    );

    if (selectedScorer == null || !mounted) return;

    // Check if the 1st innings scorer selected "USE MYSELF AS SCORER"
    final isMyself = (currentUserId.isNotEmpty &&
            (selectedScorer.id == currentUserId ||
                selectedScorer.profileId == currentUserId)) ||
        selectedScorer.name == currentProfile.name ||
        selectedScorer.name == setup.teamAScorerName ||
        selectedScorer.id == 'scorer_myself';

    final effectiveFirstScorerId = (setup.teamAScorerId != null && setup.teamAScorerId!.isNotEmpty)
        ? setup.teamAScorerId
        : (currentUserId.isNotEmpty ? currentUserId : null);
    final effectiveFirstScorerName = (setup.teamAScorerName != null && setup.teamAScorerName!.isNotEmpty)
        ? setup.teamAScorerName
        : (currentProfile.name.isNotEmpty ? currentProfile.name : null);

    final updatedSetup = setup.copyWith(
      teamAScorerId: effectiveFirstScorerId,
      teamAScorerName: effectiveFirstScorerName,
      teamBScorerName: selectedScorer.name,
      teamBScorerId: selectedScorer.profileId ?? selectedScorer.id,
    );

    setState(() {
      _newScorerName = selectedScorer.name;
    });

    if (isMyself) {
      // 1st innings scorer selects 'USE MYSELF AS SCORER':
      // Directly navigate to Open Lineup screen
      final lineupResult = await context.push<OpeningLineupResult?>(
        '/opening-lineup',
        extra: {
          'setupData': updatedSetup,
          'isSecondInnings': true,
        },
      );

      if (lineupResult != null && mounted) {
        Navigator.pop(context, {
          'setupData': updatedSetup,
          'lineup': lineupResult,
        });
      }
    } else {
      // 1st innings scorer selects other players as scorer:
      // Request has to be sent to 2nd innings scorer and opt for accept or decline
      final request = await ScorerHandoverService.instance.createRequest(
        matchId: setup.id.isNotEmpty ? setup.id : const Uuid().v4(),
        requestedByUserId:
            currentUserId.isNotEmpty ? currentUserId : const Uuid().v4(),
        requestedByName: currentProfile.name.isNotEmpty
            ? currentProfile.name
            : (setup.teamAScorerName ?? '1st Innings Scorer'),
        requestedScorerUserId: selectedScorer.profileId ?? selectedScorer.id,
        requestedScorerName: selectedScorer.name,
        currentScorerUserId:
            currentUserId.isNotEmpty ? currentUserId : const Uuid().v4(),
        matchTitle: '${setup.teamAName} vs ${setup.teamBName}',
        // Embed full setup so the recipient's device can navigate to the
        // 2nd innings Opening Lineup without any guesswork.
        payload: {
          'type': 'innings_break_handover',
          'setupData': updatedSetup.toJson(),
          'firstInningsScorerId': effectiveFirstScorerId,
          'firstInningsScorerName': effectiveFirstScorerName,
          'isSecondInnings': true,
          // 1st innings summary so the recipient's ScoringScreen knows the target
          'firstInningsRuns': widget.data.runs,
          'firstInningsWickets': widget.data.wickets,
          'firstInningsBattingTeam': widget.data.battingTeam,
          'firstInningsOvers': '${widget.data.ballsBowled ~/ 6}.${widget.data.ballsBowled % 6}',
          'firstInningsBalls': widget.data.ballsBowled,
          'target': widget.data.runs + 1,
        },
      );

      if (!mounted) return;

      if (request == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to send scorer request.'),
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
            // The recipient (Demo1) handles their own navigation to the
            // opening lineup on their device. On the 1st scorer's device,
            // we just go back to the innings break / home screen.
            if (mounted) {
              // Close the innings break screen back to the scoring screen
              // which will show "handover complete" state.
              Navigator.popUntil(context, (route) => route.isFirst);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Scorer handover accepted! The new scorer is now active.'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 4),
                ),
              );
            }
          },
          onChooseAnother: _handleAssignScorer,
        ),
      );
    }
  }

  /// Continue scoring the second innings with the current active scorer.
  /// This never creates a handover request.
  Future<void> _handleContinueAsScorer() async {
    final setup = widget.data.setupData;
    final profile = ref.read(profileProvider);
    final updatedSetup = setup.copyWith(
      teamBScorerId: profile.id.isNotEmpty ? profile.id : setup.teamAScorerId,
      teamBScorerName: profile.name.isNotEmpty
          ? profile.name
          : (setup.teamAScorerName ?? 'Scorer (Myself)'),
    );

    setState(() {
      _newScorerName = updatedSetup.teamBScorerName;
    });

    final lineupResult = await context.push<OpeningLineupResult?>(
      '/opening-lineup',
      extra: {
        'setupData': updatedSetup,
        'isSecondInnings': true,
      },
    );

    if (lineupResult != null && mounted) {
      Navigator.pop(context, {
        'setupData': updatedSetup,
        'lineup': lineupResult,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final oversText =
        '${widget.data.ballsBowled ~/ 6}.${widget.data.ballsBowled % 6}';
    final runRate = widget.data.ballsBowled > 0
        ? (widget.data.runs / (widget.data.ballsBowled / 6)).toStringAsFixed(2)
        : '0.00';

    return Scaffold(
      backgroundColor: AppColors.lightBg,
      appBar: AppBar(
        backgroundColor: AppColors.darkSurface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Innings Summary',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Card
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                          color: Color.fromRGBO(26, 33, 56, 0.06),
                          blurRadius: 16,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 4,
                          height: 120,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(16),
                              bottomLeft: Radius.circular(16),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '${widget.data.battingTeam.toUpperCase()} - 1ST INNINGS',
                                      style: GoogleFonts.plusJakartaSans(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE8F5E9),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'COMPLETED',
                                        style: GoogleFonts.inter(
                                          color: AppColors.successDark,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 9,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.baseline,
                                  textBaseline: TextBaseline.alphabetic,
                                  children: [
                                    Text(
                                      '${widget.data.runs}/${widget.data.wickets}',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.lightTextPrimary,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '($oversText overs)',
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        color: AppColors.lightTextSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'RUN RATE',
                                          style: GoogleFonts.inter(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.lightTextSecondary,
                                          ),
                                        ),
                                        Text(
                                          runRate,
                                          style: GoogleFonts.inter(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.lightTextPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          'EXTRAS',
                                          style: GoogleFonts.inter(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.lightTextSecondary,
                                          ),
                                        ),
                                        Text(
                                          '${widget.data.extraRuns}',
                                          style: GoogleFonts.inter(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.lightTextPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Scorer assignment — available for signed-in players.
                  // Guests score themselves offline without handover.
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '2nd Innings Scorer:',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.bold,
                          color: AppColors.lightTextPrimary,
                        ),
                      ),
                      if (!ref.watch(profileProvider).isLoggedIn)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: Text(
                            'Myself (Active)',
                            style: GoogleFonts.plusJakartaSans(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      else
                        TextButton.icon(
                          onPressed: _handleAssignScorer,
                          icon: const Icon(
                            Icons.person_add,
                            size: 16,
                            color: AppColors.primary,
                          ),
                          label: Text(
                            _newScorerName ?? 'Assign Scorer',
                            style: GoogleFonts.plusJakartaSans(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Batting Performance
                  Text(
                    'Batting Performance',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFECEEF1)),
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Text(
                                  'BATTER',
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.lightTextSecondary,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  'R',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.lightTextSecondary,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  'B',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.lightTextSecondary,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  '4S',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.lightTextSecondary,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  '6S',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.lightTextSecondary,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Text(
                                  'SR',
                                  textAlign: TextAlign.right,
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.lightTextSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1, color: Color(0xFFECEEF1)),
                        ...widget.data.topBatters.map(
                          (b) => Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    b.name + (b.isOut ? '' : '*'),
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.bold,
                                      color: b.isOut
                                          ? AppColors.lightTextPrimary
                                          : AppColors.primary,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    '${b.runs}',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.bold,
                                      color: b.isOut
                                          ? AppColors.lightTextPrimary
                                          : AppColors.primary,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    '${b.balls}',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.inter(
                                      color: AppColors.lightTextSecondary,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    '${b.fours}',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.inter(
                                      color: AppColors.lightTextSecondary,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    '${b.sixes}',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.inter(
                                      color: AppColors.lightTextSecondary,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 1,
                                  child: Text(
                                    b.strikeRate.toStringAsFixed(1),
                                    textAlign: TextAlign.right,
                                    style: GoogleFonts.inter(
                                      color: AppColors.lightTextSecondary,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Match Statistics
                  Text(
                    'Match Statistics',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFECEEF1)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatCol('EXTRAS', '${widget.data.extraRuns}'),
                        Container(
                          width: 1,
                          height: 30,
                          color: const Color(0xFFECEEF1),
                        ),
                        _buildStatCol('FOURS', '${widget.data.totalFours}'),
                        Container(
                          width: 1,
                          height: 30,
                          color: const Color(0xFFECEEF1),
                        ),
                        _buildStatCol('SIXES', '${widget.data.totalSixes}'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Top Bowlers
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Top Bowlers (${widget.data.fieldingTeam})',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.lightTextPrimary,
                        ),
                      ),
                      GestureDetector(
                        onTap: _showAllBowlersDialog,
                        child: Text(
                          'VIEW ALL',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFECEEF1)),
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Text(
                                  'BOWLER',
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.lightTextSecondary,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  'O',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.lightTextSecondary,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  'M',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.lightTextSecondary,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  'R',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.lightTextSecondary,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  'W',
                                  textAlign: TextAlign.right,
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.lightTextSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1, color: Color(0xFFECEEF1)),
                        ...widget.data.topBowlers.map(
                          (b) => Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    b.name,
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.darkSurface,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    b.oversDisplay,
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.inter(
                                      color: AppColors.lightTextSecondary,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    '${b.maidens}',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.inter(
                                      color: AppColors.lightTextSecondary,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    '${b.runsConceded}',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.inter(
                                      color: AppColors.lightTextSecondary,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    '${b.wickets}',
                                    textAlign: TextAlign.right,
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
          // Bottom Button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Color.fromRGBO(26, 33, 56, 0.08),
                  blurRadius: 16,
                  offset: Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // "Continue as Scorer" — always available
                  SizedBox(
                    width: double.infinity,
                    height: !ref.watch(profileProvider).isLoggedIn ? 52 : 48,
                    child: !ref.watch(profileProvider).isLoggedIn
                        ? ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 3,
                            ),
                            onPressed: _handleContinueAsScorer,
                            icon: const Icon(Icons.play_arrow, size: 20, color: Colors.white),
                            label: Text(
                              'CONTINUE AS SCORER',
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                letterSpacing: 0.5,
                              ),
                            ),
                          )
                        : OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              side: const BorderSide(color: Color(0xFFECEEF1)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: _handleContinueAsScorer,
                            icon: const Icon(Icons.play_arrow, size: 20),
                            label: Text(
                              'CONTINUE AS SCORER',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                  ),
                  // "Assign Scorer" — enabled for signed-in players
                  if (ref.watch(profileProvider).isLoggedIn) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 3,
                        ),
                        onPressed: _handleAssignScorer,
                        icon: const Icon(
                          Icons.person_add_alt_1,
                          color: Colors.white,
                        ),
                        label: Text(
                          'ASSIGN SCORER',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCol(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: AppColors.lightTextSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.lightTextPrimary,
          ),
        ),
      ],
    );
  }
}
