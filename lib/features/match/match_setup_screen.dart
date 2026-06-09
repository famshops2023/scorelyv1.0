import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/player_setup.dart';

class MatchSetupData {
  final String teamAName;
  final String teamBName;
  final List<PlayerSetupData> teamAPlayers;
  final List<PlayerSetupData> teamBPlayers;
  final int overs;
  final String tossWonBy;
  final int maxOversPerBowler;
  final int powerplayOvers;
  final String battingFirstTeam;

  const MatchSetupData({
    required this.teamAName,
    required this.teamBName,
    required this.teamAPlayers,
    required this.teamBPlayers,
    required this.overs,
    required this.tossWonBy,
    required this.maxOversPerBowler,
    required this.powerplayOvers,
    required this.battingFirstTeam,
  });
}

class MatchSetupScreen extends StatefulWidget {
  final Map<String, dynamic>? initialData;
  const MatchSetupScreen({super.key, this.initialData});

  @override
  State<MatchSetupScreen> createState() => _MatchSetupScreenState();
}

class _MatchSetupScreenState extends State<MatchSetupScreen> {
  late TextEditingController _teamAController;
  late TextEditingController _teamBController;
  List<PlayerSetupData> _teamAPlayers = [];
  List<PlayerSetupData> _teamBPlayers = [];

  int _overs = 20;
  String _tossWonBy = 'TEAM A';
  String _tossDecision = 'BATTING';
  int _maxOversPerBowler = 4;
  int _powerplayOvers = 6;
  String _ballType = 'LEATHER';

  @override
  void initState() {
    super.initState();
    _teamAController = TextEditingController(text: widget.initialData?['teamAName'] ?? '');
    _teamBController = TextEditingController(text: widget.initialData?['teamBName'] ?? '');
    _teamAPlayers = widget.initialData?['teamAPlayers'] ?? [];
    _teamBPlayers = widget.initialData?['teamBPlayers'] ?? [];
  }

  void _updateDependentOvers() {
    setState(() {
      int maxOvers = (_overs / 5).ceil();
      if (_overs < 5) maxOvers = 1;
      _maxOversPerBowler = maxOvers;

      int powerplay = (_overs * 0.3).ceil();
      _powerplayOvers = powerplay;
    });
  }

  @override
  void dispose() {
    _teamAController.dispose();
    _teamBController.dispose();
    super.dispose();
  }

  void _startMatch() {
    final String teamAName = _teamAController.text.trim().isNotEmpty ? _teamAController.text.trim() : 'Team A';
    final String teamBName = _teamBController.text.trim().isNotEmpty ? _teamBController.text.trim() : 'Team B';

    String battingFirstTeam;
    if (_tossWonBy == 'TEAM A') {
      battingFirstTeam = _tossDecision == 'BATTING' ? teamAName : teamBName;
    } else {
      battingFirstTeam = _tossDecision == 'BATTING' ? teamBName : teamAName;
    }

    final data = MatchSetupData(
      teamAName: teamAName,
      teamBName: teamBName,
      teamAPlayers: _teamAPlayers,
      teamBPlayers: _teamBPlayers,
      overs: _overs,
      tossWonBy: _tossWonBy == 'TEAM A' ? teamAName : teamBName,
      maxOversPerBowler: _maxOversPerBowler,
      powerplayOvers: _powerplayOvers,
      battingFirstTeam: battingFirstTeam,
    );
    context.push('/match-details', extra: data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF191C1E),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () {},
        ),
        title: Text(
          'MATCH SETUP',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: 1.0,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('TEAM SELECTION'),
            const SizedBox(height: 12),
            _buildTeamInput('TEAM A', 'Home Team Name', _teamAController, true),
            const SizedBox(height: 12),
            _buildTeamInput('TEAM B', 'Away Team Name', _teamBController, false),
            const SizedBox(height: 24),

            _buildSectionTitle('OVERS'),
            const SizedBox(height: 12),
            _buildOversCard(),
            const SizedBox(height: 12),
            _buildOversChips(),
            const SizedBox(height: 24),

            _buildSectionTitle('COIN TOSS WINNER'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildTossCard('TEAM A', Icons.workspace_premium)),
                const SizedBox(width: 12),
                Expanded(child: _buildTossCard('TEAM B', Icons.stadium_outlined)),
              ],
            ),
            const SizedBox(height: 16),
            
            Center(child: _buildSectionTitle('DECIDED TO')),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildDecisionButton('BATTING')),
                const SizedBox(width: 12),
                Expanded(child: _buildDecisionButton('BOWLING')),
              ],
            ),
            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                  child: _buildCounterCard('OVERS/BOWLER', _maxOversPerBowler, (val) {
                    setState(() => _maxOversPerBowler = val);
                  }),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildCounterCard('POWERPLAY', _powerplayOvers, (val) {
                    setState(() => _powerplayOvers = val);
                  }),
                ),
              ],
            ),
            const SizedBox(height: 24),

            _buildSectionTitle('BALL TYPE'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildBallChip('LEATHER', Icons.sports_baseball)),
                const SizedBox(width: 8),
                Expanded(child: _buildBallChip('TENNIS', Icons.sports_tennis)),
                const SizedBox(width: 8),
                Expanded(child: _buildBallChip('TAPE', Icons.texture)),
              ],
            ),
            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _startMatch,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFBA0013),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 4,
                  shadowColor: const Color(0xFFBA0013).withValues(alpha: 0.4),
                ),
                icon: const Icon(Icons.play_arrow, color: Colors.white, size: 20),
                label: Text(
                  'START MATCH',
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
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF575D78),
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _buildTeamInput(String title, String hint, TextEditingController controller, bool isTeamA) {
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
      child: Row(
        children: [
          Container(
            width: 4,
            height: 70,
            decoration: BoxDecoration(
              color: isTeamA ? const Color(0xFFBA0013) : const Color(0xFF191C1E),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: isTeamA ? const Color(0xFFBA0013) : const Color(0xFF191C1E),
                    ),
                  ),
                  TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      hintText: hint,
                      hintStyle: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFFBFC5E4),
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.only(top: 4),
                    ),
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF191C1E),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(right: 16),
            child: Icon(Icons.sports_cricket, color: Color(0xFFBFC5E4), size: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildOversCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () {
              if (_overs > 1) {
                setState(() => _overs--);
                _updateDependentOvers();
              }
            },
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFECEEF1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.remove, color: Color(0xFF191C1E)),
            ),
          ),
          Column(
            children: [
              Text(
                _overs.toString(),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 48,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF191C1E),
                  height: 1.0,
                ),
              ),
              Text(
                'overs',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFFBFC5E4),
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: () {
              setState(() => _overs++);
              _updateDependentOvers();
            },
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFBA0013),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFBA0013).withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.add, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOversChips() {
    return Row(
      children: [5, 10, 20, 50].map((val) {
        bool isSelected = _overs == val;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() => _overs = val);
              _updateDependentOvers();
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFBA0013) : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? const Color(0xFFBA0013) : const Color(0xFFECEEF1),
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: const Color(0xFFBA0013).withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        )
                      ]
                    : [],
              ),
              alignment: Alignment.center,
              child: Text(
                val.toString(),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : const Color(0xFF191C1E),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTossCard(String teamName, IconData icon) {
    bool isSelected = _tossWonBy == teamName;
    return GestureDetector(
      onTap: () => setState(() => _tossWonBy = teamName),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF191C1E) : Colors.transparent,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFECEEF1) : const Color(0xFFF7F9FC),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 28,
                color: isSelected ? const Color(0xFF191C1E) : const Color(0xFFBFC5E4),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              teamName,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isSelected ? const Color(0xFF191C1E) : const Color(0xFFBFC5E4),
              ),
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
          color: isSelected ? const Color(0xFFBA0013) : const Color(0xFFECEEF1),
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          decision,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : const Color(0xFF575D78),
          ),
        ),
      ),
    );
  }

  Widget _buildCounterCard(String title, int value, Function(int) onChanged) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF575D78),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () {
                  if (value > 1) onChanged(value - 1);
                },
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: Color(0xFFECEEF1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.remove, size: 16, color: Color(0xFF191C1E)),
                ),
              ),
              Text(
                value.toString(),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF191C1E),
                ),
              ),
              GestureDetector(
                onTap: () => onChanged(value + 1),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: Color(0xFFECEEF1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add, size: 16, color: Color(0xFF191C1E)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBallChip(String type, IconData icon) {
    bool isSelected = _ballType == type;
    return GestureDetector(
      onTap: () => setState(() => _ballType = type),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF191C1E) : const Color(0xFFECEEF1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : const Color(0xFF575D78),
            ),
            const SizedBox(width: 6),
            Text(
              type,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : const Color(0xFF575D78),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return LayoutBuilder(
      builder: (context, _) {
        final bottomInset = MediaQuery.of(context).viewPadding.bottom;
        return Container(
          height: 70 + bottomInset,
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFECEEF1), width: 1)),
          ),
          child: Padding(
            padding: EdgeInsets.only(bottom: bottomInset),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(Icons.home_outlined, 'Home', true),
                _buildNavItem(Icons.groups_outlined, 'Teams', false),
                _buildNavItem(Icons.history, 'History', false),
                _buildNavItem(Icons.person_outline, 'Profile', false),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isSelected) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          color: isSelected ? const Color(0xFFBA0013) : const Color(0xFF575D78),
          size: 24,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? const Color(0xFFBA0013) : const Color(0xFF575D78),
          ),
        ),
      ],
    );
  }
}
