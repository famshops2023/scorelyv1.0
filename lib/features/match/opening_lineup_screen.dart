import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'match_setup_screen.dart';
import '../teams/providers/teams_provider.dart';

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

  const OpeningLineupScreen({
    super.key,
    required this.setupData,
    this.isSecondInnings = false,
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
    final scorerName = widget.setupData.teamBScorerName ?? widget.setupData.teamAScorerName;
    if (scorerName != null && scorerName.isNotEmpty) {
      officialScorer = TeamMember(
        id: 'official_scorer',
        name: scorerName,
        roles: ['Official Scorer'],
      );
    }
  }

  bool get _isReady {
    bool baseReady = openingBat1 != null &&
        openingBat2 != null &&
        openingBowler != null &&
        wicketKeeper != null &&
        officialScorer != null;
        
    if (widget.setupData.isQuickMatch) {
      return baseReady;
    } else {
      return baseReady && captain != null;
    }
  }

  void _proceedToScore() {
    final lineup = OpeningLineupResult(
      openingBat1: openingBat1!,
      openingBat2: openingBat2!,
      openingBowler: openingBowler!,
      wicketKeeper: wicketKeeper!,
      captain: captain,
      officialScorer: officialScorer,
    );

    if (widget.isSecondInnings) {
      Navigator.pop(context, lineup);
    } else {
      context.pushReplacement('/scoring', extra: {
        'setupData': widget.setupData,
        'lineup': lineup,
      });
    }
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
            case 'Official Scorer':
              officialScorer = selectedPlayer;
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
          backgroundColor: const Color(0xFFBA0013),
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
          case 'Official Scorer':
            officialScorer = selectedPlayer;
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
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A2138), // Header background color from comments
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
                  color: const Color(0xFF575D78),
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
                  _buildRoleCard(
                    title: 'OPENING BAT 1',
                    icon: Icons.sports_cricket,
                    player: openingBat1,
                    onSelect: () => _selectPlayer('Opening Bat 1', battingTeam),
                  ),
                  _buildRoleCard(
                    title: 'OPENING BAT 2',
                    icon: Icons.sports_cricket,
                    player: openingBat2,
                    onSelect: () => _selectPlayer('Opening Bat 2', battingTeam),
                  ),
                  _buildRoleCard(
                    title: 'OPENING BOWLER',
                    icon: Icons.sports_baseball,
                    player: openingBowler,
                    onSelect: () => _selectPlayer('Opening Bowler', bowlingTeam),
                  ),
                  _buildRoleCard(
                    title: 'WICKETKEEPER',
                    icon: Icons.sports_handball, // Fallback icon for wicketkeeper
                    player: wicketKeeper,
                    onSelect: () => _selectPlayer('Wicketkeeper', bowlingTeam),
                  ),
                  if (!widget.setupData.isQuickMatch)
                    _buildRoleCard(
                      title: 'CAPTAIN',
                      icon: Icons.stars,
                      player: captain,
                      onSelect: () => _selectPlayer('Captain', battingTeam), // Either team could have a captain, default to batting
                    ),
                  _buildRoleCard(
                    title: 'OFFICIAL SCORER',
                    icon: Icons.description,
                    player: officialScorer,
                    onSelect: () => _selectPlayer('Official Scorer', battingTeam), // Scorer could be from any team or not in squad
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
                          color: const Color(0xFF575D78),
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
                    backgroundColor: const Color(0xFFBA0013),
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

  Widget _buildRoleCard({
    required String title,
    required IconData icon,
    TeamMember? player,
    required VoidCallback onSelect,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF575D78),
              ),
            ),
          ),
          const Spacer(),
          if (player == null)
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: Color(0xFFF2F4F8),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: const Color(0xFFBA0013), size: 24),
            )
          else
            Column(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: const Color(0xFF191C1E),
                  child: Text(
                    player.name[0].toUpperCase(),
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  player.name,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF191C1E),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 36,
            child: TextButton(
              onPressed: onSelect,
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFFF2F4F8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                player == null ? 'SELECT' : 'CHANGE',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFBA0013),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
