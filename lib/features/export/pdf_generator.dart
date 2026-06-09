import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../services/database.dart';
import '../../models/match_stats.dart';

// Scorely brand colors as PDF colors
const _primaryRed = PdfColor.fromInt(0xFFBA0013);
const _navyDark = PdfColor.fromInt(0xFF1A2238);

const _surfaceContainer = PdfColor.fromInt(0xFFECEEF1);
const _surfaceVariant = PdfColor.fromInt(0xFFE0E3E6);
const _onSurface = PdfColor.fromInt(0xFF191C1E);
const _secondary = PdfColor.fromInt(0xFF575D78);
const _green = PdfColor.fromInt(0xFF006B1B);

class PdfGenerator {
  /// Generates a full match scorecard PDF with all details, scorecards, and awards.
  static Future<Uint8List> generateFullScorecard({
    required CricketMatch match,
    required Team? teamA,
    required Team? teamB,
    required InningsStats innings1,
    required InningsStats innings2,
    required MVPData mvp,
    required BestPlayerData bestBatter,
    required BestPlayerData bestBowler,
  }) async {
    final pdf = pw.Document();

    // ---- PAGE 1: Match Cover + Details + Innings Summary ----
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _buildPageHeader(match, teamA, teamB),
        footer: (context) => _buildPageFooter(context),
        build: (context) => [
          _buildMatchInfoSection(match, innings1, innings2),
          pw.SizedBox(height: 20),
          _buildMatchResultSection(match, innings1, innings2),
          pw.SizedBox(height: 20),
          _buildAwardsSection(mvp, bestBatter, bestBowler),
          pw.SizedBox(height: 20),
          _buildInningsScorecardSection('1ST INNINGS', innings1, innings2.teamName),
          pw.SizedBox(height: 20),
          _buildInningsScorecardSection('2ND INNINGS', innings2, innings1.teamName),
        ],
      ),
    );

    return pdf.save();
  }

  // ---- LEGACY: Simple scorecard (kept for backward compat) ----
  static Future<Uint8List> generateScorecard(CricketMatch match) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('SCORELY SCORECARD', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 20)),
              pw.SizedBox(height: 12),
              pw.Text(match.matchTitle, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              pw.Text('Date: ${_formatDate(match.createdAt)}'),
              pw.SizedBox(height: 8),
              pw.Text('Result: ${match.winnerTeamName ?? 'N/A'}'),
            ],
          );
        },
      ),
    );
    return pdf.save();
  }

  // ======================== SECTION BUILDERS ========================

  static pw.Widget _buildPageHeader(CricketMatch match, Team? teamA, Team? teamB) {
    return pw.Column(
      children: [
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: const pw.BoxDecoration(color: _navyDark),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'SCORELY',
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    'Official Match Scorecard',
                    style: const pw.TextStyle(color: PdfColors.white, fontSize: 10),
                  ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    '${teamA?.name ?? 'Team A'} vs ${teamB?.name ?? 'Team B'}',
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    _formatDate(match.createdAt),
                    style: const pw.TextStyle(color: PdfColors.white, fontSize: 10),
                  ),
                ],
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 16),
      ],
    );
  }

  static pw.Widget _buildPageFooter(pw.Context context) {
    return pw.Column(
      children: [
        pw.Divider(color: _surfaceVariant),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Generated by Scorely · ${_formatDate(DateTime.now())}',
              style: const pw.TextStyle(color: _secondary, fontSize: 9),
            ),
            pw.Text(
              'Page ${context.pageNumber} of ${context.pagesCount}',
              style: const pw.TextStyle(color: _secondary, fontSize: 9),
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildMatchInfoSection(CricketMatch match, InningsStats innings1, InningsStats innings2) {
    final tossTeam = innings1.teamName;
    final format = match.totalOvers <= 20 ? 'T${match.totalOvers}' : match.totalOvers <= 50 ? 'ODI (${match.totalOvers} Overs)' : 'Club (${match.totalOvers} Overs)';

    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _surfaceVariant),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: const pw.BoxDecoration(color: _primaryRed),
            child: pw.Text(
              'MATCH DETAILS',
              style: pw.TextStyle(color: PdfColors.white, fontSize: 11, fontWeight: pw.FontWeight.bold, letterSpacing: 1.5),
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Table(
            columnWidths: {
              0: const pw.FlexColumnWidth(1),
              1: const pw.FlexColumnWidth(2),
              2: const pw.FlexColumnWidth(1),
              3: const pw.FlexColumnWidth(2),
            },
            children: [
              pw.TableRow(children: [
                _infoLabel('FORMAT'),
                _infoValue(format),
                _infoLabel('DATE'),
                _infoValue('${_formatDate(match.createdAt)} | ${_formatTime(match.createdAt)}'),
              ]),
              pw.TableRow(children: [
                _infoLabel('VENUE'),
                _infoValue('Local Ground'),
                _infoLabel('TOSS'),
                _infoValue('$tossTeam batted first'),
              ]),
              pw.TableRow(children: [
                _infoLabel('MATCH'),
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 4),
                  child: pw.Text(match.matchTitle, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: _onSurface)),
                ),
                _infoLabel('STATUS'),
                _infoValue(match.isCompleted ? 'Completed' : 'In Progress'),
              ]),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildMatchResultSection(CricketMatch match, InningsStats innings1, InningsStats innings2) {
    final winner = match.winnerTeamName ?? 'Match Tied';
    String resultText;
    if (innings2.totalRuns > innings1.totalRuns) {
      final wicketsLeft = 10 - innings2.totalWickets;
      resultText = '$winner won by $wicketsLeft wickets';
    } else if (innings1.totalRuns > innings2.totalRuns) {
      final runsMargin = innings1.totalRuns - innings2.totalRuns;
      resultText = '$winner won by $runsMargin runs';
    } else {
      resultText = 'Match Tied';
    }

    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(16),
      decoration: const pw.BoxDecoration(color: _primaryRed, borderRadius: pw.BorderRadius.all(pw.Radius.circular(8))),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('MATCH RESULT', style: pw.TextStyle(color: PdfColors.white, fontSize: 10, fontWeight: pw.FontWeight.bold, letterSpacing: 2.0)),
          pw.SizedBox(height: 6),
          pw.Text(resultText, style: pw.TextStyle(color: PdfColors.white, fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 12),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              _scoreChip(innings1.teamName, '${innings1.totalRuns}/${innings1.totalWickets}', '(${innings1.totalOvers} Ov)'),
              pw.Text('VS', style: pw.TextStyle(color: const PdfColor.fromInt(0xB3FFFFFF), fontSize: 14, fontWeight: pw.FontWeight.bold)),
              _scoreChip(innings2.teamName, '${innings2.totalRuns}/${innings2.totalWickets}', '(${innings2.totalOvers} Ov)'),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildAwardsSection(MVPData mvp, BestPlayerData bestBatter, BestPlayerData bestBowler) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _surfaceVariant),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: const pw.BoxDecoration(color: _navyDark),
            child: pw.Text('MATCH AWARDS', style: pw.TextStyle(color: PdfColors.white, fontSize: 11, fontWeight: pw.FontWeight.bold, letterSpacing: 1.5)),
          ),
          pw.SizedBox(height: 12),
          pw.Row(
            children: [
              _awardCard('🏆 Player of Match / MVP', mvp.name, '${mvp.teamName} · ${mvp.stats}'),
              pw.SizedBox(width: 12),
              _awardCard('🏏 Best Batter', bestBatter.name, '${bestBatter.teamName} · ${bestBatter.stats}'),
              pw.SizedBox(width: 12),
              _awardCard('🎳 Best Bowler', bestBowler.name, '${bestBowler.teamName} · ${bestBowler.stats}'),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildInningsScorecardSection(String label, InningsStats innings, String bowlingTeamName) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Innings header
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: const pw.BoxDecoration(color: _navyDark),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('$label — ${innings.teamName}', style: pw.TextStyle(color: PdfColors.white, fontSize: 12, fontWeight: pw.FontWeight.bold)),
              pw.Text(
                '${innings.totalRuns}/${innings.totalWickets} (${innings.totalOvers} Ov)',
                style: pw.TextStyle(color: PdfColors.white, fontSize: 14, fontWeight: pw.FontWeight.bold),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 4),

        // Batting table
        pw.Text('BATTING', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: _secondary, letterSpacing: 1.0)),
        pw.SizedBox(height: 4),
        _buildBattingTable(innings),
        pw.SizedBox(height: 4),
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          color: _surfaceContainer,
          child: pw.Text('EXTRAS  ${innings.extrasInfo}', style: const pw.TextStyle(fontSize: 10, color: _secondary)),
        ),
        pw.SizedBox(height: 12),

        // Fall of wickets
        if (innings.fallOfWickets.isNotEmpty) ...[
          pw.Text('FALL OF WICKETS', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: _secondary, letterSpacing: 1.0)),
          pw.SizedBox(height: 4),
          _buildFowRow(innings.fallOfWickets),
          pw.SizedBox(height: 12),
        ],

        // Bowling table
        pw.Text('BOWLING — ${bowlingTeamName.toUpperCase()}', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: _secondary, letterSpacing: 1.0)),
        pw.SizedBox(height: 4),
        _buildBowlingTable(innings),
      ],
    );
  }

  // ======================== TABLE BUILDERS ========================

  static pw.Widget _buildBattingTable(InningsStats innings) {
    final batters = innings.batterStats.values.toList();
    final headerStyle = pw.TextStyle(color: PdfColors.white, fontSize: 10, fontWeight: pw.FontWeight.bold);
    final cellStyle = const pw.TextStyle(fontSize: 10, color: _onSurface);
    final dimStyle = const pw.TextStyle(fontSize: 9, color: _secondary);

    return pw.Table(
      border: pw.TableBorder.all(color: _surfaceVariant, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FixedColumnWidth(30),
        2: const pw.FixedColumnWidth(30),
        3: const pw.FixedColumnWidth(25),
        4: const pw.FixedColumnWidth(25),
        5: const pw.FixedColumnWidth(40),
      },
      children: [
        // Header
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: _navyDark),
          children: ['BATTER', 'R', 'B', '4s', '6s', 'SR']
              .map((h) => pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                    child: pw.Text(h, style: headerStyle, textAlign: h == 'BATTER' ? pw.TextAlign.left : pw.TextAlign.center),
                  ))
              .toList(),
        ),
        // Data rows
        ...batters.map((b) {
          final isNotOut = !b.isOut;
          return pw.TableRow(
            decoration: pw.BoxDecoration(color: isNotOut ? const PdfColor.fromInt(0xFFFFF5F5) : PdfColors.white),
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(children: [
                      pw.Text(b.name, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: _onSurface)),
                      if (isNotOut) pw.Text(' *', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: _primaryRed)),
                    ]),
                    pw.Text(isNotOut ? 'not out' : b.dismissalInfo, style: dimStyle),
                  ],
                ),
              ),
              _tableCell('${b.runs}', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: _onSurface)),
              _tableCell('${b.balls}', style: cellStyle),
              _tableCell('${b.fours}', style: cellStyle),
              _tableCell('${b.sixes}', style: cellStyle),
              _tableCell(b.strikeRate.toStringAsFixed(1), style: cellStyle),
            ],
          );
        }),
      ],
    );
  }

  static pw.Widget _buildBowlingTable(InningsStats innings) {
    final bowlers = innings.bowlerStats.values.toList();
    final headerStyle = pw.TextStyle(color: PdfColors.white, fontSize: 10, fontWeight: pw.FontWeight.bold);
    final cellStyle = const pw.TextStyle(fontSize: 10, color: _onSurface);

    return pw.Table(
      border: pw.TableBorder.all(color: _surfaceVariant, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FixedColumnWidth(35),
        2: const pw.FixedColumnWidth(25),
        3: const pw.FixedColumnWidth(30),
        4: const pw.FixedColumnWidth(25),
        5: const pw.FixedColumnWidth(35),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: _navyDark),
          children: ['BOWLER', 'O', 'M', 'R', 'W', 'ER']
              .map((h) => pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                    child: pw.Text(h, style: headerStyle, textAlign: h == 'BOWLER' ? pw.TextAlign.left : pw.TextAlign.center),
                  ))
              .toList(),
        ),
        ...bowlers.map((b) => pw.TableRow(
              decoration: b.wickets > 0 ? const pw.BoxDecoration(color: PdfColor.fromInt(0xFFF0FFF0)) : null,
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                  child: pw.Text(b.name, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: _onSurface)),
                ),
                _tableCell(b.oversDisplay, style: cellStyle),
                _tableCell('${b.maidens}', style: cellStyle),
                _tableCell('${b.runsConceded}', style: cellStyle),
                _tableCell(
                  '${b.wickets}',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: b.wickets > 0 ? pw.FontWeight.bold : pw.FontWeight.normal,
                    color: b.wickets > 0 ? _green : _onSurface,
                  ),
                ),
                _tableCell(b.economy.toStringAsFixed(1), style: cellStyle),
              ],
            )),
      ],
    );
  }

  static pw.Widget _buildFowRow(List<FallOfWicket> fow) {
    return pw.Wrap(
      spacing: 6,
      runSpacing: 4,
      children: fow.map((w) {
        return pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: _surfaceVariant),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
          ),
          child: pw.Column(
            children: [
              pw.Text('${w.score}/${w.wicketNumber}', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: _primaryRed)),
              pw.Text('${w.playerName} (${w.overInfo})', style: const pw.TextStyle(fontSize: 8, color: _secondary)),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ======================== SMALL HELPERS ========================

  static pw.Widget _tableCell(String text, {pw.TextStyle? style}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      child: pw.Text(text, style: style, textAlign: pw.TextAlign.center),
    );
  }

  static pw.Widget _infoLabel(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Text(text, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: _secondary, letterSpacing: 0.8)),
    );
  }

  static pw.Widget _infoValue(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Text(text, style: const pw.TextStyle(fontSize: 11, color: _onSurface)),
    );
  }

  static pw.Widget _scoreChip(String teamName, String score, String overs) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Text(teamName, style: const pw.TextStyle(color: PdfColors.white, fontSize: 10)),
        pw.SizedBox(height: 4),
        pw.Text(score, style: pw.TextStyle(color: PdfColors.white, fontSize: 20, fontWeight: pw.FontWeight.bold)),
        pw.Text(overs, style: const pw.TextStyle(color: PdfColor.fromInt(0xB3FFFFFF), fontSize: 10)),
      ],
    );
  }

  static pw.Widget _awardCard(String title, String name, String subtitle) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          color: _surfaceContainer,
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(title, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: _secondary)),
            pw.SizedBox(height: 4),
            pw.Text(name, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: _onSurface)),
            pw.SizedBox(height: 2),
            pw.Text(subtitle, style: const pw.TextStyle(fontSize: 9, color: _secondary)),
          ],
        ),
      ),
    );
  }

  // ======================== DATE HELPERS ========================

  static String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  static String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

/// Simple data container passed from match_stat_screen to the PDF generator.
class MVPData {
  final String name;
  final String teamName;
  final String stats;
  MVPData({required this.name, required this.teamName, required this.stats});
}

class BestPlayerData {
  final String name;
  final String teamName;
  final String stats;
  BestPlayerData({required this.name, required this.teamName, required this.stats});
}
