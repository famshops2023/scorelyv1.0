import 'package:flutter/material.dart';
import 'package:scorely/core/theme/colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/history_provider.dart';
import '../../services/database.dart';
import '../match/providers/pending_matches_provider.dart';
import '../match/match_setup_screen.dart';
import '../teams/providers/teams_provider.dart';
import '../../models/live_match_data.dart';
import '../../providers/profile_provider.dart';
import './providers/live_match_insforge_provider.dart';
import '../match/helpers/live_match_promo.dart';
import 'widgets/home_drawer.dart';
import 'widgets/quick_match_cards.dart';
import 'widgets/home_stats_section.dart';

// --- Colors from DESIGN_home.md ---
class HomeColors {
  static const Color surface = AppColors.lightBg;
  static const Color onSurface = AppColors.lightTextPrimary;
  static const Color primary = AppColors.primary;
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color secondary = AppColors.lightTextSecondary;
  static const Color secondaryContainer = Color(0xFFD8DEFE);
  static const Color tertiary = AppColors.successDark;
  static const Color appbarBg = AppColors.lightTextPrimary;
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color activeGreen = AppColors.successDark;
}

// --- Typography from DESIGN_home.md ---
class HomeTypography {
  static TextStyle headlineLg = GoogleFonts.plusJakartaSans(
    fontSize: 27,
    fontWeight: FontWeight.w700,
    color: HomeColors.onSurface,
    letterSpacing: -0.54,
  );

  static TextStyle headlineMd = GoogleFonts.plusJakartaSans(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: HomeColors.onSurface,
  );

  static TextStyle headlineSm = GoogleFonts.plusJakartaSans(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    color: HomeColors.onSurface,
  );

  static TextStyle bodyLg = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: HomeColors.onSurface,
  );

  static TextStyle bodyMd = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: HomeColors.onSurface,
  );

  static TextStyle labelBold = GoogleFonts.inter(
    fontSize: 10,
    fontWeight: FontWeight.w700,
    color: HomeColors.secondary,
    letterSpacing: 0.5,
  );
}

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final liveInsforgeAsync = ref.watch(liveMatchInsforgeProvider);
    final recentAsync = ref.watch(recentMatchesProvider);
    final pendingMatches = ref.watch(pendingMatchesProvider);

    return Scaffold(
      backgroundColor: HomeColors.surface,
      appBar: _buildAppBar(context, pendingMatches.isNotEmpty),
      drawer: const HomeDrawer(),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 17.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildGreeting(),
              const SizedBox(height: 20),
              QuickMatchActionCards(
                onQuickMatchTap: () => _handleQuickMatchTap(context),
                onScheduleMatchTap: () => _handleScheduleMatchTap(context),
              ),
              if (pendingMatches.isNotEmpty) ...[
                const SizedBox(height: 27),
                _buildPendingMatchSection(context, ref, pendingMatches),
              ],
              const SizedBox(height: 27),
              _buildLiveMatchSection(context, ref, liveInsforgeAsync),
              const SizedBox(height: 27),
              HomeStatsSection(),
              const SizedBox(height: 27),
              _buildRecentMatchesSection(context, ref, recentAsync),
            ],
          ),
        ),
      ),
    );
  }

  void _handleScheduleMatchTap(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: HomeColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text('Coming Soon 🚀', style: HomeTypography.headlineSm),
        content: Text(
          'Scheduled Matches with Live Sync and Team Management will be available in the next major update.\n\nFor now, enjoy Quick Matches!',
          style: HomeTypography.bodyMd,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Got it',
              style: TextStyle(
                color: HomeColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context, bool hasNotifications) {
    return AppBar(
      backgroundColor: HomeColors.appbarBg,
      elevation: 0,
      iconTheme: const IconThemeData(color: Colors.white),
      leading: Builder(
        builder: (context) => IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () {
            Scaffold.of(context).openDrawer();
          },
        ),
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/images/scorely_icon.png',
            height: 46,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.sports_cricket, color: Colors.amber),
          ),
          const SizedBox(width: 8),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'SCORELY',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
                TextSpan(
                  text: ' - Home',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w400,
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      centerTitle: true,
      actions: [
        Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_none, color: Colors.white),
              onPressed: () {},
            ),
            if (hasNotifications)
              Positioned(
                right: 12,
                top: 12,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildGreeting() {
    final hour = DateTime.now().hour;
    String greeting;
    if (hour < 12) {
      greeting = 'Good Morning, Scorer!';
    } else if (hour < 17) {
      greeting = 'Good Afternoon, Scorer!';
    } else {
      greeting = 'Good Evening, Scorer!';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          greeting,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            fontStyle: FontStyle.italic,
            color: HomeColors.onSurface,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          'Ready for the next match?',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            fontStyle: FontStyle.italic,
            color: HomeColors.activeGreen,
          ),
        ),
      ],
    );
  }

  Future<void> _handleQuickMatchTap(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final bool hasSeenQuickMatchWarning =
        prefs.getBool('seen_quick_match_warning') ?? false;
    final int limit = prefs.getInt('settings_storage_limit') ?? 5;

    if (hasSeenQuickMatchWarning) {
      if (context.mounted) {
        context.push('/create-team', extra: {'isQuickMatch': true});
      }
      return;
    }

    if (!context.mounted) return;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: AppColors.primary, width: 6),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: const BoxDecoration(
                        color: Color(
                          0xFFFFEBEE,
                        ), // Light red background from image
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.info,
                        color: AppColors.primary,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Heads Up!',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.darkSurface, // Dark navy from image
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'To keep Scorely running smoothly, only your latest $limit matches are stored on your device. Older matches will be automatically deleted as new matches are added',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: const Color(0xFF5A6278), // Slate grey from image
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context, false),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              side: const BorderSide(color: AppColors.darkSurface),
                            ),
                            child: Text(
                              'CANCEL',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.darkSurface,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              'I UNDERSTAND',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    if (result == true) {
      await prefs.setBool('seen_quick_match_warning', true);
      if (context.mounted) {
        context.push('/create-team', extra: {'isQuickMatch': true});
      }
    }
  }

  // ======================== PENDING MATCHES ========================

  Widget _buildPendingMatchSection(
    BuildContext context,
    WidgetRef ref,
    List<MatchSetupData> pendingMatches,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 7),
            Text(
              'PENDING MATCHES',
              style: HomeTypography.labelBold.copyWith(
                color: HomeColors.secondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          child: Row(
            children: pendingMatches.map((m) {
              return Padding(
                padding: const EdgeInsets.only(right: 14),
                child: _PendingMatchCard(context: context, ref: ref, match: m),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // ======================== LIVE MATCH ========================

  Widget _buildLiveMatchSection(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<LiveMatchData>> liveAsync,
  ) {
    return liveAsync.when(
      loading: () => const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _LiveMatchHeader(),
          SizedBox(height: 10),
          _ShimmerCard(height: 130),
        ],
      ),
      error: (e, _) => const SizedBox.shrink(),
      data: (matches) {
        if (matches.isEmpty) {
          return const SizedBox.shrink();
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _LiveMatchHeader(),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              child: Row(
                children: matches.map((m) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 14),
                    child: _LiveInsforgeMatchCard(match: m),
                  );
                }).toList(),
              ),
            ),
          ],
        );
      },
    );
  }

  // ======================== RECENT MATCHES ========================

  Widget _buildRecentMatchesSection(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<CricketMatch>> recentAsync,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('RECENT MATCHES', style: HomeTypography.labelBold),
            GestureDetector(
              onTap: () => context.push('/history'),
              child: Text(
                'SEE ALL',
                style: HomeTypography.labelBold.copyWith(
                  color: HomeColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        recentAsync.when(
          loading: () => const _ShimmerCard(height: 130),
          error: (e, _) => const _EmptyCard(message: 'Could not load matches'),
          data: (matches) {
            if (matches.isEmpty) {
              return const _EmptyCard(
                message: 'No recent matches yet.\nTap Quick Match to start!',
              );
            }
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              child: Row(
                children: matches.map((m) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 14),
                    child: _RecentMatchCard(
                      context: context,
                      ref: ref,
                      match: m,
                    ),
                  );
                }).toList(),
              ),
            );
          },
        ),
      ],
    );
  }
}

// ======================== PENDING MATCH CARD (sub-widget) ========================

class _PendingMatchCard extends ConsumerWidget {
  final BuildContext context;
  final WidgetRef ref;
  final MatchSetupData match;

  const _PendingMatchCard({
    required this.context,
    required this.ref,
    required this.match,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final format = match.matchType;
    final isWaitingForB = match.status == 'waiting_for_team_b';

    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: HomeColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(26, 33, 56, 0.08),
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(17),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF2994A),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    isWaitingForB ? 'WAITING FOR SQUAD' : 'READY FOR TOSS',
                    style: HomeTypography.labelBold.copyWith(
                      color: const Color(0xFFF2994A),
                    ),
                  ),
                ],
              ),
              Text(
                format,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: HomeColors.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          RichText(
            text: TextSpan(
              style: GoogleFonts.plusJakartaSans(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: HomeColors.onSurface,
              ),
              children: [
                TextSpan(text: match.teamAName),
                TextSpan(
                  text: ' vs ',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: HomeColors.secondary,
                  ),
                ),
                TextSpan(text: match.teamBName),
              ],
            ),
          ),
          const SizedBox(height: 17),
          SizedBox(
            width: double.infinity,
            height: 41,
            child: ElevatedButton(
              onPressed: () {
                if (isWaitingForB) {
                  final teams = ref.read(teamsProvider).value ?? [];

                  final teamB = teams.firstWhere(
                    (t) => t.name == match.teamBName,
                    orElse: () => TeamData(
                      id: '',
                      name: '',
                      location: '',
                      dateActive: DateTime.now(),
                      members: [],
                    ),
                  );
                  if (teamB.id.isNotEmpty) {
                    context.push(
                      '/team-squad',
                      extra: {
                        'teamId': teamB.id,
                        'readOnly': false,
                        'singleSelectionMode': false,
                        'setupData': match,
                        'isSelectingPlayingXi': true,
                        'teamType': 'B',
                      },
                    );
                  } else {
                    proceedToToss(context, ref, match);
                  }
                } else {
                  proceedToToss(context, ref, match);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isWaitingForB
                    ? HomeColors.secondary
                    : HomeColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                isWaitingForB ? 'SELECT SQUAD B' : 'PROCEED TO TOSS',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.85,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ======================== LIVE MATCH SUB-WIDGETS ========================

class _LiveMatchHeader extends StatelessWidget {
  const _LiveMatchHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: const BoxDecoration(
            color: HomeColors.activeGreen,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 7),
        Text(
          'LIVE MATCH',
          style: HomeTypography.labelBold.copyWith(color: HomeColors.secondary),
        ),
      ],
    );
  }
}

class _LiveInsforgeMatchCard extends ConsumerWidget {
  final LiveMatchData match;

  const _LiveInsforgeMatchCard({required this.match});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final myId = profile.id;
    final isScorer = match.scorerId == myId;

    return Container(
      width: 290,
      decoration: BoxDecoration(
        color: HomeColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(26, 33, 56, 0.08),
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(17),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Format + Venue
          Text(
            '${match.format.toUpperCase()} • ${match.venue.toUpperCase()}',
            style: HomeTypography.labelBold.copyWith(
              color: HomeColors.secondary,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 12),
          // Team A Name & Score
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                match.teamAName,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: HomeColors.onSurface,
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    match.teamAScore,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: HomeColors.primary,
                    ),
                  ),
                  if (match.teamAOvers.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    Text(
                      '(${match.teamAOvers})',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        color: HomeColors.secondary,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'vs',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: HomeColors.secondary.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 4),
          // Team B Name & Score
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                match.teamBName,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: HomeColors.onSurface,
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    match.teamBScore,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: match.teamBScore == 'yet to bat'
                          ? FontWeight.w400
                          : FontWeight.w700,
                      color: match.teamBScore == 'yet to bat'
                          ? HomeColors.secondary
                          : HomeColors.primary,
                      fontStyle: match.teamBScore == 'yet to bat'
                          ? FontStyle.italic
                          : FontStyle.normal,
                    ),
                  ),
                  if (match.teamBOvers.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    Text(
                      '(${match.teamBOvers})',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        color: HomeColors.secondary,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Button
          SizedBox(
            width: double.infinity,
            height: 41,
            child: ElevatedButton(
              onPressed: () {
                if (isScorer) {
                  // Resume scoring: retrieve match data from pending matches provider
                  final pendingList = ref.read(pendingMatchesProvider);
                  final localSetup = pendingList.firstWhere(
                    (m) => m.id == match.id,
                    orElse: () => MatchSetupData(
                      id: match.id,
                      teamAName: match.teamAName,
                      teamBName: match.teamBName,
                      teamAPlayers: [],
                      teamBPlayers: [],
                      overs: 20,
                      tossWonBy: '',
                      maxOversPerBowler: 4,
                      powerplayOvers: 6,
                      battingFirstTeam: match.teamAName,
                      matchType: match.format,
                      ballType: 'Tennis',
                      venue: match.venue,
                      matchDate: DateTime.now(),
                    ),
                  );
                  context.push('/scoring', extra: localSetup);
                } else {
                  // Show stats: navigate to live match view screen
                  context.push('/live-match', extra: match);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: HomeColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                isScorer ? 'RESUME SCORING' : 'SHOW STATS',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.85,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ======================== RECENT MATCH CARD (sub-widget) ========================

class _RecentMatchCard extends ConsumerWidget {
  final BuildContext context;
  final WidgetRef ref;
  final CricketMatch match;

  const _RecentMatchCard({
    required this.context,
    required this.ref,
    required this.match,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamsAsync = ref.watch(matchTeamNamesProvider(match));

    return teamsAsync.when(
      loading: () => const SizedBox(
        width: 255,
        height: 130,
        child: _ShimmerCard(height: 130),
      ),
      error: (e, _) =>
          const SizedBox(width: 255, child: _EmptyCard(message: 'Error')),
      data: (teams) {
        final (teamA, teamB) = teams;
        final dateStr = _formatDate(match.createdAt);
        final format = 'T${match.totalOvers}';

        final teamAScore = '${match.teamARuns}/${match.teamAWickets}';
        final teamBScore = '${match.teamBRuns}/${match.teamBWickets}';

        final winner = match.winnerTeamName;
        final resultText = winner != null
            ? _buildResultText(winner, match, teamA, teamB)
            : 'Match Result Unavailable';

        return GestureDetector(
          onTap: () => context.push('/match-stats', extra: match.id),
          child: Container(
            width: 255,
            decoration: BoxDecoration(
              color: HomeColors.cardBg,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Color.fromRGBO(26, 33, 56, 0.05),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        '$dateStr • $format',
                        style: HomeTypography.labelBold.copyWith(
                          fontSize: 9,
                          letterSpacing: 0.4,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(
                      Icons.remove_red_eye_outlined,
                      size: 14,
                      color: HomeColors.secondary,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        teamA,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: HomeColors.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      teamAScore,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: HomeColors.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        teamB,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: HomeColors.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      teamBScore,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: HomeColors.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF94F990),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      resultText.toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF005313),
                        letterSpacing: 0.4,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _buildResultText(
    String winner,
    CricketMatch match,
    String teamA,
    String teamB,
  ) {
    final teamARuns = match.teamARuns;
    final teamBRuns = match.teamBRuns;
    final teamBWickets = match.teamBWickets;

    if (teamBRuns > teamARuns) {
      final wicketsLeft = 10 - teamBWickets;
      return '$winner won by $wicketsLeft wickets';
    } else if (teamARuns > teamBRuns) {
      final runsMargin = teamARuns - teamBRuns;
      return '$winner won by $runsMargin runs';
    }
    return '$winner won';
  }

  String _formatDate(DateTime dt) {
    const months = [
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC',
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }
}

// ======================== UTILITY WIDGETS ========================

class _ShimmerCard extends StatelessWidget {
  final double height;
  const _ShimmerCard({required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFE0E3E6),
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final String message;
  const _EmptyCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        color: HomeColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E3E6)),
      ),
      child: Text(
        message,
        style: GoogleFonts.inter(fontSize: 13, color: HomeColors.secondary),
        textAlign: TextAlign.center,
      ),
    );
  }
}
