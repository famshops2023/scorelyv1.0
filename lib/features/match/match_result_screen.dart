import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'dart:math';

import '../../models/match_result_data.dart';
import '../teams/providers/teams_provider.dart';
import 'match_setup_screen.dart';

import 'package:share_plus/share_plus.dart';

class MatchResultScreen extends ConsumerStatefulWidget {
  final MatchResultData resultData;

  const MatchResultScreen({super.key, required this.resultData});

  @override
  ConsumerState<MatchResultScreen> createState() => _MatchResultScreenState();
}

class _MatchResultScreenState extends ConsumerState<MatchResultScreen> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 5),
    );
    if (widget.resultData.winningTeam != null) {
      _confettiController.play();
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Path drawStar(Size size) {
    // Method to convert degree to radians
    double degToRad(double deg) => deg * (pi / 180.0);

    const numberOfPoints = 5;
    final halfWidth = size.width / 2;
    final externalRadius = halfWidth;
    final internalRadius = halfWidth / 2.5;
    final degreesPerStep = degToRad(360 / numberOfPoints);
    final halfDegreesPerStep = degreesPerStep / 2;
    final path = Path();
    final fullAngle = degToRad(360);
    path.moveTo(size.width, halfWidth);

    for (double step = 0; step < fullAngle; step += degreesPerStep) {
      path.lineTo(
        halfWidth + externalRadius * cos(step),
        halfWidth + externalRadius * sin(step),
      );
      path.lineTo(
        halfWidth + internalRadius * cos(step + halfDegreesPerStep),
        halfWidth + internalRadius * sin(step + halfDegreesPerStep),
      );
    }
    path.close();
    return path;
  }

  @override
  Widget build(BuildContext context) {
    final teams = ref.watch(teamsProvider).value ?? [];
    final winningTeamName = widget.resultData.winningTeam;
    final winningTeam = teams.firstWhere(
      (t) => t.name.toLowerCase() == winningTeamName?.toLowerCase(),
      orElse: () => TeamData(id: '', name: '', location: '', dateActive: DateTime.now(), members: []),
    );
    final String? logoUrl = winningTeam.id.isNotEmpty ? winningTeam.logoUrl : null;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1a2238),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        title: Text(
          '${widget.resultData.team1Name} vs ${widget.resultData.team2Name}',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.only(left: 20, right: 20, top: 24, bottom: 120),
              child: Column(
                children: [
                  _buildCelebrationCard(logoUrl),
                  const SizedBox(height: 24),
                  _buildSummaryStatsGrid(),
                  const SizedBox(height: 24),
                  _buildActionButtons(context),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [
                Colors.green,
                Colors.blue,
                Colors.pink,
                Colors.orange,
                Colors.purple,
                Color(0xFFBA0013),
              ],
              createParticlePath: drawStar,
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomNav(),
          ),
        ],
      ),
    );
  }

  Widget _buildCelebrationCard(String? logoUrl) {
    final hasWinner = widget.resultData.winningTeam != null;
    final winnerName = widget.resultData.winningTeam ?? 'DRAW';
    // Use tournament format or default
    final tournamentName = widget.resultData.format.isNotEmpty ? widget.resultData.format : 'Match Result';
    final resultText = widget.resultData.matchStatusText.replaceAll('\n', ' ');

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBA0013), width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(26, 33, 56, 0.08),
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Red Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFBA0013),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
              ),
            ),
            child: Column(
              children: [
                Text(
                  hasWinner ? 'VICTORY!' : 'MATCH TIED!',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    fontStyle: FontStyle.italic,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  tournamentName,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        widget.resultData.ballType.toUpperCase(),
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        widget.resultData.format.toUpperCase(),
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Body
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
            child: Column(
              children: [
                // Logo & Trophy Badge
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      width: 128,
                      height: 128,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFFFDAD6), width: 4),
                        color: const Color(0xFFE0E3E6),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          )
                        ],
                      ),
                      child: ClipOval(
                        child: logoUrl != null
                            ? Image.network(
                                logoUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(Icons.sports_cricket, size: 64, color: Colors.grey);
                                },
                              )
                            : Image.asset(
                                'assets/images/scorely_icon.png',
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(Icons.sports_cricket, size: 64, color: Colors.grey);
                                },
                              ),
                      ),
                    ),
                    Positioned(
                      bottom: -8,
                      right: -8,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFBA0013),
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 5,
                            )
                          ],
                        ),
                        child: const Icon(Icons.emoji_events, color: Colors.white, size: 24),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                Text(
                  winnerName.toUpperCase(),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF191C1E),
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 12),
                
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFBA0013).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    resultText,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF5D3F3C),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryStatsGrid() {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: const Border(left: BorderSide(color: Color(0xFFBA0013), width: 4)),
              boxShadow: const [
                BoxShadow(
                  color: Color.fromRGBO(26, 33, 56, 0.08),
                  blurRadius: 20,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.resultData.innings1Team.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFBA0013),
                    letterSpacing: 0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      widget.resultData.innings1Score.split('/').first,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF191C1E),
                      ),
                    ),
                    Text(
                      '/${widget.resultData.innings1Score.split('/').last}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF575D78),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${widget.resultData.innings1Overs} OVERS',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF5D3F3C),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: const Border(left: BorderSide(color: Color(0xFF575D78), width: 4)),
              boxShadow: const [
                BoxShadow(
                  color: Color.fromRGBO(26, 33, 56, 0.08),
                  blurRadius: 20,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.resultData.innings2Team.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF575D78),
                    letterSpacing: 0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      widget.resultData.innings2Score.split('/').first,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF191C1E),
                      ),
                    ),
                    Text(
                      '/${widget.resultData.innings2Score.split('/').last}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF575D78),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${widget.resultData.innings2Overs} OVERS',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF5D3F3C),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: () {
              final winnerName = widget.resultData.winningTeam ?? 'The team';
              final team1 = widget.resultData.innings1Team;
              final team2 = widget.resultData.innings2Team;
              final score1 = widget.resultData.innings1Score;
              final score2 = widget.resultData.innings2Score;
              final overs1 = widget.resultData.innings1Overs;
              final overs2 = widget.resultData.innings2Overs;
              final format = widget.resultData.format;
              final venue = widget.resultData.venue;
              final status = widget.resultData.matchStatusText.replaceAll('\n', ' ');

              final shareText =
                  '🏏 Match Result – Scorely\n\n'
                  '$team1 vs $team2\n'
                  '📍 $venue | $format\n\n'
                  '1st Innings: $team1  $score1 ($overs1)\n'
                  '2nd Innings: $team2  $score2 ($overs2)\n\n'
                  '🏆 $winnerName $status\n\n'
                  'Track live cricket scores with Scorely!';

              SharePlus.instance.share(ShareParams(text: shareText));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFBA0013),
              elevation: 4,
              shadowColor: const Color(0xFFBA0013).withValues(alpha: 0.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.share, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text(
                  'SHARE VICTORY',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: () {
              // Capture the parent context (MatchResultScreen) before showing dialog
              final parentContext = context;
              showDialog(
                context: context,
                builder: (_) => CloneSetupDialog(
                  previousSetup: widget.resultData.setupData,
                  ref: ref,
                  parentContext: parentContext,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Color(0xFFD8DADD), width: 1.5),
              ),
            ),
            child: Text(
              'START NEW MATCH',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1A2138),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        boxShadow: [
          BoxShadow(
            color: Color.fromRGBO(26, 33, 56, 0.08),
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.analytics_outlined, 'Summary', isActive: true, onTap: () {
                context.go('/match-stats', extra: {
                  'matchId': widget.resultData.matchId,
                  'initialIndex': 3,
                });
              }),
              _buildNavItem(Icons.sports_cricket_outlined, 'Scoreboard', onTap: () {
                context.go('/match-stats', extra: {
                  'matchId': widget.resultData.matchId,
                  'initialIndex': 1,
                });
              }),
              _buildNavItem(Icons.groups_outlined, 'Squad', onTap: () {
                context.go('/match-stats', extra: {
                  'matchId': widget.resultData.matchId,
                  'initialIndex': 2,
                });
              }),
              _buildNavItem(Icons.home_outlined, 'Home', onTap: () {
                context.go('/home');
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, {bool isActive = false, VoidCallback? onTap}) {
    final color = isActive ? const Color(0xFFBA0013) : const Color(0xFF575D78);
    
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: isActive ? BoxDecoration(
          color: const Color(0xFFBA0013).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ) : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CloneSetupDialog extends StatefulWidget {
  final MatchSetupData? previousSetup;
  final WidgetRef ref;
  /// The BuildContext of the parent screen (MatchResultScreen).
  /// Navigation must be performed using this context because the dialog
  /// context becomes invalid after Navigator.pop().
  final BuildContext parentContext;

  const CloneSetupDialog({
    super.key,
    required this.previousSetup,
    required this.ref,
    required this.parentContext,
  });

  @override
  State<CloneSetupDialog> createState() => _CloneSetupDialogState();
}

class _CloneSetupDialogState extends State<CloneSetupDialog> {
  bool _matchSetupChecked = true;
  bool _teamSquadChecked = true;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Circle Icon
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: Color(0xFFFDEBED),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.assignment_outlined,
                color: Color(0xFFBA0013),
                size: 32,
              ),
            ),
            const SizedBox(height: 20),
            // Title
            Text(
              'CLONE PREVIOUS SETUP?',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF191C1E),
                letterSpacing: -0.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            // Subtitle
            Text(
              'Would you like to use the settings and squads from your last match?',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF575D78),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            // Option 1: Match Setup
            _buildOptionCard(
              title: 'Match Setup',
              description: 'Overs, ball type, match format',
              icon: Icons.settings_outlined,
              isSelected: _matchSetupChecked,
              onTap: () {
                setState(() {
                  _matchSetupChecked = !_matchSetupChecked;
                });
              },
            ),
            const SizedBox(height: 12),
            // Option 2: Team Squad
            _buildOptionCard(
              title: 'Team Squad',
              description: 'Players list and assigned roles',
              icon: Icons.people_outline,
              isSelected: _teamSquadChecked,
              onTap: () {
                setState(() {
                  _teamSquadChecked = !_teamSquadChecked;
                });
              },
            ),
            const SizedBox(height: 32),
            // Bottom Action Buttons
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFD8DADD), width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'CANCEL',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF575D78),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _handleCloneAction();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFBA0013),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'CLONE SETUP',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required String title,
    required String description,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F9FC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFFBA0013) : const Color(0xFFECEEF1),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: const Color(0xFF575D78), size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF191C1E),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF8E95A5),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
              color: isSelected ? const Color(0xFFBA0013) : const Color(0xFFD8DADD),
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  void _handleCloneAction() {
    // IMPORTANT: Use widget.parentContext for all navigation.
    // This dialog's own `context` is unmounted after Navigator.pop() is called
    // just before this method runs, so any context.push/go here would silently fail.
    final navContext = widget.parentContext;
    final setup = widget.previousSetup;

    if (setup == null) {
      navContext.go('/home');
      return;
    }

    if (_matchSetupChecked && _teamSquadChecked) {
      // Both checked: Go to Toss carrying the cloned setup & squads
      final newSetup = setup.copyWith(
        id: const Uuid().v4(),
        status: 'draft',
        tossWonBy: '',
        battingFirstTeam: '',
      );
      navContext.push('/toss', extra: newSetup);
    } else if (!_matchSetupChecked && _teamSquadChecked) {
      // Team Squad checked, Match Setup unchecked: go to Match Setup pre-filled to change settings
      final extraData = {
        'teamAName': setup.teamAName,
        'teamBName': setup.teamBName,
        'teamAPlayers': setup.teamAPlayers,
        'teamBPlayers': setup.teamBPlayers,
        'isQuickMatch': setup.isQuickMatch,
      };
      navContext.go('/match-setup', extra: extraData);
    } else if (_matchSetupChecked && !_teamSquadChecked) {
      // Match Setup checked, Team Squad unchecked: reset players
      final newSetup = setup.copyWith(
        id: const Uuid().v4(),
        status: 'draft',
        tossWonBy: '',
        battingFirstTeam: '',
        teamAPlayers: [],
        teamBPlayers: [],
      );

      if (setup.isQuickMatch) {
        navContext.go('/create-team', extra: {
          'isQuickMatch': true,
          'overs': setup.overs,
          'matchType': setup.matchType,
          'ballType': setup.ballType,
        });
      } else {
        // Scheduled match: go to select playing XI for team A
        final teams = widget.ref.read(teamsProvider).value ?? [];
        final teamA = teams.firstWhere(
          (t) => t.name.toLowerCase() == setup.teamAName.toLowerCase(),
          orElse: () => TeamData(id: '', name: '', location: '', dateActive: DateTime.now(), members: []),
        );
        if (teamA.id.isNotEmpty) {
          navContext.go('/team-squad', extra: {
            'teamId': teamA.id,
            'readOnly': false,
            'singleSelectionMode': false,
            'setupData': newSetup,
            'isSelectingPlayingXi': true,
            'teamType': 'A',
          });
        } else {
          // Fallback: go to Match Setup screen
          navContext.go('/match-setup', extra: newSetup.toJson());
        }
      }
    } else {
      // Both unchecked: go home
      navContext.go('/home');
    }
  }
}
