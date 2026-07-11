import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math';

import '../../services/database.dart';
import '../../models/match_stats.dart';
import '../../providers/history_provider.dart';
import '../../services/match_stats_calculator.dart';
import '../../services/mvp_calculator.dart';
import '../../services/pdf_download_service.dart';
import '../scoreboard/scoreboard_screen.dart';
import 'package:share_plus/share_plus.dart';

class MatchStatScreen extends ConsumerStatefulWidget {
  final int? matchId;
  const MatchStatScreen({super.key, this.matchId});
  
  @override
  ConsumerState<MatchStatScreen> createState() => _MatchStatScreenState();
}

class _MatchStatScreenState extends ConsumerState<MatchStatScreen> {
  bool _isLoading = true;
  CricketMatch? _match;
  InningsStats? _innings1;
  InningsStats? _innings2;

  
  Team? _teamA;
  Team? _teamB;
  List<Player> _teamAPlayers = [];
  List<Player> _teamBPlayers = [];
  List<BallEvent> _balls = [];

  List<int> _innings1CumulativeRuns = [];
  List<int> _innings2CumulativeRuns = [];

  List<BallEvent> _innings1Balls = [];
  List<BallEvent> _innings2Balls = [];

  int _selectedIndex = 3; 

  @override
  void initState() {
    super.initState();
    _loadMatch();
  }

  Future<void> _loadMatch() async {
    final db = ref.read(databaseServiceProvider);
    CricketMatch? match;
    
    try {
      if (widget.matchId != null) {
        match = await (db.select(db.matches)..where((m) => m.id.equals(widget.matchId!))).getSingleOrNull();
      } else {
        final allMatches = await db.getAllMatches();
        if (allMatches.isNotEmpty) {
          match = allMatches.first;
        }
      }

      if (match != null) {
        _teamA = match.teamAId != null ? await (db.select(db.teams)..where((t) => t.id.equals(match!.teamAId!))).getSingleOrNull() : null;
        _teamB = match.teamBId != null ? await (db.select(db.teams)..where((t) => t.id.equals(match!.teamBId!))).getSingleOrNull() : null;
        
        _teamAPlayers = match.teamAId != null ? await (db.select(db.players)..where((p) => p.teamId.equals(match!.teamAId!))).get() : <Player>[];
        _teamBPlayers = match.teamBId != null ? await (db.select(db.players)..where((p) => p.teamId.equals(match!.teamBId!))).get() : <Player>[];
        
        _balls = await (db.select(db.ballEvents)..where((b) => b.matchId.equals(match!.id))).get();
        
        _innings1 = MatchStatsCalculator.computeInningsStats(match, _teamA, _teamB, _teamAPlayers, _teamBPlayers, _balls, true);
        _innings2 = MatchStatsCalculator.computeInningsStats(match, _teamA, _teamB, _teamAPlayers, _teamBPlayers, _balls, false);

        _calculateCumulativeRuns();
      }
    } catch (e) {
      debugPrint('Error loading match stats: $e');
    }

    if (mounted) {
      setState(() {
        _match = match;
        _isLoading = false;
      });
    }
  }

  void _calculateCumulativeRuns() {
    _innings1CumulativeRuns = [];
    _innings2CumulativeRuns = [];
    _innings1Balls = [];
    _innings2Balls = [];
    
    final teamBPlayerIds = _teamBPlayers.map((e) => e.id).toSet();
    bool teamABattedFirst = true;
    if (_balls.isNotEmpty) {
      if (teamBPlayerIds.contains(_balls.first.batterId)) teamABattedFirst = false;
    }
    
    final innings1Batters = teamABattedFirst ? _teamAPlayers.map((e) => e.id).toSet() : teamBPlayerIds;
    final innings2Batters = teamABattedFirst ? teamBPlayerIds : _teamAPlayers.map((e) => e.id).toSet();

    int currentOver = 0;
    int currentRuns = 0;
    for (var ball in _balls.where((b) => innings1Batters.contains(b.batterId))) {
      _innings1Balls.add(ball);
      currentRuns += ball.runs;
      if (ball.overNumber > currentOver) {
        _innings1CumulativeRuns.add(currentRuns);
        currentOver = ball.overNumber;
      }
    }
    if (currentRuns > 0 && (_innings1CumulativeRuns.isEmpty || _innings1CumulativeRuns.last != currentRuns)) {
      _innings1CumulativeRuns.add(currentRuns);
    }

    currentOver = 0;
    currentRuns = 0;
    for (var ball in _balls.where((b) => innings2Batters.contains(b.batterId))) {
      _innings2Balls.add(ball);
      currentRuns += ball.runs;
      if (ball.overNumber > currentOver) {
        _innings2CumulativeRuns.add(currentRuns);
        currentOver = ball.overNumber;
      }
    }
    if (currentRuns > 0 && (_innings2CumulativeRuns.isEmpty || _innings2CumulativeRuns.last != currentRuns)) {
      _innings2CumulativeRuns.add(currentRuns);
    }
  }

  String _getMatchResultText() {
    if (_match?.winnerTeamName == null) return 'Match Tied / No Result';
    final winnerName = _match!.winnerTeamName;
    
    final innings1 = _innings1!;
    final innings2 = _innings2!;
    
    if (innings2.totalRuns > innings1.totalRuns) {
      final wicketsLeft = 10 - innings2.totalWickets;
      return '$winnerName won by $wicketsLeft wickets';
    } else if (innings1.totalRuns > innings2.totalRuns) {
      final runsMargin = innings1.totalRuns - innings2.totalRuns;
      return '$winnerName won by $runsMargin runs';
    }
    return '$winnerName won the match';
  }

  String _getMonth(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return month > 0 && month <= 12 ? months[month - 1] : '';
  }

  String get _appBarTitle {
    switch (_selectedIndex) {
      case 1: return 'SCOREBOARD';
      case 2: return 'TEAMS';
      case 3: return 'SUMMARY';
      default: return 'SUMMARY';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1a2238),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        title: Text(
          _appBarTitle,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_outlined, color: Colors.white, size: 20),
            tooltip: 'Download PDF',
            onPressed: _match == null || _innings1 == null || _innings2 == null
                ? null
                : () => PdfDownloadService.downloadMatchPdf(
                      context: context,
                      match: _match!,
                      teamA: _teamA,
                      teamB: _teamB,
                      innings1: _innings1!,
                      innings2: _innings2!,
                      allBalls: _balls,
                      teamAPlayers: _teamAPlayers,
                      teamBPlayers: _teamBPlayers,
                    ),
          ),
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white, size: 20),
            onPressed: () {
              if (_match != null) {
                final teamA = _teamA?.name ?? 'Team A';
                final teamB = _teamB?.name ?? 'Team B';
                final matchResult = _getMatchResultText();
                final shareText = 'Check out this match on Scorely!\n\n$teamA vs $teamB\nResult: $matchResult\n\nDownload Scorely to see full match statistics!';
                // ignore: deprecated_member_use
                Share.share(shareText);
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _match == null || _innings1 == null || _innings2 == null
              ? Center(
                  child: Text('No Match Data Available',
                      style: GoogleFonts.inter(color: Colors.grey, fontSize: 16)))
              : Column(
                  children: [
                    Expanded(
                      child: _buildBodyContent(),
                    ),
                    _buildBottomNav(),
                  ],
                ),
    );
  }

  Widget _buildBodyContent() {
    switch (_selectedIndex) {
      case 1:
        return ScoreboardScreen(
          match: _match!,
          innings1: _innings1!,
          innings2: _innings2!,
          innings1Balls: _innings1Balls,
          innings2Balls: _innings2Balls,
        );
      case 2:
        return _buildSquadsTab();
      case 3:
      default:
        return _buildNewSummaryTab();
    }
  }

  Widget _buildBottomNav() {
    return LayoutBuilder(
      builder: (context, _) {
        final bottomInset = MediaQuery.of(context).viewPadding.bottom;
        return Container(
          height: 70 + bottomInset,
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Color.fromRGBO(26, 33, 56, 0.08),
                blurRadius: 20,
                offset: Offset(0, -4),
              ),
            ],
            border: Border(top: BorderSide(color: Color(0xFFECEEF1), width: 1)),
          ),
          child: Padding(
            padding: EdgeInsets.only(bottom: bottomInset),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.home_outlined, 'Home'),
                _buildNavItem(1, Icons.article_outlined, 'Scoreboard'),
                _buildNavItem(2, Icons.groups_outlined, 'Teams'),
                _buildNavItem(3, Icons.query_stats, 'Stats'),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () {
        if (index == 0) {
          context.go('/home');
        } else {
          setState(() {
            _selectedIndex = index;
          });
        }
      },
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isSelected ? const Color(0xFFBA0013) : const Color(0xFF575D78),
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? const Color(0xFFBA0013) : const Color(0xFF575D78),
            ),
          ),
        ],
      ),
    );
  }

  // ================= NEW SUMMARY TAB =================

  Widget _buildNewSummaryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildResultBanner(),
          const SizedBox(height: 16),
          _buildMatchDetailsCard(),
          const SizedBox(height: 16),
          _buildInningsSummaryCard(),
          const SizedBox(height: 16),
          _buildMatchAnalyticsCard(),
          const SizedBox(height: 16),
          _buildMatchAwardsSection(),
          const SizedBox(height: 16),
          _buildMVPAnalysisCard(),
        ],
      ),
    );
  }

  Widget _buildResultBanner() {
    final resultText = _getMatchResultText();
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFE31E24), 
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(26, 33, 56, 0.08),
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Icon(Icons.emoji_events, size: 120, color: Colors.white.withValues(alpha: 0.1)),
          ),
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.emoji_events, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MATCH RESULT',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white.withValues(alpha: 0.8),
                        letterSpacing: 2.0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      resultText,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMatchDetailsCard() {
    final tossText = '${_innings1?.teamName ?? 'Team 1'} batted first';
    final dateText = '${_match!.createdAt.day} ${_getMonth(_match!.createdAt.month)}, ${_match!.createdAt.year}';
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E3E6)),
        boxShadow: const [
          BoxShadow(color: Color.fromRGBO(26, 33, 56, 0.08), blurRadius: 20, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 4, height: 16, decoration: BoxDecoration(color: const Color(0xFFBA0013), borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 8),
              Text('MATCH DETAILS', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF191C1E), letterSpacing: 1.0)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('TOSS', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF575D78), letterSpacing: 1.0)),
                    const SizedBox(height: 4),
                    Text(tossText, style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF191C1E))),
                    const SizedBox(height: 16),
                    Text('DATE', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF575D78), letterSpacing: 1.0)),
                    const SizedBox(height: 4),
                    Text(dateText, style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF191C1E))),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('FORMAT', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF575D78), letterSpacing: 1.0)),
                    const SizedBox(height: 4),
                    Text('T${_match!.totalOvers}', style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF191C1E))),
                    const SizedBox(height: 16),
                    Text('VENUE', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF575D78), letterSpacing: 1.0)),
                    const SizedBox(height: 4),
                    Text('Local Ground', style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF191C1E))),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInningsSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E3E6)),
        boxShadow: const [
          BoxShadow(color: Color.fromRGBO(26, 33, 56, 0.08), blurRadius: 20, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 4, height: 16, decoration: BoxDecoration(color: const Color(0xFFBA0013), borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 8),
              Text('INNINGS SUMMARY', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF191C1E), letterSpacing: 1.0)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_innings1!.teamName.toUpperCase(), style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF575D78))),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${_innings1!.totalRuns}/${_innings1!.totalWickets}', style: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF191C1E))),
                        Text('(${_innings1!.totalOvers})', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: const Color(0xFF575D78))),
                      ],
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 40, color: const Color(0xFFE0E3E6), margin: const EdgeInsets.symmetric(horizontal: 16)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_innings2!.teamName.toUpperCase(), style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF575D78))),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${_innings2!.totalRuns}/${_innings2!.totalWickets}', style: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFFBA0013))),
                        Text('(${_innings2!.totalOvers})', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: const Color(0xFF575D78))),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMatchAnalyticsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E3E6)),
        boxShadow: const [
          BoxShadow(color: Color.fromRGBO(26, 33, 56, 0.08), blurRadius: 20, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Match Analytics', style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF191C1E))),
          const SizedBox(height: 16),
          Text('RUN RATE PROGRESSION', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF575D78), letterSpacing: 1.0)),
          const SizedBox(height: 8),
          Container(
            height: 180,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF2F4F7), 
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                RotatedBox(
                  quarterTurns: 3,
                  child: Text('RUNS', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF575D78), letterSpacing: 2.0)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        child: CustomPaint(
                          size: Size.infinite,
                          painter: RunRateChartPainter(
                            runs1: _innings1CumulativeRuns,
                            runs2: _innings2CumulativeRuns,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('OVERS', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF575D78), letterSpacing: 2.0)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Container(width: 12, height: 12, decoration: const BoxDecoration(color: Color(0xFFBA0013), shape: BoxShape.circle)),
                  const SizedBox(width: 4),
                  Text(_innings1!.teamName.toUpperCase(), style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF575D78))),
                ],
              ),
              const SizedBox(width: 24),
              Row(
                children: [
                  Container(width: 12, height: 12, decoration: const BoxDecoration(color: Color(0xFF131B31), shape: BoxShape.circle)),
                  const SizedBox(width: 4),
                  Text(_innings2!.teamName.toUpperCase(), style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF575D78))),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMatchAwardsSection() {
    final overallMvp = MvpCalculator.calculateMVP(_match!, _teamA, _teamB, _teamAPlayers, _teamBPlayers, _balls);
    
    BatterStats? topBatter;
    int maxRuns = -1;
    for (var b in _innings1!.batterStats.values.followedBy(_innings2!.batterStats.values)) {
      if (b.runs > maxRuns) {
        maxRuns = b.runs;
        topBatter = b;
      }
    }

    BowlerStats? topBowler;
    int maxWickets = -1;
    for (var b in _innings1!.bowlerStats.values.followedBy(_innings2!.bowlerStats.values)) {
      if (b.wickets > maxWickets) {
        maxWickets = b.wickets;
        topBowler = b;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(width: 4, height: 16, decoration: BoxDecoration(color: const Color(0xFFBA0013), borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 8),
            Text('MATCH AWARDS', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF191C1E), letterSpacing: 1.0)),
          ],
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          child: Row(
            children: [
              _buildAwardCard('MVP', overallMvp.playerName, '${overallMvp.totalPoints} pts', true),
              const SizedBox(width: 16),
              _buildAwardCard('Player of the Match', overallMvp.playerName, 'Match Winning Impact', false),
              const SizedBox(width: 16),
              if (topBatter != null) _buildAwardCard('Top Batter', topBatter.name, '${topBatter.runs}* (${topBatter.balls})', false),
              const SizedBox(width: 16),
              if (topBowler != null) _buildAwardCard('Top Bowler', topBowler.name, '${topBowler.wickets}/${topBowler.runsConceded} (${topBowler.oversDisplay})', false),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAwardCard(String tag, String player, String subtext, bool isMVP) {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E3E6)),
        boxShadow: const [
          BoxShadow(color: Color.fromRGBO(26, 33, 56, 0.08), blurRadius: 20, offset: Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFF2F4F7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.person, size: 40, color: Color(0xFF575D78)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFBA0013),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(tag.toUpperCase(), style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.0)),
                ),
                const SizedBox(height: 4),
                Text(player, style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF191C1E)), overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(subtext, style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF575D78)), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMVPAnalysisCard() {
    final overallMvp = MvpCalculator.calculateMVP(_match!, _teamA, _teamB, _teamAPlayers, _teamBPlayers, _balls);
    
    double normalize(double val, double maxVal) => (val / maxVal).clamp(0.1, 1.0);
    
    double strikeRate = 0.5;
    double consistency = 0.5;
    double impact = 0.5;
    double bowling = 0.5;
    double fielding = 0.5;
    
    if (overallMvp.playerName != 'No MVP') {
      strikeRate = normalize(overallMvp.totalPoints.toDouble(), 100) * 0.9;
      consistency = normalize(overallMvp.totalPoints.toDouble(), 120) * 0.8;
      impact = normalize(overallMvp.totalPoints.toDouble(), 80) * 1.0;
      bowling = normalize(overallMvp.totalPoints.toDouble(), 150) * 0.6;
      fielding = normalize(overallMvp.totalPoints.toDouble(), 200) * 0.4;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E3E6)),
        boxShadow: const [
          BoxShadow(color: Color.fromRGBO(26, 33, 56, 0.08), blurRadius: 20, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('MVP Analysis', style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF191C1E))),
          const SizedBox(height: 24),
          Center(
            child: SizedBox(
              width: 240,
              height: 240,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: RadarChartPainter(strikeRate, consistency, impact, bowling, fielding),
                    ),
                  ),
                  Align(alignment: Alignment.topCenter, child: Text('STRIKE RATE', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF575D78)))),
                  Align(alignment: Alignment.centerRight, child: Text('CONSISTENCY', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF575D78)))),
                  Align(alignment: Alignment.bottomCenter, child: Text('IMPACT', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF575D78)))),
                  Align(alignment: Alignment.centerLeft, child: Text('BOWLING', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF575D78)))),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: const Color(0xFFECEEF1), borderRadius: BorderRadius.circular(8)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('IMPACT SCORE', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF575D78))),
                      const SizedBox(height: 4),
                      Text('${(impact * 10).toStringAsFixed(1)}/10', style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFFBA0013))),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: const Color(0xFFECEEF1), borderRadius: BorderRadius.circular(8)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('MATCH MVP RANK', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF575D78))),
                      const SizedBox(height: 4),
                      Text('#1', style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF191C1E))),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ================= SQUADS TAB =================
  Widget _buildSquadsTab() {
    final teamA = _teamAPlayers.map((e) => e.name).toList();
    final teamB = _teamBPlayers.map((e) => e.name).toList();
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: _squadCard(_teamA?.name ?? 'Team 1', teamA, Colors.redAccent)),
        const SizedBox(width: 10),
        Expanded(child: _squadCard(_teamB?.name ?? 'Team 2', teamB, Colors.blueAccent)),
      ]),
    );
  }

  Widget _squadCard(String team, List<String> players, Color accent) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4)]),
      child: Column(children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: accent, borderRadius: const BorderRadius.vertical(top: Radius.circular(12))),
          child: Text(team, textAlign: TextAlign.center, style: GoogleFonts.inter(color: Colors.white, fontSize: 13.2, fontWeight: FontWeight.bold)),
        ),
        if (players.isEmpty)
          Padding(padding: const EdgeInsets.all(12), child: Text('No players available', style: GoogleFonts.inter(fontSize: 12.1, color: Colors.grey))),
        ...players.asMap().entries.map((e) => Container(
          color: e.key.isEven ? Colors.white : const Color(0xFFF8F9FA),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(children: [
            Container(width: 18, height: 18, decoration: BoxDecoration(color: accent.withValues(alpha: 0.1), shape: BoxShape.circle), alignment: Alignment.center, child: Text('${e.key + 1}', style: GoogleFonts.inter(fontSize: 8.8, color: accent, fontWeight: FontWeight.bold))),
            const SizedBox(width: 8),
            Expanded(child: Text(e.value, style: GoogleFonts.inter(fontSize: 12.1, color: Colors.black87))),
          ]),
        )),
      ]),
    );
  }
}

class RunRateChartPainter extends CustomPainter {
  final List<int> runs1;
  final List<int> runs2;
  
  RunRateChartPainter({required this.runs1, required this.runs2});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint1 = Paint()..color = const Color(0xFFBA0013)..strokeWidth = 3..style = PaintingStyle.stroke..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round;
    final paint2 = Paint()..color = const Color(0xFF131B31)..strokeWidth = 3..style = PaintingStyle.stroke..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round;
    
    final maxOvers = max(runs1.length, runs2.length).clamp(1, 100);
    final maxRuns = max(runs1.isEmpty ? 0 : runs1.last, runs2.isEmpty ? 0 : runs2.last).clamp(1, 1000);
    
    void drawLine(List<int> runs, Paint paint) {
      if (runs.isEmpty) return;
      final path = Path();
      path.moveTo(0, size.height);
      for (int i = 0; i < runs.length; i++) {
        final x = (i + 1) * (size.width / maxOvers);
        final y = size.height - (runs[i] / maxRuns * size.height);
        path.lineTo(x, y);
      }
      canvas.drawPath(path, paint);
    }
    
    final gridPaint = Paint()..color = const Color(0xFFE0E3E6)..strokeWidth = 1.0..style = PaintingStyle.stroke;
    for (int i = 1; i <= 4; i++) {
      final y = size.height * (i / 5);
      double startX = 0;
      while (startX < size.width) {
        canvas.drawLine(Offset(startX, y), Offset(startX + 4, y), gridPaint);
        startX += 8;
      }
    }
    
    drawLine(runs1, paint1);
    drawLine(runs2, paint2);
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class RadarChartPainter extends CustomPainter {
  final double strikeRate; 
  final double consistency;
  final double impact;
  final double bowling;
  final double fielding; 

  RadarChartPainter(this.strikeRate, this.consistency, this.impact, this.bowling, this.fielding);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2.5; 
    
    final bgPaint = Paint()..color = const Color(0xFFE0E3E6)..style = PaintingStyle.stroke..strokeWidth = 1.0;
    for (int i = 1; i <= 4; i++) {
      _drawPentagon(canvas, center, radius * (i / 4), bgPaint);
    }
    
    final dataPaint = Paint()..color = const Color(0xFFBA0013).withValues(alpha: 0.3)..style = PaintingStyle.fill;
    final dataStrokePaint = Paint()..color = const Color(0xFFBA0013)..style = PaintingStyle.stroke..strokeWidth = 2.0;
    
    final path = Path();
    final values = [strikeRate, consistency, impact, bowling, fielding];
    for (int i = 0; i < 5; i++) {
      final angle = -pi / 2 + (i * 2 * pi / 5);
      final r = radius * values[i];
      final x = center.dx + r * cos(angle);
      final y = center.dy + r * sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    
    canvas.drawPath(path, dataPaint);
    canvas.drawPath(path, dataStrokePaint);
  }

  void _drawPentagon(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    for (int i = 0; i < 5; i++) {
      final angle = -pi / 2 + (i * 2 * pi / 5);
      final x = center.dx + radius * cos(angle);
      final y = center.dy + radius * sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
