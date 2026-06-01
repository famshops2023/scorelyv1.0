import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';
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
  late String _teamAName;
  late String _teamBName;
  late List<PlayerSetupData> _teamAPlayers;
  late List<PlayerSetupData> _teamBPlayers;

  int _overs = 20;
  String? _tossWonBy;
  String? _battingFirstTeam;
  final TextEditingController _maxOversController = TextEditingController();
  final TextEditingController _powerplayOversController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _teamAName = widget.initialData?['teamAName'] ?? 'Team Alpha';
    _teamBName = widget.initialData?['teamBName'] ?? 'Team Bravo';
    _teamAPlayers = widget.initialData?['teamAPlayers'] ?? [];
    _teamBPlayers = widget.initialData?['teamBPlayers'] ?? [];
    _tossWonBy = _teamAName;
    _battingFirstTeam = _teamAName;

    _updateDependentOvers();
  }

  void _updateDependentOvers() {
    // Default standard calculations (T20 style logic)
    int maxOvers = (_overs / 5).ceil();
    if (_overs < 5) maxOvers = 1;
    _maxOversController.text = maxOvers.toString();

    int powerplay = (_overs * 0.3).ceil(); // ~30% for powerplay
    _powerplayOversController.text = powerplay.toString();
  }

  void _setOvers(int val) {
    setState(() {
      _overs = val;
      _updateDependentOvers();
    });
  }

  @override
  void dispose() {
    _maxOversController.dispose();
    _powerplayOversController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1a2238),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Match Setup',
              style: AppTypography.headlineMedium.copyWith(color: Colors.white),
            ),
            Text(
              'Configure your match details',
              style: AppTypography.bodySmall.copyWith(color: Colors.white70),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(18.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('TEAMS'),
                  Row(
                    children: [
                      Expanded(child: _buildTeamCard(_teamAName, Colors.red)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildTeamCard(_teamBName, Colors.blue)),
                    ],
                  ),
                  const SizedBox(height: 24),

                  _buildSectionTitle('OVERS'),
                  _buildOversSection(),
                  const SizedBox(height: 24),

                  _buildSectionTitle('TOSS WON BY'),
                  _buildTossSelection(),
                  const SizedBox(height: 24),

                  _buildSectionTitle('BATTING FIRST'),
                  _buildBattingFirstSelection(),
                  const SizedBox(height: 24),

                  _buildSectionTitle('BOWLING RESTRICTIONS'),
                  _buildInputRow('Max overs per bowler:', _maxOversController),
                  const SizedBox(height: 24),

                  _buildSectionTitle('POWERPLAY OVERS'),
                  _buildInputRow(
                    'Total Powerplay overs:',
                    _powerplayOversController,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          _buildBottomButton(),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: AppTypography.labelCaps.copyWith(color: Colors.black54),
      ),
    );
  }

  Widget _buildTeamCard(String name, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
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
            width: 3,
            height: 32,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name == _teamAName ? 'TEAM A' : 'TEAM B',
                  style: AppTypography.labelCaps.copyWith(
                    color: color,
                    fontSize: 8,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  name,
                  style: AppTypography.bodyLarge.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Icon(Icons.edit, size: 13, color: Colors.grey.withValues(alpha: 0.5)),
        ],
      ),
    );
  }

  Widget _buildOversSection() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
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
              _buildRoundButton(Icons.remove, () {
                if (_overs > 1) _setOvers(_overs - 1);
              }, AppColors.surface),
              Column(
                children: [
                  Text(
                    _overs.toString(),
                    style: AppTypography.displayLarge.copyWith(
                      color: Colors.black87,
                      fontSize: 38,
                    ),
                  ),
                  Text(
                    'overs',
                    style: AppTypography.bodySmall.copyWith(color: Colors.grey),
                  ),
                ],
              ),
              _buildRoundButton(Icons.add, () {
                _setOvers(_overs + 1);
              }, Colors.red),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildOverChip(5),
            _buildOverChip(10),
            _buildOverChip(20),
            _buildOverChip(50),
          ],
        ),
      ],
    );
  }

  Widget _buildRoundButton(IconData icon, VoidCallback onTap, Color bgColor) {
    final isRed = bgColor == Colors.red;
    final isDark = bgColor == AppColors.surface;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(
          icon,
          color: isRed || isDark ? Colors.white : Colors.black87,
          size: 26,
        ),
      ),
    );
  }

  Widget _buildOverChip(int value) {
    final isSelected = _overs == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => _setOvers(value),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.red : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? Colors.red
                  : Colors.grey.withValues(alpha: 0.2),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            value.toString(),
            style: AppTypography.bodyLarge.copyWith(
              color: isSelected ? Colors.white : Colors.black87,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTossSelection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
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
          _buildTossOption(_teamAName, 'A', Colors.blue),
          Divider(height: 1, color: Colors.grey.withValues(alpha: 0.2)),
          _buildTossOption(_teamBName, 'B', Colors.green),
        ],
      ),
    );
  }

  Widget _buildTossOption(String teamName, String initial, Color color) {
    final isSelected = _tossWonBy == teamName;
    return InkWell(
      onTap: () => setState(() => _tossWonBy = teamName),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Text(
                initial,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                teamName,
                style: AppTypography.bodyLarge.copyWith(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: Colors.black87,
                ),
              ),
            ),
            if (isSelected) const Icon(Icons.check_circle, color: Colors.red),
          ],
        ),
      ),
    );
  }

  Widget _buildBattingFirstSelection() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _battingFirstTeam = _battingFirstTeam == _teamAName
              ? _teamBName
              : _teamAName;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
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
            Text(
              _battingFirstTeam ?? _teamAName,
              style: AppTypography.bodyLarge.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildInputRow(String label, TextEditingController controller) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: AppTypography.bodyLarge.copyWith(color: Colors.black87),
          ),
        ),
        SizedBox(
          width: 80,
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: AppTypography.bodyLarge.copyWith(color: Colors.black87),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: Colors.grey.withValues(alpha: 0.2),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Colors.red),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomButton() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () {
            final data = MatchSetupData(
              teamAName: _teamAName,
              teamBName: _teamBName,
              teamAPlayers: _teamAPlayers,
              teamBPlayers: _teamBPlayers,
              overs: _overs,
              tossWonBy: _tossWonBy ?? _teamAName,
              maxOversPerBowler: int.tryParse(_maxOversController.text) ?? 4,
              powerplayOvers: int.tryParse(_powerplayOversController.text) ?? 6,
              battingFirstTeam: _battingFirstTeam ?? _teamAName,
            );
            context.push('/match-details', extra: data);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.play_arrow, color: Colors.white),
              SizedBox(width: 8),
              Text(
                'Start Match',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
