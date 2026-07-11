import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/history_provider.dart';
import '../../services/database.dart';

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
    final liveAsync = ref.watch(liveMatchProvider);
    final recentAsync = ref.watch(recentMatchesProvider);

    return Scaffold(
      backgroundColor: HomeColors.surface,
      appBar: _buildAppBar(context),
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
              const SizedBox(height: 27),
              _buildLiveMatchSection(context, ref, liveAsync),
              const SizedBox(height: 27),
              _buildMyStatsSection(ref, recentAsync),
              const SizedBox(height: 27),
              _buildRecentMatchesSection(context, ref, recentAsync),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: HomeColors.appbarBg,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.menu, color: Colors.white),
        onPressed: () {},
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
            Positioned(
              right: 12,
              top: 12,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.account_circle, color: Colors.white, size: 28),
          onPressed: () {
            context.push('/profile');
          },
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

  Widget _buildQuickMatchCard(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/create-team'),
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
      onTap: () => context.push('/match-setup'),
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

  // ======================== LIVE MATCH ========================

  Widget _buildLiveMatchSection(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<CricketMatch?> liveAsync,
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
                color: HomeColors.activeGreen,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 7),
            Text(
              'LIVE MATCH',
              style: HomeTypography.labelBold.copyWith(
                color: HomeColors.secondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        liveAsync.when(
          loading: () => const _ShimmerCard(height: 130),
          error: (e, _) => const _EmptyCard(message: 'No live match'),
          data: (match) {
            if (match == null) {
              return const _EmptyCard(message: 'No live match in progress');
            }
            return _LiveMatchCard(context: context, ref: ref, match: match);
          },
        ),
      ],
    );
  }

  // ======================== MY STATS ========================

  Widget _buildMyStatsSection(WidgetRef ref, AsyncValue<List<CricketMatch>> recentAsync) {
    // Aggregate stats from the local completed matches
    int totalMatches = 0;
    int totalRuns = 0;
    int totalWickets = 0;

    recentAsync.whenData((matches) {
      totalMatches = matches.length;
      for (final m in matches) {
        totalRuns += m.teamARuns + m.teamBRuns;
        totalWickets += m.teamAWickets + m.teamBWickets;
      }
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('MY STATS', style: HomeTypography.labelBold),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _buildStatCard('MATCHES', '$totalMatches')),
            const SizedBox(width: 10),
            Expanded(child: _buildStatCard('RUNS', '$totalRuns')),
            const SizedBox(width: 10),
            Expanded(child: _buildStatCard('WICKETS', '$totalWickets')),
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
              return const _EmptyCard(message: 'No recent matches yet.\nTap Quick Match to start!');
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

  // ======================== BOTTOM NAV ========================

  Widget _buildBottomNav(BuildContext context) {
    return LayoutBuilder(
      builder: (context, _) {
        final bottomInset = MediaQuery.of(context).viewPadding.bottom;
        return Container(
          padding: EdgeInsets.only(
            bottom: 12 + bottomInset,
            top: 10,
            left: 14,
            right: 14,
          ),
          decoration: const BoxDecoration(
            color: HomeColors.cardBg,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Color.fromRGBO(26, 33, 56, 0.05),
                blurRadius: 20,
                offset: Offset(0, -4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home, 'Home', true),
              GestureDetector(
                onTap: () => context.push('/teams'),
                child: _buildNavItem(Icons.people_alt, 'Teams', false),
              ),
              GestureDetector(
                onTap: () => context.push('/history'),
                child: _buildNavItem(Icons.history, 'History', false),
              ),
              GestureDetector(
                onTap: () => context.push('/profile'),
                child: _buildNavItem(Icons.person_outline, 'Profile', false),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isActive) {
    if (isActive) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFFFFE8E6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: HomeColors.primary, size: 20),
            const SizedBox(height: 3),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: HomeColors.primary,
              ),
            ),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: HomeColors.secondary, size: 20),
          const SizedBox(height: 3),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: HomeColors.secondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ======================== LIVE MATCH CARD (sub-widget) ========================

class _LiveMatchCard extends ConsumerWidget {
  final BuildContext context;
  final WidgetRef ref;
  final CricketMatch match;

  const _LiveMatchCard({
    required this.context,
    required this.ref,
    required this.match,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamsAsync = ref.watch(matchTeamNamesProvider(match));

    return teamsAsync.when(
      loading: () => const _ShimmerCard(height: 130),
      error: (e, _) => const _EmptyCard(message: 'Error loading match'),
      data: (teams) {
        final (teamA, teamB) = teams;
        final format = 'T${match.totalOvers}';
        final score = '${match.teamARuns}/${match.teamAWickets}';
        final overs = '(${match.teamAOvers}.${match.teamABalls})';

        return Container(
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
                          color: HomeColors.activeGreen,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '$format • LIVE',
                        style: HomeTypography.labelBold.copyWith(
                          color: HomeColors.primary,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    score,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: HomeColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 7),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  RichText(
                    text: TextSpan(
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: HomeColors.onSurface,
                      ),
                      children: [
                        TextSpan(text: teamA),
                        TextSpan(
                          text: ' vs ',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: HomeColors.secondary,
                          ),
                        ),
                        TextSpan(text: teamB),
                      ],
                    ),
                  ),
                  Text(
                    overs,
                    style: HomeTypography.bodyMd.copyWith(
                      color: HomeColors.secondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 17),
              SizedBox(
                width: double.infinity,
                height: 41,
                child: ElevatedButton(
                  onPressed: () {
                    context.push('/match-stats', extra: match.id);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: HomeColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'VIEW MATCH',
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
      },
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
      error: (e, _) => const SizedBox(width: 255, child: _EmptyCard(message: 'Error')),
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
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
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

  String _buildResultText(String winner, CricketMatch match, String teamA, String teamB) {
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
    const months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
                    'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
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
        style: GoogleFonts.inter(
          fontSize: 13,
          color: HomeColors.secondary,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
