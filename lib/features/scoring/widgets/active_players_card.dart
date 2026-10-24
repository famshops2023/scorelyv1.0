import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scorely/core/theme/colors.dart';
import '../../../models/match_stats.dart';

class ActivePlayersCard extends StatelessWidget {
  final String? strikerName;
  final BatterStats strikerStats;
  final String? nonStrikerName;
  final BatterStats nonStrikerStats;
  final String? currentBowler;
  final BowlerStats bowlerStats;
  final VoidCallback onSwapStrike;
  final VoidCallback onRetireBatter;
  final void Function(bool isStriker) onChangeBatter;
  final VoidCallback onChangeBowler;

  const ActivePlayersCard({
    super.key,
    required this.strikerName,
    required this.strikerStats,
    required this.nonStrikerName,
    required this.nonStrikerStats,
    required this.currentBowler,
    required this.bowlerStats,
    required this.onSwapStrike,
    required this.onRetireBatter,
    required this.onChangeBatter,
    required this.onChangeBowler,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkCard2,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 35,
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(3),
                          bottomLeft: Radius.circular(3),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => onChangeBatter(true),
                        behavior: HitTestBehavior.opaque,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${(strikerName ?? 'Striker').toUpperCase()} *',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Colors.white,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${strikerStats.runs} (${strikerStats.balls}) • 4s:${strikerStats.fours} 6s:${strikerStats.sixes}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: Colors.grey[400],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.swap_calls,
                        color: AppColors.success, size: 22),
                    tooltip: 'Swap Strike',
                    onPressed: onSwapStrike,
                  ),
                  IconButton(
                    icon: const Icon(Icons.exit_to_app,
                        color: AppColors.primary, size: 22),
                    tooltip: 'Retire Batter',
                    onPressed: onRetireBatter,
                  ),
                ],
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => onChangeBatter(false),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        (nonStrikerName ?? 'Non-Striker').toUpperCase(),
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                          color: Colors.grey[300],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${nonStrikerStats.runs} (${nonStrikerStats.balls}) • 4s:${nonStrikerStats.fours} 6s:${nonStrikerStats.sixes}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(color: Colors.white10),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'BOWLER',
                      style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[400]),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      (currentBowler ?? 'Bowler').toUpperCase(),
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.white),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Text(
                '${bowlerStats.oversDisplay} - M:${bowlerStats.maidens} - R:${bowlerStats.runsConceded} - W:${bowlerStats.wickets}',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: onChangeBowler,
                style: TextButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.05),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Change',
                  style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.success),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
