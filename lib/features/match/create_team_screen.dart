import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/player_setup.dart';

class CreateTeamScreen extends StatefulWidget {
  const CreateTeamScreen({super.key});

  @override
  State<CreateTeamScreen> createState() => _CreateTeamScreenState();
}

class _CreateTeamScreenState extends State<CreateTeamScreen> {
  final _teamAController = TextEditingController(text: '');
  final _teamBController = TextEditingController(text: '');

  int _activeTeamIndex = 0; // 0 for Team A, 1 for Team B
  final List<PlayerSetupData> _teamAPlayers = [];
  final List<PlayerSetupData> _teamBPlayers = [];

  final _playerInputController = TextEditingController();
  String _searchQuery = '';

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
          if (!_teamAPlayers.any(
            (p) => p.name.toUpperCase() == name.toUpperCase(),
          )) {
            _teamAPlayers.insert(0, newPlayer);
          }
        } else {
          if (!_teamBPlayers.any(
            (p) => p.name.toUpperCase() == name.toUpperCase(),
          )) {
            _teamBPlayers.insert(0, newPlayer);
          }
        }
        _playerInputController.clear();
        _searchQuery = '';
      });
    } else {
      _showAddPlayerDialog();
    }
  }

  void _showAddPlayerDialog() {
    final dialogController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Add Player',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
          ),
          content: TextField(
            controller: dialogController,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Enter player name',
            ),
            onSubmitted: (val) {
              Navigator.pop(context);
              if (val.trim().isNotEmpty) {
                _playerInputController.text = val;
                _addPlayer();
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                if (dialogController.text.trim().isNotEmpty) {
                  _playerInputController.text = dialogController.text;
                  _addPlayer();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF006B1B),
                foregroundColor: Colors.white,
              ),
              child: const Text('ADD'),
            ),
          ],
        );
      },
    );
  }

  void _updatePlayerRole(int index, PlayerRole role) {
    setState(() {
      final players = _activeTeamIndex == 0 ? _teamAPlayers : _teamBPlayers;
      final filteredPlayers = players
          .where(
            (p) => p.name.toLowerCase().contains(_searchQuery.toLowerCase()),
          )
          .toList();
      final player = filteredPlayers[index];

      final originalIndex = players.indexOf(player);
      if (originalIndex != -1) {
        if (_activeTeamIndex == 0) {
          _teamAPlayers[originalIndex] = _teamAPlayers[originalIndex].copyWith(
            role: role,
          );
        } else {
          _teamBPlayers[originalIndex] = _teamBPlayers[originalIndex].copyWith(
            role: role,
          );
        }
      }
    });
  }

  void _setCaptain(int index) {
    setState(() {
      final players = _activeTeamIndex == 0 ? _teamAPlayers : _teamBPlayers;
      final filteredPlayers = players
          .where(
            (p) => p.name.toLowerCase().contains(_searchQuery.toLowerCase()),
          )
          .toList();
      final player = filteredPlayers[index];

      final originalIndex = players.indexOf(player);
      if (originalIndex != -1) {
        if (_activeTeamIndex == 0) {
          for (int i = 0; i < _teamAPlayers.length; i++) {
            _teamAPlayers[i] = _teamAPlayers[i].copyWith(
              isCaptain: i == originalIndex,
            );
          }
        } else {
          for (int i = 0; i < _teamBPlayers.length; i++) {
            _teamBPlayers[i] = _teamBPlayers[i].copyWith(
              isCaptain: i == originalIndex,
            );
          }
        }
      }
    });
  }

  void _removePlayer(int index) {
    setState(() {
      final players = _activeTeamIndex == 0 ? _teamAPlayers : _teamBPlayers;
      final filteredPlayers = players
          .where(
            (p) => p.name.toLowerCase().contains(_searchQuery.toLowerCase()),
          )
          .toList();
      final player = filteredPlayers[index];

      final originalIndex = players.indexOf(player);
      if (originalIndex != -1) {
        if (_activeTeamIndex == 0) {
          _teamAPlayers.removeAt(originalIndex);
        } else {
          _teamBPlayers.removeAt(originalIndex);
        }
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
          backgroundColor: Color(0xFFBA0013),
        ),
      );
      return;
    }

    if (!teamAHasCaptain || !teamBHasCaptain) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a captain for both teams.'),
          backgroundColor: Color(0xFFBA0013),
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
      backgroundColor: const Color(0xFFF7F9FC), // Premium light background
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A2138),
        elevation: 0,
        centerTitle: false,
        title: Text(
          'CREATE TEAM',
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 24,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Color(0xFFBA0013), size: 28),
          onPressed: () {
            context.pop();
          },
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFECEEF1), width: 2),
                ),
                child: ClipOval(
                  child: Image.network(
                    'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&q=80&w=120',
                    fit: BoxFit.cover,
                    width: 40,
                    height: 40,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.person, color: Color(0xFF575D78));
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // SETUP ENGINE / SQUAD CONFIG
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 17.0,
                      vertical: 17.0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 20,
                              height: 3,
                              color: const Color(0xFFBA0013),
                            ),
                            const SizedBox(width: 7),
                            Text(
                              'SETUP ENGINE',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFFBA0013),
                                letterSpacing: 0.6,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 7),
                        Text(
                          'SQUAD CONFIG',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF191C1E),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Team Name Inputs
                  _buildTeamField(
                    label: 'TEAM A NAME',
                    controller: _teamAController,
                    hint: 'e.g., Alpha Team',
                    outlineColor: const Color(0xFFE7BDB8),
                  ),
                  const SizedBox(height: 8),
                  _buildTeamField(
                    label: 'TEAM B NAME',
                    controller: _teamBController,
                    hint: 'e.g., Beta Team',
                    outlineColor: const Color(0xFFE7BDB8),
                  ),
                  const SizedBox(height: 17),

                  // Tabs
                  _buildTabs(),

                  // Roster Header
                  _buildRosterHeader(),

                  // Search Bar
                  _buildSearchInput(),
                  const SizedBox(height: 8),

                  // Player List
                  _buildPlayerList(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          // Bottom button
          _buildBottomButton(),
        ],
      ),
    );
  }

  Widget _buildTeamField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required Color outlineColor,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 17.0, vertical: 5.0),
      child: TextField(
        controller: controller,
        onChanged: (val) => setState(() {}),
        style: GoogleFonts.inter(
          color: const Color(0xFF191C1E),
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.inter(
            color: const Color(0xFF575D78),
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
          ),
          floatingLabelBehavior: FloatingLabelBehavior.always,
          hintText: hint,
          hintStyle: GoogleFonts.inter(
            color: const Color(0xFF8E95A5),
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 17,
            vertical: 15,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: outlineColor, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFBA0013), width: 2.0),
          ),
        ),
      ),
    );
  }

  Widget _buildTabs() {
    final isTeamA = _activeTeamIndex == 0;
    final teamAName = _teamAController.text.trim().isEmpty
        ? 'TEAM A'
        : _teamAController.text.trim().toUpperCase();
    final teamBName = _teamBController.text.trim().isEmpty
        ? 'TEAM B'
        : _teamBController.text.trim().toUpperCase();

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFECEEF1), width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _activeTeamIndex = 0),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14.0),
                    child: Text(
                      '$teamAName (${_teamAPlayers.length})',
                      style: GoogleFonts.inter(
                        color: isTeamA
                            ? const Color(0xFFBA0013)
                            : const Color(0xFF575D78),
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                  Container(
                    height: 3,
                    color: isTeamA
                        ? const Color(0xFFBA0013)
                        : Colors.transparent,
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _activeTeamIndex = 1),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14.0),
                    child: Text(
                      '$teamBName (${_teamBPlayers.length})',
                      style: GoogleFonts.inter(
                        color: !isTeamA
                            ? const Color(0xFFBA0013)
                            : const Color(0xFF575D78),
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                  Container(
                    height: 3,
                    color: !isTeamA
                        ? const Color(0xFFBA0013)
                        : Colors.transparent,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRosterHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 17.0, vertical: 14.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.people_alt, color: Color(0xFFBA0013), size: 20),
              const SizedBox(width: 7),
              Text(
                'ROSTER',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF191C1E),
                ),
              ),
            ],
          ),
          Row(
            children: [
              InkWell(
                onTap: () {
                  // Standard dialog to join or search
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDBE1FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.qr_code_scanner,
                        color: Color(0xFF3F465F),
                        size: 14,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'JOIN',
                        style: GoogleFonts.inter(
                          color: const Color(0xFF3F465F),
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 7),
              InkWell(
                onTap: _addPlayer,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF006B1B),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.person_add_alt_1,
                        color: Colors.white,
                        size: 14,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'ADD',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchInput() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 17.0, vertical: 3.0),
      child: TextField(
        controller: _playerInputController,
        style: GoogleFonts.inter(
          color: const Color(0xFF191C1E),
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        onChanged: (val) {
          setState(() {
            _searchQuery = val;
          });
        },
        onSubmitted: (_) => _addPlayer(),
        decoration: InputDecoration(
          prefixIcon: const Icon(
            Icons.search,
            color: Color(0xFF575D78),
            size: 19,
          ),
          hintText: 'Search players...',
          hintStyle: GoogleFonts.inter(
            color: const Color(0xFF8E95A5),
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE7BDB8), width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFBA0013), width: 2.0),
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerList() {
    final players = _activeTeamIndex == 0 ? _teamAPlayers : _teamBPlayers;
    final filteredPlayers = players
        .where((p) => p.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    if (filteredPlayers.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(27),
        alignment: Alignment.center,
        child: Text(
          _searchQuery.isEmpty
              ? 'No players added yet.'
              : 'No matching players found.',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: const Color(0xFF8E95A5),
            fontWeight: FontWeight.w400,
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filteredPlayers.length,
      itemBuilder: (context, index) {
        final player = filteredPlayers[index];
        return _buildPlayerCard(index, player);
      },
    );
  }

  Widget _buildPlayerCard(int index, PlayerSetupData player) {
    final numberStr = (index + 1).toString().padLeft(2, '0');
    final isCaptain = player.isCaptain;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 17.0, vertical: 7.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(14),
          bottomRight: Radius.circular(14),
          topLeft: Radius.circular(3),
          bottomLeft: Radius.circular(3),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A2138).withValues(alpha: 0.06),
            blurRadius: 17,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Row(
          children: [
            Container(width: 4, height: 94, color: const Color(0xFFBA0013)),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14.0,
                  vertical: 10.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFDEBED),
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: Text(
                            numberStr,
                            style: GoogleFonts.inter(
                              color: const Color(0xFFBA0013),
                              fontWeight: FontWeight.w700,
                              fontSize: 10,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            player.name.toUpperCase(),
                            style: GoogleFonts.plusJakartaSans(
                              color: const Color(0xFF191C1E),
                              fontWeight: FontWeight.w600,
                              fontSize: 17,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Color(0xFF8E95A5),
                            size: 19,
                          ),
                          onPressed: () => _removePlayer(index),
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECEEF1),
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildRoleTab(
                                index,
                                player,
                                PlayerRole.wicketKeeper,
                                'WK',
                              ),
                              _buildRoleTab(
                                index,
                                player,
                                PlayerRole.batsman,
                                'BAT',
                              ),
                              _buildRoleTab(
                                index,
                                player,
                                PlayerRole.bowler,
                                'BOWL',
                              ),
                              _buildRoleTab(
                                index,
                                player,
                                PlayerRole.allRounder,
                                'AR',
                              ),
                            ],
                          ),
                        ),
                        InkWell(
                          onTap: () => _setCaptain(index),
                          borderRadius: BorderRadius.circular(17),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isCaptain
                                  ? const Color(0xFF8CE88C)
                                  : const Color(0xFFECEEF1),
                              boxShadow: isCaptain
                                  ? [
                                      BoxShadow(
                                        color: const Color(
                                          0xFF8CE88C,
                                        ).withValues(alpha: 0.4),
                                        blurRadius: 8,
                                        spreadRadius: 2,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Center(
                              child: Text(
                                'C',
                                style: GoogleFonts.plusJakartaSans(
                                  color: isCaptain
                                      ? const Color(0xFF003000)
                                      : const Color(0xFF575D78),
                                  fontWeight: FontWeight.w900,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
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
    );
  }

  Widget _buildRoleTab(
    int index,
    PlayerSetupData player,
    PlayerRole role,
    String label,
  ) {
    final isSelected = player.role == role;
    return GestureDetector(
      onTap: () => _updatePlayerRole(index, role),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF006B1B) : Colors.transparent,
          borderRadius: BorderRadius.circular(5),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            color: isSelected ? Colors.white : const Color(0xFF575D78),
            fontWeight: FontWeight.w700,
            fontSize: 10,
            letterSpacing: 0.6,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomButton() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.all(17),
        color: const Color(0xFFF7F9FC),
        child: SizedBox(
          width: double.infinity,
          height: 51,
          child: ElevatedButton(
            onPressed: _proceedToMatchSetup,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFBA0013),
              foregroundColor: Colors.white,
              elevation: 3,
              shadowColor: const Color(0xFFBA0013).withValues(alpha: 0.4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'PROCEED TO MATCH',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(width: 7),
                const Icon(Icons.flash_on, color: Colors.white, size: 15),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
