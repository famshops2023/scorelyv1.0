import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

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

  @override
  Widget build(BuildContext context) {
    final allTeams = ref.watch(teamsProvider);
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
                    onPressed: () {
                      context.push('/edit-squad', extra: '');
                    },
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
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(
                horizontal: 17.0,
                vertical: 8.0,
              ),
              itemCount: displayTeams.length,
              itemBuilder: (context, index) {
                final team = displayTeams[index];

                // Determine if current user is admin for this team
                bool isAdmin = false;
                final userMember = team.members
                    .where((m) => m.id == currentUserId)
                    .firstOrNull;
                if (userMember != null && userMember.isAdmin) {
                  isAdmin = true;
                }

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
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return LayoutBuilder(
      builder: (context, _) {
        final bottomInset = MediaQuery.of(context).viewPadding.bottom;
        return Container(
          padding: EdgeInsets.only(
            bottom: 12 + bottomInset,
            top: 10,
            left: 14,
            right: 14,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Color.fromRGBO(26, 33, 56, 0.05),
                blurRadius: 20,
                offset: Offset(0, -4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              GestureDetector(
                onTap: () => context.push('/home'),
                child: _buildNavItem(Icons.home, 'Home', false),
              ),
              _buildNavItem(Icons.people_alt, 'Teams', true),
              GestureDetector(
                onTap: () => context.push('/history'),
                child: _buildNavItem(Icons.history, 'History', false),
              ),
              GestureDetector(
                onTap: () => context.push('/profile'),
                child: _buildNavItem(Icons.person_outline, 'Profile', false),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isActive) {
    if (isActive) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFFFFE8E6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: const Color(0xFFBA0013), size: 20),
            const SizedBox(height: 3),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: const Color(0xFFBA0013),
              ),
            ),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFF575D78), size: 20),
          const SizedBox(height: 3),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF575D78),
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
}
