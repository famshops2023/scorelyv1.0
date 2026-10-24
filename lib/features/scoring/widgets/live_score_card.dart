import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scorely/core/theme/colors.dart';

class LiveScoreCard extends StatelessWidget {
  final String teamAName;
  final String teamBName;
  final String battingTeam;
  final int runs;
  final int wickets;
  final int ballsBowled;
  final int totalOvers;
  final bool isSecondInnings;
  final int firstInningsRuns;
  final int firstInningsWickets;
  final int? target;

  const LiveScoreCard({
    super.key,
    required this.teamAName,
    required this.teamBName,
    required this.battingTeam,
    required this.runs,
    required this.wickets,
    required this.ballsBowled,
    required this.totalOvers,
    required this.isSecondInnings,
    required this.firstInningsRuns,
    required this.firstInningsWickets,
    this.target,
  });

  @override
  Widget build(BuildContext context) {
    double crr = ballsBowled == 0 ? 0.0 : (runs / (ballsBowled / 6));

    String rrrText = '---';
    String targetText = '---';
    String needsText = '';

    if (isSecondInnings && target != null) {
      targetText = '$target';
      int remainingRuns = target! - runs;
      int remainingBalls = (totalOvers * 6) - ballsBowled;

      if (remainingRuns <= 0) {
        needsText = '$battingTeam Won';
      } else if (remainingBalls <= 0) {
        needsText = '$battingTeam Lost by $remainingRuns runs';
      } else {
        needsText = 'Need $remainingRuns runs in $remainingBalls balls';
      }

      if (remainingBalls > 0) {
        double rrr = (remainingRuns / (remainingBalls / 6));
        rrrText = rrr.toStringAsFixed(2);
      } else {
        rrrText = '0.00';
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      decoration: const BoxDecoration(
        color: AppColors.darkNavBg,
        border: Border(
          bottom: BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${teamAName.toUpperCase()} VS ${teamBName.toUpperCase()}',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[400],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.5),
                      blurRadius: 8,
                      spreadRadius: 1,
                    )
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.circle, color: Colors.white, size: 8),
                    const SizedBox(width: 4),
                    Text(
                      'LIVE',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            isSecondInnings
                ? '2nd INNINGS (1st Inn: $firstInningsRuns/$firstInningsWickets)'
                : '1st INNINGS',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            battingTeam.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$runs/$wickets',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 48,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.0,
            ),
          ),
          Text(
            '(${ballsBowled ~/ 6}.${ballsBowled % 6} / $totalOvers Overs)',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              color: Colors.grey[400],
            ),
          ),
          if (isSecondInnings && needsText.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              needsText,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.success,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              _buildScoreGridItem('CRR', crr.toStringAsFixed(2)),
              _buildDivider(),
              _buildScoreGridItem('RRR', rrrText),
              _buildDivider(),
              _buildScoreGridItem('TARGET', targetText),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 30,
      color: Colors.white10,
    );
  }

  Widget _buildScoreGridItem(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
