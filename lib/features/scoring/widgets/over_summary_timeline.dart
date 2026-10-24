import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scorely/core/theme/colors.dart';

class OverSummaryTimeline extends StatelessWidget {
  final List<String> thisOver;
  final int ballsBowled;
  final int historyIndex;
  final int historyLength;
  final VoidCallback? onUndo;
  final VoidCallback? onRedo;

  const OverSummaryTimeline({
    super.key,
    required this.thisOver,
    required this.ballsBowled,
    required this.historyIndex,
    required this.historyLength,
    this.onUndo,
    this.onRedo,
  });

  @override
  Widget build(BuildContext context) {
    int overRuns = 0;
    for (var ball in thisOver) {
      if (ball.contains('Wd')) {
        final runs = int.tryParse(ball.replaceAll('Wd', '')) ?? 0;
        overRuns += 1 + runs;
      } else if (ball.contains('Nb')) {
        final runs = int.tryParse(ball.replaceAll('Nb', '')) ?? 0;
        overRuns += 1 + runs;
      } else if (ball.contains('B')) {
        final runs = int.tryParse(ball.replaceAll('B', '')) ?? 0;
        overRuns += runs;
      } else if (ball.contains('LB')) {
        final runs = int.tryParse(ball.replaceAll('LB', '')) ?? 0;
        overRuns += runs;
      } else if (ball == 'W') {
        overRuns += 0;
      } else if (ball == '.') {
        overRuns += 0;
      } else {
        final runs = int.tryParse(ball) ?? 0;
        overRuns += runs;
      }
    }

    int currentOverIndex = ballsBowled ~/ 6;
    int ballsInCurrentOver = ballsBowled % 6;
    String overDisplay = '$currentOverIndex.$ballsInCurrentOver';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'THIS OVER: $overDisplay',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[400],
                ),
              ),
              Text(
                'Runs: $overRuns',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: thisOver.map((ball) {
                  Color bg = const Color(0xFF0F172A);
                  Color fg = Colors.white;

                  if (ball == 'W') {
                    bg = AppColors.primary;
                    fg = Colors.white;
                  } else if (ball == '4' || ball == '6') {
                    bg = AppColors.success;
                    fg = Colors.black;
                  } else if (ball == '.') {
                    bg = AppColors.darkCard2;
                    fg = Colors.grey;
                  } else if (ball.contains('Wd') || ball.contains('Nb')) {
                    bg = AppColors.warning;
                    fg = Colors.white;
                  }

                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: bg,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      ball,
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: fg,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.undo, size: 20),
                color: historyIndex > 0 ? Colors.white : Colors.grey[700],
                onPressed: historyIndex > 0 ? onUndo : null,
              ),
              IconButton(
                icon: const Icon(Icons.redo, size: 20),
                color: historyIndex < historyLength - 1
                    ? Colors.white
                    : Colors.grey[700],
                onPressed: historyIndex < historyLength - 1 ? onRedo : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
