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
import '../models/match_result_data.dart';
import '../services/database.dart';

final goRouter = GoRouter(
  initialLocation: '/',
  routes: [
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
        final data = state.extra as MatchSetupData;
        return MatchDetailsScreen(setupData: data);
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
  ],
);
