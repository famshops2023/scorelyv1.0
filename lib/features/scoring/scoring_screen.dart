import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../match/match_setup_screen.dart';
import '../../models/player_setup.dart';
import '../../models/match_result_data.dart';
import '../../models/match_stats.dart';
import '../../services/database.dart';
import 'package:drift/drift.dart' as drift;
import '../../providers/history_provider.dart';

class LocalBallEvent {
  final int runs;
  final bool isWicket;
  final String? wicketType;
  final bool isExtra;
  final String? extraType;
  final String batterName;
  final String bowlerName;

  LocalBallEvent({
    required this.runs,
    required this.isWicket,
    this.wicketType,
    required this.isExtra,
    this.extraType,
    required this.batterName,
    required this.bowlerName,
  });
}

// --- Local Data Models for Stats & Undo Stack ---



class MatchState {
  final int runs;
  final int wickets;
  final int ballsBowled;
  final int extraRuns;
  final List<String> thisOver;
  final String striker;
  final String nonStriker;
  final String currentBowler;
  final Map<String, BatterStats> batterStats;
  final Map<String, BowlerStats> bowlerStats;
  final List<String> wicketsHistory;
  final List<String> batterOrder;
  final int nextBatterIndex;
  final List<LocalBallEvent> localBalls;

  MatchState({
    required this.runs,
    required this.wickets,
    required this.ballsBowled,
    required this.extraRuns,
    required this.thisOver,
    required this.striker,
    required this.nonStriker,
    required this.currentBowler,
    required this.batterStats,
    required this.bowlerStats,
    required this.wicketsHistory,
    required this.batterOrder,
    required this.nextBatterIndex,
    required this.localBalls,
  });

  MatchState clone() {
    return MatchState(
      runs: runs,
      wickets: wickets,
      ballsBowled: ballsBowled,
      extraRuns: extraRuns,
      thisOver: List.from(thisOver),
      striker: striker,
      nonStriker: nonStriker,
      currentBowler: currentBowler,
      batterStats: batterStats.map((k, v) => MapEntry(k, v.clone())),
      bowlerStats: bowlerStats.map((k, v) => MapEntry(k, v.clone())),
      wicketsHistory: List.from(wicketsHistory),
      batterOrder: List.from(batterOrder),
      nextBatterIndex: nextBatterIndex,
      localBalls: List.from(localBalls),
    );
  }
}

// --- Main Widget Screen ---

class ScoringScreen extends ConsumerStatefulWidget {
  final MatchSetupData? setupData;
  const ScoringScreen({super.key, this.setupData});

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
        );

    _battingTeam = _setup.battingFirstTeam;
    _fieldingTeam =
        _battingTeam == _setup.teamAName ? _setup.teamBName : _setup.teamAName;

    _battingPlayers =
        _battingTeam == _setup.teamAName ? _setup.teamAPlayers : _setup.teamBPlayers;
    _fieldingPlayers =
        _battingTeam == _setup.teamAName ? _setup.teamBPlayers : _setup.teamAPlayers;

    // Initialize batting crease
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

    // Save initial state in history
    _commitState();
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

  void _confirmBallOutcome() {
    if (_selectedAction == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select a scoring action first.')),
      );
      return;
    }

    setState(() {
      final action = _selectedAction!;

      if (action == 'W') {
        _processWicketConfirm();
      } else if (action == 'WD') {
        _processWideConfirm();
      } else if (action == 'NB') {
        _processNoBallConfirm();
      } else if (action == 'B' || action == 'LB') {
        _processByesConfirm(action);
      } else {
        final r = int.parse(action);
        _processNormalRunsConfirm(r);
      }

      // Check for victory/loss
      _checkInningsStatus();

      // Reset selection state
      _selectedExtraRuns = 0;
      _selectedWicketType = null;
      _selectedWicketBatter = null;
      _selectedWicketFielder = null;
    });
  }

  void _processNormalRunsConfirm(int r) {
    if (_striker != null) {
      _batterStats[_striker!]?.runs += r;
      _batterStats[_striker!]?.balls += 1;
      if (r == 4) _batterStats[_striker!]?.fours += 1;
      if (r == 6) _batterStats[_striker!]?.sixes += 1;
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

    _localBalls.add(LocalBallEvent(runs: r, isWicket: false, isExtra: false, batterName: _striker ?? 'Unknown', bowlerName: _currentBowler ?? 'Unknown'));
    _commitState();

    if (_ballsBowled % 6 == 0 && !_isInningsOver()) {
      // End of over swap strike
      final temp = _striker;
      _striker = _nonStriker;
      _nonStriker = temp;
      _promptOverCompleteBowlerChange();
    }
  }

  void _processWideConfirm() {
    final penalty = 1 + _selectedExtraRuns;
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

    _localBalls.add(LocalBallEvent(runs: penalty, isWicket: false, isExtra: true, extraType: 'Wide', batterName: _striker ?? 'Unknown', bowlerName: _currentBowler ?? 'Unknown'));
    _commitState();
  }

  void _processNoBallConfirm() {
    final penalty = 1;
    final batterRuns = _selectedExtraRuns;
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

    _localBalls.add(LocalBallEvent(runs: penalty + batterRuns, isWicket: false, isExtra: true, extraType: 'NoBall', batterName: _striker ?? 'Unknown', bowlerName: _currentBowler ?? 'Unknown'));
    _commitState();
  }

  void _processByesConfirm(String type) {
    final extra = _selectedExtraRuns;
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
    _thisOver.add(type.isNotEmpty ? '$extra$type' : extra.toString());

    if (extra % 2 != 0) {
      final temp = _striker;
      _striker = _nonStriker;
      _nonStriker = temp;
    }

    _localBalls.add(LocalBallEvent(runs: extra, isWicket: false, isExtra: true, extraType: type == 'B' ? 'Bye' : 'LegBye', batterName: _striker ?? 'Unknown', bowlerName: _currentBowler ?? 'Unknown'));
    _commitState();

    if (_ballsBowled % 6 == 0 && !_isInningsOver()) {
      final temp = _striker;
      _striker = _nonStriker;
      _nonStriker = temp;
      _promptOverCompleteBowlerChange();
    }
  }


  void _processWicketConfirm() {
    final isStrikerOut = _selectedWicketBatter != 'Non-Striker';
    final outPlayerName = isStrikerOut ? _striker! : _nonStriker!;

    _wickets++;
    _batterStats[outPlayerName]?.isOut = true;
    _batterStats[outPlayerName]?.dismissalInfo = _buildDismissalString();

    if (_selectedWicketType != 'Run Out' && _currentBowler != null) {
      _bowlerStats[_currentBowler!]?.wickets += 1;
    }

    _ballsBowled += 1;
    if (_currentBowler != null) {
      _bowlerStats[_currentBowler!]?.ballsBowled += 1;
    }

    _thisOver.add('W');
    _wicketsHistory.add(outPlayerName);

    _localBalls.add(LocalBallEvent(runs: 0, isWicket: true, wicketType: _selectedWicketType, isExtra: false, batterName: outPlayerName, bowlerName: _currentBowler ?? 'Unknown'));
    _commitState();

    _promptIncomingBatter(outPlayerName, isStrikerOut);

    if (_ballsBowled % 6 == 0 && !_isInningsOver()) {
      _promptOverCompleteBowlerChange();
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

  void _promptIncomingBatter(String outPlayerName, bool isStrikerOut) {
    final unbatted = _battingPlayers
        .where((p) => !_batterOrder.contains(p.name))
        .toList();
    if (unbatted.isEmpty) {
      _checkInningsStatus();
      return;
    }

    showModalBottomSheet(
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

  void _promptOverCompleteBowlerChange() {
    final list =
        _fieldingPlayers.where((p) => p.name != _currentBowler).toList();
    showModalBottomSheet(
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
                    return ListTile(
                      title: Text(p.name,
                          style: GoogleFonts.inter(color: Colors.white)),
                      subtitle: Text(p.role.displayName,
                          style: GoogleFonts.inter(color: Colors.grey)),
                      onTap: () {
                        setState(() {
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
    final nextTeam = _fieldingTeam;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
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
                    color: const Color(0xFFCCFF00),
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
                backgroundColor: Colors.red,
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

      // Default striker / non-striker
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

      // Default bowler
      if (_fieldingPlayers.isNotEmpty) {
        _currentBowler = _fieldingPlayers.firstWhere(
            (p) => p.role == PlayerRole.bowler,
            orElse: () => _fieldingPlayers[0]).name;
        _bowlerStats[_currentBowler!] = BowlerStats(name: _currentBowler!);
      }

      _commitState();
    });
  }

  void _endMatch({String? winner, required bool tie}) async {
    String message = '';

    if (tie) {
      message = 'Match Tied! 🎉';
    } else {
      final runsDiff = (_target! - 1) - _runs;
      if (winner == _battingTeam) {
        final wktsDiff = _battingPlayers.length - 1 - _wickets;
        message = 'Won the Match! 🎉\nBy\n$wktsDiff Wickets';
      } else {
        message = 'Won the Match! 🎉\nBy\n$runsDiff Runs';
      }
    }

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
        // 1. Insert Teams
        final tAId = await db.into(db.teams).insert(TeamsCompanion.insert(name: _setup.teamAName));
        final tBId = await db.into(db.teams).insert(TeamsCompanion.insert(name: _setup.teamBName));

        // 2. Insert Players
        Map<String, int> playerMap = {};
        for (var p in _setup.teamAPlayers) {
          final pId = await db.into(db.players).insert(PlayersCompanion.insert(
            name: p.name,
            teamId: drift.Value(tAId),
          ));
          playerMap[p.name] = pId;
        }
        for (var p in _setup.teamBPlayers) {
          final pId = await db.into(db.players).insert(PlayersCompanion.insert(
            name: p.name,
            teamId: drift.Value(tBId),
          ));
          playerMap[p.name] = pId;
        }

        // 3. Insert Match
        matchId = await db.into(db.matches).insert(MatchesCompanion.insert(
          matchTitle: '${_setup.teamAName} vs ${_setup.teamBName}',
          totalOvers: _setup.overs,
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
        List<LocalBallEvent> allBalls = [..._firstInningsBallsList, ..._localBalls];
        for (var lb in allBalls) {
          await db.into(db.ballEvents).insert(BallEventsCompanion.insert(
            matchId: matchId!,
            runs: drift.Value(lb.runs),
            isWicket: drift.Value(lb.isWicket),
            wicketType: drift.Value(lb.wicketType),
            isExtra: drift.Value(lb.isExtra),
            extraType: drift.Value(lb.extraType),
            batterId: playerMap[lb.batterName] ?? 0,
            bowlerId: playerMap[lb.bowlerName] ?? 0,
          ));
        }
      });

      await ref.read(matchHistoryProvider.notifier).loadMatches();
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
      );
      context.go('/match-result', extra: data);
    }
  }

  // --- Sub-panel Builders ---

  Widget _buildExtrasSubPanel() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ADDITIONAL RUNS ON $_selectedAction',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
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
                selectedColor: const Color(0xFFCCFF00),
                backgroundColor: const Color(0xFF0F172A),
                onSelected: (val) {
                  setState(() {
                    _selectedExtraRuns = runs;
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF202A46),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
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
    );
  }

  Widget _buildWicketSubPanel() {
    final wicketTypes = ['Bowled', 'Caught', 'Run Out', 'LBW', 'Stumped', 'Hit Wicket'];
    final batters = [_striker, _nonStriker].whereType<String>().toList();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'WICKET DETAILS',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 12),
          // Wicket Type Dropdown
          Text(
            'Type',
            style: GoogleFonts.inter(fontSize: 11, color: Colors.grey[500]),
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFF0F172A),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
            initialValue: (_selectedWicketType?.isNotEmpty ?? false) ? _selectedWicketType : null,
            items: wicketTypes
                .map((w) => DropdownMenuItem(
                      value: w,
                      child: Text(w, style: GoogleFonts.inter(color: Colors.white)),
                    ))
                .toList(),
            onChanged: (val) {
              setState(() {
                _selectedWicketType = val ?? '';
              });
            },
          ),
          const SizedBox(height: 12),
          // Dismissed Batter Dropdown (only striker/non‑striker)
          Text(
            'Dismissed Batter',
            style: GoogleFonts.inter(fontSize: 11, color: Colors.grey[500]),
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFF0F172A),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
            initialValue: (_selectedWicketBatter?.isNotEmpty ?? false) ? _selectedWicketBatter : null,
            items: batters
                .map((b) => DropdownMenuItem(
                      value: b == _striker ? 'Striker' : 'Non-Striker',
                      child: Text(b == _striker ? 'Striker ($b)' : 'Non-Striker ($b)', style: GoogleFonts.inter(color: Colors.white)),
                    ))
                .toList(),
            onChanged: (val) {
              setState(() {
                _selectedWicketBatter = val ?? '';
              });
            },
          ),
          const SizedBox(height: 12),
          // Conditional fielder selector for Caught / Run Out / Stumped
          if (_selectedWicketType == 'Caught' || _selectedWicketType == 'Run Out' || _selectedWicketType == 'Stumped') ...[
            Text(
              _selectedWicketType == 'Caught' ? 'Catcher' : 'Assisting Fielder',
              style: GoogleFonts.inter(fontSize: 11, color: Colors.grey[500]),
            ),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF0F172A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
              initialValue: _selectedWicketFielder,
              items: _fieldingPlayers
                  .map((f) => DropdownMenuItem(value: f.name, child: Text(f.name, style: GoogleFonts.inter(color: Colors.white))))
                  .toList(),
              onChanged: (val) {
                setState(() {
                  _selectedWicketFielder = val;
                });
              },
            ),
          ],
          const SizedBox(height: 12),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF202A46),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              // Confirm wicket with current selections
              _processWicketConfirm();
              // Reset selections for next wicket
              setState(() {
                _selectedWicketType = null;
                _selectedWicketBatter = null;
                _selectedWicketFielder = null;
              });
            },
            child: Text('Confirm Wicket',
                style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // --- Rendering UI Blocks ---

  Widget _buildScoreCard() {
    double crr = _ballsBowled == 0 ? 0.0 : (_runs / (_ballsBowled / 6));

    String rrrText = '---';
    String targetText = '---';
    if (_isSecondInnings && _target != null) {
      targetText = '$_target';
      int remainingRuns = _target! - _runs;
      int remainingBalls = (_setup.overs * 6) - _ballsBowled;
      if (remainingBalls > 0) {
        double rrr = (remainingRuns / (remainingBalls / 6));
        rrrText = rrr.toStringAsFixed(2);
      } else {
        rrrText = '0.00';
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      decoration: const BoxDecoration(
        color: Color(0xFF131824),
        border: Border(
          bottom: BorderSide(color: Colors.redAccent, width: 2),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_setup.teamAName} vs ${_setup.teamBName}',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[400],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withValues(alpha: 0.5),
                      blurRadius: 8,
                      spreadRadius: 1,
                    )
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.circle, color: Colors.white, size: 8),
                    const SizedBox(width: 4),
                    Text(
                      'LIVE',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _isSecondInnings
                ? '2nd INNINGS (1st Inn: $_firstInningsRuns/$_firstInningsWickets)'
                : '1st INNINGS',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.redAccent,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _battingTeam,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$_runs/$_wickets',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 48,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.0,
            ),
          ),
          Text(
            '(${(_ballsBowled ~/ 6)}.${(_ballsBowled % 6)} / ${_setup.overs} Overs)',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildScoreGridItem('CRR', crr.toStringAsFixed(2)),
              _buildDivider(),
              _buildScoreGridItem('RRR', rrrText),
              _buildDivider(),
              _buildScoreGridItem('TARGET', targetText),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 30,
      color: Colors.white10,
    );
  }

  Widget _buildScoreGridItem(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivePlayersCard() {
    final strikerStats =
        _batterStats[_striker] ?? BatterStats(name: _striker ?? 'Striker');
    final nonStrikerStats = _batterStats[_nonStriker] ??
        BatterStats(name: _nonStriker ?? 'Non-Striker');
    final bowlerStats = _bowlerStats[_currentBowler] ??
        BowlerStats(name: _currentBowler ?? 'Bowler');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF202A46),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 35,
                      decoration: const BoxDecoration(
                        color: Color(0xFFCCFF00),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(3),
                          bottomLeft: Radius.circular(3),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _promptChangeBatter(true),
                        behavior: HitTestBehavior.opaque,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_striker ?? 'Striker'} *',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Colors.white,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${strikerStats.runs} (${strikerStats.balls}) • 4s:${strikerStats.fours} 6s:${strikerStats.sixes}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: Colors.grey[400],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.swap_calls,
                        color: Color(0xFFCCFF00), size: 22),
                    tooltip: 'Swap Strike',
                    onPressed: _swapStrike,
                  ),
                  IconButton(
                    icon: const Icon(Icons.exit_to_app,
                        color: Colors.redAccent, size: 22),
                    tooltip: 'Retire Batter',
                    onPressed: _promptRetireBatter,
                  ),
                ],
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => _promptChangeBatter(false),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _nonStriker ?? 'Non-Striker',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                          color: Colors.grey[300],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${nonStrikerStats.runs} (${nonStrikerStats.balls}) • 4s:${nonStrikerStats.fours} 6s:${nonStrikerStats.sixes}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(color: Colors.white10),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'BOWLER',
                      style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[400]),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _currentBowler ?? 'Bowler',
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.white),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Text(
                '${bowlerStats.oversDisplay} - M:${bowlerStats.maidens} - R:${bowlerStats.runsConceded} - W:${bowlerStats.wickets}',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: _promptChangeBowler,
                style: TextButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.05),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Change',
                  style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFCCFF00)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverSummaryTimeline() {
    int overRuns = 0;
    for (var ball in _thisOver) {
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

    int currentOverIndex = _ballsBowled ~/ 6;
    int ballsInCurrentOver = _ballsBowled % 6;
    String overDisplay = '$currentOverIndex.$ballsInCurrentOver';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
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
                  color: const Color(0xFFCCFF00),
                ),
              ),
            ],
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _thisOver.map((ball) {
                  Color bg = const Color(0xFF0F172A);
                  Color fg = Colors.white;

                  if (ball == 'W') {
                    bg = Colors.red;
                    fg = Colors.white;
                  } else if (ball == '4' || ball == '6') {
                    bg = const Color(0xFFCCFF00);
                    fg = Colors.black;
                  } else if (ball == '.') {
                    bg = const Color(0xFF334155);
                    fg = Colors.grey;
                  } else if (ball.contains('Wd') || ball.contains('Nb')) {
                    bg = const Color(0xFFCA8A04);
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
                color: _historyIndex > 0 ? Colors.white : Colors.grey[700],
                onPressed: _historyIndex > 0 ? _undo : null,
              ),
              IconButton(
                icon: const Icon(Icons.redo, size: 20),
                color: _historyIndex < _history.length - 1
                    ? Colors.white
                    : Colors.grey[700],
                onPressed: _historyIndex < _history.length - 1 ? _redo : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String action) {
    final isSelected = _selectedAction == action;
    Color buttonBg = isSelected ? const Color(0xFFCCFF00) : const Color(0xFF202A46);
    Color textColor = isSelected ? Colors.black : Colors.white;

    if (action == 'W' && !isSelected) {
      buttonBg = Colors.red.withValues(alpha: 0.15);
      textColor = Colors.redAccent;
    } else if ((action == '4' || action == '6') && !isSelected) {
      buttonBg = const Color(0xFFCCFF00).withValues(alpha: 0.15);
      textColor = const Color(0xFFCCFF00);
    }

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedAction = action;
            _selectedExtraRuns = 0;
            _selectedWicketType = 'Bowled';
            _selectedWicketBatter = 'Striker';
            _selectedWicketFielder = null;
          });
        },
        child: Container(
          margin: const EdgeInsets.all(6),
          height: 60,
          decoration: BoxDecoration(
            color: buttonBg,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.05),
              width: 1.5,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFFCCFF00).withValues(alpha: 0.3),
                      blurRadius: 8,
                      spreadRadius: 2,
                    )
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            action,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickTapActionBoard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      child: Column(
        children: [
          Row(
            children: [
              _buildActionButton('W'),
              _buildActionButton('WD'),
              _buildActionButton('NB'),
              _buildActionButton('B'),
              _buildActionButton('LB'),
            ],
          ),
          Row(
            children: [
              _buildActionButton('0'),
              _buildActionButton('1'),
              _buildActionButton('2'),
              _buildActionButton('3'),
            ],
          ),
          Row(
            children: [
              _buildActionButton('4'),
              _buildActionButton('5'),
              _buildActionButton('6'),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final showExtrasPanel = _selectedAction == 'WD' ||
        _selectedAction == 'NB' ||
        _selectedAction == 'B' ||
        _selectedAction == 'LB';
    final showWicketPanel = _selectedAction == 'W';

    return Scaffold(
      backgroundColor: const Color(0xFF0B0F19),
      appBar: AppBar(
        backgroundColor: const Color(0xFF131824),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'LIVE MATCH SCORER',
          style: GoogleFonts.inter(
            fontSize: 16,
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
                  _buildScoreCard(),
                  const SizedBox(height: 16),
                  _buildActivePlayersCard(),
                  const SizedBox(height: 8),
                  _buildOverSummaryTimeline(),
                  const SizedBox(height: 12),
                  _buildQuickTapActionBoard(),
                  const SizedBox(height: 12),
                  if (showExtrasPanel) _buildExtrasSubPanel(),
                  if (showWicketPanel) _buildWicketSubPanel(),
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
                    backgroundColor: Colors.red,
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
