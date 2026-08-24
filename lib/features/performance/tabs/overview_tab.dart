import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../providers/career_stats_provider.dart';
import '../../../core/theme/colors.dart';
import '../../../models/user_profile.dart';

class OverviewTab extends StatelessWidget {
  final AsyncValue<CareerStats> statsAsync;
  final UserProfile profile;

  const OverviewTab({
    super.key,
    required this.statsAsync,
    required this.profile,
  });

  @override
  Widget build(BuildContext context) {
    return statsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (e, _) => _buildError(),
      data: (stats) => _buildContent(stats),
    );
  }

  Widget _buildContent(CareerStats stats) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
      children: [
        // 4-card quick stats grid
        _buildSectionTitle('CAREER OVERVIEW'),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.6,
          children: [
            _OverviewStatCard(
              label: 'MATCHES',
              value: '${stats.matches}',
              icon: Icons.sports_cricket,
              color: AppColors.primary,
            ),
            _OverviewStatCard(
              label: 'TOTAL RUNS',
              value: '${stats.totalRuns}',
              icon: Icons.trending_up,
              color: const Color(0xFF006B1B),
            ),
            _OverviewStatCard(
              label: 'WICKETS',
              value: '${stats.totalWickets}',
              icon: Icons.crisis_alert,
              color: const Color(0xFF1565C0),
            ),
            _OverviewStatCard(
              label: 'CATCHES',
              value: '${stats.catches}',
              icon: Icons.back_hand_outlined,
              color: const Color(0xFF6A1B9A),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Recent Form
        _buildSectionTitle('RECENT FORM'),
        const SizedBox(height: 12),
        _buildRecentForm(stats.recentForm),

        const SizedBox(height: 24),

        // Quick Batting Snapshot
        if (stats.matches > 0) ...[
          _buildSectionTitle('BATTING SNAPSHOT'),
          const SizedBox(height: 12),
          _buildBattingSnapshot(stats),
          const SizedBox(height: 24),
        ],

        // Quick Bowling Snapshot
        if (stats.totalWickets > 0) ...[
          _buildSectionTitle('BOWLING SNAPSHOT'),
          const SizedBox(height: 12),
          _buildBowlingSnapshot(stats),
          const SizedBox(height: 24),
        ],

        if (stats.matches == 0) _buildEmptyState(),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppColors.primary,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildRecentForm(List<String> form) {
    if (form.isEmpty) {
      return _buildEmptyCard('No matches played yet');
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ...form.map((result) => _FormDot(result: result)),
              if (form.length < 5)
                ...List.generate(
                  5 - form.length,
                  (_) => const _FormDot(result: '?'),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Last ${form.length} match${form.length == 1 ? '' : 'es'}',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: const Color(0xFF575D78),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBattingSnapshot(CareerStats stats) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Expanded(child: _SnapshotItem(label: 'Average', value: stats.battingAvg.toStringAsFixed(1))),
          _divider(),
          Expanded(child: _SnapshotItem(label: 'Strike Rate', value: stats.strikeRate.toStringAsFixed(1))),
          _divider(),
          Expanded(child: _SnapshotItem(label: 'Highest', value: '${stats.highScore}')),
        ],
      ),
    );
  }

  Widget _buildBowlingSnapshot(CareerStats stats) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Expanded(child: _SnapshotItem(label: 'Economy', value: stats.economy.toStringAsFixed(1))),
          _divider(),
          Expanded(child: _SnapshotItem(label: 'Avg', value: stats.bowlingAvg.toStringAsFixed(1))),
          _divider(),
          Expanded(child: _SnapshotItem(label: 'Best', value: stats.bestBowling)),
        ],
      ),
    );
  }

  Widget _divider() {
    return Container(width: 1, height: 40, color: const Color(0xFFECEEF1));
  }

  Widget _buildEmptyCard(String message) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Center(
        child: Text(
          message,
          style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF575D78)),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Color(0xFFECEEF1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.sports_cricket, size: 48, color: Color(0xFF575D78)),
            ),
            const SizedBox(height: 16),
            Text(
              'No Match Data Yet',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF191C1E),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Play some matches to see your career statistics here.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF575D78)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return const Center(child: Text('Error loading stats'));
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: const [
        BoxShadow(
          color: Color.fromRGBO(26, 33, 56, 0.06),
          blurRadius: 16,
          offset: Offset(0, 4),
        ),
      ],
    );
  }
}

class _OverviewStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _OverviewStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(26, 33, 56, 0.06),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF191C1E),
                  height: 1.1,
                ),
              ),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF575D78),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FormDot extends StatelessWidget {
  final String result;
  const _FormDot({required this.result});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color text;
    switch (result) {
      case 'W':
        bg = const Color(0xFF006B1B);
        text = Colors.white;
        break;
      case 'L':
        bg = AppColors.primary;
        text = Colors.white;
        break;
      case 'D':
        bg = const Color(0xFF575D78);
        text = Colors.white;
        break;
      default:
        bg = const Color(0xFFECEEF1);
        text = const Color(0xFF575D78);
    }
    return Container(
      margin: const EdgeInsets.only(right: 10),
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: bg.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          result,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: text,
          ),
        ),
      ),
    );
  }
}

class _SnapshotItem extends StatelessWidget {
  final String label;
  final String value;
  const _SnapshotItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF191C1E),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: const Color(0xFF575D78),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
