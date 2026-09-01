import 'package:flutter/material.dart';
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
import 'package:share_plus/share_plus.dart';

// --- Colors from DESIGN_home.md ---
class HomeColors {
  static const Color surface = Color(0xFFF7F9FC);
  static const Color onSurface = Color(0xFF191C1E);
  static const Color primary = Color(0xFFBA0013);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color secondary = Color(0xFF575D78);
  static const Color secondaryContainer = Color(0xFFD8DEFE);
  static const Color tertiary = Color(0xFF006B1B);
  static const Color appbarBg = Color(0xFF191C1E);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color activeGreen = Color(0xFF006B1B);
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
      drawer: _buildDrawer(context, ref),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 17.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildGreeting(),
              const SizedBox(height: 20),
              _buildQuickMatchCard(context),
              const SizedBox(height: 14),
              _buildScheduleMatchCard(context),
              if (pendingMatches.isNotEmpty) ...[
                const SizedBox(height: 27),
                _buildPendingMatchSection(context, ref, pendingMatches),
              ],
              const SizedBox(height: 27),
              _buildLiveMatchSection(context, ref, liveInsforgeAsync),
              const SizedBox(height: 27),
              _buildMyStatsSection(ref, recentAsync),
              const SizedBox(height: 27),
              _buildRecentMatchesSection(context, ref, recentAsync),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final isLoggedIn = profile.isLoggedIn;
    final userName = isLoggedIn && profile.name.isNotEmpty
        ? profile.name
        : 'Guest User';
    final userEmail = isLoggedIn ? profile.email : 'Sign in to sync your data';

    return Drawer(
      backgroundColor: HomeColors.surface,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: HomeColors.appbarBg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: HomeColors.primary,
                  child: Text(
                    userName.isNotEmpty ? userName[0].toUpperCase() : 'G',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  userName,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    if (!isLoggedIn) {
                      Navigator.pop(context);
                      context.push('/login');
                    }
                  },
                  child: Text(
                    userEmail,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: isLoggedIn ? Colors.white70 : Colors.blue[300],
                      decoration: isLoggedIn ? TextDecoration.none : TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
          _buildDrawerItem(
            icon: Icons.person_outline,
            title: 'Profile',
            onTap: () {
              Navigator.pop(context);
              context.push('/profile');
            },
          ),
          _buildDrawerItem(
            icon: Icons.analytics_outlined,
            title: 'My performance',
            onTap: () {
              Navigator.pop(context);
              context.push('/performance');
            },
          ),
          const Divider(),
          _buildDrawerItem(
            icon: Icons.star_outline,
            title: 'Rate us',
            onTap: () {
              Navigator.pop(context);
            },
          ),
          _buildDrawerItem(
            icon: Icons.info_outline,
            title: 'About us',
            onTap: () {
              Navigator.pop(context);
              context.push('/info', extra: 0);
            },
          ),
          _buildDrawerItem(
            icon: Icons.help_outline,
            title: 'Help/FAQs',
            onTap: () {
              Navigator.pop(context);
              context.push('/info', extra: 1);
            },
          ),
          _buildDrawerItem(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Policy',
            onTap: () {
              Navigator.pop(context);
              context.push('/info', extra: 2);
            },
          ),
          _buildDrawerItem(
            icon: Icons.description_outlined,
            title: 'Terms of Service',
            onTap: () {
              Navigator.pop(context);
              context.push('/info', extra: 3);
            },
          ),
          _buildDrawerItem(
            icon: Icons.settings_outlined,
            title: 'Settings',
            onTap: () {
              Navigator.pop(context);
              context.push('/settings');
            },
          ),
          _buildDrawerItem(
            icon: Icons.share_outlined,
            title: 'Share app',
            onTap: () {
              Navigator.pop(context);
              SharePlus.instance.share(
                ShareParams(
                  text: 'Check out Scorely! The ultimate cricket scoring app for live match updates and team management. Download it now: https://scorely.app',
                  subject: 'Scorely Cricket App',
                ),
              );
            },
          ),
          if (isLoggedIn) ...[
            const Divider(),
            _buildDrawerItem(
              icon: Icons.logout_outlined,
              title: 'Sign out',
              onTap: () async {
                Navigator.pop(context);
                await ref.read(profileProvider.notifier).signOut();
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: HomeColors.secondary),
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: HomeColors.onSurface,
        ),
      ),
      onTap: onTap,
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
            height: 32,
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
                    color: Color(0xFFBA0013),
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
                  top: BorderSide(color: Color(0xFFBA0013), width: 6),
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
                        color: Color(0xFFBA0013),
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Heads Up!',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A2138), // Dark navy from image
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
                              side: const BorderSide(color: Color(0xFF1A2138)),
                            ),
                            child: Text(
                              'CANCEL',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1A2138),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFBA0013),
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

  Widget _buildQuickMatchCard(BuildContext context) {
    return GestureDetector(
      onTap: () => _handleQuickMatchTap(context),
      child: Container(
        width: double.infinity,
        height: 102,
        decoration: BoxDecoration(
          color: HomeColors.primary,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: HomeColors.primary.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -8,
              top: -8,
              bottom: -8,
              child: Icon(
                Icons.bolt,
                size: 119,
                color: Colors.white.withValues(alpha: 0.15),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'QUICK MATCH',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: HomeColors.onPrimary,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Start scoring within 30 seconds',
                    style: HomeTypography.bodyMd.copyWith(
                      color: HomeColors.onPrimary.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleMatchCard(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // context.push('/match-setup'); // Temporarily disabled for MVP
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
                child: Text('Got it', style: TextStyle(color: HomeColors.primary, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: HomeColors.secondaryContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 17),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Schedule Match', style: HomeTypography.headlineSm),
                const SizedBox(height: 3),
                Text(
                  'Plan Future Match',
                  style: HomeTypography.bodyMd.copyWith(
                    color: HomeColors.secondary,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.all(7),
              child: const Icon(
                Icons.calendar_today_outlined,
                color: HomeColors.primary,
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
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
                color: Color(0xFFBA0013),
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

  // ======================== MY STATS ========================

  Widget _buildMyStatsSection(
    WidgetRef ref,
    AsyncValue<List<CricketMatch>> recentAsync,
  ) {
    // Aggregate stats from the local completed matches

    int turfMatches = 0;
    int turfRuns = 0;
    int turfWickets = 0;

    int otherMatches = 0;
    int otherRuns = 0;
    int otherWickets = 0;

    recentAsync.whenData((matches) {
      for (final m in matches) {
        final runs = m.teamARuns + m.teamBRuns;
        final wickets = m.teamAWickets + m.teamBWickets;

        if (m.matchType == 'Box/Turf') {
          turfMatches++;
          turfRuns += runs;
          turfWickets += wickets;
        } else {
          otherMatches++;
          otherRuns += runs;
          otherWickets += wickets;
        }
      }
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('TURF/BOX', style: HomeTypography.labelBold),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _buildStatCard('MATCHES', '$turfMatches')),
            const SizedBox(width: 10),
            Expanded(child: _buildStatCard('RUNS', '$turfRuns')),
            const SizedBox(width: 10),
            Expanded(child: _buildStatCard('WICKETS', '$turfWickets')),
          ],
        ),
        const SizedBox(height: 20),
        Text('Ground Matches', style: HomeTypography.labelBold),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _buildStatCard('MATCHES', '$otherMatches')),
            const SizedBox(width: 10),
            Expanded(child: _buildStatCard('RUNS', '$otherRuns')),
            const SizedBox(width: 10),
            Expanded(child: _buildStatCard('WICKETS', '$otherWickets')),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 17),
      decoration: BoxDecoration(
        color: HomeColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: const Border(
          bottom: BorderSide(color: HomeColors.primary, width: 2),
        ),
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
          Text(label, style: HomeTypography.labelBold),
          const SizedBox(height: 7),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 19,
              fontWeight: FontWeight.w600,
              color: HomeColors.onSurface,
            ),
          ),
        ],
      ),
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
