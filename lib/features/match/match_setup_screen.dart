import 'package:flutter/material.dart';
import 'package:scorely/core/theme/colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/player_setup.dart';
import '../../models/match_status.dart';
import '../../providers/history_provider.dart';
import '../../providers/profile_provider.dart';
import 'providers/pending_matches_provider.dart';
import 'providers/quick_match_storage.dart';
import 'helpers/live_match_promo.dart';
import '../../services/duplicate_match_service.dart';
import 'widgets/existing_match_dialog.dart';

class MatchSetupData {
  final String id;
  final String status;
  final String teamAName;
  final String teamBName;
  final List<PlayerSetupData> teamAPlayers;
  final List<PlayerSetupData> teamBPlayers;
  final int overs;
  final String tossWonBy;
  final int maxOversPerBowler;
  final int powerplayOvers;
  final String battingFirstTeam;
  final String matchType;
  final String ballType;
  final String venue;
  final DateTime matchDate;
  final bool isQuickMatch;
  final String? teamAScorerName;
  final String? teamAScorerId;
  final String? teamBScorerName;
  final String? teamBScorerId;
  final String? matchCode;
  final String? matchAppId;

  /// Profile ID of the authenticated creator. Source of truth for "can I
  /// proceed to toss / edit this pending match?".
  final String? creatorProfileId;

  /// Pending-only sub-state (squad selection vs ready for toss).
  final String setupStage;

  /// The single authoritative active scorer profile ID while live.
  final String? activeScorerId;

  /// Signed-in players associated with the match (both squads).
  final List<String> playerProfileIds;

  /// Result summary written when the match is completed.
  final String? resultSummary;

  /// When the match reached the completed state.
  final DateTime? completedAt;

  /// Stable client creation request ID (idempotency key) for duplicate prevention.
  final String? creationRequestId;

  bool get isPending => MatchStatus.isPending(status);
  bool get isLive => MatchStatus.isLive(status);
  bool get isCompleted => MatchStatus.isCompleted(status);
  bool get isAbandoned => MatchStatus.isAbandoned(status);
  bool get isWaitingForSquad =>
      MatchSetupStage.normalize(setupStage) == MatchSetupStage.squadSelection;
  bool get hasTossCompleted =>
      tossWonBy.trim().isNotEmpty && battingFirstTeam.trim().isNotEmpty;

  bool isCreator(String? profileId) =>
      profileId != null &&
      profileId.isNotEmpty &&
      creatorProfileId != null &&
      creatorProfileId == profileId;

  bool isActiveScorer(String? profileId) =>
      profileId != null &&
      profileId.isNotEmpty &&
      activeScorerId != null &&
      activeScorerId == profileId;

  /// Returns a clean match display ID like SM-10001
  String get displayMatchId => (matchCode != null && matchCode!.isNotEmpty)
      ? matchCode!
      : deriveMatchCode(id);

  /// Deterministically derives a match code in the form 'SM-10001' from raw match ID or UUID
  static String deriveMatchCode(String rawId) {
    if (rawId.isEmpty) return 'SM-10001';
    final clean = rawId.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
    if (clean.isEmpty) return 'SM-10001';
    final tail = clean.length >= 4 ? clean.substring(clean.length - 4) : clean.padLeft(4, '0');
    final val = int.tryParse(tail, radix: 16) ?? int.tryParse(tail) ?? 0;
    final num = (val.abs() % 90000) + 10001;
    return 'SM-$num';
  }

  const MatchSetupData({
    this.id = '',
    this.status = MatchStatus.pending,
    required this.teamAName,
    required this.teamBName,
    required this.teamAPlayers,
    required this.teamBPlayers,
    required this.overs,
    required this.tossWonBy,
    required this.maxOversPerBowler,
    required this.powerplayOvers,
    required this.battingFirstTeam,
    required this.matchType,
    required this.ballType,
    required this.venue,
    required this.matchDate,
    this.isQuickMatch = false,
    this.teamAScorerName,
    this.teamAScorerId,
    this.teamBScorerName,
    this.teamBScorerId,
    this.matchCode,
    this.matchAppId,
    this.creatorProfileId,
    this.setupStage = MatchSetupStage.readyForToss,
    this.activeScorerId,
    this.playerProfileIds = const [],
    this.resultSummary,
    this.completedAt,
    this.creationRequestId,
  });

  MatchSetupData copyWith({
    String? id,
    String? status,
    List<PlayerSetupData>? teamAPlayers,
    List<PlayerSetupData>? teamBPlayers,
    String? tossWonBy,
    String? battingFirstTeam,
    bool? isQuickMatch,
    String? teamAScorerName,
    String? teamAScorerId,
    String? teamBScorerName,
    String? teamBScorerId,
    String? matchCode,
    String? matchAppId,
    String? creatorProfileId,
    String? setupStage,
    String? activeScorerId,
    List<String>? playerProfileIds,
    String? resultSummary,
    DateTime? completedAt,
    String? creationRequestId,
  }) {
    return MatchSetupData(
      id: id ?? this.id,
      status: status ?? this.status,
      teamAName: teamAName,
      teamBName: teamBName,
      teamAPlayers: teamAPlayers ?? this.teamAPlayers,
      teamBPlayers: teamBPlayers ?? this.teamBPlayers,
      overs: overs,
      maxOversPerBowler: maxOversPerBowler,
      powerplayOvers: powerplayOvers,
      matchType: matchType,
      ballType: ballType,
      venue: venue,
      matchDate: matchDate,
      tossWonBy: tossWonBy ?? this.tossWonBy,
      battingFirstTeam: battingFirstTeam ?? this.battingFirstTeam,
      isQuickMatch: isQuickMatch ?? this.isQuickMatch,
      teamAScorerName: teamAScorerName ?? this.teamAScorerName,
      teamAScorerId: teamAScorerId ?? this.teamAScorerId,
      teamBScorerName: teamBScorerName ?? this.teamBScorerName,
      teamBScorerId: teamBScorerId ?? this.teamBScorerId,
      matchCode: matchCode ?? this.matchCode,
      matchAppId: matchAppId ?? this.matchAppId,
      creatorProfileId: creatorProfileId ?? this.creatorProfileId,
      setupStage: setupStage ?? this.setupStage,
      activeScorerId: activeScorerId ?? this.activeScorerId,
      playerProfileIds: playerProfileIds ?? this.playerProfileIds,
      resultSummary: resultSummary ?? this.resultSummary,
      completedAt: completedAt ?? this.completedAt,
      creationRequestId: creationRequestId ?? this.creationRequestId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'status': status,
      'teamAName': teamAName,
      'teamBName': teamBName,
      'teamAPlayers': teamAPlayers.map((p) => p.toJson()).toList(),
      'teamBPlayers': teamBPlayers.map((p) => p.toJson()).toList(),
      'overs': overs,
      'tossWonBy': tossWonBy,
      'maxOversPerBowler': maxOversPerBowler,
      'powerplayOvers': powerplayOvers,
      'battingFirstTeam': battingFirstTeam,
      'matchType': matchType,
      'ballType': ballType,
      'venue': venue,
      'matchDate': matchDate.toIso8601String(),
      'isQuickMatch': isQuickMatch,
      'teamAScorerName': teamAScorerName,
      'teamAScorerId': teamAScorerId,
      'teamBScorerName': teamBScorerName,
      'teamBScorerId': teamBScorerId,
      'matchCode': matchCode ?? displayMatchId,
      'matchAppId': matchAppId,
      'creatorProfileId': creatorProfileId,
      'setupStage': setupStage,
      'activeScorerId': activeScorerId,
      'playerProfileIds': playerProfileIds,
      'resultSummary': resultSummary,
      'completedAt': completedAt?.toIso8601String(),
      if (creationRequestId != null && creationRequestId!.isNotEmpty)
        'creationRequestId': creationRequestId,
    };
  }

  factory MatchSetupData.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'] as String? ?? '';
    final rawStatus = json['status'] as String?;
    final normalizedStatus = MatchStatus.normalize(rawStatus);
    final rawStage = json['setupStage'] as String? ??
        (rawStatus == 'waiting_for_team_b' || rawStatus == 'waiting_for_squad'
            ? MatchSetupStage.squadSelection
            : null);
    final rawPlayerIds = json['playerProfileIds'];
    final playerProfileIds = rawPlayerIds is List
        ? rawPlayerIds.map((e) => e.toString()).where((e) => e.isNotEmpty).toList()
        : <String>[];
    return MatchSetupData(
      id: rawId,
      status: normalizedStatus,
      teamAName: json['teamAName'] as String? ?? '',
      teamBName: json['teamBName'] as String? ?? '',
      teamAPlayers: (json['teamAPlayers'] as List?)?.map((p) => PlayerSetupData.fromJson(p)).toList() ?? [],
      teamBPlayers: (json['teamBPlayers'] as List?)?.map((p) => PlayerSetupData.fromJson(p)).toList() ?? [],
      overs: json['overs'] as int? ?? 20,
      tossWonBy: json['tossWonBy'] as String? ?? '',
      maxOversPerBowler: json['maxOversPerBowler'] as int? ?? 4,
      powerplayOvers: json['powerplayOvers'] as int? ?? 6,
      battingFirstTeam: json['battingFirstTeam'] as String? ?? '',
      matchType: json['matchType'] as String? ?? 'T20',
      ballType: json['ballType'] as String? ?? 'Tennis',
      venue: json['venue'] as String? ?? '',
      matchDate: json['matchDate'] != null ? DateTime.parse(json['matchDate']) : DateTime.now(),
      isQuickMatch: json['isQuickMatch'] as bool? ?? false,
      teamAScorerName: json['teamAScorerName'] as String?,
      teamAScorerId: json['teamAScorerId'] as String?,
      teamBScorerName: json['teamBScorerName'] as String?,
      teamBScorerId: json['teamBScorerId'] as String?,
      matchCode: json['matchCode'] as String? ?? deriveMatchCode(rawId),
      matchAppId: json['matchAppId'] as String?,
      creatorProfileId: json['creatorProfileId'] as String?,
      setupStage: MatchSetupStage.normalize(rawStage),
      activeScorerId: json['activeScorerId'] as String?,
      playerProfileIds: playerProfileIds,
      resultSummary: json['resultSummary'] as String?,
      completedAt: json['completedAt'] != null
          ? DateTime.tryParse(json['completedAt'].toString())
          : null,
      creationRequestId: json['creationRequestId'] as String? ??
          json['creation_request_id'] as String?,
    );
  }
}

class MatchSetupScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? initialData;
  const MatchSetupScreen({super.key, this.initialData});

  @override
  ConsumerState<MatchSetupScreen> createState() => _MatchSetupScreenState();
}

class _MatchSetupScreenState extends ConsumerState<MatchSetupScreen> {
  late TextEditingController _teamAController;
  late TextEditingController _teamBController;
  late TextEditingController _venueController;
  List<PlayerSetupData> _teamAPlayers = [];
  List<PlayerSetupData> _teamBPlayers = [];

  int _overs = 20;
  int _maxOversPerBowler = 4;
  int _powerplayOvers = 6;
  String _matchType = 'T20';
  String _ballType = 'Leather';

  bool _isNow = true;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  
  bool _isQuickMatch = false;

  late String _matchId;
  late String _creationRequestId;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _matchId = widget.initialData?['id'] as String? ??
        widget.initialData?['sessionId'] as String? ??
        const Uuid().v4();
    _creationRequestId = widget.initialData?['creationRequestId'] as String? ??
        const Uuid().v4();

    _teamAController = TextEditingController(
      text: widget.initialData?['teamAName'] ?? '',
    );
    _teamBController = TextEditingController(
      text: widget.initialData?['teamBName'] ?? '',
    );
    _venueController = TextEditingController(
      text: widget.initialData?['venue'] ?? 'Coimbatore Stadium',
    );
    _teamAPlayers = widget.initialData?['teamAPlayers'] ?? [];
    _teamBPlayers = widget.initialData?['teamBPlayers'] ?? [];
    
    _isQuickMatch = widget.initialData?['isQuickMatch'] ?? false;
    if (_isQuickMatch) {
      _matchType = widget.initialData?['matchType'] ?? 'Box/Turf'; // Default for quick match
    } else {
      _matchType = widget.initialData?['matchType'] ?? 'T20';
    }
    
    _ballType = widget.initialData?['ballType'] ?? 'Leather';

    _loadDefaultOvers();
  }

  Future<void> _loadDefaultOvers() async {
    final int defaultOvers;
    if (widget.initialData?['overs'] != null) {
      defaultOvers = widget.initialData!['overs'] as int;
    } else {
      final prefs = await SharedPreferences.getInstance();
      defaultOvers = prefs.getInt('settings_default_overs') ?? 20;
    }
    if (mounted) {
      setState(() {
        _overs = defaultOvers;
        _updateDependentOvers();
      });
    }
  }

  void _updateDependentOvers() {
    setState(() {
      int maxOvers = (_overs / 5).ceil();
      if (_overs < 5) maxOvers = 1;
      _maxOversPerBowler = maxOvers;

      int powerplay = (_overs * 0.3).ceil();
      _powerplayOvers = powerplay;
    });
  }

  @override
  void dispose() {
    _teamAController.dispose();
    _teamBController.dispose();
    _venueController.dispose();
    super.dispose();
  }

  Future<void> _startMatch() async {
    if (_isSubmitting) return;

    final String teamAName = _teamAController.text.trim();
    final String teamBName = _teamBController.text.trim();
    
    if (teamAName.isEmpty || teamBName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Both Team A and Team B must be selected'),
          backgroundColor: AppColors.primary,
        ),
      );
      return;
    }

    final String venue = _venueController.text.trim().isNotEmpty
        ? _venueController.text.trim()
        : 'Unknown Venue';

    final DateTime matchDate = _isNow
        ? DateTime.now()
        : DateTime(
            _selectedDate.year,
            _selectedDate.month,
            _selectedDate.day,
            _selectedTime.hour,
            _selectedTime.minute,
          );

    setState(() => _isSubmitting = true);

    try {
      final profile = ref.read(profileProvider);
      final creatorProfileId = profile.id.isNotEmpty ? profile.id : null;

      // Duplicate detection before creating a record
      final dupResult = await DuplicateMatchService.instance.checkForDuplicate(
        creatorProfileId: creatorProfileId,
        teamAName: teamAName,
        teamBName: teamBName,
        isQuickMatch: _isQuickMatch,
        matchDate: matchDate,
        currentSessionMatchId: _matchId,
        currentCreationRequestId: _creationRequestId,
      );

      if (!mounted) return;

      if (dupResult.isDuplicate && dupResult.existingMatch != null) {
        // Show Existing Match confirmation popup
        await ExistingMatchDialog.show(
          context,
          existingMatch: dupResult.existingMatch!,
          onContinue: () {
            DuplicateMatchService.instance.continueExistingMatch(
              context,
              ref,
              dupResult.existingMatch!,
            );
          },
          onCreateNew: () async {
            // Explicit creator decision: create a separate match with new IDs
            _matchId = const Uuid().v4();
            _creationRequestId = const Uuid().v4();
            await _createAndProceed(
              matchId: _matchId,
              creationRequestId: _creationRequestId,
              teamAName: teamAName,
              teamBName: teamBName,
              venue: venue,
              matchDate: matchDate,
            );
          },
          onCancel: () {
            // Dismiss and return to setup with zero changes
          },
        );
        return;
      }

      // No duplicate or same session -> proceed
      await _createAndProceed(
        matchId: _matchId,
        creationRequestId: _creationRequestId,
        teamAName: teamAName,
        teamBName: teamBName,
        venue: venue,
        matchDate: matchDate,
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _createAndProceed({
    required String matchId,
    required String creationRequestId,
    required String teamAName,
    required String teamBName,
    required String venue,
    required DateTime matchDate,
  }) async {
    final profile = ref.read(profileProvider);
    final hasSquads = _teamAPlayers.isNotEmpty && _teamBPlayers.isNotEmpty;
    final data = MatchSetupData(
      id: matchId,
      creationRequestId: creationRequestId,
      status: MatchStatus.pending,
      matchCode: MatchSetupData.deriveMatchCode(matchId),
      teamAName: teamAName,
      teamBName: teamBName,
      teamAPlayers: _teamAPlayers,
      teamBPlayers: _teamBPlayers,
      overs: _overs,
      tossWonBy: '', // Will be set in TossScreen
      maxOversPerBowler: _maxOversPerBowler,
      powerplayOvers: _powerplayOvers,
      battingFirstTeam: '', // Will be set in TossScreen
      matchType: _matchType,
      ballType: _ballType,
      venue: venue,
      matchDate: matchDate,
      isQuickMatch: _isQuickMatch,
      creatorProfileId: profile.id.isNotEmpty ? profile.id : null,
      setupStage: hasSquads
          ? MatchSetupStage.readyForToss
          : MatchSetupStage.squadSelection,
      playerProfileIds: _teamAPlayers
          .followedBy(_teamBPlayers)
          .map((p) => p.profileId)
          .whereType<String>()
          .where((id) => id.isNotEmpty)
          .toSet()
          .toList(),
    );

    if (_isQuickMatch) {
      final storageLimit = ref.read(storageLimitProvider);
      QuickMatchStorage.saveQuickMatch(data, storageLimit: storageLimit);
      proceedToToss(context, ref, data);
    } else {
      await ref.read(pendingMatchesProvider.notifier).addOrUpdateMatch(data);
      if (!mounted) return;
      context.push('/match-details', extra: data);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBg,
      appBar: AppBar(
        backgroundColor: AppColors.lightTextPrimary,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'MATCH SETUP',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: 1.0,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: Colors.white),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Sharing match setup coming soon!',
                    style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                  ),
                  backgroundColor: AppColors.lightTextPrimary,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('TEAM SELECTION'),
            const SizedBox(height: 12),
            _buildTeamInput(
              context,
              'TEAM A',
              'Home Team Name',
              _teamAController,
              true,
            ),
            const SizedBox(height: 12),
            _buildTeamInput(
              context,
              'TEAM B',
              'Away Team Name',
              _teamBController,
              false,
            ),
            const SizedBox(height: 24),

            _buildSectionTitle('OVERS'),
            const SizedBox(height: 12),
            _buildOversCard(),
            const SizedBox(height: 12),
            _buildOversChips(),
            const SizedBox(height: 24),

            _buildSectionTitle('MATCH TYPE'),
            const SizedBox(height: 12),
            _buildMatchTypeSection(),
            const SizedBox(height: 24),
            _buildSectionTitle('BALL TYPE'),
            const SizedBox(height: 12),
            _buildBallTypeSection(),
            const SizedBox(height: 24),

            _buildSectionTitle('VENUE'),
            const SizedBox(height: 12),
            _buildVenueInput(),
            const SizedBox(height: 24),

            if (!_isQuickMatch) ...[
              _buildSectionTitle('DATE & TIME'),
              const SizedBox(height: 12),
              _buildDateTimeNowToggle(),
              const SizedBox(height: 24),
            ],

            Row(
              children: [
                Expanded(
                  child: _buildCounterCard('OVERS/BOWLER', _maxOversPerBowler, (val) {
                    if (val <= _overs) {
                      setState(() => _maxOversPerBowler = val);
                    }
                  }),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildCounterCard('POWERPLAY', _powerplayOvers, (val) {
                    if (val <= _overs) {
                      setState(() => _powerplayOvers = val);
                    }
                  }),
                ),
              ],
            ),
            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _startMatch,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                  shadowColor: AppColors.primary.withValues(alpha: 0.4),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.play_arrow,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _isQuickMatch ? 'START MATCH' : 'SCHEDULE MATCH',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppColors.lightTextSecondary,
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _buildTeamInput(
    BuildContext context,
    String title,
    String hint,
    TextEditingController controller,
    bool isTeamA,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 70,
            decoration: BoxDecoration(
              color: isTeamA
                  ? AppColors.primary
                  : AppColors.lightTextPrimary,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: isTeamA
                          ? AppColors.primary
                          : AppColors.lightTextPrimary,
                    ),
                  ),
                  TextField(
                    controller: controller,
                    readOnly: _isQuickMatch,
                    decoration: InputDecoration(
                      hintText: hint,
                      hintStyle: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFFBFC5E4),
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.only(top: 4),
                    ),
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.lightTextPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!_isQuickMatch) ...[
                  GestureDetector(
                    onTap: () async {
                      final selectedTeam = await context.push<String>(
                        '/teams-select',
                      );
                      if (selectedTeam != null && selectedTeam.isNotEmpty) {
                        controller.text = selectedTeam;
                      }
                    },
                    child: const Icon(
                      Icons.search,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                const Icon(
                  Icons.sports_cricket,
                  color: Color(0xFFBFC5E4),
                  size: 24,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOversCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () {
              if (_overs > 1) {
                setState(() => _overs--);
                _updateDependentOvers();
              }
            },
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFECEEF1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.remove, color: AppColors.lightTextPrimary),
            ),
          ),
          Column(
            children: [
              Text(
                _overs.toString(),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 48,
                  fontWeight: FontWeight.w700,
                  color: AppColors.lightTextPrimary,
                  height: 1.0,
                ),
              ),
              Text(
                'overs',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFFBFC5E4),
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: () {
              setState(() => _overs++);
              _updateDependentOvers();
            },
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.add, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOversChips() {
    return Row(
      children: [5, 10, 20, 50].map((val) {
        bool isSelected = _overs == val;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() => _overs = val);
              _updateDependentOvers();
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : const Color(0xFFECEEF1),
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : [],
              ),
              alignment: Alignment.center,
              child: Text(
                val.toString(),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : AppColors.lightTextPrimary,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMatchTypeSection() {
    if (_isQuickMatch) {
      return Row(
        children: [
          Expanded(child: _buildMatchTypeChip('Box/Turf')),
          const SizedBox(width: 8),
          Expanded(child: _buildMatchTypeChip('Limited Overs')),
        ],
      );
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildMatchTypeChip('Test')),
            const SizedBox(width: 8),
            Expanded(child: _buildMatchTypeChip('Box/Turf')),
            const SizedBox(width: 8),
            Expanded(child: _buildMatchTypeChip('T20')),
            const SizedBox(width: 8),
            Expanded(child: _buildMatchTypeChip('One Day')),
          ],
        ),
        const SizedBox(height: 8),
        Row(children: [Expanded(child: _buildMatchTypeChip('Limited Overs'))]),
      ],
    );
  }

  Widget _buildBallTypeSection() {
    return Row(
      children: [
        Expanded(child: _buildBallChip('Leather', Icons.sports_baseball)),
        const SizedBox(width: 8),
        Expanded(child: _buildBallChip('Tennis', Icons.sports_tennis)),
        const SizedBox(width: 8),
        Expanded(child: _buildBallChip('Other', Icons.sports_cricket)),
      ],
    );
  }

  Widget _buildMatchTypeChip(String type) {
    bool isSelected = _matchType == type;
    return GestureDetector(
      onTap: () => setState(() => _matchType = type),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : const Color(0xFFECEEF1),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        alignment: Alignment.center,
        child: Text(
          type,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : AppColors.lightTextPrimary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildVenueInput() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 56,
            decoration: const BoxDecoration(
              color: AppColors.lightTextPrimary,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                controller: _venueController,
                decoration: InputDecoration(
                  hintText: 'Enter Venue',
                  hintStyle: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFFBFC5E4),
                  ),
                  border: InputBorder.none,
                  isDense: true,
                ),
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.lightTextPrimary,
                ),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(right: 16),
            child: Icon(
              Icons.location_on_outlined,
              color: Color(0xFFBFC5E4),
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateTimeNowToggle() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Play Now',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.lightTextPrimary,
                ),
              ),
              Switch(
                value: _isNow,
                onChanged: (val) {
                  setState(() => _isNow = val);
                },
                activeThumbColor: Colors.white,
                activeTrackColor: AppColors.primary,
              ),
            ],
          ),
          if (!_isNow) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(color: Color(0xFFECEEF1), height: 1),
            ),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2100),
                      );
                      if (date != null) {
                        setState(() => _selectedDate = date);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.lightBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            size: 16,
                            color: AppColors.lightTextSecondary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.lightTextPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: _selectedTime,
                      );
                      if (time != null) {
                        setState(() => _selectedTime = time);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.lightBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            size: 16,
                            color: AppColors.lightTextSecondary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _selectedTime.format(context),
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.lightTextPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCounterCard(String title, int value, Function(int) onChanged) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.lightTextSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () {
                  if (value > 1) onChanged(value - 1);
                },
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: Color(0xFFECEEF1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.remove,
                    size: 16,
                    color: AppColors.lightTextPrimary,
                  ),
                ),
              ),
              Text(
                value.toString(),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.lightTextPrimary,
                ),
              ),
              GestureDetector(
                onTap: () => onChanged(value + 1),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: Color(0xFFECEEF1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.add,
                    size: 16,
                    color: AppColors.lightTextPrimary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBallChip(String type, IconData icon) {
    bool isSelected = _ballType == type;
    return GestureDetector(
      onTap: () => setState(() => _ballType = type),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.lightTextPrimary : const Color(0xFFECEEF1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : AppColors.lightTextSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              type,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : AppColors.lightTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return LayoutBuilder(
      builder: (context, _) {
        final bottomInset = MediaQuery.of(context).viewPadding.bottom;
        return Container(
          height: 70 + bottomInset,
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFECEEF1), width: 1)),
          ),
          child: Padding(
            padding: EdgeInsets.only(bottom: bottomInset),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(Icons.home_outlined, 'Home', true, onTap: () => context.go('/home')),
                _buildNavItem(Icons.groups_outlined, 'Teams', false, onTap: () => context.go('/teams')),
                _buildNavItem(Icons.history, 'History', false, onTap: () => context.go('/history')),
                _buildNavItem(Icons.person_outline, 'Profile', false, onTap: () => context.go('/profile')),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isSelected, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isSelected ? AppColors.primary : AppColors.lightTextSecondary,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected
                  ? AppColors.primary
                  : AppColors.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
