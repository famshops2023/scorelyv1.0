import 'package:flutter/material.dart';
import 'package:scorely/core/theme/colors.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../match/match_setup_screen.dart';
import '../match/opening_lineup_screen.dart';
import '../../models/player_setup.dart';
import '../../models/match_result_data.dart';
import '../../services/database.dart';
import '../../services/sync_manager.dart';
import '../../services/live_scoring_service.dart';
import 'package:drift/drift.dart' as drift;
import '../../providers/history_provider.dart';
import '../../services/sound_service.dart';
import '../../services/wakelock_service.dart';
import '../../services/notification_service.dart';
import '../../services/ongoing_match_service.dart';
import 'models/scoring_models.dart';
import 'widgets/live_score_card.dart';
import 'widgets/active_players_card.dart';
import 'widgets/over_summary_timeline.dart';
import 'widgets/quick_tap_action_board.dart';
import 'widgets/wicket_sub_panel.dart';

export 'models/scoring_models.dart';

// --- Main Widget Screen ---

class ScoringScreen extends ConsumerStatefulWidget {
  final MatchSetupData? setupData;
  final OpeningLineupResult? lineup;
  const ScoringScreen({super.key, this.setupData, this.lineup});

  @override
  ConsumerState<ScoringScreen> createState() => _ScoringScreenState();
}

class _ScoringScreenState extends ConsumerState<ScoringScreen> {
  late MatchSetupData _setup;

  // State Variables
  late String _battingTeam;
  late String _fieldingTeam;
  late List<PlayerSetupData> _battingPlayers;
  late List<PlayerSetupData> _fieldingPlayers;

  int _runs = 0;
  int _wickets = 0;
  int _ballsBowled = 0; // Legal balls bowled
  int _extraRuns = 0;
  List<String> _thisOver = [];

  // Active players
  String? _striker;
  String? _nonStriker;
  String? _currentBowler;

  // Stats Maps
  Map<String, BatterStats> _batterStats = {};
  Map<String, BowlerStats> _bowlerStats = {};

  List<String> _wicketsHistory = []; // Order of players out
  List<String> _batterOrder = []; // Order of players who came out to bat
  int _nextBatterIndex = 2; // Next batter to select from team list

  // 2nd Innings tracking
  bool _isSecondInnings = false;
  int? _target;
  int _firstInningsRuns = 0;
  int _firstInningsWickets = 0;
  String _firstInningsTeam = '';
  String _firstInningsOvers = '';
  int _firstInningsBalls = 0;

  List<LocalBallEvent> _localBalls = [];
  List<LocalBallEvent> _firstInningsBallsList = [];

  // Undo/Redo stacks
  List<MatchState> _history = [];
  int _historyIndex = -1;

  // Action board state
  String? _selectedAction; // "0", "1", "2", "3", "4", "5", "6", "WD", "NB", "B", "LB", "W"
  int _selectedExtraRuns = 0; // Wid/NB/B/LB runs
  String? _selectedWicketType; // Bowled, Caught, LBW, Stumped, Run Out
  String? _selectedWicketBatter; // Striker, Non-Striker
  String? _selectedWicketFielder; // Catcher or assister

  // Live scoring service — only active for scheduled (non-quick) matches
  final LiveScoringService _liveService = LiveScoringService();

  @override
  void initState() {
    super.initState();

    _setup = widget.setupData ??
        MatchSetupData(
          teamAName: 'Team Alpha',
          teamBName: 'Team Bravo',
          teamAPlayers: List.generate(
              11,
              (i) => PlayerSetupData(
                  name: 'Alpha Player ${i + 1}',
                  role: i < 5 ? PlayerRole.batsman : PlayerRole.bowler)),
          teamBPlayers: List.generate(
              11,
              (i) => PlayerSetupData(
                  name: 'Bravo Player ${i + 1}',
                  role: i < 5 ? PlayerRole.batsman : PlayerRole.bowler)),
          overs: 20,
          tossWonBy: 'Team Alpha',
          maxOversPerBowler: 4,
          powerplayOvers: 6,
          battingFirstTeam: 'Team Alpha',
          matchType: 'T20',
          ballType: 'Leather',
          venue: 'Demo Stadium',
          matchDate: DateTime.now(),
        );

    _battingTeam = _setup.battingFirstTeam;
    _fieldingTeam =
        _battingTeam == _setup.teamAName ? _setup.teamBName : _setup.teamAName;

    _battingPlayers =
        _battingTeam == _setup.teamAName ? _setup.teamAPlayers : _setup.teamBPlayers;
    _fieldingPlayers =
        _battingTeam == _setup.teamAName ? _setup.teamBPlayers : _setup.teamAPlayers;

    // Initialize batting crease
    if (widget.lineup != null) {
      _striker = widget.lineup!.openingBat1.name;
      _nonStriker = widget.lineup!.openingBat2.name;
      _currentBowler = widget.lineup!.openingBowler.name;
      _batterOrder.addAll([_striker!, _nonStriker!]);
      _batterStats[_striker!] = BatterStats(name: _striker!);
      _batterStats[_nonStriker!] = BatterStats(name: _nonStriker!);
      _bowlerStats[_currentBowler!] = BowlerStats(name: _currentBowler!);
    } else {
      if (_battingPlayers.isNotEmpty) {
        _striker = _battingPlayers[0].name;
        _batterOrder.add(_striker!);
        _batterStats[_striker!] = BatterStats(name: _striker!);
      }
      if (_battingPlayers.length > 1) {
        _nonStriker = _battingPlayers[1].name;
        _batterOrder.add(_nonStriker!);
        _batterStats[_nonStriker!] = BatterStats(name: _nonStriker!);
      }

      // Initialize bowling
      if (_fieldingPlayers.isNotEmpty) {
        _currentBowler = _fieldingPlayers.firstWhere(
            (p) => p.role == PlayerRole.bowler,
            orElse: () => _fieldingPlayers[0]).name;
        _bowlerStats[_currentBowler!] = BowlerStats(name: _currentBowler!);
      }
    }

    // Save initial state in history
    _commitState();

    // Check if an ongoing match session exists to restore
    final ongoingId = _setup.id.isNotEmpty
        ? _setup.id
        : 'quick_${_setup.teamAName}_vs_${_setup.teamBName}';
    _restoreOngoingMatchIfAny(ongoingId);

    // Init live scoring push for scheduled matches
    final insForgeId = _setup.id;
    if (!_setup.isQuickMatch && insForgeId.isNotEmpty) {
      _liveService.init(insForgeId);
    }

    // Keep screen awake during match scoring if enabled
    WakelockService.instance.enableIfAllowed();
  }

  @override
  void dispose() {
    WakelockService.instance.disable();
    _liveService.dispose();
    super.dispose();
  }

  // --- Undo/Redo Engine ---

  void _commitState() {
    if (_historyIndex < _history.length - 1) {
      _history = _history.sublist(0, _historyIndex + 1);
    }
    _history.add(MatchState(
      runs: _runs,
      wickets: _wickets,
      ballsBowled: _ballsBowled,
      extraRuns: _extraRuns,
      thisOver: List.from(_thisOver),
      striker: _striker ?? '',
      nonStriker: _nonStriker ?? '',
      currentBowler: _currentBowler ?? '',
      batterStats: _batterStats.map((k, v) => MapEntry(k, v.clone())),
      bowlerStats: _bowlerStats.map((k, v) => MapEntry(k, v.clone())),
      wicketsHistory: List.from(_wicketsHistory),
      batterOrder: List.from(_batterOrder),
      nextBatterIndex: _nextBatterIndex,
      localBalls: List.from(_localBalls),
    ));
    _historyIndex = _history.length - 1;

    // Push live update to InsForge for scheduled matches
    if (!_setup.isQuickMatch && _setup.id.isNotEmpty) {
      _pushLiveUpdate();
    }

    // Persist snapshot to avoid data loss on crash or restart
    _saveOngoingSnapshot();
  }

  void _saveOngoingSnapshot() {
    final ongoingId = _setup.id.isNotEmpty
        ? _setup.id
        : 'quick_${_setup.teamAName}_vs_${_setup.teamBName}';
    final snapshot = {
      'setup': _setup.toJson(),
      'battingTeam': _battingTeam,
      'fieldingTeam': _fieldingTeam,
      'runs': _runs,
      'wickets': _wickets,
      'ballsBowled': _ballsBowled,
      'extraRuns': _extraRuns,
      'thisOver': _thisOver,
      'striker': _striker,
      'nonStriker': _nonStriker,
      'currentBowler': _currentBowler,
      'batterStats': _batterStats.map((k, v) => MapEntry(k, v.toJson())),
      'bowlerStats': _bowlerStats.map((k, v) => MapEntry(k, v.toJson())),
      'wicketsHistory': _wicketsHistory,
      'batterOrder': _batterOrder,
      'nextBatterIndex': _nextBatterIndex,
      'isSecondInnings': _isSecondInnings,
      'target': _target,
      'firstInningsRuns': _firstInningsRuns,
      'firstInningsWickets': _firstInningsWickets,
      'firstInningsTeam': _firstInningsTeam,
      'firstInningsOvers': _firstInningsOvers,
      'firstInningsBalls': _firstInningsBalls,
      'localBalls': _localBalls.map((b) => b.toJson()).toList(),
      'firstInningsBallsList':
          _firstInningsBallsList.map((b) => b.toJson()).toList(),
    };
    OngoingMatchService.instance.saveSnapshot(ongoingId, snapshot);
  }

  Future<void> _restoreOngoingMatchIfAny(String ongoingId) async {
    final snapshot = await OngoingMatchService.instance.getSnapshot(ongoingId);
    if (snapshot != null && mounted) {
      setState(() {
        _runs = snapshot['runs'] as int? ?? _runs;
        _wickets = snapshot['wickets'] as int? ?? _wickets;
        _ballsBowled = snapshot['ballsBowled'] as int? ?? _ballsBowled;
        _extraRuns = snapshot['extraRuns'] as int? ?? _extraRuns;
        _thisOver = (snapshot['thisOver'] as List?)?.map((e) => e.toString()).toList() ?? _thisOver;
        _striker = snapshot['striker'] as String? ?? _striker;
        _nonStriker = snapshot['nonStriker'] as String? ?? _nonStriker;
        _currentBowler = snapshot['currentBowler'] as String? ?? _currentBowler;
        _isSecondInnings = snapshot['isSecondInnings'] as bool? ?? _isSecondInnings;
        _target = snapshot['target'] as int? ?? _target;
        _firstInningsRuns = snapshot['firstInningsRuns'] as int? ?? _firstInningsRuns;
        _firstInningsWickets = snapshot['firstInningsWickets'] as int? ?? _firstInningsWickets;
        _firstInningsTeam = snapshot['firstInningsTeam'] as String? ?? _firstInningsTeam;
        _firstInningsOvers = snapshot['firstInningsOvers'] as String? ?? _firstInningsOvers;
        _firstInningsBalls = snapshot['firstInningsBalls'] as int? ?? _firstInningsBalls;
        _battingTeam = snapshot['battingTeam'] as String? ?? _battingTeam;
        _fieldingTeam = snapshot['fieldingTeam'] as String? ?? _fieldingTeam;

        if (snapshot['batterStats'] != null) {
          final map = snapshot['batterStats'] as Map<String, dynamic>;
          _batterStats = map.map((k, v) => MapEntry(k, BatterStats.fromJson(v as Map<String, dynamic>)));
        }
        if (snapshot['bowlerStats'] != null) {
          final map = snapshot['bowlerStats'] as Map<String, dynamic>;
          _bowlerStats = map.map((k, v) => MapEntry(k, BowlerStats.fromJson(v as Map<String, dynamic>)));
        }
        if (snapshot['wicketsHistory'] != null) {
          _wicketsHistory = (snapshot['wicketsHistory'] as List).map((e) => e.toString()).toList();
        }
        if (snapshot['batterOrder'] != null) {
          _batterOrder = (snapshot['batterOrder'] as List).map((e) => e.toString()).toList();
        }
        if (snapshot['localBalls'] != null) {
          _localBalls = (snapshot['localBalls'] as List)
              .map((e) => LocalBallEvent.fromJson(e as Map<String, dynamic>))
              .toList();
        }
        if (snapshot['firstInningsBallsList'] != null) {
          _firstInningsBallsList = (snapshot['firstInningsBallsList'] as List)
              .map((e) => LocalBallEvent.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      });
      _commitState();
    }
  }

  void _checkAndRecordMaidenOver() {
    if (_currentBowler == null) return;
    bool concededRuns = false;
    for (final ball in _thisOver) {
      // Wides and No-Balls always concede at least 1 run — cannot be maiden
      if (ball.contains('Wd') || ball.contains('Nb')) {
        concededRuns = true;
        break;
      }
      // Wicket, dot ball, byes and leg-byes do NOT concede bowler runs
      if (ball == 'W' || ball == '.') continue;
      // Byes (e.g. '2B') and LegByes (e.g. '3LB') — runs go to extras, not bowler
      if (ball.endsWith('LB')) continue;
      if (ball.endsWith('B') && !ball.contains('N')) continue;
      final runs = int.tryParse(ball);
      if (runs != null && runs > 0) {
        concededRuns = true;
        break;
      }
    }
    if (!concededRuns && _thisOver.isNotEmpty) {
      _bowlerStats[_currentBowler!]?.maidens += 1;
    }
  }

  /// Builds the live score blob and pushes it to InsForge.
  void _pushLiveUpdate() {
    final innings1TeamName = _firstInningsTeam.isEmpty ? _setup.battingFirstTeam : _firstInningsTeam;
    final batting1st = innings1TeamName == _setup.teamAName;

    // Build current_batters list
    final List<Map<String, dynamic>> currentBatters = [];
    if (_striker != null) {
      final bs = _batterStats[_striker!];
      currentBatters.add({
        'name': _striker,
        'runs': bs?.runs ?? 0,
        'balls': bs?.balls ?? 0,
        'fours': bs?.fours ?? 0,
        'sixes': bs?.sixes ?? 0,
        'is_striker': true,
      });
    }
    if (_nonStriker != null) {
      final bs = _batterStats[_nonStriker!];
      currentBatters.add({
        'name': _nonStriker,
        'runs': bs?.runs ?? 0,
        'balls': bs?.balls ?? 0,
        'fours': bs?.fours ?? 0,
        'sixes': bs?.sixes ?? 0,
        'is_striker': false,
      });
    }

    // Build current_bowler map
    final Map<String, dynamic> currentBowler = {};
    if (_currentBowler != null) {
      final bw = _bowlerStats[_currentBowler!];
      currentBowler['name'] = _currentBowler;
      currentBowler['overs'] = bw?.oversDisplay ?? '0.0';
      currentBowler['runs'] = bw?.runsConceded ?? 0;
      currentBowler['wickets'] = bw?.wickets ?? 0;
    }

    // Scores
    final String teamAScore = _isSecondInnings
        ? '$_firstInningsRuns/$_firstInningsWickets'
        : '$_runs/$_wickets';
    final String teamAOvers = _isSecondInnings
        ? _firstInningsOvers
        : '${_ballsBowled ~/ 6}.${_ballsBowled % 6}';
    final String teamBScore = _isSecondInnings ? '$_runs/$_wickets' : 'Yet to bat';
    final String teamBOvers = _isSecondInnings ? '${_ballsBowled ~/ 6}.${_ballsBowled % 6}' : '';

    // last 6 balls of this over
    final String last6 = _thisOver.join(' ');

    final blob = <String, dynamic>{
      'team_a_score': batting1st ? teamAScore : teamBScore,
      'team_a_overs': batting1st ? teamAOvers : teamBOvers,
      'team_b_score': batting1st ? teamBScore : teamAScore,
      'team_b_overs': batting1st ? teamBOvers : teamAOvers,
      'innings': _isSecondInnings ? 2 : 1,
      'last_6_balls': last6,
      'current_batters': currentBatters,
      'current_bowler': currentBowler,
      'scorer_id': _setup.teamAScorerName ?? '',
      'team_a_player_ids': _setup.teamAPlayers.map((p) => p.name).toList(),
      'team_b_player_ids': _setup.teamBPlayers.map((p) => p.name).toList(),
      'format': _setup.matchType,
      'venue': _setup.venue,
    };

    _liveService.pushLiveUpdate(blob);
  }

  void _undo() {
    if (_historyIndex > 0) {
      setState(() {
        _historyIndex--;
        _restoreState(_history[_historyIndex]);
      });
    }
  }

  void _redo() {
    if (_historyIndex < _history.length - 1) {
      setState(() {
        _historyIndex++;
        _restoreState(_history[_historyIndex]);
      });
    }
  }

  void _restoreState(MatchState state) {
    _runs = state.runs;
    _wickets = state.wickets;
    _ballsBowled = state.ballsBowled;
    _extraRuns = state.extraRuns;
    _thisOver = List.from(state.thisOver);
    _striker = state.striker.isEmpty ? null : state.striker;
    _nonStriker = state.nonStriker.isEmpty ? null : state.nonStriker;
    _currentBowler = state.currentBowler.isEmpty ? null : state.currentBowler;
    _batterStats = state.batterStats.map((k, v) => MapEntry(k, v.clone()));
    _bowlerStats = state.bowlerStats.map((k, v) => MapEntry(k, v.clone()));
    _wicketsHistory = List.from(state.wicketsHistory);
    _batterOrder = List.from(state.batterOrder);
    _nextBatterIndex = state.nextBatterIndex;
    _localBalls = List.from(state.localBalls);
  }

  bool _isInningsOver() {
    bool allOut = _wickets >= 10 || (_battingPlayers.isNotEmpty && _wickets >= _battingPlayers.length - 1);
    if (!_isSecondInnings) {
      return _ballsBowled >= _setup.overs * 6 || allOut;
    } else {
      return _runs >= _target! || _ballsBowled >= _setup.overs * 6 || allOut;
    }
  }

  // --- Strike management & quick actions ---

  void _swapStrike() {
    setState(() {
      final temp = _striker;
      _striker = _nonStriker;
      _nonStriker = temp;
      _commitState();
    });
  }

  void _promptChangeBatter(bool isStriker) {
    final currentBatter = isStriker ? _striker : _nonStriker;
    if (currentBatter == null) return;
    
    final stats = _batterStats[currentBatter];
    if (stats != null && (stats.runs > 0 || stats.balls > 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cannot change $currentBatter because they have already faced balls. Use Retire instead.')),
      );
      return;
    }

    final unbatted = _battingPlayers
        .where((p) => !_batterOrder.contains(p.name) && p.name != currentBatter)
        .toList();

    if (unbatted.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No other unbatted players available.')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CHANGE BATTER',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Replace $currentBatter with:',
                style: GoogleFonts.inter(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: unbatted.length,
                  itemBuilder: (context, idx) {
                    final p = unbatted[idx];
                    return ListTile(
                      title: Text(p.name,
                          style: GoogleFonts.inter(color: Colors.white)),
                      onTap: () {
                        setState(() {
                          _batterOrder.remove(currentBatter);
                          _batterStats.remove(currentBatter);

                          if (isStriker) {
                            _striker = p.name;
                          } else {
                            _nonStriker = p.name;
                          }
                          
                          _batterOrder.add(p.name);
                          _batterStats[p.name] = BatterStats(name: p.name);
                        });
                        Navigator.pop(context);
                        _commitState();
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _promptRetireBatter() {
    final list =
        [_striker, _nonStriker].where((name) => name != null).map((n) => n!).toList();
    if (list.isEmpty) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CHOOSE BATTER TO RETIRE',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Column(
                children: list.map((name) {
                  return ListTile(
                    title: Text(name,
                        style: GoogleFonts.inter(color: Colors.white)),
                    onTap: () {
                      Navigator.pop(context);
                      _retirePlayer(name);
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  void _retirePlayer(String name) {
    final unbatted = _battingPlayers
        .where((p) => !_batterOrder.contains(p.name))
        .toList();
    if (unbatted.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No unbatted players available.')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SELECT INCOMING BATTER',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: unbatted.length,
                  itemBuilder: (context, idx) {
                    final p = unbatted[idx];
                    return ListTile(
                      title: Text(p.name,
                          style: GoogleFonts.inter(color: Colors.white)),
                      onTap: () {
                        setState(() {
                          _batterStats[name]?.isOut = true;
                          _batterStats[name]?.dismissalInfo = 'retired hurt';

                          if (name == _striker) {
                            _striker = p.name;
                          } else {
                            _nonStriker = p.name;
                          }
                          _batterOrder.add(p.name);
                          _batterStats[p.name] = BatterStats(name: p.name);
                        });
                        Navigator.pop(context);
                        _commitState();
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _promptChangeBowler() {
    final list =
        _fieldingPlayers.where((p) => p.name != _currentBowler).toList();
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SELECT NEW BOWLER',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: list.length,
                  itemBuilder: (context, idx) {
                    final p = list[idx];
                    return ListTile(
                      title: Text(p.name,
                          style: GoogleFonts.inter(color: Colors.white)),
                      subtitle: Text(p.role.displayName,
                          style: GoogleFonts.inter(color: Colors.grey)),
                      trailing: const Icon(Icons.arrow_forward_ios,
                          size: 14, color: Colors.grey),
                      onTap: () {
                        setState(() {
                          _currentBowler = p.name;
                          if (!_bowlerStats.containsKey(_currentBowler)) {
                            _bowlerStats[_currentBowler!] =
                                BowlerStats(name: _currentBowler!);
                          }
                          _thisOver.clear(); // Clear timeline for new bowler/over
                        });
                        Navigator.pop(context);
                        _commitState();
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- Confirm outcome logic ---

  void _confirmBallOutcome() async {
    if (_selectedAction == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select a scoring action first.')),
      );
      return;
    }

    final action = _selectedAction!;

    // Wides and No-Balls do not count as legal deliveries.
    // If the innings is already over (all legal balls bowled), block them.
    if ((action == 'WD' || action == 'NB') && _isInningsOver()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Innings is complete — no more balls can be bowled.')),
      );
      return;
    }

    if (action == 'W') {
      await _processWicketConfirm();
    } else {
      setState(() {
        if (action == 'WD') {
          _processWideConfirm();
        } else if (action == 'NB') {
          _processNoBallConfirm();
        } else if (action == 'B' || action == 'LB') {
          _processByesConfirm(action);
        } else {
          final r = int.parse(action);
          _processNormalRunsConfirm(r);
        }
      });
    }

    // Check for victory/loss
    _checkInningsStatus();

    // Reset selection state — deselects action buttons and hides wicket panel
    setState(() {
      _selectedAction = null;
      _selectedExtraRuns = 0;
      _selectedWicketType = null;
      _selectedWicketBatter = null;
      _selectedWicketFielder = null;
    });
  }

  void _processNormalRunsConfirm(int r) {
    final facingBatter = _striker ?? 'Unknown'; // capture BEFORE any swap
    if (_striker != null) {
      _batterStats[_striker!]?.runs += r;
      _batterStats[_striker!]?.balls += 1;
      if (r == 4) {
        _batterStats[_striker!]?.fours += 1;
        SoundService.instance.playFour();
      }
      if (r == 6) {
        _batterStats[_striker!]?.sixes += 1;
        SoundService.instance.playSix();
      }
    }

    if (_currentBowler != null) {
      _bowlerStats[_currentBowler!]?.runsConceded += r;
      _bowlerStats[_currentBowler!]?.ballsBowled += 1;
    }

    _runs += r;
    _ballsBowled += 1;

    _thisOver.add(r == 0 ? '.' : '$r');

    // Strike swap on odd runs
    if (r % 2 != 0) {
      final temp = _striker;
      _striker = _nonStriker;
      _nonStriker = temp;
    }

    _localBalls.add(LocalBallEvent(runs: r, isWicket: false, isExtra: false, batterName: facingBatter, bowlerName: _currentBowler ?? 'Unknown'));
    _commitState();

    if (_ballsBowled % 6 == 0 && !_isInningsOver()) {
      _checkAndRecordMaidenOver();
      // End of over swap strike
      final temp = _striker;
      _striker = _nonStriker;
      _nonStriker = temp;
      _promptOverCompleteBowlerChange();
    }
  }

  void _processWideConfirm() {
    final penalty = 1 + _selectedExtraRuns;
    final facingBatter = _striker ?? 'Unknown'; // capture BEFORE any swap
    _runs += penalty;
    _extraRuns += penalty;

    if (_currentBowler != null) {
      _bowlerStats[_currentBowler!]?.runsConceded += penalty;
    }

    _thisOver.add(
        '${_selectedExtraRuns == 0 ? "" : _selectedExtraRuns}Wd');

    // Swap strike if ran odd extra runs
    if (_selectedExtraRuns % 2 != 0) {
      final temp = _striker;
      _striker = _nonStriker;
      _nonStriker = temp;
    }

    _localBalls.add(LocalBallEvent(runs: penalty, isWicket: false, isExtra: true, extraType: 'Wide', batterName: facingBatter, bowlerName: _currentBowler ?? 'Unknown'));
    _commitState();
  }

  void _processNoBallConfirm() {
    final penalty = 1;
    final batterRuns = _selectedExtraRuns;
    final facingBatter = _striker ?? 'Unknown'; // capture BEFORE any swap
    _runs += penalty + batterRuns;
    _extraRuns += penalty;

    if (_striker != null) {
      _batterStats[_striker!]?.runs += batterRuns;
      _batterStats[_striker!]?.balls += 1;
      if (batterRuns == 4) _batterStats[_striker!]?.fours += 1;
      if (batterRuns == 6) _batterStats[_striker!]?.sixes += 1;
    }

    if (_currentBowler != null) {
      _bowlerStats[_currentBowler!]?.runsConceded += penalty + batterRuns;
    }

    _thisOver.add(
        '${batterRuns == 0 ? "" : batterRuns}Nb');

    // Swap strike if odd runs hit
    if (batterRuns % 2 != 0) {
      final temp = _striker;
      _striker = _nonStriker;
      _nonStriker = temp;
    }

    _localBalls.add(LocalBallEvent(runs: penalty + batterRuns, isWicket: false, isExtra: true, extraType: 'NoBall', batterName: facingBatter, bowlerName: _currentBowler ?? 'Unknown'));
    _commitState();
  }

  void _processByesConfirm(String type) {
    final extra = _selectedExtraRuns;
    final facingBatter = _striker ?? 'Unknown'; // capture BEFORE any swap
    _runs += extra;
    _extraRuns += extra;

    if (_striker != null) {
      _batterStats[_striker!]?.balls += 1;
    }

    if (_currentBowler != null) {
      _bowlerStats[_currentBowler!]?.ballsBowled += 1;
    }

    _ballsBowled += 1;

    // Append runs with type suffix if provided
    _thisOver.add(extra == 0 ? '.' : '$extra$type');

    if (extra % 2 != 0) {
      final temp = _striker;
      _striker = _nonStriker;
      _nonStriker = temp;
    }

    _localBalls.add(LocalBallEvent(runs: extra, isWicket: false, isExtra: true, extraType: type == 'B' ? 'Bye' : 'LegBye', batterName: facingBatter, bowlerName: _currentBowler ?? 'Unknown'));
    _commitState();

    if (_ballsBowled % 6 == 0 && !_isInningsOver()) {
      _checkAndRecordMaidenOver();
      final temp = _striker;
      _striker = _nonStriker;
      _nonStriker = temp;
      _promptOverCompleteBowlerChange();
    }
  }


  Future<void> _processWicketConfirm() async {
    final isStrikerOut = _selectedWicketBatter != 'Non-Striker';
    final outPlayerName = isStrikerOut ? _striker! : _nonStriker!;

    _wickets++;
    SoundService.instance.playWicket();
    _batterStats[outPlayerName]?.isOut = true;
    _batterStats[outPlayerName]?.dismissalInfo = _buildDismissalString();

    // The striker faced this delivery
    if (_striker != null) {
      _batterStats[_striker!]?.balls += 1;
    }

    if (_selectedWicketType != 'Run Out' && _currentBowler != null) {
      _bowlerStats[_currentBowler!]?.wickets += 1;
    }

    _ballsBowled += 1;
    if (_currentBowler != null) {
      _bowlerStats[_currentBowler!]?.ballsBowled += 1;
    }

    _thisOver.add('W');
    _wicketsHistory.add(outPlayerName);

    _localBalls.add(LocalBallEvent(
      runs: 0,
      isWicket: true,
      wicketType: _selectedWicketType,
      isExtra: false,
      batterName: outPlayerName,
      bowlerName: _currentBowler ?? 'Unknown',
    ));
    _commitState();

    if (!_isInningsOver()) {
      // 1. Wait for incoming batter modal to complete first
      await _promptIncomingBatter(outPlayerName, isStrikerOut);

      // 2. If end of over, check maiden, swap strike, and prompt bowler change
      if (_ballsBowled % 6 == 0 && !_isInningsOver()) {
        _checkAndRecordMaidenOver();
        final temp = _striker;
        _striker = _nonStriker;
        _nonStriker = temp;
        _commitState();
        await _promptOverCompleteBowlerChange();
      }
    }
  }

  String _buildDismissalString() {
    final type = _selectedWicketType ?? 'Bowled';
    final bowler = _currentBowler ?? 'Bowler';
    final fielder = _selectedWicketFielder;

    switch (type) {
      case 'Bowled':
        return 'b $bowler';
      case 'Caught':
        return fielder != null ? 'c $fielder b $bowler' : 'c b $bowler';
      case 'LBW':
        return 'lbw b $bowler';
      case 'Stumped':
        return fielder != null ? 'st $fielder b $bowler' : 'st b $bowler';
      case 'Run Out':
        return fielder != null ? 'run out ($fielder)' : 'run out';
      default:
        return 'out b $bowler';
    }
  }

  Future<void> _promptIncomingBatter(String outPlayerName, bool isStrikerOut) async {
    final unbatted = _battingPlayers
        .where((p) => !_batterOrder.contains(p.name))
        .toList();
    if (unbatted.isEmpty) {
      _checkInningsStatus();
      return;
    }

    await showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F172A),
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SELECT NEW BATTER',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Select replacement for $outPlayerName',
                style:
                    GoogleFonts.inter(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: unbatted.length,
                  itemBuilder: (context, idx) {
                    final p = unbatted[idx];
                    return ListTile(
                      title: Text(p.name,
                          style: GoogleFonts.inter(color: Colors.white)),
                      onTap: () {
                        setState(() {
                          if (isStrikerOut) {
                            _striker = p.name;
                          } else {
                            _nonStriker = p.name;
                          }
                          _batterOrder.add(p.name);
                          _batterStats[p.name] = BatterStats(name: p.name);
                        });
                        Navigator.pop(context);
                        _commitState();
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Tracks the bowler who bowled the previous over — cannot bowl consecutive overs.
  String? _previousOverBowler;

  Future<void> _promptOverCompleteBowlerChange() async {
    final maxOvers = _setup.maxOversPerBowler;
    // Exclude current bowler AND the bowler of the previous over (no consecutive overs)
    final String? prevBowler = _previousOverBowler;
    final list = _fieldingPlayers
        .where((p) => p.name != _currentBowler)
        .toList();
    final bool allMaxed = maxOvers > 0 &&
        list.every((p) =>
            ((_bowlerStats[p.name]?.ballsBowled ?? 0) ~/ 6) >= maxOvers);

    await showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F172A),
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'OVER COMPLETE! SELECT NEXT BOWLER',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: list.length,
                  itemBuilder: (context, idx) {
                    final p = list[idx];
                    final oversBowled =
                        (_bowlerStats[p.name]?.ballsBowled ?? 0) ~/ 6;
                    final isQuotaFinished =
                        !allMaxed && maxOvers > 0 && oversBowled >= maxOvers;
                    // Consecutive over restriction — grey out but allow if ALL others are ineligible
                    final isConsecutive = !allMaxed && p.name == prevBowler;
                    final isDisabled = isQuotaFinished || isConsecutive;

                    String subtitle;
                    if (isQuotaFinished) {
                      subtitle = '${p.role.displayName} • $oversBowled/${maxOvers > 0 ? maxOvers : '∞'} ov (Quota Completed)';
                    } else if (isConsecutive) {
                      subtitle = '${p.role.displayName} • $oversBowled ov (Bowled previous over)';
                    } else {
                      subtitle = maxOvers > 0
                          ? '${p.role.displayName} • $oversBowled/$maxOvers ov'
                          : '${p.role.displayName} • $oversBowled ov';
                    }

                    return ListTile(
                      title: Text(
                        p.name,
                        style: GoogleFonts.inter(
                          color: isDisabled ? Colors.white38 : Colors.white,
                          fontWeight:
                              isDisabled ? FontWeight.normal : FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        subtitle,
                        style: GoogleFonts.inter(
                          color: isDisabled
                              ? Colors.redAccent.shade200
                              : Colors.grey,
                        ),
                      ),
                      enabled: !isDisabled,
                      onTap: isDisabled
                          ? null
                          : () {
                              setState(() {
                                _previousOverBowler = _currentBowler;
                                _currentBowler = p.name;
                                if (!_bowlerStats.containsKey(_currentBowler)) {
                                  _bowlerStats[_currentBowler!] =
                                      BowlerStats(name: _currentBowler!);
                                }
                                _thisOver.clear();
                              });
                              Navigator.pop(context);
                              _commitState();
                            },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- Innings complete logic ---

  void _checkInningsStatus() {
    bool allOut = _wickets >= 10 || (_battingPlayers.isNotEmpty && _wickets >= _battingPlayers.length - 1);

    if (!_isSecondInnings) {
      if (_ballsBowled >= _setup.overs * 6 || allOut) {
        _endFirstInnings();
      }
    } else {
      if (_runs >= _target!) {
        _endMatch(winner: _battingTeam, tie: false);
      } else if (_ballsBowled >= _setup.overs * 6 || allOut) {
        if (_runs == _target! - 1) {
          _endMatch(winner: null, tie: true);
        } else {
          _endMatch(winner: _fieldingTeam, tie: false);
        }
      }
    }
  }

  void _endFirstInnings() {
    NotificationService.instance.showInningsBreakNotification(
      battingTeam: _battingTeam,
      runs: _runs,
      wickets: _wickets,
      overs: '${_ballsBowled ~/ 6}.${_ballsBowled % 6}',
      chasingTeam: _fieldingTeam,
      target: _runs + 1,
    );

    final nextTeam = _fieldingTeam;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.darkCard,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'INNINGS COMPLETE!',
            style: GoogleFonts.inter(
                fontWeight: FontWeight.bold, color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$_battingTeam finished batting.',
                style: GoogleFonts.inter(color: Colors.grey),
              ),
              const SizedBox(height: 12),
              Text(
                'Score: $_runs/$_wickets in ${(_ballsBowled ~/ 6)}.${(_ballsBowled % 6)} overs.',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    color: AppColors.success,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                'Target for $nextTeam: ${_runs + 1} runs.',
                style: GoogleFonts.inter(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Navigator.pop(context);
                _startSecondInnings();
              },
              child: Text('Start 2nd Innings',
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _startSecondInnings() {
    setState(() {
      _isSecondInnings = true;
      _target = _runs + 1;
      _firstInningsRuns = _runs;
      _firstInningsWickets = _wickets;
      _firstInningsTeam = _battingTeam;
      _firstInningsOvers = '${_ballsBowled ~/ 6}.${_ballsBowled % 6}';
      _firstInningsBalls = _ballsBowled;
      _firstInningsBallsList = List.from(_localBalls);
      _localBalls.clear();

      // Swap teams
      final tempTeam = _battingTeam;
      _battingTeam = _fieldingTeam;
      _fieldingTeam = tempTeam;

      final tempPlayers = _battingPlayers;
      _battingPlayers = _fieldingPlayers;
      _fieldingPlayers = tempPlayers;

      // Reset match stats
      _runs = 0;
      _wickets = 0;
      _ballsBowled = 0;
      _extraRuns = 0;
      _thisOver.clear();
      _history.clear();
      _historyIndex = -1;
      _batterStats.clear();
      _bowlerStats.clear();
      _wicketsHistory.clear();
      _batterOrder.clear();
      _nextBatterIndex = 2;
      _previousOverBowler = null;

      // Clear active players — will be chosen via opener selection prompt
      _striker = null;
      _nonStriker = null;
      _currentBowler = null;

      _commitState();
    });

    // Prompt for 2nd innings openers after state is settled
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _promptSecondInningsLineup();
    });
  }

  void _promptSecondInningsLineup() {
    final battingTeamName = _battingTeam;
    final fieldingTeamName = _fieldingTeam;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        String? opener1;
        String? opener2;
        String? openBowler;
        return StatefulBuilder(
          builder: (ctx, setDlg) {
            return AlertDialog(
              backgroundColor: AppColors.darkCard,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text('2nd INNINGS LINEUP', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$battingTeamName — Opening Batters', style: GoogleFonts.inter(color: Colors.grey, fontSize: 13)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      dropdownColor: const Color(0xFF0F172A),
                      decoration: InputDecoration(
                        labelText: 'Striker',
                        labelStyle: GoogleFonts.inter(color: Colors.grey),
                        filled: true,
                        fillColor: const Color(0xFF0F172A),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                      ),
                      items: _battingPlayers.map((p) => DropdownMenuItem(value: p.name, child: Text(p.name, style: GoogleFonts.inter(color: Colors.white)))).toList(),
                      onChanged: (v) => setDlg(() => opener1 = v),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      dropdownColor: const Color(0xFF0F172A),
                      decoration: InputDecoration(
                        labelText: 'Non-Striker',
                        labelStyle: GoogleFonts.inter(color: Colors.grey),
                        filled: true,
                        fillColor: const Color(0xFF0F172A),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                      ),
                      items: _battingPlayers.map((p) => DropdownMenuItem(value: p.name, child: Text(p.name, style: GoogleFonts.inter(color: Colors.white)))).toList(),
                      onChanged: (v) => setDlg(() => opener2 = v),
                    ),
                    const SizedBox(height: 16),
                    Text('$fieldingTeamName — Opening Bowler', style: GoogleFonts.inter(color: Colors.grey, fontSize: 13)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      dropdownColor: const Color(0xFF0F172A),
                      decoration: InputDecoration(
                        labelText: 'Bowler',
                        labelStyle: GoogleFonts.inter(color: Colors.grey),
                        filled: true,
                        fillColor: const Color(0xFF0F172A),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                      ),
                      items: _fieldingPlayers.map((p) => DropdownMenuItem(value: p.name, child: Text(p.name, style: GoogleFonts.inter(color: Colors.white)))).toList(),
                      onChanged: (v) => setDlg(() => openBowler = v),
                    ),
                  ],
                ),
              ),
              actions: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: (opener1 == null || opener2 == null || openBowler == null || opener1 == opener2)
                      ? null
                      : () {
                          setState(() {
                            _striker = opener1;
                            _nonStriker = opener2;
                            _currentBowler = openBowler;
                            _batterOrder.addAll([_striker!, _nonStriker!]);
                            _batterStats[_striker!] = BatterStats(name: _striker!);
                            _batterStats[_nonStriker!] = BatterStats(name: _nonStriker!);
                            _bowlerStats[_currentBowler!] = BowlerStats(name: _currentBowler!);
                          });
                          Navigator.pop(ctx);
                          _commitState();
                        },
                  child: Text(
                    opener1 == opener2 && opener1 != null
                        ? 'Striker ≠ Non-Striker'
                        : 'Start Innings',
                    style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _endMatch({String? winner, required bool tie}) async {
    String message = '';

    if (tie) {
      message = 'Match Tied! 🎉';
    } else {
      final runsDiff = (_target! - 1) - _runs;
      if (winner == _battingTeam) {
        final totalAllowedWickets = _battingPlayers.isNotEmpty
            ? (_battingPlayers.length - 1)
            : 10;
        final wktsDiff = (totalAllowedWickets - _wickets).clamp(0, 10);
        message = 'Won the Match! 🎉\nBy\n$wktsDiff Wickets';
      } else {
        message = 'Won the Match! 🎉\nBy\n$runsDiff Runs';
      }
    }

    SoundService.instance.playMatchEnd();
    final cleanResult = tie
        ? 'Match Tied!'
        : '${winner ?? "Team"} ${message.replaceAll("\n", " ")}';
    NotificationService.instance.showMatchCompleteNotification(
      matchTitle: '${_setup.teamAName} vs ${_setup.teamBName}',
      resultSummary: cleanResult,
    );

    String format;
    if (_setup.overs <= 5) {
      format = 'Tape Ball';
    } else if (_setup.overs <= 10) {
      format = 'T10';
    } else if (_setup.overs <= 20) {
      format = 'T20';
    } else if (_setup.overs <= 40) {
      format = 'One Day';
    } else {
      format = 'Test';
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    int? matchId;
    try {
      final db = ref.read(databaseServiceProvider);

      await db.transaction(() async {
        // 1. Find or Insert Teams (deduplicate)
        int tAId;
        final existingTeamA = await (db.select(db.teams)
              ..where((t) => t.name.equals(_setup.teamAName)))
            .getSingleOrNull();
        if (existingTeamA != null) {
          tAId = existingTeamA.id;
        } else {
          tAId = await db
              .into(db.teams)
              .insert(TeamsCompanion.insert(name: _setup.teamAName));
        }

        int tBId;
        final existingTeamB = await (db.select(db.teams)
              ..where((t) => t.name.equals(_setup.teamBName)))
            .getSingleOrNull();
        if (existingTeamB != null) {
          tBId = existingTeamB.id;
        } else {
          tBId = await db
              .into(db.teams)
              .insert(TeamsCompanion.insert(name: _setup.teamBName));
        }

        // 2. Find or Insert Players (deduplicate)
        Map<String, int> playerMap = {};
        for (var p in _setup.teamAPlayers) {
          final existingPlayer = await (db.select(db.players)
                ..where((pl) => pl.name.equals(p.name) & pl.teamId.equals(tAId)))
              .getSingleOrNull();
          if (existingPlayer != null) {
            playerMap[p.name] = existingPlayer.id;
          } else {
            final pId = await db.into(db.players).insert(PlayersCompanion.insert(
              name: p.name,
              teamId: drift.Value(tAId),
            ));
            playerMap[p.name] = pId;
          }
        }
        for (var p in _setup.teamBPlayers) {
          final existingPlayer = await (db.select(db.players)
                ..where((pl) => pl.name.equals(p.name) & pl.teamId.equals(tBId)))
              .getSingleOrNull();
          if (existingPlayer != null) {
            playerMap[p.name] = existingPlayer.id;
          } else {
            final pId = await db.into(db.players).insert(PlayersCompanion.insert(
              name: p.name,
              teamId: drift.Value(tBId),
            ));
            playerMap[p.name] = pId;
          }
        }

        // 3. Insert Match
        matchId = await db.into(db.matches).insert(MatchesCompanion.insert(
          matchTitle: '${_setup.teamAName} vs ${_setup.teamBName}',
          totalOvers: _setup.overs,
          matchType: drift.Value(_setup.matchType),
          ballType: drift.Value(_setup.ballType),
          venue: drift.Value(_setup.venue),
          isQuickMatch: drift.Value(_setup.isQuickMatch),
          isCompleted: const drift.Value(true),
          winnerTeamName: drift.Value(winner),
          teamAId: drift.Value(tAId),
          teamBId: drift.Value(tBId),
          teamARuns: drift.Value(_firstInningsTeam == _setup.teamAName ? _firstInningsRuns : _runs),
          teamAWickets: drift.Value(_firstInningsTeam == _setup.teamAName ? _firstInningsWickets : _wickets),
          teamAOvers: drift.Value(_firstInningsTeam == _setup.teamAName ? _firstInningsBalls ~/ 6 : _ballsBowled ~/ 6),
          teamABalls: drift.Value(_firstInningsTeam == _setup.teamAName ? _firstInningsBalls % 6 : _ballsBowled % 6),
          teamBRuns: drift.Value(_firstInningsTeam == _setup.teamBName ? _firstInningsRuns : _runs),
          teamBWickets: drift.Value(_firstInningsTeam == _setup.teamBName ? _firstInningsWickets : _wickets),
          teamBOvers: drift.Value(_firstInningsTeam == _setup.teamBName ? _firstInningsBalls ~/ 6 : _ballsBowled ~/ 6),
          teamBBalls: drift.Value(_firstInningsTeam == _setup.teamBName ? _firstInningsBalls % 6 : _ballsBowled % 6),
        ));

        // 4. Insert Balls
        int legalBalls1 = 0;
        for (var lb in _firstInningsBallsList) {
          final overNum = legalBalls1 ~/ 6;
          final ballNum = (legalBalls1 % 6) + 1;
          await db.into(db.ballEvents).insert(BallEventsCompanion.insert(
            matchId: matchId!,
            inningsNumber: const drift.Value(1),
            overNumber: drift.Value(overNum),
            ballNumber: drift.Value(ballNum),
            runs: drift.Value(lb.runs),
            isWicket: drift.Value(lb.isWicket),
            wicketType: drift.Value(lb.wicketType),
            isExtra: drift.Value(lb.isExtra),
            extraType: drift.Value(lb.extraType),
            batterId: playerMap[lb.batterName] ?? 0,
            bowlerId: playerMap[lb.bowlerName] ?? 0,
            batterName: drift.Value(lb.batterName),
            bowlerName: drift.Value(lb.bowlerName),
          ));
          if (!lb.isExtra || lb.extraType == 'Bye' || lb.extraType == 'LegBye') {
            legalBalls1++;
          }
        }

        int legalBalls2 = 0;
        for (var lb in _localBalls) {
          final overNum = legalBalls2 ~/ 6;
          final ballNum = (legalBalls2 % 6) + 1;
          await db.into(db.ballEvents).insert(BallEventsCompanion.insert(
            matchId: matchId!,
            inningsNumber: const drift.Value(2),
            overNumber: drift.Value(overNum),
            ballNumber: drift.Value(ballNum),
            runs: drift.Value(lb.runs),
            isWicket: drift.Value(lb.isWicket),
            wicketType: drift.Value(lb.wicketType),
            isExtra: drift.Value(lb.isExtra),
            extraType: drift.Value(lb.extraType),
            batterId: playerMap[lb.batterName] ?? 0,
            bowlerId: playerMap[lb.bowlerName] ?? 0,
            batterName: drift.Value(lb.batterName),
            bowlerName: drift.Value(lb.bowlerName),
          ));
          if (!lb.isExtra || lb.extraType == 'Bye' || lb.extraType == 'LegBye') {
            legalBalls2++;
          }
        }
      });

      await ref.read(matchHistoryProvider.notifier).loadMatches();
      ref.invalidate(recentMatchesProvider);
      ref.invalidate(liveMatchProvider);
      // Trigger an immediate sync attempt — SyncManager will retry later on reconnect if this fails.
      if (matchId != null) {
        ref.read(syncManagerProvider).onMatchCompleted(matchId!);
      }

      // Clear ongoing match snapshot since match is fully saved
      final ongoingId = _setup.id.isNotEmpty
          ? _setup.id
          : 'quick_${_setup.teamAName}_vs_${_setup.teamBName}';
      await OngoingMatchService.instance.clearSnapshot(ongoingId);

      // Mark scheduled match as completed in InsForge
      if (!_setup.isQuickMatch && _setup.id.isNotEmpty) {
        _liveService.markMatchCompleted(winner);
      }
    } catch (e) {
      debugPrint('Error saving match: $e');
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Save Error'),
            content: Text(e.toString()),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))
            ],
          )
        );
      }
    }

    if (mounted) {
      Navigator.pop(context); // close loading
      final data = MatchResultData(
        matchId: matchId,
        winningTeam: winner,
        matchStatusText: message,
        team1Name: _firstInningsTeam,
        team1Score: '$_firstInningsRuns/$_firstInningsWickets',
        team1Overs: '$_firstInningsOvers ov',
        team2Name: _battingTeam,
        team2Score: '$_runs/$_wickets',
        team2Overs: '${_ballsBowled ~/ 6}.${_ballsBowled % 6} ov',
        format: format,
        venue: 'Local Ground',
        totalOvers: _setup.overs,
        innings1Team: _firstInningsTeam,
        innings1Score: '$_firstInningsRuns/$_firstInningsWickets',
        innings1Overs: '$_firstInningsOvers overs',
        innings2Team: _battingTeam,
        innings2Score: '$_runs/$_wickets',
        innings2Overs: '${_ballsBowled ~/ 6}.${_ballsBowled % 6} overs',
        ballType: _setup.ballType,
        setupData: _setup,
      );
      context.go('/match-result', extra: data);
    }
  }

  // --- Sub-panel Builders ---

  void _showExtrasPopup(String action) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: AppColors.darkCard,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ADDITIONAL RUNS ON $action',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[400],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [0, 1, 2, 3, 4, 6].map((runs) {
                        final isSel = _selectedExtraRuns == runs;
                        return ChoiceChip(
                          label: Text(
                            '+$runs',
                            style: GoogleFonts.plusJakartaSans(
                              color: isSel ? Colors.black : Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          selected: isSel,
                          selectedColor: AppColors.primary,
                          backgroundColor: const Color(0xFF0F172A),
                          onSelected: (val) {
                            setDialogState(() {
                              _selectedExtraRuns = runs;
                            });
                            setState(() {
                              _selectedExtraRuns = runs;
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _selectedAction = null;
                              _selectedExtraRuns = 0;
                            });
                            Navigator.pop(context);
                          },
                          child: Text('Cancel', style: GoogleFonts.inter(color: Colors.white)),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.darkCard2,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                            _confirmBallOutcome();
                            setState(() {
                              _selectedAction = null;
                            });
                          },
                          child: Text('Add Extra',
                              style: GoogleFonts.inter(
                                  color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final showWicketPanel = _selectedAction == 'W';

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        backgroundColor: AppColors.darkNavBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'LIVE MATCH SCORER',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1.0,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  LiveScoreCard(
                    teamAName: _setup.teamAName,
                    teamBName: _setup.teamBName,
                    battingTeam: _battingTeam,
                    runs: _runs,
                    wickets: _wickets,
                    ballsBowled: _ballsBowled,
                    totalOvers: _setup.overs,
                    isSecondInnings: _isSecondInnings,
                    firstInningsRuns: _firstInningsRuns,
                    firstInningsWickets: _firstInningsWickets,
                    target: _target,
                  ),
                  const SizedBox(height: 16),
                  ActivePlayersCard(
                    strikerName: _striker,
                    strikerStats: _batterStats[_striker] ??
                        BatterStats(name: _striker ?? 'Striker'),
                    nonStrikerName: _nonStriker,
                    nonStrikerStats: _batterStats[_nonStriker] ??
                        BatterStats(name: _nonStriker ?? 'Non-Striker'),
                    currentBowler: _currentBowler,
                    bowlerStats: _bowlerStats[_currentBowler] ??
                        BowlerStats(name: _currentBowler ?? 'Bowler'),
                    onSwapStrike: _swapStrike,
                    onRetireBatter: _promptRetireBatter,
                    onChangeBatter: _promptChangeBatter,
                    onChangeBowler: _promptChangeBowler,
                  ),
                  const SizedBox(height: 8),
                  OverSummaryTimeline(
                    thisOver: _thisOver,
                    ballsBowled: _ballsBowled,
                    historyIndex: _historyIndex,
                    historyLength: _history.length,
                    onUndo: _undo,
                    onRedo: _redo,
                  ),
                  const SizedBox(height: 12),
                  QuickTapActionBoard(
                    selectedAction: _selectedAction,
                    onActionTap: (action) {
                      setState(() {
                        _selectedAction = action;
                        _selectedExtraRuns = 0;
                        _selectedWicketType = 'Bowled';
                        _selectedWicketBatter = 'Striker';
                        _selectedWicketFielder = null;
                      });

                      if (action == 'WD' ||
                          action == 'NB' ||
                          action == 'B' ||
                          action == 'LB') {
                        _showExtrasPopup(action);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  if (showWicketPanel)
                    WicketSubPanel(
                      selectedWicketType: _selectedWicketType,
                      onWicketTypeChanged: (val) =>
                          setState(() => _selectedWicketType = val),
                      selectedWicketBatter: _selectedWicketBatter,
                      onWicketBatterChanged: (val) =>
                          setState(() => _selectedWicketBatter = val),
                      selectedWicketFielder: _selectedWicketFielder,
                      onWicketFielderChanged: (val) =>
                          setState(() => _selectedWicketFielder = val),
                      striker: _striker,
                      nonStriker: _nonStriker,
                      fieldingPlayers: _fieldingPlayers,
                      onConfirmWicket: () async {
                        setState(() {
                          _selectedAction = null;
                          _selectedExtraRuns = 0;
                        });
                        await _processWicketConfirm();
                        _checkInningsStatus();
                        if (mounted) {
                          setState(() {
                            _selectedWicketType = null;
                            _selectedWicketBatter = null;
                            _selectedWicketFielder = null;
                          });
                        }
                      },
                    ),
                ],
              ),
            ),
          ),

          // Confirm button — SafeArea ensures it clears the system nav bar
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _confirmBallOutcome,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 4,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.play_arrow, color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Next Ball',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
