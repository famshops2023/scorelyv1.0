import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/live_match_data.dart';
import '../home/providers/live_match_insforge_provider.dart';

class LiveMatchScreen extends ConsumerWidget {
  final LiveMatchData matchData;

  const LiveMatchScreen({super.key, required this.matchData});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final liveMatchesAsync = ref.watch(liveMatchInsforgeProvider);
    
    // Find the latest sync of this match, fallback to route extra if not loaded yet
    final match = liveMatchesAsync.maybeWhen(
      data: (list) => list.firstWhere((m) => m.id == matchData.id, orElse: () => matchData),
      orElse: () => matchData,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A2138),
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFF7F9FC), size: 24),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Live Match View',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFBA0013).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFFBA0013),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  'LIVE',
                  style: GoogleFonts.inter(
                    color: const Color(0xFFBA0013),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(liveMatchInsforgeProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildScoreCard(match),
              const SizedBox(height: 16),
              _buildBattingBowlingCard(match),
              const SizedBox(height: 16),
              _buildOverAndBallsCard(match),
              const SizedBox(height: 24),
              Center(
                child: Text(
                  'Auto-refreshing every 20 seconds',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: const Color(0xFF575D78),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScoreCard(LiveMatchData match) {
    // Determine active batting score
    final currentScore = match.innings == 1 ? match.teamAScore : match.teamBScore;
    final currentOvers = match.innings == 1 ? match.teamAOvers : match.teamBOvers;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2138),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(26, 33, 56, 0.1),
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                match.teamAName,
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'VS',
                style: GoogleFonts.inter(
                  color: Colors.white54,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                match.teamBName,
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            currentScore,
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white,
              fontSize: 44,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$currentOvers Ov',
            style: GoogleFonts.inter(
              color: Colors.white70,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatText('Format', match.format),
                _buildStatText('Venue', match.venue),
                _buildStatText('Innings', '${match.innings}'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatText(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            color: Colors.white60,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildBattingBowlingCard(LiveMatchData match) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          // Batting Table
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'BATTING',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFBA0013),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(flex: 3, child: _buildTableHeader('BATTER')),
                    Expanded(child: _buildTableHeader('R', alignRight: true)),
                    Expanded(child: _buildTableHeader('B', alignRight: true)),
                    Expanded(flex: 2, child: _buildTableHeader('SR', alignRight: true)),
                  ],
                ),
                const SizedBox(height: 8),
                if (match.currentBatters.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text('No active batters', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
                  )
                else
                  ...match.currentBatters.map((b) {
                    final runs = b['runs'] as int? ?? 0;
                    final balls = b['balls'] as int? ?? 0;
                    final sr = balls > 0 ? (runs / balls * 100).toStringAsFixed(1) : '0.0';
                    final isFacing = b['isFacing'] as bool? ?? false;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: _buildBattingRow(
                        '${b['name'] ?? ''}${isFacing ? '*' : ''}',
                        '$runs',
                        '$balls',
                        sr,
                        isStriker: isFacing,
                      ),
                    );
                  }),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE0E3E6)),
          // Bowling Table
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'BOWLING',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFBA0013),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(flex: 3, child: _buildTableHeader('BOWLER')),
                    Expanded(child: _buildTableHeader('O', alignRight: true)),
                    Expanded(child: _buildTableHeader('R', alignRight: true)),
                    Expanded(child: _buildTableHeader('W', alignRight: true)),
                    Expanded(flex: 2, child: _buildTableHeader('ECON', alignRight: true)),
                  ],
                ),
                const SizedBox(height: 8),
                if (match.currentBowler.isEmpty || match.currentBowler['name'] == null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text('No active bowler', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: _buildBowlingRow(
                      match.currentBowler['name']?.toString() ?? '',
                      match.currentBowler['overs']?.toString() ?? '0.0',
                      match.currentBowler['runs']?.toString() ?? '0',
                      match.currentBowler['wickets']?.toString() ?? '0',
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader(String text, {bool alignRight = false}) {
    return Text(
      text,
      textAlign: alignRight ? TextAlign.right : TextAlign.left,
      style: GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.bold,
        color: const Color(0xFF575D78),
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildBattingRow(
    String name,
    String r,
    String b,
    String sr, {
    bool isStriker = false,
  }) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Text(
            name,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: isStriker ? FontWeight.bold : FontWeight.w500,
              color: const Color(0xFF191C1E),
            ),
          ),
        ),
        Expanded(
          child: Text(
            r,
            textAlign: TextAlign.right,
            style: GoogleFonts.inter(fontSize: 14, fontWeight: isStriker ? FontWeight.bold : FontWeight.w500),
          ),
        ),
        Expanded(
          child: Text(
            b,
            textAlign: TextAlign.right,
            style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF575D78)),
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            sr,
            textAlign: TextAlign.right,
            style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF575D78)),
          ),
        ),
      ],
    );
  }

  Widget _buildBowlingRow(String name, String o, String r, String w) {
    double econ = 0.0;
    try {
      final doubleOvers = double.parse(o);
      final intRuns = int.parse(r);
      final int totalBalls = ((doubleOvers.truncate() * 6) + ((doubleOvers - doubleOvers.truncate()) * 10).round());
      if (totalBalls > 0) {
        econ = (intRuns / totalBalls) * 6;
      }
    } catch (_) {}

    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Text(
            name,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF191C1E),
            ),
          ),
        ),
        Expanded(
          child: Text(
            o,
            textAlign: TextAlign.right,
            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: Text(
            r,
            textAlign: TextAlign.right,
            style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF575D78)),
          ),
        ),
        Expanded(
          child: Text(
            w,
            textAlign: TextAlign.right,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: const Color(0xFFBA0013),
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            econ.toStringAsFixed(2),
            textAlign: TextAlign.right,
            style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF575D78)),
          ),
        ),
      ],
    );
  }

  Widget _buildOverAndBallsCard(LiveMatchData match) {
    final ballsList = match.last6Balls.trim().split(' ').where((e) => e.isNotEmpty).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(26, 33, 56, 0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'THIS OVER',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF575D78),
            ),
          ),
          const SizedBox(height: 12),
          if (ballsList.isEmpty)
            Text(
              'No balls bowled in this over yet',
              style: GoogleFonts.inter(fontSize: 13, color: Colors.grey, fontStyle: FontStyle.italic),
            )
          else
            Row(
              children: ballsList.map((ball) {
                Color bg = const Color(0xFFE0E3E6);
                Color fg = const Color(0xFF575D78);
                if (ball.contains('Wd') || ball.contains('Nb')) {
                  bg = const Color(0xFFFFF2CC);
                  fg = const Color(0xFFB45F06);
                } else if (ball == 'W') {
                  bg = const Color(0xFFFFD8D6);
                  fg = const Color(0xFFBA0013);
                } else if (ball == '4' || ball == '6') {
                  bg = const Color(0xFFE2F9E1);
                  fg = const Color(0xFF006B1B);
                }
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: bg,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    ball,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: fg,
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}
