import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';
import '../../models/player_setup.dart';

class CreateTeamScreen extends StatefulWidget {
  const CreateTeamScreen({super.key});

  @override
  State<CreateTeamScreen> createState() => _CreateTeamScreenState();
}

class _CreateTeamScreenState extends State<CreateTeamScreen> {
  final _teamAController = TextEditingController(text: 'Team Alpha');
  final _teamBController = TextEditingController(text: 'Team Bravo');

  int _activeTeamIndex = 0; // 0 for Team A, 1 for Team B
  final List<PlayerSetupData> _teamAPlayers = [];
  final List<PlayerSetupData> _teamBPlayers = [];

  final _playerInputController = TextEditingController();

  @override
  void dispose() {
    _teamAController.dispose();
    _teamBController.dispose();
    _playerInputController.dispose();
    super.dispose();
  }

  void _addPlayer() {
    final name = _playerInputController.text.trim();
    if (name.isNotEmpty) {
      setState(() {
        final newPlayer = PlayerSetupData(name: name);
        if (_activeTeamIndex == 0) {
          if (!_teamAPlayers.any((p) => p.name == name)) {
            _teamAPlayers.add(newPlayer);
          }
        } else {
          if (!_teamBPlayers.any((p) => p.name == name)) {
            _teamBPlayers.add(newPlayer);
          }
        }
        _playerInputController.clear();
      });
    }
  }

  void _updatePlayerRole(int index, PlayerRole role) {
    setState(() {
      if (_activeTeamIndex == 0) {
        _teamAPlayers[index] = _teamAPlayers[index].copyWith(role: role);
      } else {
        _teamBPlayers[index] = _teamBPlayers[index].copyWith(role: role);
      }
    });
  }

  void _setCaptain(int index) {
    setState(() {
      if (_activeTeamIndex == 0) {
        for (int i = 0; i < _teamAPlayers.length; i++) {
          _teamAPlayers[i] = _teamAPlayers[i].copyWith(isCaptain: i == index);
        }
      } else {
        for (int i = 0; i < _teamBPlayers.length; i++) {
          _teamBPlayers[i] = _teamBPlayers[i].copyWith(isCaptain: i == index);
        }
      }
    });
  }

  void _removePlayer(int index) {
    setState(() {
      if (_activeTeamIndex == 0) {
        _teamAPlayers.removeAt(index);
      } else {
        _teamBPlayers.removeAt(index);
      }
    });
  }

  void _proceedToMatchSetup() {
    final teamAHasCaptain = _teamAPlayers.any((p) => p.isCaptain);
    final teamBHasCaptain = _teamBPlayers.any((p) => p.isCaptain);

    if (_teamAPlayers.isEmpty || _teamBPlayers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add players to both teams.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!teamAHasCaptain || !teamBHasCaptain) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a captain for both teams.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final data = {
      'teamAName': _teamAController.text.trim().isEmpty
          ? 'Team A'
          : _teamAController.text.trim(),
      'teamBName': _teamBController.text.trim().isEmpty
          ? 'Team B'
          : _teamBController.text.trim(),
      'teamAPlayers': _teamAPlayers,
      'teamBPlayers': _teamBPlayers,
    };

    context.push('/match-setup', extra: data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // light grayish background
      appBar: AppBar(
        backgroundColor: const Color(0xFF1a2238), // dark blue header
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Create Team',
              style: AppTypography.headlineMedium.copyWith(color: Colors.white),
            ),
            Text(
              'Add players and assign roles',
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
          _buildTeamTabs(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTeamNameInput(),
                  const SizedBox(height: 24),
                  _buildAddPlayerInput(),
                  const SizedBox(height: 24),
                  _buildPlayerList(),
                ],
              ),
            ),
          ),
          _buildBottomButton(),
        ],
      ),
    );
  }

  Widget _buildTeamTabs() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        children: [
          _buildTabItem(
            0,
            _teamAController.text.isEmpty ? 'TEAM A' : _teamAController.text,
            Colors.red,
          ),
          _buildTabItem(
            1,
            _teamBController.text.isEmpty ? 'TEAM B' : _teamBController.text,
            Colors.blue,
          ),
        ],
      ),
    );
  }

  Widget _buildTabItem(int index, String title, Color activeColor) {
    final isActive = _activeTeamIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _activeTeamIndex = index;
          _playerInputController.clear();
        }),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isActive ? activeColor : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Center(
            child: Text(
              title.toUpperCase(),
              style: AppTypography.labelCaps.copyWith(
                color: isActive ? activeColor : Colors.black54,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTeamNameInput() {
    final isTeamA = _activeTeamIndex == 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'TEAM NAME',
          style: AppTypography.labelCaps.copyWith(color: Colors.black54),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: isTeamA ? _teamAController : _teamBController,
          onChanged: (val) => setState(() {}),
          style: AppTypography.bodyLarge.copyWith(color: Colors.black87),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isTeamA ? Colors.red : Colors.blue,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddPlayerInput() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _playerInputController,
            style: AppTypography.bodyMedium.copyWith(color: Colors.black87),
            decoration: InputDecoration(
              hintText: 'Player Name',
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            onSubmitted: (_) => _addPlayer(),
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: _addPlayer,
          style: ElevatedButton.styleFrom(
            backgroundColor: _activeTeamIndex == 0 ? Colors.red : Colors.blue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Icon(Icons.add),
        ),
      ],
    );
  }

  Widget _buildPlayerList() {
    final players = _activeTeamIndex == 0 ? _teamAPlayers : _teamBPlayers;

    if (players.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        alignment: Alignment.center,
        child: Text(
          'No players added yet.',
          style: AppTypography.bodyMedium.copyWith(color: Colors.black45),
        ),
      );
    }

    return Column(
      children: List.generate(players.length, (index) {
        final player = players[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      player.name,
                      style: AppTypography.headlineMedium.copyWith(
                        fontSize: 18,
                        color: Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _setCaptain(index),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: player.isCaptain
                            ? Colors.amber.withValues(alpha: 0.2)
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: player.isCaptain
                              ? Colors.amber
                              : Colors.transparent,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.star,
                            size: 14,
                            color: player.isCaptain
                                ? Colors.amber
                                : Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'CAPT',
                            style: AppTypography.labelCaps.copyWith(
                              color: player.isCaptain
                                  ? Colors.amber.shade700
                                  : Colors.grey,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _removePlayer(index),
                    child: const Icon(
                      Icons.close,
                      color: Colors.grey,
                      size: 20,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: PlayerRole.values.map((role) {
                    final isSelected = player.role == role;
                    return GestureDetector(
                      onTap: () => _updatePlayerRole(index, role),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? (_activeTeamIndex == 0
                                        ? Colors.red
                                        : Colors.blue)
                                    .withValues(alpha: 0.1)
                              : AppColors.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected
                                ? (_activeTeamIndex == 0
                                      ? Colors.red
                                      : Colors.blue)
                                : Colors.transparent,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              role.icon,
                              size: 14,
                              color: isSelected
                                  ? (_activeTeamIndex == 0
                                        ? Colors.red
                                        : Colors.blue)
                                  : Colors.grey,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              role.displayName,
                              style: AppTypography.bodySmall.copyWith(
                                color: isSelected
                                    ? (_activeTeamIndex == 0
                                          ? Colors.red
                                          : Colors.blue)
                                    : Colors.grey,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildBottomButton() {
    return Container(
      padding: const EdgeInsets.all(24),
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
          onPressed: _proceedToMatchSetup,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: const Text(
            'Next: Match Setup',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
