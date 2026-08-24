import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../providers/career_stats_provider.dart';
import '../../../core/theme/colors.dart';

class BattingTab extends StatelessWidget {
  final AsyncValue<CareerStats> statsAsync;

  const BattingTab({super.key, required this.statsAsync});

  @override
  Widget build(BuildContext context) {
    return statsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (e, _) => const Center(child: Text('Error loading stats')),
      data: (stats) {
        if (stats.innings == 0) return _buildEmptyState();
        return _buildContent(stats);
      },
    );
  }

  Widget _buildContent(CareerStats stats) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
      children: [
        // Primary 3 hero cards
        _sectionTitle('BATTING OVERVIEW'),
        const SizedBox(height: 12),
        _buildHeroRow(stats),

        const SizedBox(height: 20),

        // Secondary grid
        _buildSecondaryGrid(stats),

        const SizedBox(height: 24),

        // Performance trend chart
        _sectionTitle('PERFORMANCE TREND'),
        const SizedBox(height: 12),
        _buildRunsChart(stats),

        const SizedBox(height: 24),

        // Recent Innings
        _sectionTitle('RECENT INNINGS'),
        const SizedBox(height: 12),
        _buildRecentInnings(stats),

        const SizedBox(height: 24),

        // Milestones
        _sectionTitle('MILESTONES'),
        const SizedBox(height: 12),
        _buildMilestones(stats),

        const SizedBox(height: 24),

        // Dismissal breakdown
        _sectionTitle('DISMISSAL BREAKDOWN'),
        const SizedBox(height: 12),
        _buildDismissalChart(stats),

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
        _HeroStatCard(
          label: 'RUNS',
          value: '${stats.totalRuns}',
          color: AppColors.primary,
          isLarge: true,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            children: [
              _HeroStatCard(
                label: 'AVERAGE',
                value: stats.battingAvg.toStringAsFixed(1),
                color: const Color(0xFF006B1B),
                isLarge: false,
              ),
              const SizedBox(height: 10),
              _HeroStatCard(
                label: 'STRIKE RATE',
                value: stats.strikeRate.toStringAsFixed(1),
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
      {'label': 'MATCHES', 'value': '${stats.matches}'},
      {'label': 'INNINGS', 'value': '${stats.innings}'},
      {'label': 'HIGHEST', 'value': '${stats.highScore}'},
      {'label': '50s', 'value': '${stats.fifties}'},
      {'label': '100s', 'value': '${stats.hundreds}'},
      {'label': '4s', 'value': '${stats.fours}'},
      {'label': '6s', 'value': '${stats.sixes}'},
      {'label': 'BALLS', 'value': '${stats.ballsFaced}'},
      {'label': 'NOT OUTS', 'value': '${stats.notOuts}'},
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
      itemBuilder: (context, i) => _SecondaryStatTile(
        label: items[i]['label']!,
        value: items[i]['value']!,
      ),
    );
  }

  Widget _buildRunsChart(CareerStats stats) {
    if (stats.runsPerMatch.isEmpty) {
      return _emptyCard('No innings data yet');
    }
    return Container(
      height: 160,
      padding: const EdgeInsets.all(16),
      decoration: _cardDeco(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Runs per match',
            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF575D78)),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: CustomPaint(
              size: Size.infinite,
              painter: _LineChartPainter(
                data: stats.runsPerMatch,
                lineColor: AppColors.primary,
                avgValue: stats.runsPerMatch.isEmpty ? 0 : stats.runsPerMatch.reduce((a, b) => a + b) / stats.runsPerMatch.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentInnings(CareerStats stats) {
    if (stats.recentInnings.isEmpty) return _emptyCard('No innings data yet');
    return Container(
      decoration: _cardDeco(),
      child: Column(
        children: stats.recentInnings.asMap().entries.map((e) {
          final idx = e.key;
          final inning = e.value;
          final score = inning['runs'] as int;
          final balls = inning['balls'] as int;
          final isNotOut = inning['notOut'] as bool;
          final sr = balls > 0 ? (score / balls * 100) : 0.0;
          return Column(
            children: [
              if (idx > 0) const Divider(height: 1, color: Color(0xFFECEEF1)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '$score${isNotOut ? '*' : ''}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: isNotOut ? const Color(0xFF006B1B) : const Color(0xFF191C1E),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '($balls balls)  •  SR ${sr.toStringAsFixed(1)}',
                        style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF575D78)),
                      ),
                    ),
                    if (isNotOut)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF006B1B).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'NOT OUT',
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF006B1B),
                          ),
                        ),
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

  Widget _buildMilestones(CareerStats stats) {
    return Row(
      children: [
        Expanded(child: _MilestoneCard(label: '50s', value: '${stats.fifties}', icon: Icons.star_half, color: const Color(0xFFF9A825))),
        const SizedBox(width: 10),
        Expanded(child: _MilestoneCard(label: '100s', value: '${stats.hundreds}', icon: Icons.star, color: const Color(0xFFFF8F00))),
        const SizedBox(width: 10),
        Expanded(child: _MilestoneCard(label: 'BEST', value: '${stats.highScore}', icon: Icons.emoji_events, color: AppColors.primary)),
      ],
    );
  }

  Widget _buildDismissalChart(CareerStats stats) {
    // Placeholder data since ball-level dismissal types aren't tracked yet
    final segments = <_DonutSegment>[
      _DonutSegment(label: 'Caught', value: 40, color: AppColors.primary),
      _DonutSegment(label: 'Bowled', value: 25, color: const Color(0xFF1565C0)),
      _DonutSegment(label: 'LBW', value: 15, color: const Color(0xFF6A1B9A)),
      _DonutSegment(label: 'Run Out', value: 12, color: const Color(0xFFF9A825)),
      _DonutSegment(label: 'Stumped', value: 8, color: const Color(0xFF006B1B)),
    ];
    return _DonutChartCard(segments: segments, title: 'Dismissal Types');
  }

  Widget _buildAdditionalMetrics(CareerStats stats) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDeco(),
      child: Column(
        children: [
          _MetricRow(label: 'Boundary %', value: '${stats.boundaryPct.toStringAsFixed(1)}%'),
          const Divider(height: 16, color: Color(0xFFECEEF1)),
          _MetricRow(label: 'Ducks', value: '${stats.ducks}'),
          const Divider(height: 16, color: Color(0xFFECEEF1)),
          _MetricRow(label: 'Not Outs', value: '${stats.notOuts}'),
        ],
      ),
    );
  }

  Widget _emptyCard(String message) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDeco(),
      child: Center(
        child: Text(message, style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF575D78))),
      ),
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
              child: const Icon(Icons.sports_cricket, size: 48, color: Color(0xFF575D78)),
            ),
            const SizedBox(height: 16),
            Text('No Batting Data', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w700, color: const Color(0xFF191C1E))),
            const SizedBox(height: 8),
            Text(
              'Your batting statistics will appear here once you start scoring matches.',
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
        boxShadow: const [
          BoxShadow(color: Color.fromRGBO(26, 33, 56, 0.06), blurRadius: 16, offset: Offset(0, 4)),
        ],
      );
}

// ─── Hero Stat Card ──────────────────────────────────────────────────────────

class _HeroStatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool isLarge;

  const _HeroStatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.isLarge,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: isLarge ? 130 : null,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: isLarge
            ? LinearGradient(
                colors: [color, color.withValues(alpha: 0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isLarge ? null : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isLarge ? null : Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: isLarge ? 0.3 : 0.1),
            blurRadius: isLarge ? 16 : 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: isLarge ? Colors.white.withValues(alpha: 0.85) : const Color(0xFF575D78),
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: isLarge ? 32 : 20,
              fontWeight: FontWeight.w800,
              color: isLarge ? Colors.white : color,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Secondary Stat Tile ─────────────────────────────────────────────────────

class _SecondaryStatTile extends StatelessWidget {
  final String label;
  final String value;
  const _SecondaryStatTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFECEEF1)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF191C1E),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF575D78),
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Milestone Card ──────────────────────────────────────────────────────────

class _MilestoneCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _MilestoneCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Color.fromRGBO(26, 33, 56, 0.06), blurRadius: 16, offset: Offset(0, 4))],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.w800, color: const Color(0xFF191C1E)),
          ),
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: const Color(0xFF575D78)),
          ),
        ],
      ),
    );
  }
}

// ─── Metric Row ──────────────────────────────────────────────────────────────

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
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF191C1E)),
        ),
      ],
    );
  }
}

// ─── Line Chart Painter ───────────────────────────────────────────────────────

class _LineChartPainter extends CustomPainter {
  final List<double> data;
  final Color lineColor;
  final double avgValue;

  _LineChartPainter({required this.data, required this.lineColor, required this.avgValue});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final maxVal = data.reduce(math.max);
    final minVal = data.reduce(math.min);
    final range = (maxVal - minVal).clamp(1.0, double.infinity);

    final paintLine = Paint()
      ..color = lineColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final paintFill = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [lineColor.withValues(alpha: 0.2), lineColor.withValues(alpha: 0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final paintAvg = Paint()
      ..color = const Color(0xFF575D78).withValues(alpha: 0.4)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final paintDot = Paint()
      ..color = lineColor
      ..style = PaintingStyle.fill;

    final points = <Offset>[];
    final step = size.width / (data.length - 1).clamp(1, 999);

    for (int i = 0; i < data.length; i++) {
      final x = i * step;
      final y = size.height - ((data[i] - minVal) / range) * (size.height * 0.85) - size.height * 0.05;
      points.add(Offset(x, y));
    }

    // Fill area
    final fillPath = Path()..moveTo(points.first.dx, size.height);
    for (final p in points) {
      fillPath.lineTo(p.dx, p.dy);
    }
    fillPath.lineTo(points.last.dx, size.height);
    fillPath.close();
    canvas.drawPath(fillPath, paintFill);

    // Line
    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      linePath.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(linePath, paintLine);

    // Avg reference line
    final avgY = size.height - ((avgValue - minVal) / range) * (size.height * 0.85) - size.height * 0.05;
    canvas.drawLine(Offset(0, avgY), Offset(size.width, avgY), paintAvg);

    // Dots
    for (final p in points) {
      canvas.drawCircle(p, 4, Paint()..color = Colors.white..style = PaintingStyle.fill);
      canvas.drawCircle(p, 3, paintDot);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ─── Donut Chart ─────────────────────────────────────────────────────────────

class _DonutSegment {
  final String label;
  final double value;
  final Color color;
  const _DonutSegment({required this.label, required this.value, required this.color});
}

class _DonutChartCard extends StatelessWidget {
  final List<_DonutSegment> segments;
  final String title;
  const _DonutChartCard({required this.segments, required this.title});

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
          SizedBox(
            width: 120,
            height: 120,
            child: CustomPaint(painter: _DonutPainter(segments: segments)),
          ),
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
    final paint = Paint()..style = PaintingStyle.stroke..strokeWidth = 20;

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
