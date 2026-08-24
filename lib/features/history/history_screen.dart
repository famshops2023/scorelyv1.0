import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/history_provider.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matches = ref.watch(matchHistoryProvider);
    final pendingCount = ref.watch(pendingSyncCountProvider).value ?? 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'MATCH HISTORY',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF191C1E),
            letterSpacing: 0.5,
          ),
        ),
        automaticallyImplyLeading: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: const Color(0xFFECEEF1),
            height: 1,
          ),
        ),
      ),
      // Sync-pending banner
      body: Column(
        children: [
          if (pendingCount > 0)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: const Color(0xFFFFF3E0),
              child: Row(
                children: [
                  const Icon(Icons.cloud_upload_outlined, color: Color(0xFFE65100), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '$pendingCount match${pendingCount > 1 ? 'es' : ''} pending sync — will upload automatically when online.',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFFE65100),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: matches.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: (matches.length > 20 ? 20 : matches.length) + 1,
              itemBuilder: (context, index) {
                if (index == (matches.length > 20 ? 20 : matches.length)) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24.0),
                    child: Center(
                      child: Text(
                        'For older matches, please contact our support team.',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF575D78),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                final match = matches[index];
                return Dismissible(
                  key: Key(match.id.toString()),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 24),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFBA0013),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
                  ),
                  onDismissed: (_) {
                    ref
                        .read(matchHistoryProvider.notifier)
                        .deleteMatch(match.id);
                  },
                  child: GestureDetector(
                    onTap: () {
                      context.push('/match-stats', extra: match.id);
                    },
                    child: _buildMatchItem(match),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchItem(dynamic match) {
    final String winnerText = match.winnerTeamName != null && match.winnerTeamName.toString().isNotEmpty
        ? '${match.winnerTeamName} WON'
        : 'MATCH DRAWN';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFECEEF1)),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(26, 33, 56, 0.06),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  match.matchTitle.toString().toUpperCase(),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF191C1E),
                    letterSpacing: 0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'COMPLETED',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF006B1B),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(color: Color(0xFFECEEF1), height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _teamInfo(
                match.matchTitle.toString().split(' vs ').first,
                match.teamARuns,
                match.teamAWickets,
                match.teamAOvers,
                match.teamABalls,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'VS',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF575D78),
                  ),
                ),
              ),
              _teamInfo(
                match.matchTitle.toString().split(' vs ').last,
                match.teamBRuns,
                match.teamBWickets,
                match.teamBOvers,
                match.teamBBalls,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1A2138),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.emoji_events_outlined, color: Color(0xFFFFD700), size: 18),
                const SizedBox(width: 8),
                Text(
                  winnerText,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _teamInfo(String name, int runs, int wickets, int overs, int balls) {
    return Column(
      children: [
        Text(
          name,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF575D78),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          '$runs/$wickets',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF191C1E),
          ),
        ),
        Text(
          '($overs.$balls overs)',
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF575D78),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Color(0xFFECEEF1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.history,
              size: 56,
              color: Color(0xFF575D78),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'NO MATCHES YET',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF191C1E),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Completed matches will appear here',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFF575D78),
            ),
          ),
        ],
      ),
    );
  }
}
