import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:scorely/core/theme/colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import '../../models/player_setup.dart';
import '../../models/user_profile.dart';
import '../../services/database.dart';
import '../discovery/discovery_screen.dart';
import 'match_setup_screen.dart';
import 'match_result_screen.dart';
import 'providers/quick_match_storage.dart';

class CreateTeamScreen extends ConsumerStatefulWidget {
  final bool isQuickMatch;
  final Map<String, dynamic>? initialData;
  
  const CreateTeamScreen({
    super.key,
    this.isQuickMatch = false,
    this.initialData,
  });

  @override
  ConsumerState<CreateTeamScreen> createState() => _CreateTeamScreenState();
}

class _CreateTeamScreenState extends ConsumerState<CreateTeamScreen> {
  final _teamAController = TextEditingController(text: '');
  final _teamBController = TextEditingController(text: '');

  int _activeTeamIndex = 0; // 0 for Team A, 1 for Team B
  final List<PlayerSetupData> _teamAPlayers = [];
  final List<PlayerSetupData> _teamBPlayers = [];

  final _playerInputController = TextEditingController();
  String _searchQuery = '';

  late final String _creationRequestId;
  late final String _matchId;

  @override
  void initState() {
    super.initState();
    _creationRequestId = widget.initialData?['creationRequestId'] as String? ?? const Uuid().v4();
    _matchId = widget.initialData?['id'] as String? ?? widget.initialData?['sessionId'] as String? ?? const Uuid().v4();
    if (widget.initialData != null) {
      if (widget.initialData!['teamAName'] != null) {
        _teamAController.text = widget.initialData!['teamAName'].toString();
      }
      if (widget.initialData!['teamBName'] != null) {
        _teamBController.text = widget.initialData!['teamBName'].toString();
      }
      if (widget.initialData!['teamAPlayers'] is List<PlayerSetupData>) {
        _teamAPlayers.addAll(widget.initialData!['teamAPlayers'] as List<PlayerSetupData>);
      }
      if (widget.initialData!['teamBPlayers'] is List<PlayerSetupData>) {
        _teamBPlayers.addAll(widget.initialData!['teamBPlayers'] as List<PlayerSetupData>);
      }
    }
  }

  @override
  void dispose() {
    _teamAController.dispose();
    _teamBController.dispose();
    _playerInputController.dispose();
    super.dispose();
  }

  Future<void> _openDiscoveryForPlayers() async {
    final result = await context.push<dynamic>(
      '/discovery',
      extra: {
        'isSelectionMode': true,
        'initialTab': 'Players',
        'signedUpOnly': false,
        'multiSelect': true,
      },
    );

    if (result != null && mounted) {
      final List<DiscoveryItem> selected;
      if (result is List) {
        selected = result.whereType<DiscoveryItem>().toList();
      } else if (result is DiscoveryItem) {
        selected = [result];
      } else {
        return;
      }

      if (selected.isEmpty) return;

      int addedCount = 0;
      final activePlayers = _activeTeamIndex == 0 ? _teamAPlayers : _teamBPlayers;

      setState(() {
        for (final item in selected) {
          if (activePlayers.any((p) =>
              p.name.toUpperCase() == item.name.toUpperCase() ||
              (p.profileId != null && p.profileId == item.rawId))) {
            continue;
          }

          PlayerRole role = PlayerRole.batsman;
          if (item.role != null && item.role!.isNotEmpty) {
            final r = item.role!.toUpperCase();
            if (r.contains('BOWL')) {
              role = PlayerRole.bowler;
            } else if (r.contains('ALL') || r.contains('AR')) {
              role = PlayerRole.allRounder;
            } else if (r.contains('WK') || r.contains('WICKET')) {
              role = PlayerRole.wicketKeeper;
            }
          }

          activePlayers.insert(
            0,
            PlayerSetupData(
              name: item.name,
              role: role,
              profileId: (item.profileId != null && item.profileId!.isNotEmpty) ? item.profileId : item.rawId,
              isSignedIn: true,
            ),
          );
          addedCount++;
        }
      });

      if (mounted) {
        if (addedCount > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.successDark,
              content: Text(
                '$addedCount player${addedCount == 1 ? '' : 's'} added to ${_activeTeamIndex == 0 ? "Team A" : "Team B"}!',
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Selected player(s) are already in the squad.')),
          );
        }
      }
    }
  }

  Future<void> _scanPlayerQR() async {
    final scanned = await context.push<dynamic>('/team-qr-scanner');
    if (scanned == null || !mounted) return;

    final raw = scanned.toString().trim();
    if (raw.isEmpty) return;

    String playerName = '';
    String? profileId;
    PlayerRole role = PlayerRole.batsman;

    // Try parsing as JSON from UserProfile.toJson()
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        playerName = (decoded['name'] as String? ?? '').trim();
        profileId = (decoded['id'] ?? decoded['profileId'] ?? decoded['profile_id']) as String?;
        final playingRoleStr = (decoded['playingRole'] as String? ?? decoded['role'] as String? ?? '').toUpperCase();
        if (playingRoleStr.contains('BOWL')) {
          role = PlayerRole.bowler;
        } else if (playingRoleStr.contains('ALL') || playingRoleStr.contains('AR')) {
          role = PlayerRole.allRounder;
        } else if (playingRoleStr.contains('WK') || playingRoleStr.contains('WICKET')) {
          role = PlayerRole.wicketKeeper;
        } else {
          role = PlayerRole.batsman;
        }
      }
    } catch (_) {
      // Fallback: raw text could be player name, raw UUID, or SP-XXXX ID
      final trimmed = raw.trim();
      final isUuid = RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$').hasMatch(trimmed);
      if (isUuid) {
        profileId = trimmed;
        playerName = UserProfile.deriveDisplayId(trimmed);
      } else if (trimmed.toUpperCase().startsWith('SP')) {
        profileId = trimmed.replaceAll(' ', '').toUpperCase();
        playerName = trimmed;
      } else {
        playerName = trimmed;
      }
    }

    if (playerName.isEmpty && profileId != null && profileId.isNotEmpty) {
      playerName = UserProfile.deriveDisplayId(profileId);
    }

    if (playerName.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid player QR code.')),
        );
      }
      return;
    }

    final activePlayers = _activeTeamIndex == 0 ? _teamAPlayers : _teamBPlayers;
    if (activePlayers.any((p) =>
        p.name.toUpperCase() == playerName.toUpperCase() ||
        (profileId != null && p.profileId == profileId))) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$playerName is already in the squad.')),
        );
      }
      return;
    }

    setState(() {
      activePlayers.insert(
        0,
        PlayerSetupData(
          name: playerName,
          role: role,
          profileId: profileId,
          isSignedIn: true,
        ),
      );
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.successDark,
          content: Text('$playerName added to ${_activeTeamIndex == 0 ? "Team A" : "Team B"}!'),
        ),
      );
    }
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
            cursorColor: AppColors.primary,
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
                backgroundColor: AppColors.successDark,
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
          backgroundColor: AppColors.primary,
        ),
      );
      return;
    }

    if (!teamAHasCaptain || !teamBHasCaptain) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a captain for both teams.'),
          backgroundColor: AppColors.primary,
        ),
      );
      return;
    }

    final data = {
      if (widget.initialData != null) ...widget.initialData!,
      'id': _matchId,
      'sessionId': _matchId,
      'creationRequestId': _creationRequestId,
      'teamAName': _teamAController.text.trim().isEmpty
          ? 'Team A'
          : _teamAController.text.trim(),
      'teamBName': _teamBController.text.trim().isEmpty
          ? 'Team B'
          : _teamBController.text.trim(),
      'teamAPlayers': _teamAPlayers,
      'teamBPlayers': _teamBPlayers,
      'isQuickMatch': widget.isQuickMatch,
    };

    context.push('/match-setup', extra: data);
  }

  Future<void> _showCloneDialog() async {
    // 1. Try to load previous setup from QuickMatchStorage
    var setup = await QuickMatchStorage.getLastQuickMatch();

    // 2. If not found in QuickMatchStorage, attempt to load from database
    if (setup == null) {
      try {
        final matches = await DatabaseService.instance.getAllMatches();
        if (matches.isNotEmpty) {
          final lastMatch = matches.first;
          String teamAName = 'Team A';
          String teamBName = 'Team B';
          if (lastMatch.matchTitle.contains(' vs ')) {
            final parts = lastMatch.matchTitle.split(' vs ');
            if (parts.isNotEmpty) teamAName = parts[0].trim();
            if (parts.length > 1) teamBName = parts[1].trim();
          }
          final db = DatabaseService.instance;
          final balls = await (db.select(db.ballEvents)
                ..where((b) => b.matchId.equals(lastMatch.id)))
              .get();
          final playerNamesA = <String>{};
          final playerNamesB = <String>{};
          for (final b in balls) {
            if (b.inningsNumber == 1) {
              if (b.batterName.isNotEmpty) playerNamesA.add(b.batterName);
              if (b.bowlerName.isNotEmpty) playerNamesB.add(b.bowlerName);
            } else {
              if (b.batterName.isNotEmpty) playerNamesB.add(b.batterName);
              if (b.bowlerName.isNotEmpty) playerNamesA.add(b.bowlerName);
            }
          }
          final teamAPlayers = playerNamesA.map((n) => PlayerSetupData(name: n)).toList();
          final teamBPlayers = playerNamesB.map((n) => PlayerSetupData(name: n)).toList();
          if (teamAPlayers.isNotEmpty) teamAPlayers.first = teamAPlayers.first.copyWith(isCaptain: true);
          if (teamBPlayers.isNotEmpty) teamBPlayers.first = teamBPlayers.first.copyWith(isCaptain: true);

          final cloneUuid = const Uuid().v4();
          setup = MatchSetupData(
            id: cloneUuid,
            matchCode: MatchSetupData.deriveMatchCode(cloneUuid),
            teamAName: teamAName,
            teamBName: teamBName,
            teamAPlayers: teamAPlayers,
            teamBPlayers: teamBPlayers,
            overs: lastMatch.totalOvers,
            tossWonBy: '',
            maxOversPerBowler: (lastMatch.totalOvers / 5).ceil().clamp(1, 10),
            powerplayOvers: (lastMatch.totalOvers * 0.3).round().clamp(1, 10),
            battingFirstTeam: '',
            matchType: lastMatch.matchType,
            ballType: lastMatch.ballType,
            venue: lastMatch.venue,
            matchDate: lastMatch.createdAt,
            isQuickMatch: lastMatch.isQuickMatch,
          );
        }
      } catch (e) {
        debugPrint('Error loading last match for clone: $e');
      }
    }

    if (!mounted) return;

    if (setup == null) {
      showDialog(
        context: context,
        builder: (dialogCtx) => Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.history_rounded,
                    color: AppColors.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'No Previous Setup',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'There is no previous match setup to clone. Play your first match and your squad config will be available here next time.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.lightTextSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(dialogCtx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'GOT IT',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      return;
    }

    final parentContext = context;
    showDialog(
      context: context,
      builder: (_) => CloneSetupDialog(
        previousSetup: setup,
        ref: ref,
        parentContext: parentContext,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBg, // Premium light background
      appBar: AppBar(
        backgroundColor: AppColors.darkSurface,
        elevation: 0,
        centerTitle: false,
        title: Text(
          'SQUAD SETUP',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            context.pop();
          },
        ),

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
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 7),
                            Text(
                              'SETUP ENGINE',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
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
                            color: AppColors.lightTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 44,
                          child: OutlinedButton.icon(
                            onPressed: _showCloneDialog,
                            icon: const Icon(
                              Icons.copy_all_rounded,
                              size: 16,
                            ),
                            label: Text(
                              'CLONE PREVIOUS SETUP',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.6,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              side: const BorderSide(
                                color: AppColors.primary,
                                width: 1.5,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
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
          color: AppColors.lightTextPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.inter(
            color: AppColors.lightTextSecondary,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
          ),
          floatingLabelBehavior: FloatingLabelBehavior.always,
          hintText: hint,
          hintStyle: GoogleFonts.inter(
            color: AppColors.lightTextMuted,
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
            borderSide: const BorderSide(color: AppColors.primary, width: 2.0),
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
                            ? AppColors.primary
                            : AppColors.lightTextSecondary,
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                  Container(
                    height: 3,
                    color: isTeamA
                        ? AppColors.primary
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
                            ? AppColors.primary
                            : AppColors.lightTextSecondary,
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                  Container(
                    height: 3,
                    color: !isTeamA
                        ? AppColors.primary
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
              const Icon(Icons.people_alt, color: AppColors.primary, size: 20),
              const SizedBox(width: 7),
              Text(
                'ROSTER',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: AppColors.lightTextPrimary,
                ),
              ),
            ],
          ),
          Row(
            children: [
              // 1. SEARCH Button
              InkWell(
                onTap: _openDiscoveryForPlayers,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDE9FE),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.search,
                        color: Color(0xFF5B21B6),
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'SEARCH',
                        style: GoogleFonts.inter(
                          color: const Color(0xFF5B21B6),
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),

              // 2. QR Scanner Button
              InkWell(
                onTap: _scanPlayerQR,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
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
                      const SizedBox(width: 4),
                      Text(
                        'QR',
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
              const SizedBox(width: 6),

              // 3. ADD Button
              InkWell(
                onTap: _addPlayer,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.successDark,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.person_add_alt_1,
                        color: Colors.white,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
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
        cursorColor: Colors.white,
        controller: _playerInputController,
        style: GoogleFonts.inter(
          color: AppColors.lightTextPrimary,
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
          prefixIcon: Tooltip(
            message: 'Search registered players',
            child: IconButton(
              icon: const Icon(
                Icons.search,
                color: AppColors.primary,
                size: 20,
              ),
              onPressed: _openDiscoveryForPlayers,
            ),
          ),
          hintText: 'Search or type player name...',
          hintStyle: GoogleFonts.inter(
            color: AppColors.lightTextMuted,
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
            borderSide: const BorderSide(color: AppColors.primary, width: 2.0),
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
            color: AppColors.lightTextMuted,
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
            color: AppColors.darkSurface.withValues(alpha: 0.06),
            blurRadius: 17,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Row(
          children: [
            Container(width: 4, height: 94, color: AppColors.primary),
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
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 10,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  player.name.toUpperCase(),
                                  style: GoogleFonts.plusJakartaSans(
                                    color: AppColors.lightTextPrimary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 17,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (player.isSignedIn) ...[
                                const SizedBox(width: 8),
                                Tooltip(
                                  message: 'Signed-in player',
                                  child: Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF10B981),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                                if (player.profileId != null && player.profileId!.isNotEmpty) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF10B981).withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      UserProfile.deriveDisplayId(player.profileId!),
                                      style: GoogleFonts.inter(
                                        color: const Color(0xFF059669),
                                        fontWeight: FontWeight.w700,
                                        fontSize: 9.5,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: AppColors.lightTextMuted,
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
                                      : AppColors.lightTextSecondary,
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
          color: isSelected ? AppColors.successDark : Colors.transparent,
          borderRadius: BorderRadius.circular(5),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            color: isSelected ? Colors.white : AppColors.lightTextSecondary,
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
        color: AppColors.lightBg,
        child: SizedBox(
          width: double.infinity,
          height: 51,
          child: ElevatedButton(
            onPressed: _proceedToMatchSetup,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 3,
              shadowColor: AppColors.primary.withValues(alpha: 0.4),
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
