import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../providers/career_stats_provider.dart';
import '../../../core/theme/colors.dart';

class FieldingTab extends StatelessWidget {
  final AsyncValue<CareerStats> statsAsync;

  const FieldingTab({super.key, required this.statsAsync});

  @override
  Widget build(BuildContext context) {
    return statsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (e, _) => const Center(child: Text('Error loading stats')),
      data: (stats) => _buildContent(stats),
    );
  }

  Widget _buildContent(CareerStats stats) {
    final totalExtras = stats.wides + stats.noBalls;
    final widesRatio = totalExtras > 0 ? stats.wides / totalExtras : 0.5;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
      children: [
        // Fielding Performance Card (matches design from image)
        _sectionTitle('FIELDING PERFORMANCE'),
        const SizedBox(height: 12),
        _buildFieldingCard(stats),

        const SizedBox(height: 24),

        // Discipline Monitor (matches image exactly)
        _sectionTitle('DISCIPLINE MONITOR'),
        const SizedBox(height: 12),
        _buildDisciplineCard(stats, totalExtras, widesRatio),

        const SizedBox(height: 24),

        // Fielding breakdown
        _sectionTitle('FIELDING IMPACT'),
        const SizedBox(height: 12),
        _buildFieldingImpact(stats),
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

  Widget _buildFieldingCard(CareerStats stats) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDeco(),
      child: Column(
        children: [
          _FieldingRow(
            icon: Icons.sports_baseball,
            label: 'Catches Taken',
            value: stats.catchesTaken,
            color: AppColors.primary,
          ),
          const Divider(height: 24, color: Color(0xFFECEEF1)),
          _FieldingRow(
            icon: Icons.directions_run,
            label: 'Run-Out Involvements',
            value: stats.runOutInvolvements,
            color: const Color(0xFF1565C0),
          ),
          const Divider(height: 24, color: Color(0xFFECEEF1)),
          _FieldingRow(
            icon: Icons.back_hand_outlined,
            label: 'Stumpings',
            value: stats.stumpings,
            color: const Color(0xFF6A1B9A),
          ),
        ],
      ),
    );
  }

  Widget _buildDisciplineCard(CareerStats stats, int totalExtras, double widesRatio) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDeco(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Extras',
                    style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF575D78), fontWeight: FontWeight.w500),
                  ),
                  Text(
                    '$totalExtras',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 40,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF191C1E),
                      height: 1.1,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.sports_cricket, color: AppColors.primary, size: 28),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Wides vs No-balls bar
          if (totalExtras > 0) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Stack(
                children: [
                  Container(height: 10, width: double.infinity, color: const Color(0xFF1565C0)),
                  FractionallySizedBox(
                    widthFactor: widesRatio,
                    child: Container(height: 10, color: AppColors.primary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Container(width: 10, height: 10, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
                const SizedBox(width: 6),
                Text('Wides (${stats.wides})', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF575D78))),
                const Spacer(),
                Container(width: 10, height: 10, decoration: const BoxDecoration(color: Color(0xFF1565C0), shape: BoxShape.circle)),
                const SizedBox(width: 6),
                Text('No-Balls (${stats.noBalls})', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF575D78))),
              ],
            ),
          ] else
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF006B1B).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  '✓ No extras conceded — excellent discipline!',
                  style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF006B1B), fontWeight: FontWeight.w600),
                ),
              ),
            ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F9FC),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 14, color: Color(0xFF575D78)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Aim to reduce total extras to below 5 per match for optimal performance rating.',
                    style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF575D78), height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldingImpact(CareerStats stats) {
    final total = (stats.catchesTaken + stats.runOutInvolvements + stats.stumpings).toDouble();
    if (total == 0) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: _cardDeco(),
        child: Center(
          child: Column(
            children: [
              const Icon(Icons.back_hand_outlined, size: 40, color: Color(0xFF575D78)),
              const SizedBox(height: 10),
              Text(
                'No fielding data yet',
                style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF575D78)),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDeco(),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            height: 100,
            child: CustomPaint(
              painter: _DonutPainter(segments: [
                _DonutSeg(value: stats.catchesTaken.toDouble(), color: AppColors.primary),
                _DonutSeg(value: stats.runOutInvolvements.toDouble(), color: const Color(0xFF1565C0)),
                _DonutSeg(value: stats.stumpings.toDouble(), color: const Color(0xFF6A1B9A)),
              ]),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ImpactLegend(label: 'Catches', value: stats.catchesTaken, color: AppColors.primary),
                const SizedBox(height: 6),
                _ImpactLegend(label: 'Run Outs', value: stats.runOutInvolvements, color: const Color(0xFF1565C0)),
                const SizedBox(height: 6),
                _ImpactLegend(label: 'Stumpings', value: stats.stumpings, color: const Color(0xFF6A1B9A)),
                const SizedBox(height: 10),
                const Divider(color: Color(0xFFECEEF1), height: 1),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total Dismissals', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF575D78))),
                    Text('${total.toInt()}', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800, color: const Color(0xFF191C1E))),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDeco() => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Color.fromRGBO(26, 33, 56, 0.06), blurRadius: 16, offset: Offset(0, 4))],
      );
}

// ─── Widgets ─────────────────────────────────────────────────────────────────

class _FieldingRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;
  final Color color;

  const _FieldingRow({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFF191C1E)),
          ),
        ),
        Text(
          '$value',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: value > 0 ? color : const Color(0xFF575D78),
          ),
        ),
      ],
    );
  }
}

class _ImpactLegend extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _ImpactLegend({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF575D78)))),
        Text('$value', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF191C1E))),
      ],
    );
  }
}

class _DonutSeg {
  final double value;
  final Color color;
  const _DonutSeg({required this.value, required this.color});
}

class _DonutPainter extends CustomPainter {
  final List<_DonutSeg> segments;
  _DonutPainter({required this.segments});

  @override
  void paint(Canvas canvas, Size size) {
    final total = segments.fold(0.0, (sum, s) => sum + s.value);
    if (total == 0) return;
    final rect = Rect.fromLTWH(6, 6, size.width - 12, size.height - 12);
    double startAngle = -math.pi / 2;
    final paint = Paint()..style = PaintingStyle.stroke..strokeWidth = 16;
    for (final seg in segments) {
      final sweepAngle = (seg.value / total) * 2 * math.pi;
      paint.color = seg.color;
      canvas.drawArc(rect, startAngle, sweepAngle - 0.04, false, paint);
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
