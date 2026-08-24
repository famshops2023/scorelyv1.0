import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../match/match_setup_screen.dart';
import '../teams/providers/teams_provider.dart';
import '../../models/match_stats.dart';

class InningsSummaryData {
  final MatchSetupData setupData;
  final String battingTeam;
  final String fieldingTeam;
  final int runs;
  final int wickets;
  final int ballsBowled;
  final int extraRuns;
  final int totalFours;
  final int totalSixes;
  final List<BatterStats> topBatters;
  final List<BowlerStats> topBowlers;

  InningsSummaryData({
    required this.setupData,
    required this.battingTeam,
    required this.fieldingTeam,
    required this.runs,
    required this.wickets,
    required this.ballsBowled,
    required this.extraRuns,
    required this.totalFours,
    required this.totalSixes,
    required this.topBatters,
    required this.topBowlers,
  });
}

class InningsBreakScreen extends ConsumerStatefulWidget {
  final InningsSummaryData data;

  const InningsBreakScreen({super.key, required this.data});

  @override
  ConsumerState<InningsBreakScreen> createState() => _InningsBreakScreenState();
}

class _InningsBreakScreenState extends ConsumerState<InningsBreakScreen> {
  String? _newScorerName;
  String? _newScorerId;

  void _showAllBowlersDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'All Bowlers — ${widget.data.fieldingTeam}',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: const Color(0xFF191C1E),
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(flex: 3, child: Text('BOWLER', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF575D78)))),
                    Expanded(child: Text('O', textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF575D78)))),
                    Expanded(child: Text('M', textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF575D78)))),
                    Expanded(child: Text('R', textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF575D78)))),
                    Expanded(child: Text('W', textAlign: TextAlign.right, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF575D78)))),
                  ],
                ),
                const Divider(height: 16),
                ...widget.data.topBowlers.map((b) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Expanded(flex: 3, child: Text(b.name, style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFF1A2138), fontSize: 13))),
                      Expanded(child: Text(b.oversDisplay, textAlign: TextAlign.center, style: GoogleFonts.inter(color: const Color(0xFF575D78), fontSize: 13))),
                      Expanded(child: Text('${b.maidens}', textAlign: TextAlign.center, style: GoogleFonts.inter(color: const Color(0xFF575D78), fontSize: 13))),
                      Expanded(child: Text('${b.runsConceded}', textAlign: TextAlign.center, style: GoogleFonts.inter(color: const Color(0xFF575D78), fontSize: 13))),
                      Expanded(child: Text('${b.wickets}', textAlign: TextAlign.right, style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFFBA0013), fontSize: 13))),
                    ],
                  ),
                )),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('CLOSE', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: const Color(0xFFBA0013))),
            ),
          ],
        );
      },
    );
  }

  Future<void> _assignNewScorer() async {
    final setup = widget.data.setupData;
    final targetTeam = widget.data.fieldingTeam;

    TeamMember? selectedPlayer;
    if (setup.isQuickMatch) {
      selectedPlayer = await context.push<TeamMember?>(
        '/team-squad',
        extra: {
          'teamId': '',
          'readOnly': false,
          'singleSelectionMode': true,
          'setupData': setup,
          'teamType': targetTeam,
        },
      );
    } else {
      final teams = ref.read(teamsProvider).value ?? [];
      final team = teams.firstWhere(
        (t) => t.name == targetTeam,
        orElse: () => TeamData(
          id: '',
          name: '',
          location: '',
          dateActive: DateTime.now(),
          members: [],
        ),
      );

      if (team.id.isNotEmpty) {
        selectedPlayer = await context.push<TeamMember?>(
          '/team-squad',
          extra: {
            'teamId': team.id,
            'readOnly': false,
            'singleSelectionMode': true,
          },
        );
      } else {
        selectedPlayer = await context.push<TeamMember?>(
          '/team-squad',
          extra: {
            'teamId': '',
            'readOnly': false,
            'singleSelectionMode': true,
            'setupData': setup,
            'teamType': targetTeam,
          },
        );
      }
    }

    if (selectedPlayer != null) {
      final player = selectedPlayer;
      setState(() {
        _newScorerName = player.name;
        _newScorerId = player.id;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final oversText = '${widget.data.ballsBowled ~/ 6}.${widget.data.ballsBowled % 6}';
    final runRate = widget.data.ballsBowled > 0 ? (widget.data.runs / (widget.data.ballsBowled / 6)).toStringAsFixed(2) : '0.00';
    
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A2138),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Innings Summary', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () {},
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Card
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(color: Color.fromRGBO(26, 33, 56, 0.06), blurRadius: 16, offset: Offset(0, 4))
                      ]
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 4,
                          height: 120,
                          decoration: const BoxDecoration(
                            color: Color(0xFFBA0013),
                            borderRadius: BorderRadius.only(topLeft: Radius.circular(16), bottomLeft: Radius.circular(16)),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('${widget.data.battingTeam.toUpperCase()} - 1ST INNINGS', style: GoogleFonts.plusJakartaSans(color: const Color(0xFFBA0013), fontWeight: FontWeight.bold, fontSize: 11)),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(4)),
                                      child: Text('COMPLETED', style: GoogleFonts.inter(color: const Color(0xFF006B1B), fontWeight: FontWeight.bold, fontSize: 9)),
                                    )
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.baseline,
                                  textBaseline: TextBaseline.alphabetic,
                                  children: [
                                    Text('${widget.data.runs}/${widget.data.wickets}', style: GoogleFonts.plusJakartaSans(fontSize: 32, fontWeight: FontWeight.bold, color: const Color(0xFF191C1E))),
                                    const SizedBox(width: 6),
                                    Text('($oversText overs)', style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF575D78))),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('RUN RATE', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF575D78))),
                                        Text(runRate, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF191C1E))),
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text('EXTRAS', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF575D78))),
                                        Text('${widget.data.extraRuns}', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF191C1E))),
                                      ],
                                    ),
                                  ],
                                )
                              ],
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Scorer assignment
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('2nd Innings Scorer:', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: const Color(0xFF191C1E))),
                      TextButton.icon(
                        onPressed: _assignNewScorer,
                        icon: const Icon(Icons.person_add, size: 16, color: Color(0xFFBA0013)),
                        label: Text(_newScorerName ?? 'Assign Scorer', style: GoogleFonts.plusJakartaSans(color: const Color(0xFFBA0013), fontWeight: FontWeight.bold)),
                      )
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Batting Performance
                  Text('Batting Performance', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF191C1E))),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFECEEF1))),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              Expanded(flex: 3, child: Text('BATTER', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF575D78)))),
                              Expanded(child: Text('R', textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF575D78)))),
                              Expanded(child: Text('B', textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF575D78)))),
                              Expanded(child: Text('4S', textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF575D78)))),
                              Expanded(child: Text('6S', textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF575D78)))),
                              Expanded(flex: 1, child: Text('SR', textAlign: TextAlign.right, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF575D78)))),
                            ],
                          ),
                        ),
                        const Divider(height: 1, color: Color(0xFFECEEF1)),
                        ...widget.data.topBatters.map((b) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              Expanded(flex: 3, child: Text(b.name + (b.isOut ? '' : '*'), style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: b.isOut ? const Color(0xFF191C1E) : const Color(0xFFBA0013), fontSize: 13))),
                              Expanded(child: Text('${b.runs}', textAlign: TextAlign.center, style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: b.isOut ? const Color(0xFF191C1E) : const Color(0xFFBA0013), fontSize: 13))),
                              Expanded(child: Text('${b.balls}', textAlign: TextAlign.center, style: GoogleFonts.inter(color: const Color(0xFF575D78), fontSize: 13))),
                              Expanded(child: Text('${b.fours}', textAlign: TextAlign.center, style: GoogleFonts.inter(color: const Color(0xFF575D78), fontSize: 13))),
                              Expanded(child: Text('${b.sixes}', textAlign: TextAlign.center, style: GoogleFonts.inter(color: const Color(0xFF575D78), fontSize: 13))),
                              Expanded(flex: 1, child: Text(b.strikeRate.toStringAsFixed(1), textAlign: TextAlign.right, style: GoogleFonts.inter(color: const Color(0xFF575D78), fontSize: 13))),
                            ],
                          ),
                        )),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Match Statistics
                  Text('Match Statistics', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF191C1E))),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFECEEF1))),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatCol('EXTRAS', '${widget.data.extraRuns}'),
                        Container(width: 1, height: 30, color: const Color(0xFFECEEF1)),
                        _buildStatCol('FOURS', '${widget.data.totalFours}'),
                        Container(width: 1, height: 30, color: const Color(0xFFECEEF1)),
                        _buildStatCol('SIXES', '${widget.data.totalSixes}'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Top Bowlers
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Top Bowlers (${widget.data.fieldingTeam})', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF191C1E))),
                      GestureDetector(
                        onTap: _showAllBowlersDialog,
                        child: Text('VIEW ALL', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFFBA0013))),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFECEEF1))),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              Expanded(flex: 3, child: Text('BOWLER', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF575D78)))),
                              Expanded(child: Text('O', textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF575D78)))),
                              Expanded(child: Text('M', textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF575D78)))),
                              Expanded(child: Text('R', textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF575D78)))),
                              Expanded(child: Text('W', textAlign: TextAlign.right, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF575D78)))),
                            ],
                          ),
                        ),
                        const Divider(height: 1, color: Color(0xFFECEEF1)),
                        ...widget.data.topBowlers.map((b) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              Expanded(flex: 3, child: Text(b.name, style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFF1A2138), fontSize: 13))),
                              Expanded(child: Text(b.oversDisplay, textAlign: TextAlign.center, style: GoogleFonts.inter(color: const Color(0xFF575D78), fontSize: 13))),
                              Expanded(child: Text('${b.maidens}', textAlign: TextAlign.center, style: GoogleFonts.inter(color: const Color(0xFF575D78), fontSize: 13))),
                              Expanded(child: Text('${b.runsConceded}', textAlign: TextAlign.center, style: GoogleFonts.inter(color: const Color(0xFF575D78), fontSize: 13))),
                              Expanded(child: Text('${b.wickets}', textAlign: TextAlign.right, style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFFBA0013), fontSize: 13))),
                            ],
                          ),
                        )),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
          // Bottom Button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Color.fromRGBO(26, 33, 56, 0.08),
                  blurRadius: 16,
                  offset: Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFBA0013),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 4,
                  ),
                  onPressed: () {
                    // Update setup data with new scorer
                    final updatedSetup = widget.data.setupData.copyWith(
                      teamBScorerName: _newScorerName,
                      teamBScorerId: _newScorerId,
                    );
                    Navigator.pop(context, updatedSetup);
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'PROCEED TO 2ND INNINGS',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward, color: Colors.white, size: 18),
                    ],
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildStatCol(String label, String value) {
    return Column(
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF575D78))),
        const SizedBox(height: 4),
        Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF191C1E))),
      ],
    );
  }
}
