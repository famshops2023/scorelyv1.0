import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/splash/splash_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/home/home_screen.dart';
import '../features/match/create_team_screen.dart';
import '../features/match/match_setup_screen.dart';
import '../features/match/match_details_screen.dart';
import '../features/scoring/scoring_screen.dart';
import '../features/export/export_screen.dart';
import '../features/history/history_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/match/match_result_screen.dart';
import '../features/match/match_stat_screen.dart';
import '../features/profile/my_profile_screen.dart';
import '../features/profile/edit_profile_screen.dart';
import '../features/teams/teams_screen.dart';
import '../features/teams/edit_squad_screen.dart';
import '../features/teams/team_squad_screen.dart';
import '../features/match/live_match_screen.dart';
import '../models/match_result_data.dart';
import '../features/match/toss_screen.dart';
import '../services/database.dart';

import '../features/teams/join_team_handler.dart';
import '../features/discovery/discovery_screen.dart';

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
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/teams',
      builder: (context, state) {
        final isSelectionMode = state.extra as bool? ?? false;
        return TeamsScreen(isSelectionMode: isSelectionMode);
      },
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
          );
        }
        final teamId = state.extra as String;
        return TeamSquadScreen(teamId: teamId);
      },
    ),
    GoRoute(
      path: '/create-team',
      builder: (context, state) => const CreateTeamScreen(),
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
      path: '/scoring',
      builder: (context, state) {
        final data = state.extra as MatchSetupData?;
        return ScoringScreen(setupData: data);
      },
    ),
    GoRoute(
      path: '/live-match',
      builder: (context, state) => const LiveMatchScreen(),
    ),

    GoRoute(
      path: '/export',
      builder: (context, state) {
        final match = state.extra as CricketMatch;
        return ExportScreen(match: match);
      },
    ),
    GoRoute(
      path: '/history',
      builder: (context, state) => const HistoryScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
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
      path: '/match-stats',
      builder: (context, state) {
        final matchId = state.extra as int?;
        return MatchStatScreen(matchId: matchId);
      },
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const MyProfileScreen(),
    ),
    GoRoute(
      path: '/edit-profile',
      builder: (context, state) => const EditProfileScreen(),
    ),
    GoRoute(
      path: '/discovery',
      builder: (context, state) {
        final isSelectionMode = state.extra as bool? ?? false;
        return DiscoveryScreen(isSelectionMode: isSelectionMode);
      },
    ),
  ],
);
