import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../providers/profile_provider.dart';
import '../../providers/career_stats_provider.dart';
import '../../core/theme/colors.dart';
import 'tabs/overview_tab.dart';
import 'tabs/batting_tab.dart';
import 'tabs/bowling_tab.dart';
import 'tabs/fielding_tab.dart';

class PerformanceScreen extends ConsumerStatefulWidget {
  const PerformanceScreen({super.key});

  @override
  ConsumerState<PerformanceScreen> createState() => _PerformanceScreenState();
}

class _PerformanceScreenState extends ConsumerState<PerformanceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const _tabs = ['Overview', 'Batting', 'Bowling', 'Fielding'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _sharePerformance(CareerStats stats, String name) {
    final text = '''🏏 $name's Cricket Career Stats
━━━━━━━━━━━━━━━
Matches: ${stats.matches}
Total Runs: ${stats.totalRuns}
Batting Avg: ${stats.battingAvg.toStringAsFixed(1)}
Strike Rate: ${stats.strikeRate.toStringAsFixed(1)}
Wickets: ${stats.totalWickets}
Economy: ${stats.economy.toStringAsFixed(1)}
━━━━━━━━━━━━━━━
Powered by Scorely''';
    SharePlus.instance.share(ShareParams(text: text));
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    final statsAsync = ref.watch(careerStatsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxScrolled) => [
          SliverAppBar(
            expandedHeight: 0,
            floating: true,
            snap: true,
            backgroundColor: Colors.white,
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Color(0xFF191C1E)),
              onPressed: () => context.pop(),
            ),
            title: Text(
              'MY PERFORMANCE',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF191C1E),
                letterSpacing: 0.5,
              ),
            ),
            actions: [
              statsAsync.whenOrNull(
                data: (stats) => IconButton(
                  icon: const Icon(Icons.share_outlined, color: AppColors.primary),
                  onPressed: () => _sharePerformance(stats, profile.name),
                ),
              ) ?? const SizedBox.shrink(),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(color: const Color(0xFFECEEF1), height: 1),
            ),
          ),
          SliverToBoxAdapter(
            child: _buildProfileHeader(profile, statsAsync),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabBarDelegate(
              TabBar(
                controller: _tabController,
                tabs: _tabs.map((t) => Tab(text: t)).toList(),
                labelStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
                unselectedLabelStyle: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                labelColor: AppColors.primary,
                unselectedLabelColor: const Color(0xFF575D78),
                indicatorColor: AppColors.primary,
                indicatorWeight: 3,
                indicatorSize: TabBarIndicatorSize.label,
                dividerColor: const Color(0xFFECEEF1),
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            OverviewTab(statsAsync: statsAsync, profile: profile),
            BattingTab(statsAsync: statsAsync),
            BowlingTab(statsAsync: statsAsync),
            FieldingTab(statsAsync: statsAsync),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(dynamic profile, AsyncValue<CareerStats> statsAsync) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [AppColors.primary, Color(0xFFD32F2F)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                profile.name.isNotEmpty ? profile.name[0].toUpperCase() : 'P',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        profile.name,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF191C1E),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _RoleBadge(label: profile.playingRole),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  profile.association.isNotEmpty ? profile.association : 'No Team',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFF575D78),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F0F5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.workspace_premium, size: 12, color: Color(0xFF575D78)),
                      const SizedBox(width: 4),
                      Text(
                        'Career Stats',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF575D78),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final String label;
  const _RoleBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  const _TabBarDelegate(this.tabBar);

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          tabBar,
          Container(color: const Color(0xFFECEEF1), height: 1),
        ],
      ),
    );
  }

  @override
  double get maxExtent => tabBar.preferredSize.height + 1;

  @override
  double get minExtent => tabBar.preferredSize.height + 1;

  @override
  bool shouldRebuild(covariant _TabBarDelegate oldDelegate) => false;
}
