import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../features/export/pdf_generator.dart';
import '../models/match_stats.dart';
import '../services/database.dart';
import '../services/mvp_calculator.dart';

class PdfDownloadService {
  /// Generates the PDF and saves it to the Downloads folder silently.
  /// Shows a SnackBar on completion (success or failure).
  static Future<void> downloadMatchPdf({
    required BuildContext context,
    required CricketMatch match,
    required Team? teamA,
    required Team? teamB,
    required InningsStats innings1,
    required InningsStats innings2,
    required List<BallEvent> allBalls,
    required List<Player> teamAPlayers,
    required List<Player> teamBPlayers,
  }) async {
    // Show generating indicator
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: const [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            ),
            SizedBox(width: 12),
            Text('Generating PDF…'),
          ],
        ),
        duration: const Duration(seconds: 10),
        backgroundColor: const Color(0xFF1A2238),
      ),
    );

    try {
      // ---- Compute awards data ----
      final mvpResult = MvpCalculator.calculateMVP(match, teamA, teamB, teamAPlayers, teamBPlayers, allBalls);

      // Best batter: most runs across both innings
      BatterStats? topBatter;
      int maxRuns = -1;
      for (var b in innings1.batterStats.values.followedBy(innings2.batterStats.values)) {
        if (b.runs > maxRuns) {
          maxRuns = b.runs;
          topBatter = b;
        }
      }

      // Best bowler: most wickets, then least economy
      BowlerStats? topBowler;
      int maxWickets = -1;
      double bestEconomy = double.infinity;
      for (var b in innings1.bowlerStats.values.followedBy(innings2.bowlerStats.values)) {
        if (b.wickets > maxWickets || (b.wickets == maxWickets && b.economy < bestEconomy)) {
          maxWickets = b.wickets;
          bestEconomy = b.economy;
          topBowler = b;
        }
      }

      // ---- Determine which team the best batter/bowler belongs to ----
      final teamAPlayerNames = teamAPlayers.map((p) => p.name).toSet();

      String teamFor(String name) {
        return teamAPlayerNames.contains(name) ? (teamA?.name ?? 'Team A') : (teamB?.name ?? 'Team B');
      }

      // ---- Build PDF ----
      final pdfBytes = await PdfGenerator.generateFullScorecard(
        match: match,
        teamA: teamA,
        teamB: teamB,
        innings1: innings1,
        innings2: innings2,
        mvp: MVPData(
          name: mvpResult.playerName,
          teamName: mvpResult.teamName,
          stats: mvpResult.detailedStats,
        ),
        bestBatter: BestPlayerData(
          name: topBatter?.name ?? 'N/A',
          teamName: topBatter != null ? teamFor(topBatter.name) : '-',
          stats: topBatter != null ? '${topBatter.runs} runs (${topBatter.balls} balls)' : '',
        ),
        bestBowler: BestPlayerData(
          name: topBowler?.name ?? 'N/A',
          teamName: topBowler != null ? teamFor(topBowler.name) : '-',
          stats: topBowler != null ? '${topBowler.wickets} wickets, Eco: ${topBowler.economy.toStringAsFixed(1)}' : '',
        ),
      );

      // ---- Build filename ----
      final teamAName = (teamA?.name ?? 'TeamA').replaceAll(' ', '_');
      final teamBName = (teamB?.name ?? 'TeamB').replaceAll(' ', '_');
      final dateStr = '${match.createdAt.day.toString().padLeft(2, '0')}'
          '${match.createdAt.month.toString().padLeft(2, '0')}'
          '${match.createdAt.year}';
      final fileName = 'Matchstat_${teamAName}_vs_${teamBName}_$dateStr.pdf';

      // ---- Share PDF natively ----
      if (context.mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
      }

      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: fileName,
      );

    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(child: Text('Failed to generate PDF: $e')),
              ],
            ),
            backgroundColor: const Color(0xFFBA0013),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }
}
