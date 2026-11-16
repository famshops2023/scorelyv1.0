import 'package:flutter/material.dart';
import 'package:scorely/core/theme/colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'providers/teams_provider.dart';
import '../match/match_setup_screen.dart';
import '../match/providers/pending_matches_provider.dart';
import '../match/helpers/live_match_promo.dart';
import '../../models/player_setup.dart';
import '../../models/match_status.dart';
import 'package:uuid/uuid.dart';
import '../../services/ratings/player_rating_repository.dart';
import '../../models/player_pro_rating.dart';
import '../../providers/profile_provider.dart';

class TeamSquadScreen extends ConsumerStatefulWidget {
  final String teamId;
  final bool readOnly;
  final bool singleSelectionMode;
  final MatchSetupData? setupData;
  final bool isSelectingPlayingXi;
  final String? teamType;
  final List<String>? excludedPlayerNames;
  final bool signedUpOnly;

  const TeamSquadScreen({
    super.key, 
    required this.teamId, 
    this.readOnly = false,
    this.singleSelectionMode = false,
    this.setupData,
    this.isSelectingPlayingXi = false,
    this.teamType,
    this.excludedPlayerNames,
    this.signedUpOnly = false,
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
    final isTurfContext = widget.setupData != null
        ? PlayerRatingRepository.isTurfMatch(
            widget.setupData?.matchType ?? '',
            widget.setupData?.venue ?? '',
          )
        : true;
    final activeMatchType = isTurfContext ? 'turf' : 'ground';
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
          profileId: p.profileId,
          name: p.name,
          roles: [],
          isCaptain: p.isCaptain,
        )).toList(),
      );
    } else {
      team = teams.firstWhere(
        (t) =>
            (widget.teamId.isNotEmpty && t.id == widget.teamId) ||
            (widget.teamType != null &&
                widget.teamType!.isNotEmpty &&
                t.name.toLowerCase() == widget.teamType!.toLowerCase()),
        orElse: () {
          if (widget.setupData != null) {
            final isTeamA = widget.teamType == widget.setupData!.teamAName;
            final players = isTeamA
                ? widget.setupData!.teamAPlayers
                : widget.setupData!.teamBPlayers;
            return TeamData(
              id: 'match_team_${widget.teamType}',
              name: widget.teamType ?? 'Team',
              location: 'Local',
              dateActive: DateTime.now(),
              members: players
                  .map((p) => TeamMember(
                        id: (p.profileId != null && p.profileId!.isNotEmpty)
                            ? p.profileId!
                            : const Uuid().v4(),
                        profileId: p.profileId,
                        name: p.name,
                        roles: [],
                        isCaptain: p.isCaptain,
                      ))
                  .toList(),
            );
          }
          return TeamData(
            id: '',
            name: '',
            location: '',
            dateActive: DateTime.now(),
            members: [],
          );
        },
      );
      isLoading = teamsAsync.isLoading;
    }

    if (isLoading && team.id.isEmpty) {
      return const Scaffold(
        backgroundColor: AppColors.lightBg,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    if (team.id.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.lightBg,
        appBar: AppBar(
          backgroundColor: AppColors.lightTextPrimary,
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
              const Icon(Icons.group_off, size: 64, color: AppColors.lightBorder),
              const SizedBox(height: 16),
              Text(
                'Team not found',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'This team may have been removed.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.lightTextSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    List<TeamMember> displayedMembers = team.members;
    if (widget.signedUpOnly) {
      displayedMembers = displayedMembers
          .where((m) => m.profileId != null && m.profileId!.isNotEmpty)
          .toList();
    }
    if (widget.excludedPlayerNames != null && widget.excludedPlayerNames!.isNotEmpty) {
      displayedMembers = displayedMembers.where((m) => !widget.excludedPlayerNames!.contains(m.name)).toList();
    }

    final int selectedCount = _selectedPlayerIds.length;
    final currentUserId = ref.watch(currentUserIdProvider);
    final isTeamCreator = currentUserId.isNotEmpty && team.createdBy == currentUserId;
    // readOnly mode or singleSelectionMode forces isAdmin = false → hides selection box and button
    final isAdmin = (widget.readOnly || widget.singleSelectionMode)
        ? false
        : (isTeamCreator || displayedMembers.any((m) => (m.id == currentUserId || m.profileId == currentUserId) && m.isAdmin));

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
      backgroundColor: AppColors.lightBg,
      appBar: AppBar(
        backgroundColor: AppColors.lightTextPrimary,
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
                      color: AppColors.lightTextPrimary,
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
                                color: AppColors.primary,
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
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                team.displayId,
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                  letterSpacing: 1.0,
                                ),
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
                              activeColor: AppColors.primary,
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
                                color: AppColors.lightTextPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '$selectedCount Selected', // Dynamic count
                          style: GoogleFonts.inter(
                            color: AppColors.lightTextSecondary,
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
                        color: AppColors.lightAccentBg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.primary),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Only Team Admins can select the playing XI.',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  if (displayedMembers.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
                      alignment: Alignment.center,
                      child: Column(
                        children: [
                          Icon(
                            widget.signedUpOnly ? Icons.person_off_outlined : Icons.group_off_outlined,
                            size: 48,
                            color: AppColors.lightBorder,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            widget.signedUpOnly ? 'No Signed-in Players in Squad' : 'No Players Available',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.lightTextPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            widget.signedUpOnly
                                ? 'Official scorers must be signed-in Scorely users to receive handover requests.'
                                : 'No eligible players found for selection.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppColors.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // ── Use Myself as Scorer button ──────────────────────────
                  // Only shown in scorer-selection mode for signed-in users
                  if (widget.signedUpOnly && widget.singleSelectionMode)
                    _buildUseMyselfScorerButton(context),

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
                              left: BorderSide(color: AppColors.primary, width: 4),
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
                                  activeColor: AppColors.primary,
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
                                    backgroundColor: AppColors.lightTextPrimary,
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
                                          color: AppColors.successDark,
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
                                        color: AppColors.lightTextPrimary,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 5,
                                        vertical: 1.5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        member.displayId,
                                        style: GoogleFonts.inter(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 9.5,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                    if (member.isCaptain) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: AppColors.primary,
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
                                          color: AppColors.lightTextSecondary,
                                          fontSize: 10,
                                        ),
                                      ),
                                    const Spacer(),
                                    _buildSquadProTitle(member.profileId, activeMatchType),
                                    const SizedBox(width: 4),
                                  ],
                                ),
                              ),
                              if (!widget.singleSelectionMode)
                                IconButton(
                                  icon: const Icon(Icons.remove_red_eye_outlined, color: AppColors.lightTextSecondary, size: 18),
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
            SafeArea(
              top: false,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(17, 12, 17, 16),
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
                          status: MatchStatus.pending,
                          setupStage: MatchSetupStage.squadSelection,
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
                          status: MatchStatus.pending,
                          setupStage: MatchSetupStage.readyForToss,
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
                    color: Colors.white,
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
                    backgroundColor: AppColors.primary,
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
            ),
          
          if (!isAdmin && widget.isSelectingPlayingXi)
            SafeArea(
              top: false,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(17, 12, 17, 16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(color: Color.fromRGBO(26, 33, 56, 0.05), blurRadius: 10, offset: Offset(0, -4)),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () => context.go('/'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.lightTextSecondary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text('Save & Exit', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// "Use Myself as Scorer" card — shown above the player list in scorer-
  /// selection mode. Tapping it pops the screen with the current profile as
  /// the selected scorer TeamMember.
  Widget _buildUseMyselfScorerButton(BuildContext context) {
    final profile = ref.read(profileProvider);

    final effectiveName = profile.name.isNotEmpty
        ? profile.name
        : (widget.setupData?.teamAScorerName ?? 'Scorer (Myself)');
    final effectiveId = profile.id.isNotEmpty
        ? profile.id
        : (widget.setupData?.teamAScorerId ?? 'scorer_myself');

    return GestureDetector(
      onTap: () {
        context.pop(
          TeamMember(
            id: effectiveId,
            profileId: effectiveId,
            name: effectiveName,
            roles: ['Official Scorer'],
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2E7D32).withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // Icon bubble
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_pin_circle_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'USE MYSELF AS SCORER',
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${profile.name} • ${profile.displayId}',
                    style: GoogleFonts.inter(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            // Arrow
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.check_circle_outline_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSquadProTitle(String? profileId, String matchType) {

    if (profileId == null || profileId.isEmpty) return const SizedBox.shrink();

    return FutureBuilder<PlayerProRating>(
      future: PlayerRatingRepository.getPlayerRating(
        playerUserId: profileId,
        matchType: matchType,
      ),
      builder: (context, snapshot) {
        final rating = snapshot.data;
        if (rating == null || !rating.hasRating || rating.matchesPlayed == 0) {
          return const SizedBox.shrink();
        }

        final level = rating.level.toUpperCase();
        final color = _getLevelColor(level);

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Text(
            level,
            style: GoogleFonts.plusJakartaSans(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 9.5,
              letterSpacing: 0.5,
            ),
          ),
        );
      },
    );
  }

  Color _getLevelColor(String level) {
    switch (level.toLowerCase()) {
      case 'legend':
        return const Color(0xFFD32F2F);
      case 'elite':
        return const Color(0xFF8E24AA);
      case 'senior':
        return const Color(0xFF1976D2);
      case 'aspirant':
        return const Color(0xFF2E7D32);
      case 'active':
        return const Color(0xFF0288D1);
      default:
        return const Color(0xFF757575);
    }
  }
}
