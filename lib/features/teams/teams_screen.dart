import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../providers/profile_provider.dart';
import 'providers/teams_provider.dart';

class TeamsScreen extends ConsumerStatefulWidget {
  final bool isSelectionMode;
  const TeamsScreen({super.key, this.isSelectionMode = false});

  @override
  ConsumerState<TeamsScreen> createState() => _TeamsScreenState();
}

class _TeamsScreenState extends ConsumerState<TeamsScreen> {
  bool _showMyTeams = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Shows an auth-gate dialog when the user taps CREATE TEAM without signing in.
  Future<void> _handleCreateTeamTap(BuildContext context) async {
    final profile = ref.read(profileProvider);
    if (profile.isLoggedIn) {
      context.push('/edit-squad', extra: '');
      return;
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Color(0xFFBA0013), width: 6),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEBEE),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFBA0013).withValues(alpha: 0.15),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.groups_2_rounded,
                      color: Color(0xFFBA0013),
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Title
                  Text(
                    'Sign In to Create a Team',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A2138),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Body
                  Text(
                    'Creating and managing teams requires a Scorely account so your squad is safely synced across devices.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      color: const Color(0xFF5A6278),
                      height: 1.55,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Tip banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F5FF),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFCDD8F6)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.bolt_rounded, size: 17, color: Color(0xFF575D78)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Prefer to stay offline? Use Quick Match to score without an account.',
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
                  const SizedBox(height: 22),

                  // Buttons
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        context.push('/login');
                      },
                      icon: const Icon(Icons.login_rounded, size: 18, color: Colors.white),
                      label: Text(
                        'SIGN IN',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFBA0013),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: const BorderSide(color: Color(0xFFDDE0E8)),
                      ),
                      child: Text(
                        'CANCEL',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A2138),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final teamsAsync = ref.watch(teamsProvider);
    final allTeams = teamsAsync.value ?? [];
    final myTeams = ref.watch(myTeamsProvider);
    final currentUserId = ref.watch(currentUserIdProvider);

    var displayTeams = _showMyTeams ? myTeams : allTeams;

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      displayTeams = displayTeams.where((team) {
        return team.name.toLowerCase().contains(query) ||
            team.id.toLowerCase().contains(query) ||
            team.members.any((m) => m.name.toLowerCase().contains(query));
      }).toList();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF191C1E),
        elevation: 0,
        title: Row(
          children: [
            const Icon(Icons.sports_cricket, color: Colors.white, size: 24),
            const SizedBox(width: 8),
            Text(
              'TEAMS',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 18,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () => context.push('/discovery'),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 17.0,
              vertical: 17.0,
            ),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () => _handleCreateTeamTap(context),
                    icon: const Icon(
                      Icons.add_circle_outline,
                      color: Colors.white,
                    ),
                    label: Text(
                      'CREATE TEAM',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        letterSpacing: 0.6,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFBA0013),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(height: 17),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECEEF1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _showMyTeams = false),
                          child: Container(
                            alignment: Alignment.center,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: !_showMyTeams
                                  ? const Color(0xFF1A2138)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'All Teams',
                              style: GoogleFonts.inter(
                                color: !_showMyTeams
                                    ? Colors.white
                                    : const Color(0xFF575D78),
                                fontWeight: !_showMyTeams
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _showMyTeams = true),
                          child: Container(
                            alignment: Alignment.center,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: _showMyTeams
                                  ? const Color(0xFF1A2138)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'My Teams',
                              style: GoogleFonts.inter(
                                color: _showMyTeams
                                    ? Colors.white
                                    : const Color(0xFF575D78),
                                fontWeight: _showMyTeams
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F2F5), // light grey background
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFDDE0E8),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: (val) => setState(() => _searchQuery = val),
                          cursorColor: const Color(0xFF1A2138),
                          style: GoogleFonts.inter(
                            color: const Color(0xFF1A2138),
                            fontSize: 14,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Search teams, players, or IDs...',
                            hintStyle: GoogleFonts.inter(
                              color: const Color(0xFF8E95A5),
                              fontSize: 14,
                            ),
                            prefixIcon: const Icon(
                              Icons.search,
                              color: Color(0xFF8E95A5),
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.qr_code_scanner, color: Color(0xFF8E95A5)),
                        onPressed: () async {
                          final result = await context.push<String>('/team-scanner');
                          if (result != null && result.isNotEmpty) {
                            _searchController.text = result;
                            setState(() => _searchQuery = result);
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 17.0,
              vertical: 8.0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _showMyTeams ? 'My Teams' : 'All Teams',
                  style: GoogleFonts.plusJakartaSans(
                    color: const Color(0xFF575D78),
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                Text(
                  '${displayTeams.length} TEAMS',
                  style: GoogleFonts.inter(
                    color: const Color(0xFFBA0013),
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: displayTeams.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _showMyTeams ? Icons.groups_3_outlined : Icons.shield_outlined,
                            size: 60,
                            color: const Color(0xFF94A3B8),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            _showMyTeams ? 'No Teams Created Yet' : 'No Teams Found',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _showMyTeams
                                ? 'Create your squad to manage players, track stats, and schedule matches.'
                                : 'Try searching for a different team name or team ID.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                          if (_showMyTeams) ...[
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                              onPressed: () => _handleCreateTeamTap(context),
                              icon: const Icon(Icons.add, color: Colors.white, size: 18),
                              label: Text(
                                'CREATE TEAM NOW',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFBA0013),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                elevation: 0,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 17.0,
                      vertical: 8.0,
                    ),
                    itemCount: displayTeams.length,
                    itemBuilder: (context, index) {
                      final team = displayTeams[index];

                      // Determine if current user is admin for this team
                      final localTeamIds = ref.watch(myCreatedTeamIdsProvider);
                      final isAdmin = localTeamIds.contains(team.id) ||
                          team.createdBy == currentUserId ||
                          (team.members.any((m) =>
                              (m.id == currentUserId || m.profileId == currentUserId) &&
                              m.isAdmin));

                      return _TeamCard(
                        team: team,
                        isAdmin: isAdmin,
                        isSelectionMode: widget.isSelectionMode,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _TeamCard extends StatelessWidget {
  final TeamData team;
  final bool isAdmin;
  final bool isSelectionMode;

  const _TeamCard({
    required this.team,
    required this.isAdmin,
    this.isSelectionMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final activeDate = dateFormat.format(team.dateActive);

    // Initial based on first 1 or 2 words
    final words = team.name.split(' ');
    String initial = '';
    if (words.isNotEmpty) {
      initial += words[0][0];
      if (words.length > 1) {
        initial += words[1][0];
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: GestureDetector(
        onTap: isSelectionMode ? () => context.pop(team.name) : null,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Row(
          children: [
            Container(width: 4, height: 80, color: const Color(0xFFBA0013)),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: const Color(0xFFBA0013),
                        borderRadius: BorderRadius.circular(8),
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
                                fontWeight: FontWeight.w700,
                                fontSize: 18,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  team.name,
                                  style: GoogleFonts.plusJakartaSans(
                                    color: const Color(0xFF191C1E),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isAdmin && !isSelectionMode) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF006B1B),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'ADMIN',
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 8,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.calendar_today,
                                size: 10,
                                color: Color(0xFF8E95A5),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Active: $activeDate',
                                style: GoogleFonts.inter(
                                  color: const Color(0xFF575D78),
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on_outlined,
                                size: 10,
                                color: Color(0xFF8E95A5),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                team.location,
                                style: GoogleFonts.inter(
                                  color: const Color(0xFF575D78),
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Action Icons
                    Row(
                      children: [
                        IconButton(
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.all(8),
                          icon: const Icon(
                            Icons.qr_code,
                            color: Color(0xFF575D78),
                            size: 18,
                          ),
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              backgroundColor: Colors.transparent,
                              builder: (context) => _buildQRBottomSheet(context, team),
                            );
                          },
                        ),
                        IconButton(
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.all(8),
                          icon: const Icon(
                            Icons.remove_red_eye_outlined,
                            color: Color(0xFF575D78),
                            size: 18,
                          ),
                          onPressed: () {
                            context.push(
                              '/team-squad',
                              extra: {
                                'teamId': team.id,
                                'readOnly': true,
                              },
                            );
                          },
                        ),
                        if (isAdmin && !isSelectionMode)
                          IconButton(
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.all(8),
                            icon: const Icon(
                              Icons.edit_outlined,
                              color: Color(0xFF575D78),
                              size: 18,
                            ),
                            onPressed: () {
                              context.push('/edit-squad', extra: team.id);
                            },
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
    ),
    );
  }

  Widget _buildQRBottomSheet(BuildContext context, TeamData team) {
    // Prefer the human-readable team code for the QR payload; fallback to UUID
    final qrData = team.teamCode.isNotEmpty ? team.teamCode : team.id;
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFDDE0E8),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '${team.name} QR Code',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF191C1E),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Color(0xFF575D78)),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Scan this code to find this team in Discovery',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF575D78),
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: QrImageView(
              data: qrData,
              version: QrVersions.auto,
              size: 200.0,
              backgroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          // Team code label below QR
          if (team.teamCode.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F9FC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFDDE0E8)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.tag, size: 16, color: Color(0xFF575D78)),
                  const SizedBox(width: 6),
                  Text(
                    team.teamCode,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF191C1E),
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
