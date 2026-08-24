import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/splash/splash_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/home/home_screen.dart';
import '../features/match/create_team_screen.dart';
import '../features/match/match_setup_screen.dart';
import '../features/match/match_details_screen.dart';
import '../features/match/opening_lineup_screen.dart';
import '../features/scoring/scoring_screen.dart';
import '../features/scoring/innings_break_screen.dart';
import '../features/export/export_screen.dart';
import '../features/history/history_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/settings/info_screen.dart';
import '../features/match/match_result_screen.dart';
import '../features/match/match_stat_screen.dart';
import '../features/profile/my_profile_screen.dart';
import '../features/profile/edit_profile_screen.dart';
import '../features/profile/login_screen.dart';
import '../features/teams/teams_screen.dart';
import '../features/teams/edit_squad_screen.dart';
import '../features/teams/team_squad_screen.dart';
import '../features/match/live_match_screen.dart';
import '../models/live_match_data.dart';
import '../models/match_result_data.dart';
import '../features/match/toss_screen.dart';
import '../services/database.dart';
import '../features/home/scorely_shell.dart';

import '../features/teams/join_team_handler.dart';
import '../features/discovery/discovery_screen.dart';
import '../features/teams/team_qr_scanner_screen.dart';
import '../features/performance/performance_screen.dart';

final goRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/joinTeam',
      builder: (context, state) {
        final teamId = state.uri.queryParameters['teamId'] ?? '';
        return JoinTeamHandler(teamId: teamId);
      },
    ),
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    
    // StatefulShellRoute holds our main shell layout
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return ScorelyShell(navigationShell: navigationShell);
      },
      branches: [
        // Branch 0: Home
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => const HomeScreen(),
            ),
          ],
        ),
        // Branch 1: Teams
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/teams',
              builder: (context, state) => const TeamsScreen(isSelectionMode: false),
            ),
          ],
        ),
        // Branch 2: History
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/history',
              builder: (context, state) => const HistoryScreen(),
            ),
          ],
        ),
        // Branch 3: Profile
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/profile',
              builder: (context, state) => const MyProfileScreen(),
            ),
          ],
        ),
      ],
    ),

    // Non-shell routes (rendered full-screen, without bottom navigation)
    GoRoute(
      path: '/discovery',
      builder: (context, state) {
        final isSelectionMode = state.extra as bool? ?? false;
        return DiscoveryScreen(isSelectionMode: isSelectionMode);
      },
    ),
    GoRoute(
      path: '/match-stats',
      builder: (context, state) {
        if (state.extra is Map<String, dynamic>) {
          final data = state.extra as Map<String, dynamic>;
          return MatchStatScreen(
            matchId: data['matchId'] as int?,
            initialIndex: data['initialIndex'] as int?,
          );
        }
        final matchId = state.extra as int?;
        return MatchStatScreen(matchId: matchId);
      },
    ),
    GoRoute(
      path: '/teams-select',
      builder: (context, state) => const TeamsScreen(isSelectionMode: true),
    ),
    GoRoute(
      path: '/discovery-select',
      builder: (context, state) => const DiscoveryScreen(isSelectionMode: true),
    ),
    GoRoute(
      path: '/edit-squad',
      builder: (context, state) {
        final teamId = (state.extra as String?) ?? '';
        return EditSquadScreen(teamId: teamId);
      },
    ),
    GoRoute(
      path: '/team-squad',
      builder: (context, state) {
        if (state.extra is Map<String, dynamic>) {
          final data = state.extra as Map<String, dynamic>;
          return TeamSquadScreen(
            teamId: data['teamId'] as String,
            readOnly: data['readOnly'] as bool? ?? false,
            singleSelectionMode: data['singleSelectionMode'] as bool? ?? false,
            setupData: data['setupData'] as MatchSetupData?,
            isSelectingPlayingXi: data['isSelectingPlayingXi'] as bool? ?? false,
            teamType: data['teamType'] as String?,
            excludedPlayerNames: (data['excludedPlayerNames'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
          );
        }
        final teamId = state.extra as String;
        return TeamSquadScreen(teamId: teamId);
      },
    ),
    GoRoute(
      path: '/create-team',
      builder: (context, state) {
        final data = state.extra as Map<String, dynamic>?;
        return CreateTeamScreen(
          isQuickMatch: data?['isQuickMatch'] as bool? ?? false,
          initialData: data,
        );
      },
    ),
    GoRoute(
      path: '/match-setup',
      builder: (context, state) {
        final data = state.extra as Map<String, dynamic>?;
        return MatchSetupScreen(initialData: data);
      },
    ),
    GoRoute(
      path: '/match-details',
      builder: (context, state) {
        if (state.extra is! MatchSetupData) {
          return Scaffold(
            appBar: AppBar(title: const Text('Error')),
            body: Center(
              child: Text(
                'Expected MatchSetupData, got: ${state.extra.runtimeType}',
                style: const TextStyle(color: Colors.red, fontSize: 18),
              ),
            ),
          );
        }
        final data = state.extra as MatchSetupData;
        return MatchDetailsScreen(setupData: data);
      },
    ),
    GoRoute(
      path: '/toss',
      builder: (context, state) {
        if (state.extra is! MatchSetupData) {
          return Scaffold(
            appBar: AppBar(title: const Text('Error')),
            body: Center(
              child: Text(
                'Expected MatchSetupData, got: ${state.extra.runtimeType}',
                style: const TextStyle(color: Colors.red, fontSize: 18),
              ),
            ),
          );
        }
        final data = state.extra as MatchSetupData;
        return TossScreen(setupData: data);
      },
    ),
    GoRoute(
      path: '/opening-lineup',
      builder: (context, state) {
        if (state.extra is Map<String, dynamic>) {
          final data = state.extra as Map<String, dynamic>;
          return OpeningLineupScreen(
            setupData: data['setupData'] as MatchSetupData,
            isSecondInnings: data['isSecondInnings'] as bool? ?? false,
          );
        }
        if (state.extra is! MatchSetupData) {
          return Scaffold(
            appBar: AppBar(title: const Text('Error')),
            body: Center(
              child: Text(
                'Expected MatchSetupData, got: ${state.extra.runtimeType}',
                style: const TextStyle(color: Colors.red, fontSize: 18),
              ),
            ),
          );
        }
        final data = state.extra as MatchSetupData;
        return OpeningLineupScreen(setupData: data);
      },
    ),
    GoRoute(
      path: '/scoring',
      builder: (context, state) {
        if (state.extra is Map<String, dynamic>) {
          final data = state.extra as Map<String, dynamic>;
          return ScoringScreen(
            setupData: data['setupData'] as MatchSetupData?,
            lineup: data['lineup'] as OpeningLineupResult?,
          );
        }
        final data = state.extra as MatchSetupData?;
        return ScoringScreen(setupData: data);
      },
    ),
    GoRoute(
      path: '/live-match',
      builder: (context, state) {
        final matchData = state.extra as LiveMatchData;
        return LiveMatchScreen(matchData: matchData);
      },
    ),
    GoRoute(
      path: '/innings-break',
      builder: (context, state) {
        if (state.extra is! InningsSummaryData) {
          return Scaffold(
            appBar: AppBar(title: const Text('Error')),
            body: Center(
              child: Text(
                'Expected InningsSummaryData, got: ${state.extra.runtimeType}',
                style: const TextStyle(color: Colors.red, fontSize: 18),
              ),
            ),
          );
        }
        final data = state.extra as InningsSummaryData;
        return InningsBreakScreen(data: data);
      },
    ),
    GoRoute(
      path: '/export',
      builder: (context, state) {
        final match = state.extra as CricketMatch;
        return ExportScreen(match: match);
      },
    ),
    GoRoute(
      path: '/match-result',
      redirect: (context, state) {
        if (state.extra == null || state.extra is! MatchResultData) {
          return '/home';
        }
        return null;
      },
      builder: (context, state) {
        final data = state.extra as MatchResultData;
        return MatchResultScreen(resultData: data);
      },
    ),
    GoRoute(
      path: '/edit-profile',
      builder: (context, state) => const EditProfileScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/team-scanner',
      builder: (context, state) => const TeamQRScannerScreen(),
    ),
    GoRoute(
      path: '/performance',
      builder: (context, state) => const PerformanceScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/info',
      builder: (context, state) {
        final initialIndex = state.extra as int? ?? 0;
        return InfoScreen(initialIndex: initialIndex);
      },
    ),
  ],
);
