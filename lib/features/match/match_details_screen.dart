import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/typography.dart';
import '../match/match_setup_screen.dart';

class MatchDetailsScreen extends StatelessWidget {
  final MatchSetupData setupData;

  const MatchDetailsScreen({super.key, required this.setupData});

  @override
  Widget build(BuildContext context) {
    final battingTeam = setupData.battingFirstTeam;
    final bowlingTeam = battingTeam == setupData.teamAName
        ? setupData.teamBName
        : setupData.teamAName;
    final overs = setupData.overs;
    final tossWinner = setupData.tossWonBy;

    // Determine format label
    String format;
    if (overs <= 5) {
      format = 'Tape Ball';
    } else if (overs <= 10) {
      format = 'T10';
    } else if (overs <= 20) {
      format = 'T20';
    } else if (overs <= 40) {
      format = 'One Day';
    } else {
      format = 'Test';
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1a2238),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Match Details',
              style: AppTypography.headlineMedium.copyWith(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
            Text(
              'Confirm before starting the match',
              style: AppTypography.bodySmall.copyWith(
                color: Colors.white60,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Toss Result Card
                  _buildTossCard(tossWinner, battingTeam),
                  const SizedBox(height: 18),

                  // Batting First label
                  _buildSectionLabel('BATTING FIRST'),
                  const SizedBox(height: 6),
                  _buildTeamCard(
                    teamName: battingTeam,
                    label: 'BATTING FIRST',
                    subtitle: 'Batting  ·  $overs Overs to Target',
                    accentColor: Colors.red,
                    avatarLetter: battingTeam[0].toUpperCase(),
                  ),
                  const SizedBox(height: 16),

                  // Bowling First label
                  _buildSectionLabel('BOWLING FIRST'),
                  const SizedBox(height: 8),
                  _buildTeamCard(
                    teamName: bowlingTeam,
                    label: 'BOWLING FIRST',
                    subtitle: 'Fielding  ·  $overs Overs to defend',
                    accentColor: Colors.blue,
                    avatarLetter: bowlingTeam[0].toUpperCase(),
                  ),
                  const SizedBox(height: 18),

                  // Match Details Grid
                  _buildSectionLabel('MATCH DETAILS'),
                  const SizedBox(height: 8),
                  _buildDetailsGrid(format, overs),
                  const SizedBox(height: 18),
                ],
              ),
            ),
          ),

          // Start Scoring button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  context.push('/scoring', extra: setupData);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 4,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.sports_cricket, color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Start Scoring',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTossCard(String tossWinner, String battingTeam) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1a2238), Color(0xFF243050)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1a2238).withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          // Coin icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFFFD700), width: 3),
              color: const Color(0xFF2a3450),
            ),
            child: const Icon(
              Icons.monetization_on,
              color: Color(0xFFFFD700),
              size: 26,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TOSS RESULT',
                  style: AppTypography.labelCaps.copyWith(
                    color: const Color(0xFFFFD700),
                    fontSize: 9,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tossWinner,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'won the toss',
                  style: TextStyle(color: Colors.white60, fontSize: 11),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle, color: Colors.white, size: 6),
                      SizedBox(width: 5),
                      Text(
                        'Elected to BAT',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
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

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: AppTypography.labelCaps.copyWith(
        color: Colors.black45,
        fontSize: 9,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildTeamCard({
    required String teamName,
    required String label,
    required String subtitle,
    required Color accentColor,
    required String avatarLetter,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(11),
            ),
            alignment: Alignment.center,
            child: Text(
              avatarLetter,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  teamName,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.black45, fontSize: 11),
                ),
              ],
            ),
          ),
          Icon(Icons.sports_cricket_outlined, color: Colors.black26, size: 18),
        ],
      ),
    );
  }

  Widget _buildDetailsGrid(String format, int overs) {
    final now = DateTime.now();
    final today = '${now.day} ${_monthName(now.month)} ${now.year}';

    final items = [
      {'icon': '🔥', 'label': 'Format', 'value': format},
      {'icon': '🏏', 'label': 'Overs', 'value': '$overs'},
      {'icon': '📍', 'label': 'Venue', 'value': 'Local Ground'},
      {'icon': '📅', 'label': 'Date', 'value': today},
    ];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: GridView.count(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 2.8,
        children: items
            .map(
              (item) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Text(item['icon']!, style: const TextStyle(fontSize: 11)),
                      const SizedBox(width: 4),
                      Text(
                        item['label']!,
                        style: const TextStyle(
                          color: Colors.black45,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item['value']!,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            )
            .toList(),
      ),
    );
  }

  String _monthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }
}
