import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/match_stats.dart';
import '../../services/database.dart';

class ScoreboardScreen extends StatefulWidget {
  final CricketMatch match;
  final InningsStats innings1;
  final InningsStats innings2;
  final List<BallEvent> innings1Balls;
  final List<BallEvent> innings2Balls;

  const ScoreboardScreen({
    super.key,
    required this.match,
    required this.innings1,
    required this.innings2,
    required this.innings1Balls,
    required this.innings2Balls,
  });

  @override
  State<ScoreboardScreen> createState() => _ScoreboardScreenState();
}

class _ScoreboardScreenState extends State<ScoreboardScreen> {
  late InningsStats _selectedInnings;

  @override
  void initState() {
    super.initState();
    _selectedInnings = widget.innings1;
  }

  List<BallEvent> get _currentBalls =>
      _selectedInnings == widget.innings1 ? widget.innings1Balls : widget.innings2Balls;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildScoreOverview(),
          const SizedBox(height: 16),
          _buildSegmentedControl(),
          const SizedBox(height: 16),
          _buildBattingScorecard(),
          const SizedBox(height: 16),
          _buildFallOfWickets(),
          const SizedBox(height: 16),
          _buildBowlingAnalysis(),
          const SizedBox(height: 16),
          _buildOverByOver(),
        ],
      ),
    );
  }

  Widget _buildScoreOverview() {
    final isLive = !widget.match.isCompleted;
    final inningsText = _selectedInnings == widget.innings1 ? '1st Innings' : '2nd Innings';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: const Border(left: BorderSide(color: Color(0xFFBA0013), width: 4)),
        boxShadow: const [
          BoxShadow(color: Color.fromRGBO(26, 33, 56, 0.08), blurRadius: 20, offset: Offset(0, 4)),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (isLive) ...[
                      Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF006B1B), shape: BoxShape.circle)),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      '${isLive ? 'LIVE • ' : ''}$inningsText',
                      style: GoogleFonts.inter(
                        color: isLive ? const Color(0xFF006B1B) : const Color(0xFF575D78),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _selectedInnings.teamName,
                  style: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.w700, color: const Color(0xFF191C1E)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${_selectedInnings.totalRuns}/${_selectedInnings.totalWickets}',
                style: GoogleFonts.plusJakartaSans(fontSize: 36, fontWeight: FontWeight.bold, letterSpacing: -1.0, color: const Color(0xFF191C1E), height: 1.0),
              ),
              const SizedBox(height: 4),
              Text(
                '${_selectedInnings.totalOvers} Overs',
                style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF575D78)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentedControl() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: const Color(0xFFECEEF1), borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          Expanded(child: _buildSegmentButton(widget.innings1)),
          Expanded(child: _buildSegmentButton(widget.innings2)),
        ],
      ),
    );
  }

  Widget _buildSegmentButton(InningsStats innings) {
    final isSelected = _selectedInnings == innings;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedInnings = innings;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isSelected ? [const BoxShadow(color: Color.fromRGBO(0, 0, 0, 0.05), blurRadius: 4, offset: Offset(0, 2))] : null,
        ),
        alignment: Alignment.center,
        child: Text(
          innings.teamName.toUpperCase(),
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isSelected ? const Color(0xFFBA0013) : const Color(0xFF575D78),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  double _calculateRunRate(InningsStats innings) {
    if (innings.totalOvers.isEmpty) return 0.0;
    final parts = innings.totalOvers.split('.');
    if (parts.length != 2) return 0.0;
    final overs = int.tryParse(parts[0]) ?? 0;
    final balls = int.tryParse(parts[1]) ?? 0;
    final totalBalls = (overs * 6) + balls;
    if (totalBalls == 0) return 0.0;
    return (innings.totalRuns / totalBalls) * 6;
  }

  Widget _buildBattingScorecard() {
    final rr = _calculateRunRate(_selectedInnings);
    final batters = _selectedInnings.batterStats.values.toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Color.fromRGBO(26, 33, 56, 0.08), blurRadius: 20, offset: Offset(0, 4))],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(color: Color(0xFF131B31), borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('BATTING', style: GoogleFonts.inter(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                Text('RR: ${rr.toStringAsFixed(2)}', style: GoogleFonts.inter(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Container(
            color: const Color(0xFFF2F4F7),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(flex: 4, child: Text('BATTER', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF575D78)))),
                Expanded(flex: 1, child: Text('R', textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF575D78)))),
                Expanded(flex: 1, child: Text('B', textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF575D78)))),
                Expanded(flex: 1, child: Text('4s', textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF575D78)))),
                Expanded(flex: 1, child: Text('6s', textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF575D78)))),
                Expanded(flex: 2, child: Text('SR', textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF575D78)))),
              ],
            ),
          ),
          if (batters.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('No batting data available', style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF575D78))),
            ),
          ...batters.asMap().entries.map((e) {
            final isNotOut = !e.value.isOut;
            return Container(
              decoration: BoxDecoration(
                color: isNotOut ? const Color(0xFFBA0013).withValues(alpha: 0.05) : Colors.white,
                border: const Border(bottom: BorderSide(color: Color(0xFFE0E3E6))),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                e.value.name,
                                style: GoogleFonts.inter(fontSize: 14, fontWeight: isNotOut ? FontWeight.bold : FontWeight.w500, color: const Color(0xFF191C1E)),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isNotOut) ...[
                              const SizedBox(width: 4),
                              const Text('*', style: TextStyle(color: Color(0xFFBA0013), fontWeight: FontWeight.bold)),
                            ]
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isNotOut ? 'NOT OUT' : e.value.dismissalInfo,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: isNotOut ? FontWeight.bold : FontWeight.normal,
                            fontStyle: isNotOut ? FontStyle.normal : FontStyle.italic,
                            color: isNotOut ? const Color(0xFF006B1B) : const Color(0xFF575D78),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Expanded(flex: 1, child: Text('${e.value.runs}', textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF191C1E)))),
                  Expanded(flex: 1, child: Text('${e.value.balls}', textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF575D78)))),
                  Expanded(flex: 1, child: Text('${e.value.fours}', textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF575D78)))),
                  Expanded(flex: 1, child: Text('${e.value.sixes}', textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF575D78)))),
                  Expanded(flex: 2, child: Text(e.value.strikeRate.toStringAsFixed(1), textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF575D78)))),
                ],
              ),
            );
          }),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFF2F4F7),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Text('EXTRAS', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF575D78))),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _selectedInnings.extrasInfo,
                    style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF191C1E)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallOfWickets() {
    final fow = _selectedInnings.fallOfWickets;
    if (fow.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Text('FALL OF WICKETS', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF575D78), letterSpacing: 1.0)),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          child: Row(
            children: fow.map((w) {
              return Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFFE0E3E6)),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: const [BoxShadow(color: Color.fromRGBO(26, 33, 56, 0.05), blurRadius: 4, offset: Offset(0, 2))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${w.score}/${w.wicketNumber}', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFFBA0013))),
                    const SizedBox(height: 2),
                    Text('${w.playerName} (${w.overInfo})', style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF575D78))),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildBowlingAnalysis() {
    final bowlers = _selectedInnings.bowlerStats.values.toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Color.fromRGBO(26, 33, 56, 0.08), blurRadius: 20, offset: Offset(0, 4))],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(color: Color(0xFF131B31), borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
            alignment: Alignment.centerLeft,
            child: Text(
              'BOWLING - ${_selectedInnings == widget.innings1 ? widget.innings2.teamName.toUpperCase() : widget.innings1.teamName.toUpperCase()}',
              style: GoogleFonts.inter(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
          Container(
            color: const Color(0xFFF2F4F7),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(flex: 4, child: Text('BOWLER', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF575D78)))),
                Expanded(flex: 1, child: Text('O', textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF575D78)))),
                Expanded(flex: 1, child: Text('M', textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF575D78)))),
                Expanded(flex: 1, child: Text('R', textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF575D78)))),
                Expanded(flex: 1, child: Text('W', textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF575D78)))),
                Expanded(flex: 2, child: Text('ER', textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF575D78)))),
              ],
            ),
          ),
          if (bowlers.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('No bowling data available', style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF575D78))),
            ),
          ...bowlers.asMap().entries.map((e) {
            return Container(
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFE0E3E6))),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(flex: 4, child: Text(e.value.name, style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF191C1E)), overflow: TextOverflow.ellipsis)),
                  Expanded(flex: 1, child: Text(e.value.oversDisplay, textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF575D78)))),
                  Expanded(flex: 1, child: Text('${e.value.maidens}', textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF575D78)))),
                  Expanded(flex: 1, child: Text('${e.value.runsConceded}', textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF575D78)))),
                  Expanded(flex: 1, child: Text('${e.value.wickets}', textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: e.value.wickets > 0 ? const Color(0xFF006B1B) : const Color(0xFF191C1E)))),
                  Expanded(flex: 2, child: Text(e.value.economy.toStringAsFixed(1), textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF575D78)))),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildOverByOver() {
    final balls = _currentBalls;
    if (balls.isEmpty) return const SizedBox.shrink();

    // Group balls by over
    final Map<int, List<BallEvent>> oversMap = {};
    for (var ball in balls) {
      oversMap.putIfAbsent(ball.overNumber, () => []).add(ball);
    }
    
    final sortedOvers = oversMap.keys.toList()..sort((a, b) => b.compareTo(a)); // Descending
    
    // Remove unused bowler mapping code

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('OVER-BY-OVER', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF575D78), letterSpacing: 1.0)),
              // View all button can be implemented later
            ],
          ),
        ),
        ...sortedOvers.take(5).map((overNumber) {
          final overBalls = oversMap[overNumber]!;
          int overRuns = 0;
          int overWickets = 0;
          for (var b in overBalls) {
            overRuns += b.runs;
            if (b.isWicket) overWickets++;
          }
          
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE0E3E6)),
              boxShadow: const [BoxShadow(color: Color.fromRGBO(26, 33, 56, 0.05), blurRadius: 4, offset: Offset(0, 2))],
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: overWickets > 0 ? const Color(0xFFE0E3E6) : const Color(0xFFE31E24), width: 2),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('OV', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF575D78), height: 1.0)),
                      Text('${overNumber + 1}', style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.bold, color: overWickets > 0 ? const Color(0xFF191C1E) : const Color(0xFFBA0013), height: 1.0)),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Over ${overNumber + 1}', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF191C1E))),
                          Text(
                            '$overRuns Runs${overWickets > 0 ? ' • $overWickets Wicket' : ''}',
                            style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF575D78)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: overBalls.map((b) {
                          final isWicket = b.isWicket;
                          final isSix = !isWicket && b.runs == 6;
                          final isDot = !isWicket && b.runs == 0;
                          
                          Color bgColor = const Color(0xFFECEEF1);
                          Color textColor = const Color(0xFF191C1E);
                          String label = '${b.runs}';
                          
                          if (isWicket) {
                            bgColor = const Color(0xFFBA0013);
                            textColor = Colors.white;
                            label = 'W';
                          } else if (isSix) {
                            bgColor = const Color(0xFFBA0013);
                            textColor = Colors.white;
                          } else if (isDot) {
                            label = '.';
                          }

                          return Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
                            alignment: Alignment.center,
                            child: Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: textColor)),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
