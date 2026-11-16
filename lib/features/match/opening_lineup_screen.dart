import 'package:flutter/material.dart';
import 'package:scorely/core/theme/colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'match_setup_screen.dart';
import 'widgets/match_role_card.dart';
import 'providers/pending_matches_provider.dart';
import '../teams/providers/teams_provider.dart';
import '../../providers/profile_provider.dart';

class OpeningLineupResult {
  final TeamMember openingBat1;
  final TeamMember openingBat2;
  final TeamMember openingBowler;
  final TeamMember wicketKeeper;
  final TeamMember? captain;
  final TeamMember? officialScorer;

  OpeningLineupResult({
    required this.openingBat1,
    required this.openingBat2,
    required this.openingBowler,
    required this.wicketKeeper,
    this.captain,
    this.officialScorer,
  });
}

class OpeningLineupScreen extends ConsumerStatefulWidget {
  final MatchSetupData setupData;
  final bool isSecondInnings;
  /// True when this screen is opened on the recipient's (handover) device.
  /// In this case, pressing "Start Match" must push directly to /scoring
  /// because there is no innings_break_screen on the stack waiting for a pop.
  final bool isHandoverMode;
  // 1st innings metadata forwarded to ScoringScreen
  final int? firstInningsRuns;
  final int? firstInningsWickets;
  final String? firstInningsBattingTeam;
  final String? firstInningsOvers;
  final int? firstInningsBalls;
  final int? target;

  const OpeningLineupScreen({
    super.key,
    required this.setupData,
    this.isSecondInnings = false,
    this.isHandoverMode = false,
    this.firstInningsRuns,
    this.firstInningsWickets,
    this.firstInningsBattingTeam,
    this.firstInningsOvers,
    this.firstInningsBalls,
    this.target,
  });

  @override
  ConsumerState<OpeningLineupScreen> createState() => _OpeningLineupScreenState();
}

class _OpeningLineupScreenState extends ConsumerState<OpeningLineupScreen> {
  TeamMember? openingBat1;
  TeamMember? openingBat2;
  TeamMember? openingBowler;
  TeamMember? wicketKeeper;
  TeamMember? captain;
  TeamMember? officialScorer;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(profileProvider);
    final scorerName = widget.setupData.teamBScorerName ??
        widget.setupData.teamAScorerName ??
        (profile.name.isNotEmpty ? profile.name : 'Scorer (Myself)');
    final scorerId = widget.setupData.teamBScorerId ??
        widget.setupData.teamAScorerId ??
        (profile.id.isNotEmpty ? profile.id : 'scorer_myself');

    officialScorer = TeamMember(
      id: scorerId,
      profileId: scorerId,
      name: scorerName,
      roles: const ['Official Scorer'],
    );
  }

  bool get _isReady {
    bool baseReady = openingBat1 != null &&
        openingBat2 != null &&
        openingBowler != null &&
        wicketKeeper != null &&
        officialScorer != null;

    if (widget.setupData.isQuickMatch || widget.isSecondInnings) {
      return baseReady;
    } else {
      return baseReady && captain != null;
    }
  }

  Future<void> _proceedToScore() async {
    final lineup = OpeningLineupResult(
      openingBat1: openingBat1!,
      openingBat2: openingBat2!,
      openingBowler: openingBowler!,
      wicketKeeper: wicketKeeper!,
      captain: captain,
      officialScorer: officialScorer,
    );

    final profile = ref.read(profileProvider);
    final matchId = widget.setupData.id;
    final scorerProfileId = officialScorer?.profileId ?? officialScorer?.id ?? '';
    final isSignedIn = profile.isLoggedIn && profile.id.isNotEmpty;
    final isGuestScorer = scorerProfileId == 'scorer_myself' ||
        scorerProfileId.isEmpty ||
        !isSignedIn;
    final isOfficialScorer = isSignedIn &&
        (scorerProfileId == profile.id || isGuestScorer);

    if (matchId.isNotEmpty) {
      if (widget.setupData.isQuickMatch) {
        // Quick match for signed-in user: transition to live atomically on InsForge
        if (isSignedIn) {
          final effectiveScorerId = (officialScorer?.profileId != null &&
                  officialScorer!.profileId!.isNotEmpty &&
                  officialScorer!.profileId != 'scorer_myself')
              ? officialScorer!.profileId!
              : profile.id;
          final effectiveScorerName = officialScorer?.name ?? profile.name;
          await ref.read(pendingMatchesProvider.notifier).markLive(
                matchId,
                scorerId: effectiveScorerId,
                scorerName: effectiveScorerName,
              );
        }
        // Guest quick matches stay local without server requirement
      } else {
        if (!isSignedIn) {
          _showScorerOnlyDialog(
            'Please sign in to start a live match. Guest matches stay offline.',
          );
          return;
        }
        if (!isOfficialScorer) {
          _showScorerOnlyDialog(
            'Only the assigned official scorer can start scoring. '
            'The scorer request has been sent to the selected player.',
          );
          return;
        }

        // This is the ONLY place a match becomes live: the signed-in official
        // scorer has completed the Opening Lineup and explicitly proceeded.
        final wentLive = await ref.read(pendingMatchesProvider.notifier).markLive(
              matchId,
              scorerId: profile.id,
              scorerName: profile.name,
            );
        if (!mounted) return;
        if (!wentLive) {
          _showScorerOnlyDialog(
            'Could not start scoring. You are not the active scorer for this '
            'match, or the connection was lost. Please check your connection '
            'and try again.',
          );
          return;
        }
      }
    }

    if (!mounted) return;
    if (widget.isSecondInnings && widget.isHandoverMode) {
      // Recipient (handover) device: no innings_break_screen on the stack.
      // Navigate directly to the scoring screen for 2nd innings.
      context.pushReplacement('/scoring', extra: <String, dynamic>{
        'setupData': widget.setupData,
        'lineup': lineup,
        'isSecondInnings': true,
        // Forward 1st innings metadata so the scoring screen shows the correct target
        'firstInningsRuns': widget.firstInningsRuns,
        'firstInningsWickets': widget.firstInningsWickets,
        'firstInningsBattingTeam': widget.firstInningsBattingTeam,
        'firstInningsOvers': widget.firstInningsOvers,
        'firstInningsBalls': widget.firstInningsBalls,
        'target': widget.target,
      });
    } else if (widget.isSecondInnings) {
      // Normal flow: innings_break_screen is on the stack, pop back to it.
      Navigator.pop(context, lineup);
    } else {
      context.pushReplacement('/scoring', extra: <String, dynamic>{
        'setupData': widget.setupData,
        'lineup': lineup,
      });
    }
  }

  void _showScorerOnlyDialog(String message) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'OFFICIAL SCORER ONLY',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
        content: Text(
          message,
          style: GoogleFonts.inter(fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              'OK',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectPlayer(String role, String targetTeamName) async {
    if (widget.setupData.isQuickMatch) {
      final selectedPlayer = await context.push<TeamMember?>(
        '/team-squad',
        extra: {
          'teamId': '', // Not used for Quick Match
          'readOnly': false,
          'singleSelectionMode': true,
          'setupData': widget.setupData,
          'teamType': targetTeamName,
        },
      );

      if (selectedPlayer != null) {
        setState(() {
          switch (role) {
            case 'Opening Bat 1':
              openingBat1 = selectedPlayer;
              break;
            case 'Opening Bat 2':
              openingBat2 = selectedPlayer;
              break;
            case 'Opening Bowler':
              openingBowler = selectedPlayer;
              break;
            case 'Wicketkeeper':
              wicketKeeper = selectedPlayer;
              break;
            case 'Captain':
              captain = selectedPlayer;
              break;
          }
        });
      }
      return;
    }

    final teams = ref.read(teamsProvider).value ?? [];

    final team = teams.firstWhere(
      (t) => t.name == targetTeamName,
      orElse: () => TeamData(
        id: '',
        name: '',
        location: '',
        dateActive: DateTime.now(),
        members: [],
      ),
    );

    if (team.id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Team "$targetTeamName" not found in database.'),
          backgroundColor: AppColors.primary,
        ),
      );
      return;
    }

    final selectedPlayer = await context.push<TeamMember?>(
      '/team-squad',
      extra: {
        'teamId': team.id,
        'readOnly': false,
        'singleSelectionMode': true,
      },
    );

    if (selectedPlayer != null) {
      setState(() {
        switch (role) {
          case 'Opening Bat 1':
            openingBat1 = selectedPlayer;
            break;
          case 'Opening Bat 2':
            openingBat2 = selectedPlayer;
            break;
          case 'Opening Bowler':
            openingBowler = selectedPlayer;
            break;
          case 'Wicketkeeper':
            wicketKeeper = selectedPlayer;
            break;
          case 'Captain':
            captain = selectedPlayer;
            break;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final String battingTeam;
    final String bowlingTeam;

    if (widget.isSecondInnings) {
      battingTeam = widget.setupData.teamAName == widget.setupData.battingFirstTeam
          ? widget.setupData.teamBName
          : widget.setupData.teamAName;
      bowlingTeam = widget.setupData.battingFirstTeam;
    } else {
      battingTeam = widget.setupData.battingFirstTeam;
      bowlingTeam = widget.setupData.teamAName == battingTeam
          ? widget.setupData.teamBName
          : widget.setupData.teamAName;
    }

    return Scaffold(
      backgroundColor: AppColors.lightBg,
      appBar: AppBar(
        backgroundColor: AppColors.darkSurface, // Header background color from comments
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(
          widget.isSecondInnings ? '2ND INNINGS OPENING LINEUP' : 'OPENING LINEUP',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: 1.0,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Text(
                'SET YOUR KEY MATCH PERSONNEL',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.lightTextSecondary,
                  letterSpacing: 1.0,
                ),
              ),
            ),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.85,
                children: [
                  MatchRoleCard(
                    title: 'OPENING BAT 1',
                    icon: Icons.sports_cricket,
                    player: openingBat1,
                    onSelect: () => _selectPlayer('Opening Bat 1', battingTeam),
                  ),
                  MatchRoleCard(
                    title: 'OPENING BAT 2',
                    icon: Icons.sports_cricket,
                    player: openingBat2,
                    onSelect: () => _selectPlayer('Opening Bat 2', battingTeam),
                  ),
                  MatchRoleCard(
                    title: 'OPENING BOWLER',
                    icon: Icons.sports_baseball,
                    player: openingBowler,
                    onSelect: () => _selectPlayer('Opening Bowler', bowlingTeam),
                  ),
                  MatchRoleCard(
                    title: 'WICKETKEEPER',
                    icon: Icons.sports_handball, // Fallback icon for wicketkeeper
                    player: wicketKeeper,
                    onSelect: () => _selectPlayer('Wicketkeeper', bowlingTeam),
                  ),
                  if (!widget.setupData.isQuickMatch && !widget.isSecondInnings)
                    MatchRoleCard(
                      title: 'CAPTAIN',
                      icon: Icons.stars,
                      player: captain,
                      onSelect: () => _selectPlayer('Captain', battingTeam), // Either team could have a captain, default to batting
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F4F8),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFFD6888A),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Ensure all primary roles are filled before starting the match.',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.lightTextSecondary,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isReady ? _proceedToScore : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: const Color(0xFFD6888A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: _isReady ? 4 : 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'PROCEED TO SCORE',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.keyboard_double_arrow_right, color: Colors.white, size: 24),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

}
