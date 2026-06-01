import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/database.dart';
import '../../models/match_stats.dart';
import '../../services/match_stats_calculator.dart';
import '../../services/mvp_calculator.dart';
import '../../providers/history_provider.dart';

class MatchStatScreen extends ConsumerStatefulWidget {
  final int? matchId;
  const MatchStatScreen({super.key, this.matchId});
  
  @override
  ConsumerState<MatchStatScreen> createState() => _MatchStatScreenState();
}

class _MatchStatScreenState extends ConsumerState<MatchStatScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  bool _isLoading = true;
  CricketMatch? _match;
  InningsStats? _innings1;
  InningsStats? _innings2;
  String _selectedTeam = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadMatch();
  }

  Team? _teamA;
  Team? _teamB;
  List<Player> _teamAPlayers = [];
  List<Player> _teamBPlayers = [];
  List<BallEvent> _balls = [];

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
        _selectedTeam = _innings1!.teamName;
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

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1a2238),
        elevation: 0,
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
        title: Text('Match Stats', style: GoogleFonts.oswald(color: Colors.white, fontSize: 16)),
        actions: [
          IconButton(icon: const Icon(Icons.share, color: Colors.white, size: 18), onPressed: () {}),
          IconButton(icon: const Icon(Icons.download, color: Colors.white, size: 18), onPressed: () {}),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          indicatorColor: const Color(0xFFDA291C),
          indicatorWeight: 3,
          labelStyle: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.bold),
          unselectedLabelStyle: GoogleFonts.montserrat(fontSize: 12),
          tabs: const [
            Tab(text: 'Summary'),
            Tab(text: 'Scorecard'),
            Tab(text: 'Squads'),
            Tab(text: 'MVP'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _match == null || _innings1 == null || _innings2 == null
              ? Center(
                  child: Text('No Match Data Available',
                      style: GoogleFonts.montserrat(color: Colors.grey, fontSize: 16)))
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildSummaryTab(),
                    _buildScorecardTab(),
                    _buildSquadsTab(),
                    _buildMVPTab(),
                  ],
                ),
    );
  }

  // ============ SUMMARY TAB ============
  Widget _buildSummaryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _summaryScoreCard(),
        const SizedBox(height: 12),
        _summaryInfoRow(),
        const SizedBox(height: 12),
        _summaryMatchNotes(),
      ]),
    );
  }

  Widget _summaryScoreCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF202A46),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        _teamCol(_innings1!.teamName, '${_innings1!.totalRuns}/${_innings1!.totalWickets}', '${_innings1!.totalOvers} ov', Colors.redAccent, true),
        Container(width: 28, height: 28, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle), alignment: Alignment.center, child: const Text('VS', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold))),
        _teamCol(_innings2!.teamName, '${_innings2!.totalRuns}/${_innings2!.totalWickets}', '${_innings2!.totalOvers} ov', Colors.blueAccent, false),
      ]),
    );
  }

  Widget _teamCol(String name, String score, String ov, Color c, bool left) {
    return Column(crossAxisAlignment: left ? CrossAxisAlignment.start : CrossAxisAlignment.end, children: [
      Text(name, style: TextStyle(color: c, fontWeight: FontWeight.bold, fontSize: 11)),
      const SizedBox(height: 4),
      Text(score, style: GoogleFonts.oswald(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
      Text(ov, style: const TextStyle(color: Colors.white54, fontSize: 9)),
    ]);
  }

  Widget _summaryInfoRow() {
    return Row(children: [
      Expanded(child: _infoTile('FORMAT', 'T${_match!.totalOvers}')),
      const SizedBox(width: 8),
      Expanded(child: _infoTile('VENUE', 'Local Ground')),
      const SizedBox(width: 8),
      Expanded(child: _infoTile('OVERS', '${_match!.totalOvers}')),
    ]);
  }

  Widget _infoTile(String label, String val) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 8, color: Colors.grey, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(val, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
      ]),
    );
  }

  Widget _summaryMatchNotes() {
    final notes = [
      {'icon': Icons.play_circle_outline, 'text': 'Match started'},
      {'icon': Icons.sports_cricket, 'text': '1st Innings: ${_innings1!.teamName} scored ${_innings1!.totalRuns}/${_innings1!.totalWickets} in ${_innings1!.totalOvers} overs'},
      {'icon': Icons.sports_cricket, 'text': '2nd Innings: ${_innings2!.teamName} scored ${_innings2!.totalRuns}/${_innings2!.totalWickets} in ${_innings2!.totalOvers} overs'},
      {'icon': Icons.emoji_events, 'text': _match!.winnerTeamName != null ? '${_match!.winnerTeamName} won the match' : 'Match tied / No result'},
    ];
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 3, height: 14, color: const Color(0xFFDA291C)),
          const SizedBox(width: 6),
          Text('MATCH NOTES', style: GoogleFonts.montserrat(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey)),
        ]),
        const SizedBox(height: 10),
        ...notes.map((n) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(n['icon'] as IconData, size: 14, color: const Color(0xFFDA291C)),
            const SizedBox(width: 8),
            Expanded(child: Text(n['text'] as String, style: const TextStyle(fontSize: 11, color: Colors.black87))),
          ]),
        )),
      ]),
    );
  }

  // ============ SCORECARD TAB ============
  Widget _buildScorecardTab() {
    final currentInnings = _selectedTeam == _innings1!.teamName ? _innings1! : _innings2!;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _teamDropdown(),
        const SizedBox(height: 10),
        _battingTable(currentInnings),
        const SizedBox(height: 14),
        _bowlingTable(currentInnings),
        const SizedBox(height: 14),
        _fallOfWickets(currentInnings),
      ]),
    );
  }

  Widget _teamDropdown() {
    final currentInnings = _selectedTeam == _innings1!.teamName ? _innings1! : _innings2!;
    final score = '${currentInnings.totalRuns}/${currentInnings.totalWickets} (${currentInnings.totalOvers} Ov)';
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(color: const Color(0xFF202A46), borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedTeam,
              dropdownColor: const Color(0xFF202A46),
              icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 18),
              style: GoogleFonts.montserrat(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
              items: {_innings1!.teamName, _innings2!.teamName}.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
              onChanged: (v) => setState(() => _selectedTeam = v!),
            ),
          ),
          Text(score, style: GoogleFonts.oswald(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _battingTable(InningsStats innings) {
    final batsmen = innings.batterStats.values.toList();
    
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4)]),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: const BoxDecoration(color: Color(0xFFDA291C), borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
          child: Row(children: [
            const Expanded(flex: 3, child: Text('Batsman', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
            ...['R', 'B', '4s', '6s', 'SR'].map((h) => Expanded(child: Text(h, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)))),
          ]),
        ),
        if (batsmen.isEmpty)
          const Padding(padding: EdgeInsets.all(12), child: Text('No batting data available', style: TextStyle(fontSize: 11, color: Colors.grey))),
        ...batsmen.asMap().entries.map((e) {
          final i = e.key;
          final b = e.value;
          final status = b.isOut ? b.dismissalInfo : 'not out';
          return Container(
            color: i.isEven ? Colors.white : const Color(0xFFF8F9FA),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(flex: 3, child: Text(b.name, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFFDA291C)))),
                Expanded(child: Text('${b.runs}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, color: Colors.black87))),
                Expanded(child: Text('${b.balls}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, color: Colors.black87))),
                Expanded(child: Text('${b.fours}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, color: Colors.black87))),
                Expanded(child: Text('${b.sixes}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, color: Colors.black87))),
                Expanded(child: Text(b.strikeRate.toStringAsFixed(2), textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, color: Colors.black87))),
              ]),
              Text(status, style: const TextStyle(fontSize: 8, color: Colors.grey)),
            ]),
          );
        }),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.grey[300]!))),
          child: Row(children: [
            const Expanded(flex: 3, child: Text('Extras', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
            Expanded(flex: 5, child: Text(innings.extrasInfo, textAlign: TextAlign.right, style: const TextStyle(fontSize: 10))),
          ]),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(color: const Color(0xFFF0F0F0), borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12))),
          child: Row(children: [
            const Expanded(flex: 3, child: Text('Total', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
            Expanded(flex: 5, child: Text('${innings.totalRuns}/${innings.totalWickets} (${innings.totalOvers} Ov)', textAlign: TextAlign.right, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
          ]),
        ),
      ]),
    );
  }

  Widget _bowlingTable(InningsStats innings) {
    final bowlers = innings.bowlerStats.values.toList();
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4)]),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: const BoxDecoration(color: Color(0xFF202A46), borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
          child: Row(children: [
            const Expanded(flex: 3, child: Text('Bowler', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
            ...['O', 'M', 'R', 'W', 'Eco'].map((h) => Expanded(child: Text(h, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)))),
          ]),
        ),
        if (bowlers.isEmpty)
          const Padding(padding: EdgeInsets.all(12), child: Text('No bowling data available', style: TextStyle(fontSize: 11, color: Colors.grey))),
        ...bowlers.asMap().entries.map((e) {
          final i = e.key;
          final b = e.value;
          return Container(
            color: i.isEven ? Colors.white : const Color(0xFFF8F9FA),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(children: [
              Expanded(flex: 3, child: Text(b.name, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF1a2238)))),
              Expanded(child: Text(b.oversDisplay, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, color: Colors.black87))),
              Expanded(child: Text('${b.maidens}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, color: Colors.black87))),
              Expanded(child: Text('${b.runsConceded}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, color: Colors.black87))),
              Expanded(child: Text('${b.wickets}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, color: Colors.black87))),
              Expanded(child: Text(b.economy.toStringAsFixed(2), textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, color: Colors.black87))),
            ]),
          );
        }),
      ]),
    );
  }

  Widget _fallOfWickets(InningsStats innings) {
    final fow = innings.fallOfWickets;
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4)]),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(color: Colors.grey[100], borderRadius: const BorderRadius.vertical(top: Radius.circular(12))),
          child: Row(children: [
            const Expanded(flex: 1, child: Text('#', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black87))),
            const Expanded(flex: 3, child: Text('Fall of wickets', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black87))),
            const Expanded(flex: 2, child: Text('Score(over)', textAlign: TextAlign.right, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black87))),
          ]),
        ),
        if (fow.isEmpty)
          const Padding(padding: EdgeInsets.all(12), child: Text('No wickets fallen', style: TextStyle(fontSize: 11, color: Colors.grey))),
        ...fow.map((f) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(children: [
            Expanded(flex: 1, child: Text('${f.wicketNumber}', style: const TextStyle(fontSize: 10, color: Colors.black87))),
            Expanded(flex: 3, child: Text(f.playerName, style: const TextStyle(fontSize: 10, color: Color(0xFFDA291C)))),
            Expanded(flex: 2, child: Text(f.overInfo, textAlign: TextAlign.right, style: const TextStyle(fontSize: 10, color: Colors.black87))),
          ]),
        )),
      ]),
    );
  }

  // ============ SQUADS TAB ============
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
          child: Text(team, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
        ),
        if (players.isEmpty)
          const Padding(padding: EdgeInsets.all(12), child: Text('No players available', style: TextStyle(fontSize: 11, color: Colors.grey))),
        ...players.asMap().entries.map((e) => Container(
          color: e.key.isEven ? Colors.white : const Color(0xFFF8F9FA),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(children: [
            Container(width: 18, height: 18, decoration: BoxDecoration(color: accent.withValues(alpha: 0.1), shape: BoxShape.circle), alignment: Alignment.center, child: Text('${e.key + 1}', style: TextStyle(fontSize: 8, color: accent, fontWeight: FontWeight.bold))),
            const SizedBox(width: 8),
            Expanded(child: Text(e.value, style: const TextStyle(fontSize: 11, color: Colors.black87))),
          ]),
        )),
      ]),
    );
  }

  // ============ MVP TAB ============
  Widget _buildMVPTab() {
    final overallMvp = MvpCalculator.calculateMVP(_match!, _teamA, _teamB, _teamAPlayers, _teamBPlayers, _balls);

    if (overallMvp.playerName == 'No MVP') {
      return const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('No MVP data available', style: TextStyle(color: Colors.grey))));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(children: [
        _mvpCard(
          '🌟', 
          'Player of the Match', 
          overallMvp.playerName, 
          overallMvp.teamName, 
          'Total Impact Points: ${overallMvp.totalPoints}\n${overallMvp.detailedStats}', 
          Colors.amber[700]!
        ),
      ]),
    );
  }

  Widget _mvpCard(String emoji, String title, String player, String team, String desc, Color accent) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border(left: BorderSide(color: accent, width: 4)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6)],
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(color: accent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
          alignment: Alignment.center,
          child: Text(emoji, style: const TextStyle(fontSize: 20)),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: TextStyle(fontSize: 9, color: accent, fontWeight: FontWeight.bold, letterSpacing: 1)),
          const SizedBox(height: 2),
          Text(player, style: GoogleFonts.oswald(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
          if (team.isNotEmpty) Text(team, style: const TextStyle(fontSize: 9, color: Colors.grey)),
          const SizedBox(height: 6),
          Text(desc, style: const TextStyle(fontSize: 10, color: Colors.black54, height: 1.4)),
        ])),
      ]),
    );
  }
}
