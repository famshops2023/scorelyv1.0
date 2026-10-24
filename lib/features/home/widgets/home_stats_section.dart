import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scorely/core/theme/colors.dart';
import '../../../providers/history_provider.dart';

class HomeStatsSection extends ConsumerWidget {
  const HomeStatsSection({super.key});

  Widget _buildStatCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: const Border(
          bottom: BorderSide(color: AppColors.primary, width: 2),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(26, 33, 56, 0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.lightTextSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 19,
              fontWeight: FontWeight.w600,
              color: AppColors.lightTextPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerRow() {
    return Row(
      children: List.generate(
        3,
        (i) => Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i < 2 ? 10 : 0),
            child: Container(
              height: 66,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow(String matches, String runs, String wickets) {
    return Row(
      children: [
        Expanded(child: _buildStatCard('MATCHES', matches)),
        const SizedBox(width: 10),
        Expanded(child: _buildStatCard('MY RUNS', runs)),
        const SizedBox(width: 10),
        Expanded(child: _buildStatCard('MY WKTS', wickets)),
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(homePersonalStatsProvider);

    final labelBold = GoogleFonts.inter(
      fontSize: 12,
      fontWeight: FontWeight.bold,
      color: AppColors.lightTextSecondary,
      letterSpacing: 0.5,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header with "PERSONAL" badge
        Row(
          children: [
            Text('MY STATS', style: labelBold),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'PERSONAL',
                style: GoogleFonts.inter(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Turf / Box row
        Text('TURF / BOX', style: labelBold),
        const SizedBox(height: 10),
        statsAsync.when(
          loading: _buildShimmerRow,
          error: (e, st) => _buildStatRow('–', '–', '–'),
          data: (s) => _buildStatRow(
            '${s.turfMatches}',
            '${s.turfRuns}',
            '${s.turfWickets}',
          ),
        ),

        const SizedBox(height: 20),

        // Ground Matches row
        Text('GROUND MATCHES', style: labelBold),
        const SizedBox(height: 10),
        statsAsync.when(
          loading: _buildShimmerRow,
          error: (e, st) => _buildStatRow('–', '–', '–'),
          data: (s) => _buildStatRow(
            '${s.groundMatches}',
            '${s.groundRuns}',
            '${s.groundWickets}',
          ),
        ),
      ],
    );
  }
}
