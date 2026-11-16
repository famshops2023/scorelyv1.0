import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/colors.dart';
import '../../teams/providers/teams_provider.dart';

/// Role selection card used across match setup screens.
///
/// Extracted from Opening Lineup so the same card (and styling) can be reused
/// for the Official Scorer section on the Toss screen.
class MatchRoleCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final TeamMember? player;
  final VoidCallback onSelect;
  final bool isLocked;

  const MatchRoleCard({
    super.key,
    required this.title,
    required this.icon,
    required this.onSelect,
    this.player,
    this.isLocked = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isLocked ? const Color(0xFFF1F3F6) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isLocked
            ? Border.all(color: const Color(0xFFE2E4E9), width: 1.5)
            : null,
        boxShadow: isLocked
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isLocked
                          ? const Color(0xFF98A2B3)
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                ),
                if (isLocked)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0E2E7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'ASSIGNED',
                      style: GoogleFonts.inter(
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF667085),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const Spacer(),
          if (player == null)
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: Color(0xFFF2F4F8),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.primary, size: 24),
            )
          else
            Column(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor:
                      isLocked ? const Color(0xFF98A2B3) : AppColors.lightTextPrimary,
                  child: Text(
                    player!.name[0].toUpperCase(),
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  player!.name,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isLocked
                        ? const Color(0xFF667085)
                        : AppColors.lightTextPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 36,
            child: TextButton(
              onPressed: isLocked ? null : onSelect,
              style: TextButton.styleFrom(
                backgroundColor:
                    isLocked ? const Color(0xFFEAECF0) : const Color(0xFFF2F4F8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                isLocked
                    ? 'ALREADY SELECTED ✓'
                    : (player == null ? 'SELECT' : 'CHANGE'),
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isLocked ? const Color(0xFF667085) : AppColors.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
