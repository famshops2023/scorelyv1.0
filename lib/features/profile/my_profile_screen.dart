import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../providers/profile_provider.dart';
import '../../providers/history_provider.dart';
import '../../services/database.dart';

class MyProfileScreen extends ConsumerWidget {
  const MyProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final history = ref.watch(matchHistoryProvider);

    // Calculate dynamic stats
    int totalMatches = 0; // Since there is no player mapping yet, we just count completed matches as played
    for (var match in history) {
      if (match.isCompleted) {
        totalMatches++;
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A2138),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'MY PROFILE',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1.0,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white, size: 20),
            onPressed: () => context.push('/edit-profile'),
          ),
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white, size: 20),
            onPressed: () {
              final shareText = 'Check out my Scorely Cricket Profile!\n\n'
                  '👤 ${profile.name}\n'
                  '🏏 ${profile.role}\n'
                  '📍 ${profile.location}\n\n'
                  'Matches Played: $totalMatches\n\n'
                  'Download Scorely to track your cricket stats!';
              // ignore: deprecated_member_use
              Share.share(shareText);
            },
          ),
          IconButton(
            icon: const Icon(Icons.qr_code_2, color: Colors.white, size: 20),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                isScrollControlled: true,
                builder: (context) => _buildQrBottomSheet(context, profile.toJson()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Profile Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 16, bottom: 24, left: 20, right: 20),
              decoration: const BoxDecoration(
                color: Color(0xFF1A2138),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFBA0013), width: 3),
                        ),
                        child: ClipOval(
                          child: profile.profileImagePath != null
                              ? Image.file(
                                  File(profile.profileImagePath!),
                                  fit: BoxFit.cover,
                                )
                              : Container(
                                  color: Colors.grey[300],
                                  alignment: Alignment.center,
                                  child: Text(
                                    profile.name.isNotEmpty ? profile.name[0].toUpperCase() : 'U',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF575D78),
                                    ),
                                  ),
                                ),
                        ),
                      ),
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: const Color(0xFF006B1B),
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF1A2138), width: 3),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    profile.name,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'ID: 98234-CRIC',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    profile.role,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.location_on_outlined, color: Colors.white, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        profile.location.isNotEmpty ? profile.location : 'Add Location',
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (profile.playingRole.isNotEmpty)
                        _buildAttributeChip(profile.playingRole),
                      if (profile.battingStyle.isNotEmpty)
                        _buildAttributeChip(profile.battingStyle),
                      if (profile.bowlingStyle.isNotEmpty)
                        _buildAttributeChip(profile.bowlingStyle),
                    ],
                  ),
                ],
              ),
            ),

            // Main Content Area
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quick Actions Row
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: const [BoxShadow(color: Color.fromRGBO(26, 33, 56, 0.05), blurRadius: 10, offset: Offset(0, 4))],
                          ),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFDBE1FF),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.bar_chart, color: Color(0xFF575D78), size: 24),
                              ),
                              const SizedBox(height: 8),
                              Text('STATS', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF191C1E))),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: const [BoxShadow(color: Color.fromRGBO(26, 33, 56, 0.05), blurRadius: 10, offset: Offset(0, 4))],
                          ),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF94F990),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.groups, color: Color(0xFF006B1B), size: 24),
                              ),
                              const SizedBox(height: 8),
                              Text('TEAMS', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF191C1E))),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Scorer Performance Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Scorer Performance',
                        style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF191C1E)),
                      ),
                      Text(
                        'View All',
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFFBA0013)),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),

                  // Total Scored
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: const Border(left: BorderSide(color: Color(0xFFBA0013), width: 4)),
                      boxShadow: const [BoxShadow(color: Color.fromRGBO(26, 33, 56, 0.05), blurRadius: 10, offset: Offset(0, 4))],
                    ),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned(
                          right: -20,
                          top: -10,
                          child: Icon(Icons.sports_cricket, size: 80, color: const Color(0xFFF2F4F7).withValues(alpha: 0.8)),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.emoji_events_outlined, color: Color(0xFFBA0013), size: 16),
                                const SizedBox(width: 8),
                                Text('TOTAL SCORED', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF5D3F3C))),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text('-', style: GoogleFonts.plusJakartaSans(fontSize: 40, fontWeight: FontWeight.bold, color: const Color(0xFF191C1E), height: 1.0)),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.trending_up, color: Color(0xFF006B1B), size: 14),
                                const SizedBox(width: 4),
                                Text('N/A this month', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF006B1B))),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Total Wickets
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: const Border(left: BorderSide(color: Color(0xFFBA0013), width: 4)),
                      boxShadow: const [BoxShadow(color: Color.fromRGBO(26, 33, 56, 0.05), blurRadius: 10, offset: Offset(0, 4))],
                    ),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned(
                          right: -20,
                          top: -10,
                          child: Icon(Icons.sports_baseball, size: 80, color: const Color(0xFFF2F4F7).withValues(alpha: 0.8)),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.sports_baseball_outlined, color: Color(0xFFBA0013), size: 16),
                                const SizedBox(width: 8),
                                Text('TOTAL WICKETS', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF5D3F3C))),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text('-', style: GoogleFonts.plusJakartaSans(fontSize: 40, fontWeight: FontWeight.bold, color: const Color(0xFF191C1E), height: 1.0)),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.trending_up, color: Color(0xFF006B1B), size: 14),
                                const SizedBox(width: 4),
                                Text('N/A this month', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF006B1B))),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),

                  // Matches Played & Pro Rating Row
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: const Border(left: BorderSide(color: Color(0xFF575D78), width: 4)),
                            boxShadow: const [BoxShadow(color: Color.fromRGBO(26, 33, 56, 0.05), blurRadius: 10, offset: Offset(0, 4))],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('MATCHES\nPLAYED', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF575D78))),
                              const SizedBox(height: 16),
                              Text('$totalMatches', style: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF191C1E))),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: const Border(left: BorderSide(color: Color(0xFF006B1B), width: 4)),
                            boxShadow: const [BoxShadow(color: Color.fromRGBO(26, 33, 56, 0.05), blurRadius: 10, offset: Offset(0, 4))],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('PRO RATING', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF006B1B))),
                              const SizedBox(height: 16),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text('4.9', style: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF006B1B))),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.star, color: Color(0xFF006B1B), size: 14),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text('Elite Badge', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF5D3F3C))),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),
                  Text(
                    'RECENT MATCHES',
                    style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF191C1E)),
                  ),
                  const SizedBox(height: 16),

                  ..._buildRecentMatches(history, context),

                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildRecentMatches(List<CricketMatch> history, BuildContext context) {
    // Get last 3 completed matches
    final completed = history.where((m) => m.isCompleted).toList();
    // sort by date descending
    completed.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final recentMatches = completed.take(3).toList();

    if (recentMatches.isEmpty) {
      return [
        Center(
          child: Text('No recent matches.', style: GoogleFonts.inter(color: Colors.grey)),
        )
      ];
    }

    return recentMatches.map((match) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [BoxShadow(color: Color.fromRGBO(26, 33, 56, 0.05), blurRadius: 10, offset: Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    match.matchTitle,
                    style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF191C1E)),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5FFEF),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'FINAL',
                    style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF006B1B)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${match.teamARuns}/${match.teamAWickets} vs ${match.teamBRuns}/${match.teamBWickets}',
              style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF575D78)),
            ),
            const SizedBox(height: 8),
            if (match.winnerTeamName != null)
              Text(
                '${match.winnerTeamName} won',
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF006B1B)),
              ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(color: Color(0xFFE6E8EB), height: 1),
            ),
            GestureDetector(
              onTap: () {
                context.go('/match-stats', extra: match.id);
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('VIEW SCORECARD', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFFBA0013))),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward, color: Color(0xFFBA0013), size: 16),
                ],
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildQrBottomSheet(BuildContext context, String qrData) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Scan Profile',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF191C1E),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Let others scan this code to view your profile.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFF575D78),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
            ),
            child: QrImageView(
              data: qrData,
              version: QrVersions.auto,
              size: 200.0,
              backgroundColor: Colors.white,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: Color(0xFF1A2138),
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: Color(0xFF1A2138),
              ),
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () => context.pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFBA0013),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'CLOSE',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildAttributeChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white),
      ),
    );
  }
}
