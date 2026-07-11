import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';
import '../../providers/history_provider.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matches = ref.watch(matchHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('MATCH HISTORY', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: matches.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: matches.length,
              itemBuilder: (context, index) {
                final match = matches[index];
                return Dismissible(
                  key: Key(match.id.toString()),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    color: AppColors.error,
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (_) {
                    ref
                        .read(matchHistoryProvider.notifier)
                        .deleteMatch(match.id);
                  },
                  child: GestureDetector(
                    onTap: () {
                      context.go('/match-stats', extra: match.id);
                    },
                    child: _buildMatchItem(match),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildMatchItem(dynamic match) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.onBackground.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                match.matchTitle.toUpperCase(),
                style: AppTypography.labelCaps.copyWith(
                  color: AppColors.primary,
                ),
              ),
              Text(
                'COMPLETED',
                style: AppTypography.labelCaps.copyWith(
                  fontSize: 10,
                  color: AppColors.tertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _teamInfo(
                match.teamARuns,
                match.teamAWickets,
                match.teamAOvers,
                match.teamABalls,
              ),
              const Text(
                'VS',
                style: TextStyle(
                  color: Colors.white24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              _teamInfo(
                match.teamBRuns,
                match.teamBWickets,
                match.teamBOvers,
                match.teamBBalls,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            match.winnerTeamName != null
                ? '${match.winnerTeamName} WON'
                : 'MATCH DRAWN',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.onBackground.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _teamInfo(int runs, int wickets, int overs, int balls) {
    return Column(
      children: [
        Text('$runs/$wickets', style: AppTypography.headlineLarge),
        Text(
          '($overs.$balls)',
          style: AppTypography.labelCaps.copyWith(color: Colors.white38),
        ),
      ],
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
            'NO MATCHES YET',
            style: AppTypography.headlineMedium.copyWith(
              color: AppColors.onBackground.withValues(alpha: 0.3),
            ),
          ),
        ],
      ),
    );
  }
}
