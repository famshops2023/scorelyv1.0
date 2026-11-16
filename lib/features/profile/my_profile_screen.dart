import 'dart:io';
import 'package:flutter/material.dart';
import 'package:scorely/core/theme/colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../providers/profile_provider.dart';
import '../../providers/history_provider.dart';
import '../../services/insforge_stats_service.dart';
import '../../providers/player_rating_provider.dart';
import '../../services/sync_manager.dart';

class MyProfileScreen extends ConsumerWidget {
  const MyProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);

    if (!profile.isLoggedIn) {
      return _buildGuestProfileView(context);
    }

    final scorerStatsAsync = ref.watch(profileScorerStatsProvider);
    final scorerStats = scorerStatsAsync.value ?? const InsforgeScorerStats();

    final totalMatches = scorerStats.totalMatches;
    final totalRunsScored = scorerStats.totalRunsScored;
    final totalWicketsTaken = scorerStats.totalWicketsTaken;
    final thisMonthRuns = scorerStats.thisMonthRuns;
    final thisMonthWickets = scorerStats.thisMonthWickets;

    return Scaffold(
      backgroundColor: AppColors.lightBg,
      appBar: AppBar(
        backgroundColor: AppColors.darkSurface,
        elevation: 0,
        automaticallyImplyLeading: false,
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
                  'Matches Scored: $totalMatches\n'
                  'Total Runs: $totalRunsScored | Total Wickets: $totalWicketsTaken\n\n'
                  'Download Scorely to track your cricket stats!';
              SharePlus.instance.share(ShareParams(text: shareText));
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
          profile.isLoggedIn
              ? IconButton(
                  tooltip: 'Sign Out',
                  icon: const Icon(Icons.logout, color: Colors.white70, size: 20),
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (dialogContext) => AlertDialog(
                        backgroundColor: AppColors.darkSurface,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        title: Text('Sign Out?', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
                        content: Text('You will lose live scoring broadcast until you sign back in.', style: GoogleFonts.inter(color: Colors.white70, fontSize: 13)),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text('Cancel', style: GoogleFonts.inter(color: Colors.white54))),
                          TextButton(onPressed: () => Navigator.pop(dialogContext, true), child: Text('Sign Out', style: GoogleFonts.inter(color: AppColors.primary, fontWeight: FontWeight.bold))),
                        ],
                      ),
                    );
                    if (confirmed == true) {
                      await ref.read(profileProvider.notifier).signOut();
                    }
                  },
                )
              : IconButton(
                  tooltip: 'Sign In for Live Scoring',
                  icon: const Icon(Icons.login, color: Color(0xFFFFA500), size: 20),
                  onPressed: () => context.push('/login'),
                ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(syncManagerProvider).pullCompletedMatchesFromRemote();
          ref.invalidate(profileScorerStatsProvider);
          ref.invalidate(userProRatingProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
          children: [
            // Header Profile Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 16, bottom: 24, left: 20, right: 20),
              decoration: const BoxDecoration(
                color: AppColors.darkSurface,
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
                          border: Border.all(color: AppColors.primary, width: 3),
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
                                      color: AppColors.lightTextSecondary,
                                    ),
                                  ),
                                ),
                        ),
                      ),
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: AppColors.successDark,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.darkSurface, width: 3),
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
                    profile.displayId,
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
                  // Auth status badge
                  GestureDetector(
                    onTap: profile.isLoggedIn ? null : () => context.push('/login'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                      decoration: BoxDecoration(
                        color: profile.isLoggedIn
                            ? AppColors.successDark.withValues(alpha: 0.2)
                            : const Color(0xFFFFA500).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: profile.isLoggedIn
                              ? AppColors.successDark.withValues(alpha: 0.5)
                              : const Color(0xFFFFA500).withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            profile.isLoggedIn ? Icons.wifi_tethering : Icons.login,
                            size: 13,
                            color: profile.isLoggedIn ? const Color(0xFF4CAF50) : const Color(0xFFFFA500),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            profile.isLoggedIn ? 'LIVE SCORER' : 'TAP TO SIGN IN',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: profile.isLoggedIn ? const Color(0xFF4CAF50) : const Color(0xFFFFA500),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
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
                  // Scorer Performance Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Scorer Performance',
                        style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.lightTextPrimary),
                      ),
                      GestureDetector(
                        onTap: () => context.push('/performance'),
                        child: Text(
                          'View All',
                          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
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
                      border: const Border(left: BorderSide(color: AppColors.primary, width: 4)),
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
                                const Icon(Icons.emoji_events_outlined, color: AppColors.primary, size: 16),
                                const SizedBox(width: 8),
                                Text('TOTAL SCORED', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF5D3F3C))),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              totalRunsScored > 0 ? '$totalRunsScored' : '0',
                              style: GoogleFonts.plusJakartaSans(fontSize: 40, fontWeight: FontWeight.bold, color: AppColors.lightTextPrimary, height: 1.0),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.trending_up, color: AppColors.successDark, size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  thisMonthRuns > 0
                                      ? '+$thisMonthRuns this month'
                                      : (totalRunsScored > 0 ? '0 this month' : 'No matches yet'),
                                  style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.successDark),
                                ),
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
                      border: const Border(left: BorderSide(color: AppColors.primary, width: 4)),
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
                                const Icon(Icons.sports_baseball_outlined, color: AppColors.primary, size: 16),
                                const SizedBox(width: 8),
                                Text('TOTAL WICKETS', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF5D3F3C))),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              totalWicketsTaken > 0 ? '$totalWicketsTaken' : '0',
                              style: GoogleFonts.plusJakartaSans(fontSize: 40, fontWeight: FontWeight.bold, color: AppColors.lightTextPrimary, height: 1.0),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.trending_up, color: AppColors.successDark, size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  thisMonthWickets > 0
                                      ? '+$thisMonthWickets this month'
                                      : (totalWicketsTaken > 0 ? '0 this month' : 'No matches yet'),
                                  style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.successDark),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),

                  // Matches Scored Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: const Border(left: BorderSide(color: AppColors.lightTextSecondary, width: 4)),
                      boxShadow: const [BoxShadow(color: Color.fromRGBO(26, 33, 56, 0.05), blurRadius: 10, offset: Offset(0, 4))],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'MATCHES SCORED',
                              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.lightTextSecondary),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '$totalMatches',
                              style: GoogleFonts.plusJakartaSans(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.lightTextPrimary),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F3F7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.scoreboard_outlined, color: AppColors.lightTextSecondary, size: 24),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // SCORELY PRO RATING SECTION
                  _buildProRatingSection(context, ref, profile),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
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
              color: AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Let others scan this code to view your profile.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.lightTextSecondary,
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
                color: AppColors.darkSurface,
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: AppColors.darkSurface,
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
                backgroundColor: AppColors.primary,
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

  Widget _buildGuestProfileView(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBg,
      appBar: AppBar(
        backgroundColor: AppColors.darkSurface,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'MY PROFILE',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1.0,
          ),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock_person_rounded,
                    size: 36,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Sign In to Access Profile',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Profile is only visible for signed-in players. Please sign in or create an account to view and customize your cricket profile, track stats, and generate your personal QR code.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: const Color(0xFF5A6278),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => context.push('/login'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'SIGN IN / REGISTER',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F5FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.offline_bolt_rounded,
                        size: 16,
                        color: AppColors.lightTextSecondary,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Offline matches and scoring remain available without an account.',
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            color: AppColors.lightTextSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProRatingSection(BuildContext context, WidgetRef ref, dynamic profile) {
    final selectedCategory = ref.watch(profileRatingCategoryProvider);
    final isTurf = selectedCategory == 'turf';
    final ratingAsync = ref.watch(userProRatingProvider(selectedCategory));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Color.fromRGBO(26, 33, 56, 0.06), blurRadius: 16, offset: Offset(0, 4)),
        ],
        border: Border.all(color: const Color(0xFFECEEF1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title & Switcher
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.workspace_premium, color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'SCORELY PRO RATING',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      color: AppColors.lightTextPrimary,
                    ),
                  ),
                ],
              ),
              // Turf / Ground switcher
              Container(
                height: 34,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F3F7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    _buildToggleBtn(
                      label: 'Turf',
                      isSelected: isTurf,
                      onTap: () => ref.read(profileRatingCategoryProvider.notifier).selectCategory('turf'),
                    ),
                    _buildToggleBtn(
                      label: 'Ground',
                      isSelected: !isTurf,
                      onTap: () => ref.read(profileRatingCategoryProvider.notifier).selectCategory('ground'),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          ratingAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 30),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (err, stack) => Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  'Rating temporarily unavailable',
                  style: GoogleFonts.inter(fontSize: 13, color: AppColors.lightTextSecondary),
                ),
              ),
            ),
            data: (rating) {
              if (!rating.hasRating || rating.matchesPlayed == 0) {
                // Empty state distinguishing "No rating yet" from 0
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFEEF0F4)),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        isTurf ? Icons.sports_cricket : Icons.grass,
                        size: 40,
                        color: AppColors.lightTextMuted,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        isTurf ? 'No Turf rating yet' : 'No Ground rating yet',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.lightTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        isTurf
                            ? 'Play a Turf match to start your Pro Rating.'
                            : 'Play a Ground match to start your Pro Rating.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                );
              }

              // Active Rating View
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.star_rounded, color: Color(0xFFFFB800), size: 36),
                            const SizedBox(width: 6),
                            Text(
                              '${rating.rating}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 38,
                                fontWeight: FontWeight.w800,
                                color: AppColors.lightTextPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getLevelColor(rating.level).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: _getLevelColor(rating.level).withValues(alpha: 0.4)),
                          ),
                          child: Text(
                            rating.level.toUpperCase(),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                              color: _getLevelColor(rating.level),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${rating.matchesPlayed} Matches',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (rating.badges.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: rating.badges.map((b) => _buildBadgeChip(b)).toList(),
                    ),
                  ],

                  const SizedBox(height: 20),
                  const Divider(height: 1, color: Color(0xFFECEEF1)),
                  const SizedBox(height: 16),

                  _buildRatingBar(label: 'Batting', score: rating.battingRating, color: const Color(0xFF2E7D32)),
                  const SizedBox(height: 12),
                  _buildRatingBar(label: 'Bowling', score: rating.bowlingRating, color: const Color(0xFF1976D2)),
                  const SizedBox(height: 12),
                  _buildRatingBar(label: 'Fielding', score: rating.fieldingRating, color: const Color(0xFFE65100)),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildToggleBtn({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.lightTextSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildBadgeChip(String badge) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFFD54F)),
      ),
      child: Text(
        badge,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF795548),
        ),
      ),
    );
  }

  Widget _buildRatingBar({
    required String label,
    required int score,
    required Color color,
  }) {
    final pct = (score / 100.0).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.lightTextPrimary,
              ),
            ),
            Text(
              '$score',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct,
            backgroundColor: const Color(0xFFECEEF1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  Color _getLevelColor(String level) {
    switch (level.toLowerCase()) {
      case 'legend':
        return const Color(0xFFD32F2F);
      case 'elite':
        return const Color(0xFF8E24AA);
      case 'senior':
        return const Color(0xFF1976D2);
      case 'aspirant':
        return const Color(0xFF2E7D32);
      case 'active':
        return const Color(0xFF0288D1);
      default:
        return const Color(0xFF757575);
    }
  }
}
