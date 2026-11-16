import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../providers/profile_provider.dart';
import '../../providers/career_stats_provider.dart';
import 'package:scorely/core/theme/colors.dart';
import 'tabs/overview_tab.dart';
import 'tabs/batting_tab.dart';
import 'tabs/bowling_tab.dart';
import 'tabs/fielding_tab.dart';

import '../../models/user_profile.dart';
import '../../models/player_pro_rating.dart';
import '../../services/ratings/player_rating_repository.dart';
import '../../services/sync_manager.dart';

class PerformanceScreen extends ConsumerStatefulWidget {
  final bool isReadOnly;
  final String? customTitle;
  final String? targetPlayerUserId;
  final String? targetPlayerName;
  final String? targetPlayerRole;
  final String? targetPlayerLocation;

  const PerformanceScreen({
    super.key,
    this.isReadOnly = false,
    this.customTitle,
    this.targetPlayerUserId,
    this.targetPlayerName,
    this.targetPlayerRole,
    this.targetPlayerLocation,
  });

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
    _tabController = TabController(
      length: widget.isReadOnly ? 1 : _tabs.length,
      vsync: this,
    );
    if (!widget.isReadOnly) {
      _tabController.addListener(_handleTabChange);
    }
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) return;
    final isLoggedIn = ref.read(profileProvider).isLoggedIn;
    if (!isLoggedIn && _tabController.index != 0) {
      final targetIndex = _tabController.index;
      _tabController.index = 0;
      if (mounted) {
        _showSignInRequiredDialog(context, sectionName: _tabs[targetIndex]);
      }
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  List<Widget> _buildTabs(bool isLoggedIn) {
    return _tabs.asMap().entries.map((entry) {
      final index = entry.key;
      final title = entry.value;

      if (isLoggedIn || index == 0) {
        return Tab(text: title);
      }

      return Tab(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.lightTextMuted,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.lock_outline,
              size: 13,
              color: AppColors.lightTextMuted,
            ),
          ],
        ),
      );
    }).toList();
  }

  void _showSignInRequiredDialog(BuildContext context, {String sectionName = 'Detailed Performance'}) {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock_person_outlined,
                    color: AppColors.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Sign In Required',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Guest users can view career Overview stats.\n\nSign in to Scorely to unlock in-depth $sectionName performance breakdowns, charts, and device sync.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.lightTextSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(dialogCtx),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: const BorderSide(
                            color: Color(0xFFDDE0E8),
                          ),
                        ),
                        child: Text(
                          'CANCEL',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.lightTextPrimary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(dialogCtx);
                          await context.push('/login');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'SIGN IN',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLockedTab(BuildContext context, String sectionName) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFECEEF1)),
            boxShadow: const [
              BoxShadow(
                color: Color.fromRGBO(0, 0, 0, 0.04),
                blurRadius: 16,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_person_outlined,
                  color: AppColors.primary,
                  size: 32,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Unlock $sectionName Analytics',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Sign in to your Scorely account to view in-depth $sectionName performance breakdowns, averages, wagon wheels, and milestones.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.lightTextSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => _showSignInRequiredDialog(context, sectionName: sectionName),
                icon: const Icon(Icons.login, size: 18),
                label: const Text('Sign In to Enable'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _sharePerformance(CareerStats stats, String name, MatchCategory category) {
    final catName = category == MatchCategory.turfBox ? 'Turf/Box' : 'Ground';
    final text = '''🏏 $name's $catName Cricket Career Stats
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
    final rawProfile = ref.watch(profileProvider);
    final effectiveProfile = widget.targetPlayerUserId != null
        ? UserProfile(
            id: widget.targetPlayerUserId!,
            name: widget.targetPlayerName ?? 'Scorely Player',
            role: widget.targetPlayerRole ?? 'Batsman',
            playingRole: widget.targetPlayerRole ?? 'Batsman',
            location: widget.targetPlayerLocation ?? '',
            isLoggedIn: true,
          )
        : rawProfile;

    final selectedCategory = ref.watch(performanceCategoryProvider);
    final statsAsync = ref.watch(careerStatsProvider);
    final countsAsync = ref.watch(matchCategoryCountsProvider);

    final screenTitle = widget.customTitle ??
        (widget.isReadOnly ? 'PERFORMANCE DETAILS' : 'MY PERFORMANCE');

    return Scaffold(
      backgroundColor: AppColors.lightBg,
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(syncManagerProvider).pullCompletedMatchesFromRemote();
          ref.invalidate(careerStatsForCategoryProvider);
          ref.invalidate(careerStatsProvider);
          ref.invalidate(matchCategoryCountsProvider);
        },
        child: NestedScrollView(
        headerSliverBuilder: (context, innerBoxScrolled) => [
          SliverAppBar(
            expandedHeight: 0,
            floating: true,
            snap: true,
            backgroundColor: Colors.white,
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.lightTextPrimary),
              onPressed: () => context.pop(),
            ),
            title: Text(
              screenTitle,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.lightTextPrimary,
                letterSpacing: 0.5,
              ),
            ),
            actions: [
              if (!widget.isReadOnly)
                statsAsync.whenOrNull(
                  data: (stats) => IconButton(
                    icon: const Icon(Icons.share_outlined, color: AppColors.primary),
                    onPressed: () => _sharePerformance(stats, effectiveProfile.name, selectedCategory),
                  ),
                ) ?? const SizedBox.shrink(),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(color: const Color(0xFFECEEF1), height: 1),
            ),
          ),
          SliverToBoxAdapter(
            child: _buildProfileHeader(effectiveProfile, statsAsync, selectedCategory, countsAsync),
          ),
          if (!widget.isReadOnly)
            SliverPersistentHeader(
              pinned: true,
              delegate: _TabBarDelegate(
                TabBar(
                  controller: _tabController,
                  tabs: _buildTabs(effectiveProfile.isLoggedIn),
                  onTap: (index) {
                    if (!effectiveProfile.isLoggedIn && index != 0) {
                      _tabController.index = 0;
                      _showSignInRequiredDialog(context, sectionName: _tabs[index]);
                    }
                  },
                  labelStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                  unselectedLabelStyle: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.lightTextSecondary,
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
        body: widget.isReadOnly
            ? OverviewTab(statsAsync: statsAsync, profile: effectiveProfile)
            : TabBarView(
                controller: _tabController,
                physics: effectiveProfile.isLoggedIn
                    ? const PageScrollPhysics()
                    : const NeverScrollableScrollPhysics(),
                children: [
                  OverviewTab(statsAsync: statsAsync, profile: effectiveProfile),
                  effectiveProfile.isLoggedIn
                      ? BattingTab(statsAsync: statsAsync)
                      : _buildLockedTab(context, 'Batting'),
                  effectiveProfile.isLoggedIn
                      ? BowlingTab(statsAsync: statsAsync)
                      : _buildLockedTab(context, 'Bowling'),
                  effectiveProfile.isLoggedIn
                      ? FieldingTab(statsAsync: statsAsync)
                      : _buildLockedTab(context, 'Fielding'),
                ],
              ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(
    dynamic profile,
    AsyncValue<CareerStats> statsAsync,
    MatchCategory selectedCategory,
    AsyncValue<Map<MatchCategory, int>> countsAsync,
  ) {
    final turfCount = countsAsync.value?[MatchCategory.turfBox];
    final groundCount = countsAsync.value?[MatchCategory.ground];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Column(
        children: [
          Row(
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
                              color: AppColors.lightTextPrimary,
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
                        color: AppColors.lightTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _buildProRatingBadge(profile, selectedCategory),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Category Selector (Turf/Box vs Ground Matches)
          _buildCategorySelector(selectedCategory, turfCount, groundCount),
        ],
      ),
    );
  }

  Widget _buildCategorySelector(
    MatchCategory selected,
    int? turfCount,
    int? groundCount,
  ) {
    return Container(
      height: 46,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F3F7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E6EC)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildCategoryItem(
              title: 'Turf / Box',
              count: turfCount,
              icon: Icons.sports_cricket,
              isSelected: selected == MatchCategory.turfBox,
              onTap: () {
                ref.read(performanceCategoryProvider.notifier).selectCategory(
                    MatchCategory.turfBox);
              },
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _buildCategoryItem(
              title: 'Ground Matches',
              count: groundCount,
              icon: Icons.grass,
              isSelected: selected == MatchCategory.ground,
              onTap: () {
                ref.read(performanceCategoryProvider.notifier).selectCategory(
                    MatchCategory.ground);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryItem({
    required String title,
    required int? count,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
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
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.lightTextSecondary,
              ),
            ),
            if (count != null && count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.25)
                      : const Color(0xFFE2E6EC),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? Colors.white : AppColors.lightTextSecondary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProRatingBadge(UserProfile profile, MatchCategory selectedCategory) {
    final matchType = selectedCategory == MatchCategory.turfBox ? 'turf' : 'ground';

    return FutureBuilder<PlayerProRating>(
      future: PlayerRatingRepository.getPlayerRating(
        playerUserId: profile.id,
        matchType: matchType,
        playerName: profile.name,
        playerRole: profile.playingRole.isNotEmpty ? profile.playingRole : profile.role,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F0F5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 10,
                  height: 10,
                  child: CircularProgressIndicator(strokeWidth: 1.5, color: AppColors.primary),
                ),
                const SizedBox(width: 6),
                Text(
                  'Loading...',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        final rating = snapshot.data;
        if (rating == null || !rating.hasRating || rating.matchesPlayed == 0) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F0F5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star_outline_rounded, size: 12, color: AppColors.lightTextSecondary),
                const SizedBox(width: 4),
                Text(
                  'No ${matchType == 'turf' ? 'Turf' : 'Ground'} rating yet',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        // Format: ★ 742 | ELITE | 💥 Hard Hitter
        final topBadgeStr = (rating.topBadge != null && rating.topBadge!.isNotEmpty)
            ? ' | ${rating.topBadge}'
            : '';

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF9E6),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFFFD54F)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.star_rounded, size: 14, color: Color(0xFFFFB800)),
              const SizedBox(width: 4),
              Text(
                '${rating.rating} | ${rating.level.toUpperCase()}$topBadgeStr',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF795548),
                ),
              ),
            ],
          ),
        );
      },
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
  bool shouldRebuild(covariant _TabBarDelegate oldDelegate) => true;
}
