import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';
import '../../providers/history_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matches = ref.watch(matchHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'SCORELY',
          style: AppTypography.headlineMedium.copyWith(letterSpacing: 2),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.settings_outlined,
              color: AppColors.onBackground,
            ),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            _buildHeroCard(context),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('RECENT MATCHES', style: AppTypography.labelCaps),
                if (matches.isNotEmpty)
                  TextButton(
                    onPressed: () => context.push('/history'),
                    child: Text(
                      'VIEW ALL',
                      style: AppTypography.labelCaps.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: matches.isEmpty
                  ? _buildEmptyState()
                  : ListView.separated(
                      itemCount: matches.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final match = matches[index];
                        return _buildMatchCard(match);
                      },
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildHeroCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.neonGradient,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'READY FOR\nA MATCH?',
            style: AppTypography.displayLarge.copyWith(
              color: AppColors.onPrimary,
              fontSize: 40,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start a new quick match session instantly.',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.onPrimary.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.push('/create-team'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.onPrimary,
              foregroundColor: AppColors.primary,
            ),
            child: const Text('START QUICK MATCH'),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchCard(dynamic match) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.onBackground.withValues(alpha: 0.05),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  match.matchTitle.toUpperCase(),
                  style: AppTypography.labelCaps.copyWith(
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${match.teamARuns}/${match.teamAWickets} vs ${match.teamBRuns}/${match.teamBWickets}',
                  style: AppTypography.headlineMedium,
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.onBackground),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 64,
            color: AppColors.onBackground.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 16),
          Text(
            'NO MATCH HISTORY',
            style: AppTypography.headlineMedium.copyWith(
              color: AppColors.onBackground.withValues(alpha: 0.3),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your recent matches will appear here.',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.onBackground.withValues(alpha: 0.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(bottom: 24, top: 12),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.surface)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(Icons.home, 'HOME', true, () {}),
          _navItem(
            Icons.history,
            'HISTORY',
            false,
            () => context.push('/history'),
          ),
          _navItem(Icons.person, 'PROFILE', false, () {}),
        ],
      ),
    );
  }

  Widget _navItem(
    IconData icon,
    String label,
    bool isActive,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isActive
                ? AppColors.primary
                : AppColors.onBackground.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTypography.labelCaps.copyWith(
              fontSize: 10,
              color: isActive
                  ? AppColors.primary
                  : AppColors.onBackground.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}
