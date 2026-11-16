import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/colors.dart';
import '../../../models/player_setup.dart';
import '../../../models/user_profile.dart';
import '../../teams/providers/teams_provider.dart';

class ScorerCandidate {
  final String id;
  final String profileId;
  final String name;
  final String teamName;
  final String role;
  final String? email;

  const ScorerCandidate({
    required this.id,
    required this.profileId,
    required this.name,
    required this.teamName,
    required this.role,
    this.email,
  });

  String get displayId => UserProfile.deriveDisplayId(profileId);
}

class ScorerSelectionSheet extends ConsumerStatefulWidget {
  final String matchTitle;
  final String currentScorerId;
  final String teamAName;
  final String teamBName;
  final List<PlayerSetupData> teamAPlayers;
  final List<PlayerSetupData> teamBPlayers;
  final Function(ScorerCandidate selected) onCandidateSelected;

  const ScorerSelectionSheet({
    super.key,
    required this.matchTitle,
    required this.currentScorerId,
    required this.teamAName,
    required this.teamBName,
    required this.teamAPlayers,
    required this.teamBPlayers,
    required this.onCandidateSelected,
  });

  @override
  ConsumerState<ScorerSelectionSheet> createState() => _ScorerSelectionSheetState();
}

class _ScorerSelectionSheetState extends ConsumerState<ScorerSelectionSheet> {
  String _searchQuery = '';

  List<ScorerCandidate> _getCandidates() {
    final List<ScorerCandidate> candidates = [];

    // 1. Collect candidate players from Team A
    for (final p in widget.teamAPlayers) {
      if (p.profileId != null &&
          p.profileId!.isNotEmpty &&
          p.profileId != widget.currentScorerId) {
        candidates.add(ScorerCandidate(
          id: p.profileId!,
          profileId: p.profileId!,
          name: p.name,
          teamName: widget.teamAName,
          role: p.role.displayName,
        ));
      }
    }

    // 2. Collect candidate players from Team B
    for (final p in widget.teamBPlayers) {
      if (p.profileId != null &&
          p.profileId!.isNotEmpty &&
          p.profileId != widget.currentScorerId &&
          !candidates.any((c) => c.profileId == p.profileId)) {
        candidates.add(ScorerCandidate(
          id: p.profileId!,
          profileId: p.profileId!,
          name: p.name,
          teamName: widget.teamBName,
          role: p.role.displayName,
        ));
      }
    }

    // 3. Also check database teams if available
    final teams = ref.read(teamsProvider).value ?? [];
    for (final team in teams) {
      if (team.name == widget.teamAName || team.name == widget.teamBName) {
        for (final m in team.members) {
          if (m.profileId != null &&
              m.profileId!.isNotEmpty &&
              m.profileId != widget.currentScorerId &&
              !candidates.any((c) => c.profileId == m.profileId)) {
            candidates.add(ScorerCandidate(
              id: m.id,
              profileId: m.profileId!,
              name: m.name,
              teamName: team.name,
              role: m.roles.isNotEmpty ? m.roles.first : 'Player',
            ));
          }
        }
      }
    }

    if (_searchQuery.isEmpty) return candidates;
    final q = _searchQuery.toLowerCase().trim();
    return candidates.where((c) {
      final nameMatches = c.name.toLowerCase().contains(q);
      final idMatches = c.displayId.toLowerCase().contains(q) ||
          c.displayId.replaceAll('-', '').toLowerCase().contains(q.replaceAll('-', ''));
      return nameMatches || idMatches;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final candidates = _getCandidates();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Assign Scorer',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Choose a signed player to request scorer takeover',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.lightTextSecondary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          // Search box
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by player name or SP-ID (e.g. SP-1042)...',
                hintStyle: GoogleFonts.inter(fontSize: 13, color: AppColors.lightTextSecondary),
                prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.lightTextSecondary),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                filled: true,
                fillColor: const Color(0xFFF2F4F8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ),
          const Divider(height: 1, color: Color(0xFFECEEF1)),
          // List of candidates
          Flexible(
            child: candidates.isEmpty
                ? Container(
                    padding: const EdgeInsets.all(32),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.person_off_outlined, size: 48, color: AppColors.lightBorder),
                        const SizedBox(height: 12),
                        Text(
                          'No Signed-in Players Found',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.lightTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Only players with registered Scorely accounts can receive scorer handover requests.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shrinkWrap: true,
                    itemCount: candidates.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final candidate = candidates[index];
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFECEEF1)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: AppColors.darkSurface,
                              child: Text(
                                candidate.name.isNotEmpty
                                    ? candidate.name[0].toUpperCase()
                                    : 'P',
                                style: GoogleFonts.plusJakartaSans(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
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
                                          candidate.name,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            color: AppColors.lightTextPrimary,
                                          ),
                                          overflow: TextOverflow.ellipsis,
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
                                          UserProfile.deriveDisplayId(candidate.profileId),
                                          style: GoogleFonts.inter(
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.primary,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withValues(alpha: 0.08),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          candidate.teamName,
                                          style: GoogleFonts.inter(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        candidate.role,
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          color: AppColors.lightTextSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                elevation: 0,
                              ),
                              onPressed: () {
                                Navigator.pop(context);
                                widget.onCandidateSelected(candidate);
                              },
                              child: Text(
                                'REQUEST',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
