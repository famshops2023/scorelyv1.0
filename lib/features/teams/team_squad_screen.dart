import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'providers/teams_provider.dart';
import '../match/match_setup_screen.dart';
import '../match/providers/pending_matches_provider.dart';
import '../match/helpers/live_match_promo.dart';
import '../../models/player_setup.dart';
import 'package:uuid/uuid.dart';

class TeamSquadScreen extends ConsumerStatefulWidget {
  final String teamId;
  final bool readOnly;
  final bool singleSelectionMode;
  final MatchSetupData? setupData;
  final bool isSelectingPlayingXi;
  final String? teamType;
  final List<String>? excludedPlayerNames;

  const TeamSquadScreen({
    super.key, 
    required this.teamId, 
    this.readOnly = false,
    this.singleSelectionMode = false,
    this.setupData,
    this.isSelectingPlayingXi = false,
    this.teamType,
    this.excludedPlayerNames,
  });

  @override
  ConsumerState<TeamSquadScreen> createState() => _TeamSquadScreenState();
}

class _TeamSquadScreenState extends ConsumerState<TeamSquadScreen> {
  Set<String> _selectedPlayerIds = {};
  bool _selectAll = false;

  @override
  Widget build(BuildContext context) {
    final teamsAsync = ref.watch(teamsProvider);
    final teams = teamsAsync.value ?? [];
    TeamData team;
    bool isLoading = false;

    if (widget.setupData != null && widget.setupData!.isQuickMatch) {
      final isTeamA = widget.teamType == widget.setupData!.teamAName;
      final players = isTeamA 
          ? widget.setupData!.teamAPlayers 
          : widget.setupData!.teamBPlayers;
          
      team = TeamData(
        id: 'quick_match_team',
        name: widget.teamType ?? 'Team',
        location: 'Local',
        dateActive: DateTime.now(),
        members: players.map((p) => TeamMember(
          id: const Uuid().v4(),
          name: p.name,
          roles: [],
          isCaptain: p.isCaptain,
        )).toList(),
      );
    } else {
      team = teams.firstWhere(
        (t) => t.id == widget.teamId,
        orElse: () => TeamData(
          id: '',
          name: '',
          location: '',
          dateActive: DateTime.now(),
          members: [],
        ),
      );
      isLoading = teamsAsync.isLoading;
    }

    if (isLoading && team.id.isEmpty) {
      return const Scaffold(
        backgroundColor: Color(0xFFF7F9FC),
        body: Center(child: CircularProgressIndicator(color: Color(0xFFBA0013))),
      );
    }

    if (team.id.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFFF7F9FC),
        appBar: AppBar(
          backgroundColor: const Color(0xFF191C1E),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => context.pop(),
          ),
          title: Text(
            'Team Squad',
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.group_off, size: 64, color: Color(0xFFDDE0E8)),
              const SizedBox(height: 16),
              Text(
                'Team not found',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF191C1E),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'This team may have been removed.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: const Color(0xFF575D78),
                ),
              ),
            ],
          ),
        ),
      );
    }

    List<TeamMember> displayedMembers = team.members;
    if (widget.excludedPlayerNames != null && widget.excludedPlayerNames!.isNotEmpty) {
      displayedMembers = team.members.where((m) => !widget.excludedPlayerNames!.contains(m.name)).toList();
    }

    final int selectedCount = _selectedPlayerIds.length;
    final currentUserId = ref.watch(currentUserIdProvider);
    // readOnly mode or singleSelectionMode forces isAdmin = false → hides selection box and button
    final isAdmin = (widget.readOnly || widget.singleSelectionMode)
        ? false
        : displayedMembers.any((m) => m.id == currentUserId && m.isAdmin);

    // Handle logo/initials
    final words = team.name.split(' ');
    String initial = '';
    if (words.isNotEmpty) {
      initial += words[0][0];
      if (words.length > 1) {
        initial += words[1][0];
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF191C1E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(
          widget.isSelectingPlayingXi
              ? 'Select Playing XI (Team ${widget.teamType})'
              : 'Team Squad',
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 16,
            letterSpacing: 0.5,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(17.0),
              child: Column(
                children: [
                  // Header Card (Replaced stadium with Team Logo)
                  Container(
                    width: double.infinity,
                    height: 140,
                    decoration: BoxDecoration(
                      color: const Color(0xFF191C1E),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                          color: Color.fromRGBO(26, 33, 56, 0.1),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Background Logo (faded) if available
                        if (team.logoUrl != null)
                          Positioned.fill(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Opacity(
                                opacity: 0.3,
                                child: Image.network(
                                  team.logoUrl!,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                        // Content
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Team Logo
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: const Color(0xFFBA0013),
                                shape: BoxShape.circle,
                                image: team.logoUrl != null
                                    ? DecorationImage(
                                        image: NetworkImage(team.logoUrl!),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              alignment: Alignment.center,
                              child: team.logoUrl == null
                                  ? Text(
                                      initial.toUpperCase(),
                                      style: GoogleFonts.plusJakartaSans(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              team.name,
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 24,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 17),
                  
                  // Selection Row
                  if (isAdmin)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: const [
                        BoxShadow(
                          color: Color.fromRGBO(26, 33, 56, 0.05),
                          blurRadius: 10,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Checkbox(
                              value: _selectAll,
                              activeColor: const Color(0xFFBA0013),
                              onChanged: (val) {
                                setState(() {
                                  _selectAll = val ?? false;
                                  if (_selectAll) {
                                    _selectedPlayerIds = displayedMembers.map((m) => m.id).toSet();
                                  } else {
                                    _selectedPlayerIds.clear();
                                  }
                                });
                              },
                            ),
                            Text(
                              'Select All Players',
                              style: GoogleFonts.inter(
                                color: const Color(0xFF191C1E),
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '$selectedCount Selected', // Dynamic count
                          style: GoogleFonts.inter(
                            color: const Color(0xFF575D78),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isAdmin) const SizedBox(height: 12),
                  
                  if (widget.isSelectingPlayingXi && !isAdmin)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFDE8E8),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFBA0013)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: Color(0xFFBA0013)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Only Team Admins can select the playing XI.',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFFBA0013),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Player List
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: displayedMembers.length,
                    itemBuilder: (context, index) {
                      final member = displayedMembers[index];
                      final isSelected = _selectedPlayerIds.contains(member.id);
                      
                      return GestureDetector(
                        onTap: widget.singleSelectionMode
                            ? () {
                                context.pop(member);
                              }
                            : null,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: const Border(
                              left: BorderSide(color: Color(0xFFBA0013), width: 4),
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Color.fromRGBO(26, 33, 56, 0.05),
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              if (isAdmin) ...[
                                Checkbox(
                                  value: isSelected,
                                  activeColor: const Color(0xFFBA0013),
                                  onChanged: (val) {
                                    setState(() {
                                      if (val == true) {
                                        _selectedPlayerIds.add(member.id);
                                      } else {
                                        _selectedPlayerIds.remove(member.id);
                                      }
                                      _selectAll = _selectedPlayerIds.length == displayedMembers.length;
                                    });
                                  },
                                ),
                                const SizedBox(width: 4),
                              ] else if (widget.singleSelectionMode) ...[
                                const SizedBox(width: 12),
                              ],
                              // Avatar
                              Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: const Color(0xFF191C1E),
                                    child: Text(
                                      member.name[0].toUpperCase(),
                                      style: GoogleFonts.plusJakartaSans(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  if (member.isCaptain)
                                    Positioned(
                                      bottom: -2,
                                      right: -2,
                                      child: Container(
                                        width: 14,
                                        height: 14,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF006B1B),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Row(
                                  children: [
                                    Text(
                                      member.name.toUpperCase(),
                                      style: GoogleFonts.plusJakartaSans(
                                        color: const Color(0xFF191C1E),
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                    if (member.isCaptain) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFBA0013),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Text(
                                          'C',
                                          style: GoogleFonts.inter(
                                            color: Colors.white,
                                            fontSize: 8,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                    const SizedBox(width: 8),
                                    // Primary Role
                                    if (member.roles.isNotEmpty)
                                      Text(
                                        member.roles.first,
                                        style: GoogleFonts.inter(
                                          color: const Color(0xFF575D78),
                                          fontSize: 10,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              if (!widget.singleSelectionMode)
                                IconButton(
                                  icon: const Icon(Icons.remove_red_eye_outlined, color: Color(0xFF575D78), size: 18),
                                  onPressed: () {},
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          
          // Bottom Button
          if (isAdmin && !widget.singleSelectionMode && !widget.readOnly)
            Container(
              width: double.infinity,
            padding: const EdgeInsets.all(17),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Color.fromRGBO(26, 33, 56, 0.05),
                  blurRadius: 10,
                  offset: Offset(0, -4),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: selectedCount > 0 ? () async {
                if (widget.isSelectingPlayingXi && widget.setupData != null) {
                  // Map selected IDs to PlayerSetupData
                  final selectedMembers = displayedMembers.where((m) => _selectedPlayerIds.contains(m.id)).toList();
                  final players = selectedMembers.map((m) => PlayerSetupData(
                    name: m.name,
                    role: m.roles.contains('WK') ? PlayerRole.wicketKeeper :
                          m.roles.contains('AR') ? PlayerRole.allRounder :
                          m.roles.contains('BOWL') ? PlayerRole.bowler : PlayerRole.batsman,
                  )).toList();

                  MatchSetupData currentData = widget.setupData!;
                  if (currentData.id.isEmpty) {
                    currentData = currentData.copyWith(id: const Uuid().v4());
                  }

                  if (widget.teamType == 'A') {
                    currentData = currentData.copyWith(
                      teamAPlayers: players,
                      status: 'waiting_for_team_b',
                    );
                    
                    // Add to pending matches
                    await ref.read(pendingMatchesProvider.notifier).addOrUpdateMatch(currentData);
                    
                    // Try to navigate to Team B
                    final teamB = teams.firstWhere(
                      (t) => t.name == currentData.teamBName,
                      orElse: () => TeamData(id: '', name: '', location: '', dateActive: DateTime.now(), members: []),
                    );
                    
                    if (teamB.id.isNotEmpty && context.mounted) {
                      context.push('/team-squad', extra: {
                        'teamId': teamB.id,
                        'readOnly': false,
                        'singleSelectionMode': false,
                        'setupData': currentData,
                        'isSelectingPlayingXi': true,
                        'teamType': 'B',
                      });
                    } else if (context.mounted) {
                       proceedToToss(context, ref, currentData);
                    }
                  } else if (widget.teamType == 'B') {
                    currentData = currentData.copyWith(
                      teamBPlayers: players,
                      status: 'ready_for_toss',
                    );
                    await ref.read(pendingMatchesProvider.notifier).addOrUpdateMatch(currentData);
                    if (context.mounted) {
                      proceedToToss(context, ref, currentData);
                    }
                  }
                }
              } : null,
              icon: Icon(
                widget.isSelectingPlayingXi 
                  ? (widget.teamType == 'A' ? Icons.arrow_forward : Icons.play_arrow) 
                  : Icons.person_add_alt_1, 
                color: Colors.white
              ),
              label: Text(
                widget.isSelectingPlayingXi
                    ? (widget.teamType == 'A' ? 'Next' : 'Proceed to Toss')
                    : 'Add Selected to Match',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFBA0013),
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFFE7BDB8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 0,
              ),
            ),
          ),
          
          if (!isAdmin && widget.isSelectingPlayingXi)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(17),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(color: Color.fromRGBO(26, 33, 56, 0.05), blurRadius: 10, offset: Offset(0, -4)),
                ],
              ),
              child: ElevatedButton(
                onPressed: () => context.go('/'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF575D78),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text('Save & Exit', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14)),
              ),
            ),
        ],
      ),
    );
  }
}
