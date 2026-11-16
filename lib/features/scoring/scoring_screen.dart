import 'package:flutter/material.dart';
import 'package:scorely/core/theme/colors.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../models/user_profile.dart';
import '../match/match_setup_screen.dart';
import '../match/opening_lineup_screen.dart';
import '../match/providers/pending_matches_provider.dart';
import 'innings_break_screen.dart';
import '../../models/player_setup.dart';
import '../../models/match_result_data.dart';
import '../../services/database.dart';
import '../../services/sync_manager.dart';
import '../../services/live_scoring_service.dart';
import '../../services/match_lifecycle_service.dart';
import '../../models/match_status.dart';
import 'package:drift/drift.dart' as drift;
import '../../providers/history_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/career_stats_provider.dart';
import '../../providers/match_result_popup_provider.dart';
import '../../services/sound_service.dart';
import '../../services/wakelock_service.dart';
import '../../services/notification_service.dart';
import '../../services/ongoing_match_service.dart';
import '../../services/ads/interstitial_ad_service.dart';
import 'models/scoring_models.dart';
import 'widgets/live_score_card.dart';
import 'widgets/active_players_card.dart';
import 'widgets/over_summary_timeline.dart';
import 'widgets/quick_tap_action_board.dart';
import 'widgets/wicket_sub_panel.dart';
import 'widgets/scorer_selection_sheet.dart';
import 'widgets/scorer_request_waiting_sheet.dart';
import '../../services/scorer_handover_service.dart';

export 'models/scoring_models.dart';

// --- Main Widget Screen ---

class ScoringScreen extends ConsumerStatefulWidget {
  final MatchSetupData? setupData;
  final OpeningLineupResult? lineup;
  /// Set to true when entering this screen directly for the 2nd innings
  /// (e.g. handover recipient who was not the 1st innings scorer).
  final bool isSecondInnings;
  /// 1st innings total — used to set the chase target when isSecondInnings is true.
  final int? firstInningsRuns;
  final int? firstInningsWickets;
  final String? firstInningsBattingTeam;
  final String? firstInningsOvers;
  final int? firstInningsBalls;
  final int? target;

  const ScoringScreen({
    super.key,
    this.setupData,
    this.lineup,
    this.isSecondInnings = false,
    this.firstInningsRuns,
    this.firstInningsWickets,
    this.firstInningsBattingTeam,
    this.firstInningsOvers,
    this.firstInningsBalls,
    this.target,
  });

  @override
  ConsumerState<ScoringScreen> createState() => _ScoringScreenState();
}

class _ScoringScreenState extends ConsumerState<ScoringScreen> {
  late MatchSetupData _setup;

  // ── IST timestamp helper ──────────────────────────────────────────────────
  /// Returns the current time (or [dt]) as an ISO-8601 string with the Indian
  /// Standard Time offset (+05:30).
  static String _istNow([DateTime? dt]) {
    final utc = (dt ?? DateTime.now()).toUtc();
    final ist = utc.add(const Duration(hours: 5, minutes: 30));
    final base = ist.toIso8601String();
    final withoutZ =
        base.endsWith('Z') ? base.substring(0, base.length - 1) : base;
    return '$withoutZ+05:30';
  }
  // ─────────────────────────────────────────────────────────────────────────

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

  // Completed overs list
  List<CompletedOverSummary> _completedOvers = [];

  // Scroll controller for auto-scrolling to wicket details or other sections
  final ScrollController _scrollController = ScrollController();

  // Action board state
  String? _selectedAction; // "0", "1", "2", "3", "4", "5", "6", "WD", "NB", "B", "LB", "W"
  int _selectedExtraRuns = 0; // Wid/NB/B/LB runs
  String? _selectedWicketType; // Bowled, Caught, LBW, Stumped, Run Out
  String? _selectedWicketBatter; // Striker, Non-Striker
  String? _selectedWicketFielder; // Catcher or assister

  // Live scoring service — only active for scheduled (non-quick) matches
  final LiveScoringService _liveService = LiveScoringService();

  // Active scorer & view-only state for scorer handover
  String? _activeScorerId;
  String? _activeScorerName;
  bool _isViewOnly = false;

  // Live pushes stay blocked until the server-authoritative active scorer is
  // known, so a non-scorer device can never publish score updates.
  bool _authorityVerified = false;

  @override
  void initState() {
    super.initState();

    // Preload interstitial ad so it is ready for 1st innings break
    InterstitialAdService.instance.loadAd();

    final currentProfile = ref.read(profileProvider);
    final initialScorerId = widget.lineup?.officialScorer?.id ??
        widget.setupData?.teamAScorerId ??
        (currentProfile.id.isNotEmpty ? currentProfile.id : null);
    final initialScorerName = widget.lineup?.officialScorer?.name ??
        widget.setupData?.teamAScorerName ??
        (currentProfile.name.isNotEmpty ? currentProfile.name : null);

    _activeScorerId = initialScorerId;
    _activeScorerName = initialScorerName;

    final baseSetup = widget.setupData ??
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

    _setup = baseSetup.copyWith(
      teamAScorerId: baseSetup.teamAScorerId ?? initialScorerId,
      teamAScorerName: baseSetup.teamAScorerName ?? initialScorerName,
    );

    _battingTeam = _setup.battingFirstTeam;
    _firstInningsTeam = _setup.battingFirstTeam;
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

    // If this screen is being entered directly for the 2nd innings
    // (handover recipient device), skip the 1st innings flow entirely
    // and start in 2nd innings mode right away.
    if (widget.isSecondInnings) {
      // We call _startSecondInnings inline (can't do it in initState async),
      // so we set all the 2nd innings fields directly:
      _isSecondInnings = true;
      _activeScorerId = widget.setupData?.teamBScorerId ??
          widget.lineup?.officialScorer?.id ??
          (ref.read(profileProvider).id.isNotEmpty ? ref.read(profileProvider).id : _activeScorerId);
      _activeScorerName = widget.setupData?.teamBScorerName ??
          widget.lineup?.officialScorer?.name ??
          (ref.read(profileProvider).name.isNotEmpty ? ref.read(profileProvider).name : _activeScorerName);
      _isViewOnly = false;
      // Set 1st innings summary from widget params (provided via payload)
      _firstInningsRuns = widget.firstInningsRuns ?? _runs;
      _firstInningsWickets = widget.firstInningsWickets ?? _wickets;
      _firstInningsTeam = widget.firstInningsBattingTeam ?? _battingTeam;
      _firstInningsOvers = widget.firstInningsOvers ?? '0.0';
      _firstInningsBalls = widget.firstInningsBalls ?? 0;
      _target = widget.target ?? (_firstInningsRuns + 1);
      // Swap teams so the team that was fielding now bats
      final tempTeam = _battingTeam;
      _battingTeam = _fieldingTeam;
      _fieldingTeam = tempTeam;
      final tempPlayers = _battingPlayers;
      _battingPlayers = _fieldingPlayers;
      _fieldingPlayers = tempPlayers;
      _runs = 0;
      _wickets = 0;
      _ballsBowled = 0;
      _extraRuns = 0;
      // Apply lineup for opening batters/bowler
      if (widget.lineup != null) {
        _striker = widget.lineup!.openingBat1.name;
        _nonStriker = widget.lineup!.openingBat2.name;
        _currentBowler = widget.lineup!.openingBowler.name;
        _batterOrder
          ..clear()
          ..addAll([_striker!, _nonStriker!]);
        _batterStats
          ..[_striker!] = BatterStats(name: _striker!)
          ..[_nonStriker!] = BatterStats(name: _nonStriker!);
        _bowlerStats[_currentBowler!] = BowlerStats(name: _currentBowler!);
      }
      _commitState();
    }

    // Check if an ongoing match session exists to restore
    final ongoingId = _setup.id.isNotEmpty
        ? _setup.id
        : 'quick_${_setup.teamAName}_vs_${_setup.teamBName}';
    _restoreOngoingMatchIfAny(ongoingId);

    // Init live scoring push for active match
    final profile = ref.read(profileProvider);
    final insForgeId = _setup.id.isNotEmpty
        ? _setup.id
        : (_setup.isQuickMatch ? const Uuid().v4() : '');
    if (_setup.id.isEmpty && insForgeId.isNotEmpty) {
      _setup = _setup.copyWith(id: insForgeId);
    }
    if (profile.isLoggedIn && insForgeId.isNotEmpty) {
      _liveService.init(
        insForgeId,
        matchData: _setup.toJson(),
        // Never overwrite the creator when a handover recipient scores.
        createdByProfileId: (_setup.creatorProfileId != null &&
                _setup.creatorProfileId!.isNotEmpty)
            ? _setup.creatorProfileId
            : profile.id,
        activeScorerId: _activeScorerId,
      );
      // Re-check the authoritative active scorer after local restore. The
      // first live push happens only once authority has been verified.
      Future.microtask(_verifyActiveScorerAuthority);
    } else {
      _authorityVerified = true;
    }

    // Keep screen awake during match scoring if enabled
    WakelockService.instance.enableIfAllowed();
  }

  @override
  void dispose() {
    _scrollController.dispose();
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
      completedOvers: _completedOvers.map((o) => o.clone()).toList(),
    ));
    _historyIndex = _history.length - 1;

    // Push live update to InsForge for all online matches (quick or scheduled)
    if (_setup.id.isNotEmpty) {
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
      'completedOvers': _completedOvers.map((o) => o.toJson()).toList(),
      'activeScorerId': _activeScorerId,
      'activeScorerName': _activeScorerName,
      'last_updated': _istNow(),
    };
    OngoingMatchService.instance.saveSnapshot(ongoingId, snapshot);
  }

  Future<void> _restoreOngoingMatchIfAny(String ongoingId) async {
    final snapshot = await OngoingMatchService.instance.getSnapshot(ongoingId);
    if (snapshot != null && mounted) {
      // Check if match was inactive without runs/updates for > 4 hours -> auto-abandon
      final lastUpdatedStr = snapshot['last_updated'] as String?;
      if (lastUpdatedStr != null) {
        final lastUpdated = DateTime.tryParse(lastUpdatedStr);
        if (lastUpdated != null && DateTime.now().difference(lastUpdated) > const Duration(hours: 4)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('No scoring updates for over 4 hours. Match has been abandoned.'),
                  backgroundColor: Colors.redAccent,
                  duration: Duration(seconds: 5),
                ),
              );
              _endMatch(winner: 'Match Abandoned', tie: false);
            }
          });
          return;
        }
      }

      // If entered fresh for 2nd innings via handover, do NOT overwrite with 1st innings snapshot!
      if (widget.isSecondInnings && (snapshot['isSecondInnings'] != true || (snapshot['ballsBowled'] as int? ?? 0) == 0)) {
        _saveOngoingSnapshot();
        return;
      }
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
        if (snapshot['completedOvers'] != null) {
          _completedOvers = (snapshot['completedOvers'] as List)
              .map((e) => CompletedOverSummary.fromJson(e as Map<String, dynamic>))
              .toList();
        }
        _activeScorerId = snapshot['activeScorerId'] as String? ?? _activeScorerId;
        _activeScorerName = snapshot['activeScorerName'] as String? ?? _activeScorerName;

        final currentUserId = ref.read(profileProvider).id;
        final currentUserName = ref.read(profileProvider).name;
        if (currentUserId.isNotEmpty &&
            _activeScorerId != null &&
            _activeScorerId!.isNotEmpty &&
            currentUserId != _activeScorerId) {
          // If this user is teamBScorer (2nd innings scorer) and it's 2nd innings, they have scoring rights
          if (_isSecondInnings &&
              (_setup.teamBScorerId == currentUserId ||
               _setup.teamBScorerName == currentUserName ||
               widget.isSecondInnings)) {
            _isViewOnly = false;
          } else {
            _isViewOnly = true;
          }
        }
      });
      _commitState();
    }
  }

  /// Server-authoritative check: only `pending_matches.active_scorer_id` may
  /// modify the match. Hiding buttons is not enough, so the scorer identity is
  /// re-read from InsForge and the screen locks itself into view-only mode for
  /// everybody else (including a previous scorer after handover).
  Future<void> _verifyActiveScorerAuthority() async {
    // Quick matches for guests skip authority check entirely — no server row.
    // Signed-in quick matches still verify against the server row so a
    // second device that somehow opens the same match is locked view-only.
    final matchId = _setup.id;
    final profile = ref.read(profileProvider);
    if (matchId.isEmpty || !profile.isLoggedIn || profile.id.isEmpty) {
      _authorityVerified = true;
      return;
    }

    final row = await MatchLifecycleService.fetchRow(matchId);
    if (!mounted) return;

    if (row == null) {
      // No server row yet: keep the locally known scorer authoritative so
      // offline scoring still works, and allow the initial push.
      _authorityVerified = true;
      _pushLiveUpdate();
      return;
    }

    final status = MatchStatus.normalize(row['status']?.toString());
    if (status == MatchStatus.completed) {
      setState(() {
        _authorityVerified = true;
        _isViewOnly = true;
      });
      return;
    }

    final active = row['active_scorer_id']?.toString();
    if (active == null || active.isEmpty) {
      _authorityVerified = true;
      _pushLiveUpdate();
      return;
    }

    setState(() {
      _authorityVerified = true;
      _activeScorerId = active;
      _isViewOnly = active != profile.id;
    });
    _liveService.setActiveScorer(active);
    if (_isViewOnly) {
      _saveOngoingSnapshot();
    } else {
      _pushLiveUpdate();
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

  void _recordCompletedOver() {
    final overNum = _ballsBowled ~/ 6;
    final balls = List<String>.from(_thisOver);
    int runs = 0;
    int wkts = 0;
    for (final b in balls) {
      if (b.contains('Wd')) {
        runs += 1 + (int.tryParse(b.replaceAll('Wd', '')) ?? 0);
      } else if (b.contains('Nb')) {
        runs += 1 + (int.tryParse(b.replaceAll('Nb', '')) ?? 0);
      } else if (b.contains('LB')) {
        runs += int.tryParse(b.replaceAll('LB', '')) ?? 0;
      } else if (b.contains('B')) {
        runs += int.tryParse(b.replaceAll('B', '')) ?? 0;
      } else if (b == 'W') {
        wkts += 1;
      } else if (b == '.') {
        // Dot ball
      } else {
        runs += int.tryParse(b) ?? 0;
      }
    }

    _completedOvers.add(CompletedOverSummary(
      overNumber: overNum,
      bowlerName: _currentBowler ?? 'Bowler',
      balls: balls,
      runs: runs,
      wickets: wkts,
    ));
  }

  /// Builds the live score blob and pushes it to InsForge.
  void _pushLiveUpdate() {
    if (_isViewOnly || !_authorityVerified) return;
    final profile = ref.read(profileProvider);
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
      'scorer_id': _activeScorerId ?? _setup.teamAScorerId ?? profile.id,
      'scorer_name': _activeScorerName ?? _setup.teamAScorerName ?? profile.name,
      'creator_id': profile.id,
      'team_a_player_ids': _setup.teamAPlayers
          .expand((p) => [
                if (p.profileId != null && p.profileId!.isNotEmpty) ...[
                  p.profileId!,
                  UserProfile.deriveDisplayId(p.profileId!),
                ],
                if (p.name.isNotEmpty) p.name,
              ])
          .toSet()
          .toList(),
      'team_b_player_ids': _setup.teamBPlayers
          .expand((p) => [
                if (p.profileId != null && p.profileId!.isNotEmpty) ...[
                  p.profileId!,
                  UserProfile.deriveDisplayId(p.profileId!),
                ],
                if (p.name.isNotEmpty) p.name,
              ])
          .toSet()
          .toList(),
      'format': _setup.matchType,
      'venue': _setup.venue,
      'toss_completed': true,
      'toss_won_by': _setup.tossWonBy,
      'batting_first_team': _setup.battingFirstTeam,
      'last_updated': _istNow(),
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
    _completedOvers = state.completedOvers.map((o) => o.clone()).toList();
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
    if (_isViewOnly) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('View-only mode: Only the active scorer (${_activeScorerName ?? "Official Scorer"}) can record balls.'),
          backgroundColor: AppColors.primary,
        ),
      );
      return;
    }

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

    final isOverComplete = _ballsBowled % 6 == 0;
    if (isOverComplete) {
      _checkAndRecordMaidenOver();
      _recordCompletedOver();
      if (!_isInningsOver()) {
        final temp = _striker;
        _striker = _nonStriker;
        _nonStriker = temp;
      }
    }

    _commitState();

    if (isOverComplete && !_isInningsOver()) {
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

    final isOverComplete = _ballsBowled % 6 == 0;
    if (isOverComplete) {
      _checkAndRecordMaidenOver();
      _recordCompletedOver();
      if (!_isInningsOver()) {
        final temp = _striker;
        _striker = _nonStriker;
        _nonStriker = temp;
      }
    }

    _commitState();

    if (isOverComplete && !_isInningsOver()) {
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

    final isOverComplete = _ballsBowled % 6 == 0;
    if (isOverComplete) {
      _checkAndRecordMaidenOver();
      _recordCompletedOver();
      if (!_isInningsOver()) {
        final temp = _striker;
        _striker = _nonStriker;
        _nonStriker = temp;
      }
    }

    _commitState();

    if (!_isInningsOver()) {
      // 1. Wait for incoming batter modal to complete first
      await _promptIncomingBatter(outPlayerName, isStrikerOut);

      // 2. If end of over, prompt bowler change
      if (isOverComplete && !_isInningsOver()) {
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

  Future<void> _endFirstInnings() async {
    // Ensure interstitial ad is loaded if not already cached
    InterstitialAdService.instance.loadAd();

    NotificationService.instance.showInningsBreakNotification(
      battingTeam: _battingTeam,
      runs: _runs,
      wickets: _wickets,
      overs: '${_ballsBowled ~/ 6}.${_ballsBowled % 6}',
      chasingTeam: _fieldingTeam,
      target: _runs + 1,
    );

    final totalFours =
        _batterStats.values.fold<int>(0, (sum, b) => sum + b.fours);
    final totalSixes =
        _batterStats.values.fold<int>(0, (sum, b) => sum + b.sixes);

    final summary = InningsSummaryData(
      setupData: _setup,
      battingTeam: _battingTeam,
      fieldingTeam: _fieldingTeam,
      runs: _runs,
      wickets: _wickets,
      ballsBowled: _ballsBowled,
      extraRuns: _extraRuns,
      totalFours: totalFours,
      totalSixes: totalSixes,
      topBatters: _batterStats.values.toList(),
      topBowlers: _bowlerStats.values.toList(),
    );

    final result = await context.push<dynamic>(
      '/innings-break',
      extra: summary,
    );

    if (!mounted) return;

    OpeningLineupResult? lineup;
    if (result is Map) {
      if (result['setupData'] is MatchSetupData) {
        _setup = result['setupData'] as MatchSetupData;
      }
      if (result['lineup'] is OpeningLineupResult) {
        lineup = result['lineup'] as OpeningLineupResult;
      }
    } else if (result is MatchSetupData) {
      _setup = result;
    }

    InterstitialAdService.instance.showInningsBreakAd(
      onDismissed: () {
        if (mounted) {
          _startSecondInnings(lineup);
        }
      },
    );
  }

  void _startSecondInnings([OpeningLineupResult? lineup]) {
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
      _completedOvers.clear();
      _history.clear();
      _historyIndex = -1;
      _batterStats.clear();
      _bowlerStats.clear();
      _wicketsHistory.clear();
      _batterOrder.clear();
      _nextBatterIndex = 2;
      _previousOverBowler = null;

      if (lineup != null) {
        _striker = lineup.openingBat1.name;
        _nonStriker = lineup.openingBat2.name;
        _currentBowler = lineup.openingBowler.name;
        _batterOrder.addAll([_striker!, _nonStriker!]);
        _batterStats[_striker!] = BatterStats(name: _striker!);
        _batterStats[_nonStriker!] = BatterStats(name: _nonStriker!);
        _bowlerStats[_currentBowler!] = BowlerStats(name: _currentBowler!);
      } else {
        // Fallback if lineup wasn't returned
        if (_battingPlayers.isNotEmpty) {
          _striker = _battingPlayers[0].name;
          _batterStats[_striker!] = BatterStats(name: _striker!);
          _batterOrder.add(_striker!);
        }
        if (_battingPlayers.length > 1) {
          _nonStriker = _battingPlayers[1].name;
          _batterStats[_nonStriker!] = BatterStats(name: _nonStriker!);
          _batterOrder.add(_nonStriker!);
        }
        if (_fieldingPlayers.isNotEmpty) {
          _currentBowler = _fieldingPlayers[0].name;
          _bowlerStats[_currentBowler!] = BowlerStats(name: _currentBowler!);
        }
      }

      _commitState();
    });
  }

  void _endMatch({String? winner, required bool tie}) async {
    if (_isViewOnly) return;
    String message = '';
    final isAbandoned = winner != null && winner.toLowerCase().contains('abandon');

    if (isAbandoned) {
      message = 'Match Abandoned';
    } else if (tie) {
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
    final cleanResult = isAbandoned
        ? 'Match Abandoned'
        : (tie
            ? 'Match Tied!'
            : '${winner ?? "Team"} ${message.replaceAll("\n", " ")}');
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

    final effectiveFirstTeam = _firstInningsTeam.trim().isNotEmpty
        ? _firstInningsTeam.trim()
        : _setup.battingFirstTeam.trim();
    final bool isTeamABattedFirst =
        effectiveFirstTeam.toLowerCase() == _setup.teamAName.trim().toLowerCase();
    final effectiveSecondTeam = _isSecondInnings
        ? _battingTeam.trim()
        : (isTeamABattedFirst ? _setup.teamBName.trim() : _setup.teamAName.trim());

    final aRuns = isTeamABattedFirst ? _firstInningsRuns : _runs;
    final aWickets = isTeamABattedFirst ? _firstInningsWickets : _wickets;
    final aBalls = isTeamABattedFirst ? _firstInningsBalls : _ballsBowled;

    final bRuns = isTeamABattedFirst ? _runs : _firstInningsRuns;
    final bWickets = isTeamABattedFirst ? _wickets : _firstInningsWickets;
    final bBalls = isTeamABattedFirst ? _ballsBowled : _firstInningsBalls;

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

        final profile = ref.read(profileProvider);
        final isAuth = profile.isLoggedIn && profile.id.isNotEmpty;

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
          syncPending: drift.Value(isAuth),
          teamAId: drift.Value(tAId),
          teamBId: drift.Value(tBId),
          teamARuns: drift.Value(aRuns),
          teamAWickets: drift.Value(aWickets),
          teamAOvers: drift.Value(aBalls ~/ 6),
          teamABalls: drift.Value(aBalls % 6),
          teamBRuns: drift.Value(bRuns),
          teamBWickets: drift.Value(bWickets),
          teamBOvers: drift.Value(bBalls ~/ 6),
          teamBBalls: drift.Value(bBalls % 6),
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

      // Enforce Storage Optimizer limit by pruning older completed matches
      final storageLimit = ref.read(storageLimitProvider);
      await db.pruneMatchesToLimit(storageLimit);

      await ref.read(matchHistoryProvider.notifier).loadMatches();
      ref.invalidate(recentMatchesProvider);
      ref.invalidate(liveMatchProvider);
      ref.invalidate(homePersonalStatsProvider);
      ref.invalidate(careerStatsForCategoryProvider);
      // Trigger an immediate sync attempt ONLY for signed-in players (skip for abandoned matches per Point 15 Q7)
      final currentProfile = ref.read(profileProvider);
      if (!isAbandoned && matchId != null && currentProfile.isLoggedIn && currentProfile.id.isNotEmpty) {
        // If the current scorer is NOT the original creator (i.e. they are the
        // 2nd innings scorer / handover recipient), pass the 1st innings scorer's
        // profile ID so it is stored on the InsForge record for cross-device stats.
        final teamAScorerProfileId = (_setup.teamAScorerId != null &&
                _setup.teamAScorerId!.isNotEmpty &&
                _setup.teamAScorerId != currentProfile.id)
            ? _setup.teamAScorerId
            : null;

        // Collect all participating signed-in player profile IDs to map with this match
        final participatingIds = <String>{
          ..._setup.teamAPlayers
              .map((p) => p.profileId)
              .where((id) => id != null && id.isNotEmpty)
              .cast<String>(),
          ..._setup.teamBPlayers
              .map((p) => p.profileId)
              .where((id) => id != null && id.isNotEmpty)
              .cast<String>(),
        }.toList();

        ref.read(syncManagerProvider).onMatchCompleted(
          matchId!,
          teamAScorerProfileId: teamAScorerProfileId,
          setupMatchId: _setup.id,
          participatingProfileIds: participatingIds,
        );
      }

      // Clear ongoing match snapshot since match is fully saved
      final ongoingId = _setup.id.isNotEmpty
          ? _setup.id
          : 'quick_${_setup.teamAName}_vs_${_setup.teamBName}';
      await OngoingMatchService.instance.clearSnapshot(ongoingId);

      // Record match completed for ad frequency & natural transition tracking
      InterstitialAdService.instance.recordMatchCompleted();

      // Mark match as completed or abandoned in InsForge live service — only for signed-in
      // users; guests have no server row and calling this would enqueue an
      // unflushable completion request.
      final matchFinalStatus = isAbandoned ? MatchStatus.abandoned : MatchStatus.completed;
      final completionProfile = ref.read(profileProvider);
      if (completionProfile.isLoggedIn && _setup.id.isNotEmpty) {
        _liveService.markMatchCompleted(
          winner,
          resultSummary: cleanResult,
          completedAt: DateTime.now(),
          status: matchFinalStatus,
        );
      }
      // Drop it from the pending/live list and persist the completion so Home
      // stops showing it and Recent Matches picks it up on the next sync.
      if (_setup.id.isNotEmpty) {
        ref.read(pendingMatchesProvider.notifier).markCompleted(
              _setup.id,
              resultSummary: cleanResult,
              winner: winner,
              status: matchFinalStatus,
            );
        // The scorer is already on the full result screen; suppress the popup.
        ref.read(matchResultPopupProvider.notifier).markResultSeen(_setup.id);
      }
    } catch (e) {
      debugPrint('Error saving match to local database: $e');
    } finally {
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context); // close loading indicator
      }
    }

    if (mounted) {
      final data = MatchResultData(
        matchId: matchId,
        matchCode: _setup.displayMatchId,
        winningTeam: winner,
        matchStatusText: message,
        team1Name: effectiveFirstTeam,
        team1Score: '$_firstInningsRuns/$_firstInningsWickets',
        team1Overs: '$_firstInningsOvers ov',
        team2Name: effectiveSecondTeam,
        team2Score: '$_runs/$_wickets',
        team2Overs: '${_ballsBowled ~/ 6}.${_ballsBowled % 6} ov',
        format: format,
        venue: 'Local Ground',
        totalOvers: _setup.overs,
        innings1Team: effectiveFirstTeam,
        innings1Score: '$_firstInningsRuns/$_firstInningsWickets',
        innings1Overs: '$_firstInningsOvers overs',
        innings2Team: effectiveSecondTeam,
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

  void _showLastOverDetails() {
    if (_completedOvers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.darkCard,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          content: Text(
            'No completed overs yet in this innings.',
            style: GoogleFonts.inter(color: Colors.white),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    int selectedIndex = _completedOvers.length - 1;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final over = _completedOvers[selectedIndex];
            final isLastOver = selectedIndex == _completedOvers.length - 1;

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Drag handle
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isLastOver
                                  ? 'LAST OVER DETAILS'
                                  : 'OVER ${over.overNumber} DETAILS',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Bowled by ${over.bowlerName}',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: Colors.grey[400],
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close,
                              color: Colors.grey, size: 20),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Selector if multiple completed overs exist
                    if (_completedOvers.length > 1) ...[
                      SizedBox(
                        height: 34,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _completedOvers.length,
                          itemBuilder: (ctx, idx) {
                            final o = _completedOvers[idx];
                            final isSel = idx == selectedIndex;
                            final isLatest = idx == _completedOvers.length - 1;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(
                                  isLatest
                                      ? 'Over ${o.overNumber} (Last)'
                                      : 'Over ${o.overNumber}',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: isSel
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                    color:
                                        isSel ? Colors.white : Colors.grey[400],
                                  ),
                                ),
                                selected: isSel,
                                selectedColor: AppColors.primary,
                                backgroundColor: const Color(0xFF0F172A),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  side: BorderSide(
                                    color: isSel
                                        ? AppColors.primary
                                        : Colors.white12,
                                  ),
                                ),
                                onSelected: (selected) {
                                  if (selected) {
                                    setSheetState(() => selectedIndex = idx);
                                  }
                                },
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // Stats summary row
                    Row(
                      children: [
                        _buildOverStatCard(
                            'RUNS', '${over.runs}', AppColors.success),
                        const SizedBox(width: 10),
                        _buildOverStatCard(
                            'WICKETS', '${over.wickets}', AppColors.primary),
                        const SizedBox(width: 10),
                        _buildOverStatCard(
                            'MAIDEN',
                            over.isMaiden ? 'YES' : 'NO',
                            over.isMaiden
                                ? AppColors.success
                                : Colors.white70),
                        const SizedBox(width: 10),
                        _buildOverStatCard(
                            'ECON',
                            over.runs.toStringAsFixed(1),
                            Colors.white),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Visual timeline of balls
                    Text(
                      'DELIVERY TIMELINE',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[400],
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: over.balls.map((ball) {
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
                          } else if (ball.contains('Wd') ||
                              ball.contains('Nb')) {
                            bg = AppColors.warning;
                            fg = Colors.white;
                          }

                          return Container(
                            margin: const EdgeInsets.only(right: 8),
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: bg,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white10),
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
                    const SizedBox(height: 16),

                    // Detailed ball breakdown
                    Text(
                      'BALL BREAKDOWN',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[400],
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      constraints: const BoxConstraints(maxHeight: 180),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: over.balls.length,
                        separatorBuilder: (_, index) => Divider(
                          color: Colors.white.withValues(alpha: 0.05),
                          height: 8,
                        ),
                        itemBuilder: (ctx, i) {
                          final ball = over.balls[i];
                          String desc = '';
                          Color badgeColor = Colors.grey;

                          if (ball == 'W') {
                            desc = 'Wicket';
                            badgeColor = AppColors.primary;
                          } else if (ball == '.') {
                            desc = 'Dot ball';
                            badgeColor = Colors.grey;
                          } else if (ball == '4') {
                            desc = '4 runs • Boundary';
                            badgeColor = AppColors.success;
                          } else if (ball == '6') {
                            desc = '6 runs • Maximum Six';
                            badgeColor = AppColors.success;
                          } else if (ball.contains('Wd')) {
                            final extra =
                                int.tryParse(ball.replaceAll('Wd', '')) ?? 0;
                            desc = extra > 0
                                ? 'Wide + $extra run${extra > 1 ? "s" : ""}'
                                : 'Wide ball';
                            badgeColor = AppColors.warning;
                          } else if (ball.contains('Nb')) {
                            final extra =
                                int.tryParse(ball.replaceAll('Nb', '')) ?? 0;
                            desc = extra > 0
                                ? 'No Ball + $extra run${extra > 1 ? "s" : ""}'
                                : 'No Ball';
                            badgeColor = AppColors.warning;
                          } else if (ball.contains('LB')) {
                            final extra =
                                int.tryParse(ball.replaceAll('LB', '')) ?? 0;
                            desc = '$extra Leg Bye${extra > 1 ? "s" : ""}';
                            badgeColor = Colors.white70;
                          } else if (ball.contains('B')) {
                            final extra =
                                int.tryParse(ball.replaceAll('B', '')) ?? 0;
                            desc = '$extra Bye${extra > 1 ? "s" : ""}';
                            badgeColor = Colors.white70;
                          } else {
                            final runs = int.tryParse(ball) ?? 0;
                            desc = '$runs run${runs > 1 ? "s" : ""}';
                            badgeColor = Colors.white70;
                          }

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            child: Row(
                              children: [
                                Text(
                                  'Delivery ${i + 1}',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[400],
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: badgeColor.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    desc,
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: badgeColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
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

  Widget _buildOverStatCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleChangeScorer() {
    final currentProfile = ref.read(profileProvider);
    final currentUserId = currentProfile.id;

    if (!currentProfile.isLoggedIn || currentUserId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Handing over scoring is only available for signed-in players. Please sign in to assign another scorer.'),
          backgroundColor: AppColors.primary,
        ),
      );
      return;
    }

    if (_activeScorerId != null &&
        _activeScorerId!.isNotEmpty &&
        currentUserId.isNotEmpty &&
        currentUserId != _activeScorerId) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Only the active scorer (${_activeScorerName ?? "Official Scorer"}) can transfer scoring.'),
          backgroundColor: AppColors.primary,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ScorerSelectionSheet(
        matchTitle: '${_setup.teamAName} vs ${_setup.teamBName}',
        currentScorerId: currentUserId,
        teamAName: _setup.teamAName,
        teamBName: _setup.teamBName,
        teamAPlayers: _battingPlayers,
        teamBPlayers: _fieldingPlayers,
        onCandidateSelected: (candidate) async {
          final request = await ScorerHandoverService.instance.createRequest(
            matchId: _setup.id.isNotEmpty ? _setup.id : 'match_${DateTime.now().millisecondsSinceEpoch}',
            inningsId: _isSecondInnings ? '2' : '1',
            requestedByUserId: currentUserId,
            requestedByName: currentProfile.name.isNotEmpty ? currentProfile.name : 'Primary Scorer',
            requestedScorerUserId: candidate.profileId,
            requestedScorerName: candidate.name,
            requestedScorerEmail: candidate.email,
            currentScorerUserId: currentUserId,
            matchTitle: '${_setup.teamAName} vs ${_setup.teamBName}',
          );

          if (!mounted) return;

          if (request == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to send scorer request. Please check internet connection.'),
                backgroundColor: AppColors.primary,
              ),
            );
            return;
          }

          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            isDismissible: false,
            backgroundColor: Colors.transparent,
            builder: (_) => ScorerRequestWaitingSheet(
              request: request,
              onAccepted: () {
                setState(() {
                  _activeScorerId = candidate.profileId;
                  _activeScorerName = candidate.name;
                  _isViewOnly = true;
                });
                _liveService.setActiveScorer(candidate.profileId);
                _saveOngoingSnapshot();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Scorer transferred to ${candidate.name}. Switched to View-Only mode.'),
                    backgroundColor: AppColors.successDark,
                  ),
                );
              },
              onChooseAnother: _handleChangeScorer,
            ),
          );
        },
      ),
    );
  }

  void _showMoreMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey[600],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                child: Text(
                  'MATCH MANAGEMENT',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[400],
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              // Handover is available only for signed-in players (guests are offline-only).
              if (ref.read(profileProvider).isLoggedIn)
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.swap_horiz, color: AppColors.primary, size: 20),
                  ),
                  title: Text(
                    'Change Scorer',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  subtitle: Text(
                    'Hand over scoring to another signed player',
                    style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[400]),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                  onTap: () {
                    Navigator.pop(ctx);
                    _handleChangeScorer();
                  },
                ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.info_outline, color: Colors.white70, size: 20),
                ),
                title: Text(
                  'Match Information',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                subtitle: Text(
                  '${_setup.teamAName} vs ${_setup.teamBName} • ${_setup.overs} Overs',
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[400]),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                onTap: () {
                  Navigator.pop(ctx);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
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
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            tooltip: 'More',
            onPressed: _showMoreMenu,
          ),
        ],
      ),
      body: Column(
        children: [
          if (_isViewOnly)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppColors.primary.withValues(alpha: 0.15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.visibility_outlined, size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    'VIEW-ONLY MODE • Active Scorer: ${_activeScorerName ?? "Official Scorer"}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
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
                    onCheckLastOver: _showLastOverDetails,
                    hasLastOver: _completedOvers.isNotEmpty,
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

                      if (action == 'W') {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (_scrollController.hasClients) {
                            _scrollController.animateTo(
                              _scrollController.position.maxScrollExtent,
                              duration: const Duration(milliseconds: 350),
                              curve: Curves.easeOutCubic,
                            );
                          }
                        });
                      } else if (action == 'WD' ||
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
                  const SizedBox(height: 24),
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
                  onPressed: _isViewOnly ? null : _confirmBallOutcome,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isViewOnly ? const Color(0xFF1E293B) : AppColors.primary,
                    disabledBackgroundColor: const Color(0xFF1E293B),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: _isViewOnly ? 0 : 4,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _isViewOnly ? Icons.lock_outline : Icons.play_arrow,
                        color: Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isViewOnly
                            ? 'Scoring Controlled by ${_activeScorerName ?? "Official Scorer"}'
                            : 'Next Ball',
                        style: GoogleFonts.inter(
                          fontSize: 14,
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
