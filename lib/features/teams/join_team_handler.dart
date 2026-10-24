import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

import '../../core/config/insforge_config.dart';
import 'package:scorely/core/theme/colors.dart';
import '../../providers/profile_provider.dart';
import 'providers/teams_provider.dart';

class JoinTeamHandler extends ConsumerStatefulWidget {
  final String teamId;

  const JoinTeamHandler({super.key, required this.teamId});

  @override
  ConsumerState<JoinTeamHandler> createState() => _JoinTeamHandlerState();
}

class _JoinTeamHandlerState extends ConsumerState<JoinTeamHandler> {
  bool _isJoining = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthAndJoin();
    });
  }

  void _checkAuthAndJoin() {
    final profile = ref.read(profileProvider);
    if (profile.isLoggedIn) {
      _joinTeam();
    }
  }

  Future<void> _joinTeam() async {
    setState(() {
      _isJoining = true;
      _errorMessage = null;
    });

    try {
      if (widget.teamId.isEmpty) {
        throw Exception('Invalid team link.');
      }

      final profile = ref.read(profileProvider);
      final userId = profile.id.isNotEmpty ? profile.id : 'local_user';
      final userName = profile.name.isNotEmpty ? profile.name : 'Player';

      // 1. Call InsForge backend API if available
      try {
        final url = Uri.parse(
          '${InsforgeConfig.baseUrl}/functions/v1/joinTeam',
        );
        await http.post(
          url,
          headers: InsforgeConfig.headers,
          body: jsonEncode({'team_id': widget.teamId, 'profile_id': userId}),
        );
      } catch (_) {
        // Fallback to local teamsProvider update if offline
      }

      // 2. Update local team members in teamsProvider
      final teams = ref.read(teamsProvider).value ?? [];
      final targetTeam = teams.firstWhere(
        (t) => t.id == widget.teamId || t.teamCode == widget.teamId,
        orElse: () => TeamData(
          id: widget.teamId,
          name: 'Squad',
          location: 'Local',
          dateActive: DateTime.now(),
          members: [],
        ),
      );

      final alreadyMember = targetTeam.members.any(
        (m) => m.id == userId || (m.profileId != null && m.profileId == userId),
      );

      if (!alreadyMember) {
        final updatedMembers = [
          ...targetTeam.members,
          TeamMember(
            id: userId,
            profileId: userId,
            name: userName,
            roles: ['BAT'],
          ),
        ];
        final updatedTeam = targetTeam.copyWith(members: updatedMembers);
        ref.read(teamsProvider.notifier).updateTeam(updatedTeam);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Successfully joined squad!',
              style: GoogleFonts.inter(color: Colors.white),
            ),
            backgroundColor: AppColors.successDark,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
        context.go('/teams');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isJoining = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  void _promptSignIn() {
    context.push('/login').then((_) {
      if (mounted) {
        _checkAuthAndJoin();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);

    if (!profile.isLoggedIn) {
      return Scaffold(
        backgroundColor: AppColors.lightBg,
        appBar: AppBar(
          backgroundColor: AppColors.darkSurface,
          elevation: 0,
          title: Text(
            'JOIN TEAM',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 1.0,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => context.go('/home'),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(28.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFDEBED),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.groups_2_rounded,
                    color: AppColors.primary,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Sign In Required to Join',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Please sign in or create a Scorely account to join this squad and sync your player stats.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.lightTextSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _promptSignIn,
                    icon: const Icon(Icons.login, size: 20, color: Colors.white),
                    label: Text(
                      'SIGN IN / CREATE ACCOUNT',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => context.go('/home'),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.inter(
                      color: AppColors.lightTextSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isJoining) ...[
              const CircularProgressIndicator(color: AppColors.primary),
              const SizedBox(height: 16),
              Text(
                'Joining team...',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onBackground,
                ),
              ),
            ] else if (_errorMessage != null) ...[
              const Icon(Icons.error_outline, color: AppColors.primary, size: 48),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: GoogleFonts.inter(fontSize: 14, color: AppColors.onBackground),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _joinTeam,
                child: const Text('Try Again'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
