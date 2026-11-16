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
import '../../models/live_match_data.dart';
import '../../providers/profile_provider.dart';
import './providers/live_match_insforge_provider.dart';
import '../match/helpers/live_match_promo.dart';
import 'widgets/home_drawer.dart';
import 'widgets/quick_match_cards.dart';
import 'widgets/home_stats_section.dart';
import 'widgets/in_app_requests_sheet.dart';
import '../../widgets/ads/scorely_banner_ad.dart';
import '../../providers/scorer_notification_provider.dart';
import '../../services/sync_manager.dart';
import '../../services/ongoing_match_service.dart';
import '../../services/match_lifecycle_service.dart';
import '../match/providers/quick_match_storage.dart';

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
    // Live matches are rendered in the LIVE section, never as pending.
    final pendingOnly = pendingMatches.where((m) => m.isPending).toList();
    final pendingScorerRequests = ref.watch(pendingScorerRequestsProvider);

    return Scaffold(
      backgroundColor: HomeColors.surface,
      appBar: _buildAppBar(context, pendingOnly.isNotEmpty || pendingScorerRequests.isNotEmpty),
      drawer: const HomeDrawer(),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(syncManagerProvider).pullCompletedMatchesFromRemote();
          ref.invalidate(homePersonalStatsProvider);
          ref.invalidate(recentMatchesProvider);
          ref.invalidate(liveMatchInsforgeProvider);
          ref.invalidate(pendingMatchesProvider);
          ref.read(pendingScorerRequestsProvider.notifier).checkRequests();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 17.0, vertical: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildGreeting(),
                const SizedBox(height: 20),
                QuickMatchActionCards(
                  onQuickMatchTap: () => _handleQuickMatchTap(context, ref),
                  onScheduleMatchTap: () => _handleScheduleMatchTap(context),
                ),
                const SizedBox(height: 27),
                _buildMatchesSection(
                  context,
                  ref,
                  pendingMatches: pendingMatches,
                  liveAsync: liveInsforgeAsync,
                  onStartQuickMatch: () => _handleQuickMatchTap(context, ref),
                ),
                const SizedBox(height: 27),
                HomeStatsSection(),
                const SizedBox(height: 27),
                _buildRecentMatchesSection(context, ref, recentAsync),
                const SizedBox(height: 20),
                const ScorelyBannerAd(),
              ],
            ),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
            'assets/images/scorely_logo.png',
            height: 38,
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
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => const InAppRequestsSheet(),
                );
              },
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

  Future<void> _handleQuickMatchTap(BuildContext context, WidgetRef ref) async {
    final prefs = await SharedPreferences.getInstance();
    final bool hasSeenQuickMatchWarning =
        prefs.getBool('seen_quick_match_warning') ?? false;
    final int limit = ref.read(storageLimitProvider);

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
                      'To keep Scorely running smoothly, only your latest $limit matches are stored on your device. Older matches will be automatically deleted as new matches are added.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: const Color(0xFF5A6278),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 10),
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: const Color(0xFF5A6278),
                          height: 1.5,
                        ),
                        children: [
                          const TextSpan(text: 'Want to store more? Go to '),
                          TextSpan(
                            text: 'Settings \u2192 Storage Optimizer',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                          const TextSpan(text: ' to increase the limit.'),
                        ],
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
                              side: const BorderSide(
                                color: AppColors.darkSurface,
                              ),
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

  // ======================== MATCHES (PENDING & LIVE) ========================

  Widget _buildMatchesSection(
    BuildContext context,
    WidgetRef ref, {
    required List<MatchSetupData> pendingMatches,
    required AsyncValue<List<LiveMatchData>> liveAsync,
    required VoidCallback onStartQuickMatch,
  }) {
    final liveMatches = liveAsync.value ?? [];

    // Build the unified list of cards: LIVE cards first, then PENDING cards
    final List<Widget> cards = [];
    final seenMatchIds = <String>{};

    // 1. Live matches from cloud/InsForge
    for (final liveMatch in liveMatches) {
      if (liveMatch.id.isNotEmpty) seenMatchIds.add(liveMatch.id);
      cards.add(_LiveInsforgeMatchCard(match: liveMatch));
    }

    // 2. Local Live Matches (e.g. guest or local match started before server poll)
    for (final p in pendingMatches) {
      if (p.isLive && (p.id.isEmpty || !seenMatchIds.contains(p.id))) {
        if (p.id.isNotEmpty) seenMatchIds.add(p.id);
        cards.add(_PendingMatchCard(context: context, ref: ref, match: p));
      }
    }

    // 3. Pending Matches (status == pending)
    for (final p in pendingMatches) {
      if (p.isPending && (p.id.isEmpty || !seenMatchIds.contains(p.id))) {
        if (p.id.isNotEmpty) seenMatchIds.add(p.id);
        cards.add(_PendingMatchCard(context: context, ref: ref, match: p));
      }
    }

    // Loading state: when live matches are loading and no pending matches are available
    if (cards.isEmpty && liveAsync.isLoading) {
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MatchesSectionHeader(),
          SizedBox(height: 10),
          _EmptyCard(
            message: 'Checking for matches...',
            isLoading: true,
          ),
        ],
      );
    }

    // Empty state: no live matches and no pending matches
    if (cards.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _MatchesSectionHeader(),
          const SizedBox(height: 10),
          _EmptyMatchesCard(
            onStartQuickMatch: onStartQuickMatch,
          ),
        ],
      );
    }

    // Unified horizontal slider/carousel showing all eligible matches
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _MatchesSectionHeader(totalCount: cards.length),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          clipBehavior: Clip.none,
          child: Row(
            children: [
              for (int i = 0; i < cards.length; i++)
                Padding(
                  padding: EdgeInsets.only(
                    right: (i == cards.length - 1) ? 0 : 14,
                  ),
                  child: cards[i],
                ),
            ],
          ),
        ),
      ],
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
          loading: () => const _EmptyCard(
            message: 'Loading recent matches...',
            isLoading: true,
          ),
          error: (e, _) => const _EmptyCard(
            message: 'No matches available to show',
            subtitle: 'Tap Quick Match above to start a match!',
          ),
          data: (matches) {
            if (matches.isEmpty) {
              return const _EmptyCard(
                message: 'No matches available to show',
                subtitle: 'Tap Quick Match above to start a match!',
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
    final profile = ref.watch(profileProvider);
    final format = match.matchType;
    final isWaitingForB = match.isWaitingForSquad; // used for status badge only
    final isCreator = match.isCreator(profile.id);

    // Active scorer assigned to someone else
    final hasAssignedOtherScorer = match.activeScorerId != null &&
        match.activeScorerId!.isNotEmpty &&
        match.activeScorerId != profile.id;

    // Creator can proceed to toss only if active scorer is not assigned to someone else
    final canProceedToToss = isCreator && !hasAssignedOtherScorer;

    final String statusLabel;
    final Color statusColor;
    if (match.isLive) {
      statusLabel = 'LIVE';
      statusColor = HomeColors.activeGreen;
    } else if (isWaitingForB) {
      statusLabel = 'PENDING • SQUAD';
      statusColor = const Color(0xFFF2994A);
    } else {
      statusLabel = 'PENDING';
      statusColor = const Color(0xFFF2994A);
    }

    // Simplified button rules (Pending match):
    //   • Creator (active scorer not assigned) → PROCEED TO TOSS
    //   • Associated signed-in players / viewers → VIEW DETAILS
    //   • Live local guest match → RESUME SCORING
    final String buttonLabel;
    final Color buttonColor;
    if (match.isLive) {
      buttonLabel = 'RESUME SCORING';
      buttonColor = HomeColors.primary;
    } else if (canProceedToToss) {
      buttonLabel = 'PROCEED TO TOSS';
      buttonColor = HomeColors.primary;
    } else {
      buttonLabel = 'VIEW DETAILS';
      buttonColor = HomeColors.secondary;
    }

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    statusLabel,
                    style: HomeTypography.labelBold.copyWith(
                      color: statusColor,
                      fontSize: 9.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  format.toUpperCase(),
                  textAlign: TextAlign.end,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                    color: HomeColors.secondary,
                    letterSpacing: 0.3,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          RichText(
            text: TextSpan(
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: HomeColors.onSurface,
              ),
              children: [
                TextSpan(text: match.teamAName),
                TextSpan(
                  text: ' vs ',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9,
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
                if (match.isLive) {
                  context.push('/scoring', extra: match);
                  return;
                }
                if (canProceedToToss) {
                  // Creator proceeds to Toss (if active scorer not assigned)
                  proceedToToss(context, ref, match);
                } else {
                  // Associated signed-in player / viewer → read-only details
                  context.push('/match-details', extra: {
                    'setupData': match,
                    'readOnly': true,
                  });
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                buttonLabel,
                style: GoogleFonts.inter(
                  fontSize: 9.5,
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

// ======================== MATCHES SUB-WIDGETS ========================

class _MatchesSectionHeader extends StatelessWidget {
  final int totalCount;
  const _MatchesSectionHeader({this.totalCount = 0});

  @override
  Widget build(BuildContext context) {
    return Row(
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
          'MATCHES',
          style: HomeTypography.labelBold.copyWith(
            color: HomeColors.secondary,
          ),
        ),
        if (totalCount > 0) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: HomeColors.secondary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$totalCount',
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: HomeColors.secondary,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _EmptyMatchesCard extends StatelessWidget {
  final VoidCallback onStartQuickMatch;

  const _EmptyMatchesCard({required this.onStartQuickMatch});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 20),
      decoration: BoxDecoration(
        color: HomeColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(26, 33, 56, 0.04),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFFE9ECF0)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.sports_cricket_outlined,
              color: AppColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'No matches right now',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: HomeColors.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'Start a Quick Match or Schedule a Match to begin!',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: HomeColors.secondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 36,
            child: ElevatedButton.icon(
              onPressed: onStartQuickMatch,
              icon: const Icon(Icons.flash_on, size: 16, color: Colors.white),
              label: Text(
                'START QUICK MATCH',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: HomeColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),
        ],
      ),
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
    // The server-persisted active scorer is the only one allowed to resume.
    final isScorer = myId.isNotEmpty && match.scorerId == myId;

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
          // Top row: LIVE badge + Format / Venue
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: HomeColors.activeGreen,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'LIVE',
                    style: HomeTypography.labelBold.copyWith(
                      color: HomeColors.activeGreen,
                      fontSize: 9.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  match.venue.isNotEmpty
                      ? '${match.format.toUpperCase()} • ${match.venue.toUpperCase()}'
                      : match.format.toUpperCase(),
                  textAlign: TextAlign.end,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                    color: HomeColors.secondary,
                    letterSpacing: 0.3,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (match.scorerName.isNotEmpty) ...[
            const SizedBox(height: 5),
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: HomeColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  'Scorer: ${match.scorerName}',
                  style: GoogleFonts.inter(
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                    color: HomeColors.primary,
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
          // Team A Name & Score
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                match.teamAName,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
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
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: HomeColors.primary,
                    ),
                  ),
                  if (match.teamAOvers.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    Text(
                      '(${match.teamAOvers})',
                      style: GoogleFonts.inter(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w400,
                        color: HomeColors.secondary,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            'vs',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 9,
              fontStyle: FontStyle.italic,
              color: HomeColors.secondary.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 3),
          // Team B Name & Score
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                match.teamBName,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
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
                      fontSize: 12,
                      fontWeight: match.teamBScore == 'yet to bat'
                          ? FontWeight.w500
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
                        fontSize: 8.5,
                        fontWeight: FontWeight.w400,
                        color: HomeColors.secondary,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Button
          SizedBox(
            width: double.infinity,
            height: 38,
            child: ElevatedButton(
              onPressed: () async {
                if (isScorer) {
                  // Resume scoring: restore original match data (teams, players, squads)
                  final pendingList = ref.read(pendingMatchesProvider);
                  var localSetup = pendingList.cast<MatchSetupData?>().firstWhere(
                    (m) => m!.id == match.id,
                    orElse: () => null,
                  );

                  // 1. If not found or squads empty, hydrate from OngoingMatchService snapshot
                  if (localSetup == null || (localSetup.teamAPlayers.isEmpty && localSetup.teamBPlayers.isEmpty)) {
                    final snapshot = await OngoingMatchService.instance.getSnapshot(match.id);
                    if (snapshot != null && snapshot['setup'] is Map) {
                      try {
                        localSetup = MatchSetupData.fromJson(
                          Map<String, dynamic>.from(snapshot['setup'] as Map),
                        );
                      } catch (_) {}
                    }
                  }

                  // 2. Check QuickMatchStorage
                  if (localSetup == null || (localSetup.teamAPlayers.isEmpty && localSetup.teamBPlayers.isEmpty)) {
                    final quickMatches = await QuickMatchStorage.getAllMatches();
                    final matchInQuick = quickMatches.cast<MatchSetupData?>().firstWhere(
                      (m) => m!.id == match.id,
                      orElse: () => null,
                    );
                    if (matchInQuick != null && (matchInQuick.teamAPlayers.isNotEmpty || matchInQuick.teamBPlayers.isNotEmpty)) {
                      localSetup = matchInQuick;
                    }
                  }

                  // 3. Try fetching authoritative row from InsForge server
                  if (localSetup == null || (localSetup.teamAPlayers.isEmpty && localSetup.teamBPlayers.isEmpty)) {
                    final row = await MatchLifecycleService.fetchRow(match.id);
                    if (row != null && row['match_data'] is Map) {
                      try {
                        localSetup = MatchSetupData.fromJson(
                          Map<String, dynamic>.from(row['match_data'] as Map),
                        );
                      } catch (_) {}
                    }
                  }

                  // 4. Per Point 15 Q15: Remove the fallback that resumes with empty squads.
                  // If original data cannot be recovered, show clear error message instead of opening incomplete match.
                  if (localSetup == null || (localSetup.teamAPlayers.isEmpty && localSetup.teamBPlayers.isEmpty)) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Cannot resume match: Squad and player data could not be recovered. Please check your network or re-open from Pending Matches.'),
                          backgroundColor: AppColors.primary,
                          duration: Duration(seconds: 4),
                        ),
                      );
                    }
                    return;
                  }

                  if (context.mounted) {
                    context.push('/scoring', extra: localSetup);
                  }
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
                  fontSize: 9.5,
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

        final matchCode = match.matchTitle.contains('(') && match.matchTitle.contains(')')
            ? match.matchTitle.split('(').last.replaceAll(')', '').trim()
            : (match.matchTitle.startsWith('SM-') ? match.matchTitle : '');

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
                        matchCode.isNotEmpty
                            ? '$dateStr • $format • $matchCode'
                            : '$dateStr • $format',
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
    if (winner.toLowerCase().contains('abandon')) {
      return 'Match Abandoned';
    }

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
  final String? subtitle;
  final bool isLoading;

  const _EmptyCard({
    required this.message,
    this.subtitle,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        color: HomeColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(26, 33, 56, 0.04),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFFE9ECF0)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isLoading)
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                color: AppColors.primary,
              ),
            )
          else
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.sports_cricket_outlined,
                color: AppColors.primary,
                size: 22,
              ),
            ),
          const SizedBox(height: 12),
          Text(
            message,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: HomeColors.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          if (subtitle != null && subtitle!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: HomeColors.secondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
