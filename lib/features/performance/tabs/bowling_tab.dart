import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../providers/career_stats_provider.dart';
import '../../../core/theme/colors.dart';

class BowlingTab extends StatelessWidget {
  final AsyncValue<CareerStats> statsAsync;

  const BowlingTab({super.key, required this.statsAsync});

  @override
  Widget build(BuildContext context) {
    return statsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (e, _) => const Center(child: Text('Error loading stats')),
      data: (stats) {
        if (stats.totalWickets == 0 && stats.overs == 0) return _buildEmptyState();
        return _buildContent(stats);
      },
    );
  }

  Widget _buildContent(CareerStats stats) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
      children: [
        // Primary 3 hero cards
        _sectionTitle('BOWLING OVERVIEW'),
        const SizedBox(height: 12),
        _buildHeroRow(stats),

        const SizedBox(height: 20),

        // Secondary grid
        _buildSecondaryGrid(stats),

        const SizedBox(height: 24),

        // Bowling trend
        _sectionTitle('BOWLING PERFORMANCE TREND'),
        const SizedBox(height: 12),
        _buildWicketsChart(stats),

        const SizedBox(height: 24),

        // Recent bowling figures
        _sectionTitle('RECENT BOWLING'),
        const SizedBox(height: 12),
        _buildRecentBowling(stats),

        const SizedBox(height: 24),

        // Wicket breakdown donut
        _sectionTitle('WICKET BREAKDOWN'),
        const SizedBox(height: 12),
        _buildWicketDonut(),

        const SizedBox(height: 24),

        // Bowling milestones
        _sectionTitle('MILESTONES'),
        const SizedBox(height: 12),
        _buildMilestones(stats),

        const SizedBox(height: 24),

        // Additional metrics
        _sectionTitle('ADDITIONAL METRICS'),
        const SizedBox(height: 12),
        _buildAdditionalMetrics(stats),
      ],
    );
  }

  Widget _sectionTitle(String title) {
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

  Widget _buildHeroRow(CareerStats stats) {
    return Row(
      children: [
        _HeroStatCard(label: 'WICKETS', value: '${stats.totalWickets}', color: AppColors.primary, isLarge: true),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            children: [
              _HeroStatCard(
                label: 'ECONOMY',
                value: stats.economy.toStringAsFixed(1),
                color: const Color(0xFF006B1B),
                isLarge: false,
              ),
              const SizedBox(height: 10),
              _HeroStatCard(
                label: 'AVERAGE',
                value: stats.bowlingAvg.toStringAsFixed(1),
                color: const Color(0xFF1565C0),
                isLarge: false,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSecondaryGrid(CareerStats stats) {
    final items = [
      {'label': 'OVERS', 'value': '${stats.overs}'},
      {'label': 'MAIDENS', 'value': '${stats.maidens}'},
      {'label': 'RUNS', 'value': '${stats.runsConceded}'},
      {'label': '4W HAULS', 'value': '${stats.fourWicketHauls}'},
      {'label': '5W HAULS', 'value': '${stats.fiveWicketHauls}'},
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.5,
      ),
      itemCount: items.length,
      itemBuilder: (context, i) => _SecondaryStatTile(label: items[i]['label']!, value: items[i]['value']!),
    );
  }

  Widget _buildWicketsChart(CareerStats stats) {
    if (stats.wicketsPerMatch.isEmpty) return _emptyCard('No bowling data yet');
    return Container(
      height: 160,
      padding: const EdgeInsets.all(16),
      decoration: _cardDeco(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Wickets per match',
            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF575D78)),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: CustomPaint(
              size: Size.infinite,
              painter: _BarChartPainter(data: stats.wicketsPerMatch, barColor: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentBowling(CareerStats stats) {
    if (stats.recentBowling.isEmpty) return _emptyCard('No bowling data yet');
    return Container(
      decoration: _cardDeco(),
      child: Column(
        children: stats.recentBowling.asMap().entries.map((e) {
          final idx = e.key;
          final b = e.value;
          final overs = b['overs'] as int;
          final maidens = b['maidens'] as int;
          final runs = b['runs'] as int;
          final wickets = b['wickets'] as int;
          final figure = '$overs-$maidens-$runs-$wickets';
          return Column(
            children: [
              if (idx > 0) const Divider(height: 1, color: Color(0xFFECEEF1)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Text(
                      figure,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: wickets >= 3 ? AppColors.primary : const Color(0xFF191C1E),
                      ),
                    ),
                    const Spacer(),
                    if (wickets >= 5)
                      _WicketBadge(label: '5W', color: AppColors.primary)
                    else if (wickets >= 4)
                      _WicketBadge(label: '4W', color: const Color(0xFF6A1B9A)),
                    Text(
                      'Match ${e.key + 1}',
                      style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF575D78)),
                    ),
                  ],
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildWicketDonut() {
    final segments = <_DonutSegment>[
      _DonutSegment(label: 'Caught', value: 35, color: AppColors.primary),
      _DonutSegment(label: 'Bowled', value: 30, color: const Color(0xFF1565C0)),
      _DonutSegment(label: 'LBW', value: 20, color: const Color(0xFF6A1B9A)),
      _DonutSegment(label: 'Stumped', value: 10, color: const Color(0xFFF9A825)),
      _DonutSegment(label: 'Run Out', value: 5, color: const Color(0xFF006B1B)),
    ];
    return _DonutChartCard(segments: segments);
  }

  Widget _buildMilestones(CareerStats stats) {
    return Row(
      children: [
        Expanded(child: _MilestoneCard(label: 'WICKETS', value: '${stats.totalWickets}', icon: Icons.crisis_alert, color: AppColors.primary)),
        const SizedBox(width: 10),
        Expanded(child: _MilestoneCard(label: '4W HAULS', value: '${stats.fourWicketHauls}', icon: Icons.bolt, color: const Color(0xFF6A1B9A))),
        const SizedBox(width: 10),
        Expanded(child: _MilestoneCard(label: '5W HAULS', value: '${stats.fiveWicketHauls}', icon: Icons.emoji_events, color: const Color(0xFFF9A825))),
        const SizedBox(width: 10),
        Expanded(child: _MilestoneCard(label: 'BEST', value: stats.bestBowling, icon: Icons.military_tech, color: const Color(0xFF006B1B))),
      ],
    );
  }

  Widget _buildAdditionalMetrics(CareerStats stats) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDeco(),
      child: Column(
        children: [
          _MetricRow(label: 'Maidens', value: '${stats.maidens}'),
          const Divider(height: 16, color: Color(0xFFECEEF1)),
          _MetricRow(label: 'Wides', value: '${stats.wides}'),
          const Divider(height: 16, color: Color(0xFFECEEF1)),
          _MetricRow(label: 'No Balls', value: '${stats.noBalls}'),
          const Divider(height: 16, color: Color(0xFFECEEF1)),
          _MetricRow(label: 'Runs Conceded', value: '${stats.runsConceded}'),
        ],
      ),
    );
  }

  Widget _emptyCard(String message) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDeco(),
      child: Center(child: Text(message, style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF575D78)))),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(color: Color(0xFFECEEF1), shape: BoxShape.circle),
              child: const Icon(Icons.crisis_alert, size: 48, color: Color(0xFF575D78)),
            ),
            const SizedBox(height: 16),
            Text('No Bowling Data', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w700, color: const Color(0xFF191C1E))),
            const SizedBox(height: 8),
            Text(
              'Your bowling statistics will appear here once you start scoring matches.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF575D78)),
            ),
          ],
        ),
      ),
    );
  }

  BoxDecoration _cardDeco() => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Color.fromRGBO(26, 33, 56, 0.06), blurRadius: 16, offset: Offset(0, 4))],
      );
}

// ─── Shared widgets ───────────────────────────────────────────────────────────

class _HeroStatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool isLarge;
  const _HeroStatCard({required this.label, required this.value, required this.color, required this.isLarge});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: isLarge ? 130 : null,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: isLarge ? LinearGradient(colors: [color, color.withValues(alpha: 0.8)], begin: Alignment.topLeft, end: Alignment.bottomRight) : null,
        color: isLarge ? null : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isLarge ? null : Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [BoxShadow(color: color.withValues(alpha: isLarge ? 0.3 : 0.1), blurRadius: isLarge ? 16 : 8, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: isLarge ? Colors.white.withValues(alpha: 0.85) : const Color(0xFF575D78), letterSpacing: 0.8)),
          const SizedBox(height: 6),
          Text(value, style: GoogleFonts.plusJakartaSans(fontSize: isLarge ? 32 : 20, fontWeight: FontWeight.w800, color: isLarge ? Colors.white : color, height: 1.0)),
        ],
      ),
    );
  }
}

class _SecondaryStatTile extends StatelessWidget {
  final String label;
  final String value;
  const _SecondaryStatTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFECEEF1))),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: const Color(0xFF191C1E))),
          const SizedBox(height: 2),
          Text(label, style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w600, color: const Color(0xFF575D78), letterSpacing: 0.5)),
        ],
      ),
    );
  }
}

class _MilestoneCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _MilestoneCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Color.fromRGBO(26, 33, 56, 0.06), blurRadius: 16, offset: Offset(0, 4))],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 6),
          Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: const Color(0xFF191C1E))),
          Text(label, style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w600, color: const Color(0xFF575D78))),
        ],
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  final String label;
  final String value;
  const _MetricRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF575D78))),
        Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF191C1E))),
      ],
    );
  }
}

class _WicketBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _WicketBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(label, style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700, color: color)),
    );
  }
}

class _DonutSegment {
  final String label;
  final double value;
  final Color color;
  const _DonutSegment({required this.label, required this.value, required this.color});
}

class _DonutChartCard extends StatelessWidget {
  final List<_DonutSegment> segments;
  const _DonutChartCard({required this.segments});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Color.fromRGBO(26, 33, 56, 0.06), blurRadius: 16, offset: Offset(0, 4))],
      ),
      child: Row(
        children: [
          SizedBox(width: 110, height: 110, child: CustomPaint(painter: _DonutPainter(segments: segments))),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: segments.map((s) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Container(width: 10, height: 10, decoration: BoxDecoration(color: s.color, shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Expanded(child: Text(s.label, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF575D78)))),
                    Text('${s.value.toInt()}%', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF191C1E))),
                  ],
                ),
              )).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<_DonutSegment> segments;
  _DonutPainter({required this.segments});

  @override
  void paint(Canvas canvas, Size size) {
    final total = segments.fold(0.0, (sum, s) => sum + s.value);
    if (total == 0) return;
    final rect = Rect.fromLTWH(8, 8, size.width - 16, size.height - 16);
    double startAngle = -math.pi / 2;
    final paint = Paint()..style = PaintingStyle.stroke..strokeWidth = 18;
    for (final seg in segments) {
      final sweepAngle = (seg.value / total) * 2 * math.pi;
      paint.color = seg.color;
      canvas.drawArc(rect, startAngle, sweepAngle - 0.03, false, paint);
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _BarChartPainter extends CustomPainter {
  final List<double> data;
  final Color barColor;
  _BarChartPainter({required this.data, required this.barColor});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    final maxVal = data.reduce(math.max).clamp(1.0, double.infinity);
    final barWidth = (size.width / data.length) * 0.6;
    final gap = (size.width / data.length) * 0.4;
    final paint = Paint()..style = PaintingStyle.fill..color = barColor;
    final paintBg = Paint()..style = PaintingStyle.fill..color = barColor.withValues(alpha: 0.1);

    for (int i = 0; i < data.length; i++) {
      final x = i * (barWidth + gap);
      final barHeight = (data[i] / maxVal) * (size.height * 0.9);
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, size.height - barHeight, barWidth, barHeight),
        const Radius.circular(4),
      );
      final bgRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, 0, barWidth, size.height),
        const Radius.circular(4),
      );
      canvas.drawRRect(bgRect, paintBg);
      canvas.drawRRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
