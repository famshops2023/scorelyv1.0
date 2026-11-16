import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scorely/features/match/match_setup_screen.dart';
import 'package:scorely/features/match/opening_lineup_screen.dart';
import 'package:scorely/features/match/toss_screen.dart';
import 'package:scorely/features/match/widgets/official_scorer_section.dart';
import 'package:scorely/features/teams/providers/teams_provider.dart';
import 'package:scorely/models/player_setup.dart';
import 'package:scorely/models/user_profile.dart';
import 'package:scorely/providers/profile_provider.dart';

class _TestProfileNotifier extends ProfileNotifier {
  _TestProfileNotifier(this._profile);

  final UserProfile _profile;

  @override
  UserProfile build() => _profile;
}

class _FakeTeamsNotifier extends TeamsNotifier {
  @override
  Future<List<TeamData>> build() async => <TeamData>[];
}

MatchSetupData _setupData() => MatchSetupData(
  teamAName: 'Team A',
  teamBName: 'Team B',
  teamAPlayers: const <PlayerSetupData>[],
  teamBPlayers: const <PlayerSetupData>[],
  overs: 20,
  tossWonBy: 'Team A',
  maxOversPerBowler: 4,
  powerplayOvers: 6,
  battingFirstTeam: 'Team A',
  matchType: 'Turf',
  ballType: 'Leather',
  venue: 'Local Ground',
  matchDate: DateTime(2026, 1, 1),
  isQuickMatch: true,
);

Widget _section({
  required UserProfile profile,
  required TeamMember? scorer,
  required ValueChanged<TeamMember> onChanged,
}) {
  return ProviderScope(
    overrides: [
      profileProvider.overrideWith(() => _TestProfileNotifier(profile)),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: Center(
          child: OfficialScorerSection(
            setupData: _setupData(),
            scorer: scorer,
            teamName: 'Team A',
            onChanged: onChanged,
          ),
        ),
      ),
    ),
  );
}

class _PopWithMember extends StatefulWidget {
  const _PopWithMember({required this.member});

  final TeamMember member;

  @override
  State<_PopWithMember> createState() => _PopWithMemberState();
}

class _PopWithMemberState extends State<_PopWithMember> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.pop(widget.member);
      }
    });
  }

  @override
  Widget build(BuildContext context) => const Scaffold(body: SizedBox.shrink());
}

void main() {
  setUpAll(() {
    // Keep widget tests hermetic: never fetch fonts from the network.
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('official scorer starts empty and shows SELECT', (tester) async {
    await tester.pumpWidget(
      _section(
        profile: UserProfile(name: 'Owner', isLoggedIn: true),
        scorer: null,
        onChanged: (_) {},
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('OFFICIAL SCORER'), findsOneWidget);
    expect(find.text('SELECT'), findsOneWidget);
  });

  testWidgets('guest self-assignment sets scorer to Myself', (tester) async {
    TeamMember? selected;

    await tester.pumpWidget(
      _section(
        profile: UserProfile(name: 'Guest Player'),
        scorer: null,
        onChanged: (member) => selected = member,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('SELECT'));
    await tester.pump();

    expect(selected, isNotNull);
    expect(selected!.name, 'Guest Player');
    expect(selected!.id, 'scorer_myself');
    expect(selected!.profileId, 'scorer_myself');
    expect(selected!.roles, contains('Official Scorer'));
    expect(
      find.textContaining('Guest scorers are set to "Myself"'),
      findsOneWidget,
    );
  });

  testWidgets('signed-in user assigns another registered player', (
    tester,
  ) async {
    TeamMember? selected;
    Object? squadExtra;
    final target = TeamMember(
      id: 'member-2',
      profileId: 'profile-2',
      name: 'Alice',
      roles: const ['Player'],
    );

    Widget buildSection(StateSetter setState) {
      return OfficialScorerSection(
        setupData: _setupData(),
        scorer: selected,
        teamName: 'Team A',
        onChanged: (member) => setState(() => selected = member),
      );
    }

    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => Scaffold(
            body: Center(
              child: StatefulBuilder(builder: (context, setState) {
                return buildSection(setState);
              }),
            ),
          ),
        ),
        GoRoute(
          path: '/team-squad',
          builder: (context, state) {
            squadExtra = state.extra;
            return _PopWithMember(member: target);
          },
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profileProvider.overrideWith(
            () => _TestProfileNotifier(
              UserProfile(id: 'profile-1', name: 'Owner', isLoggedIn: true),
            ),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('SELECT'));
    await tester.pumpAndSettle();

    expect(selected, isNotNull);
    expect(selected!.name, 'Alice');
    expect(selected!.profileId, 'profile-2');
    expect(find.text('Alice'), findsOneWidget);
    expect(find.text('CHANGE'), findsOneWidget);
    expect(find.text('SELECT'), findsNothing);

    final extra = squadExtra as Map;
    expect(extra['singleSelectionMode'], isTrue);
    expect(extra['signedUpOnly'], isTrue);
  });

  testWidgets('Toss shows the scorer card below DECIDED TO on a small screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profileProvider.overrideWith(
            () => _TestProfileNotifier(UserProfile()),
          ),
        ],
        child: MaterialApp(home: TossScreen(setupData: _setupData())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('DECIDED TO'), findsOneWidget);
    expect(find.text('OFFICIAL SCORER'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('OFFICIAL SCORER')).dy,
      greaterThan(tester.getTopLeft(find.text('DECIDED TO')).dy),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Toss blocks NEXT until an official scorer is selected', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profileProvider.overrideWith(
            () => _TestProfileNotifier(UserProfile()),
          ),
        ],
        child: MaterialApp(home: TossScreen(setupData: _setupData())),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('NEXT'));
    await tester.pumpAndSettle();

    expect(find.text('OFFICIAL SCORER REQUIRED'), findsOneWidget);
    expect(
      find.text('Please select the official scorer to continue.'),
      findsOneWidget,
    );

    await tester.tap(find.text('GOT IT'));
    await tester.pumpAndSettle();

    expect(find.text('OFFICIAL SCORER REQUIRED'), findsNothing);
    // Still on Toss — scorer selection was never made.
    expect(find.text('DECIDED TO'), findsOneWidget);
  });

  testWidgets('Opening Lineup has no editable scorer section in either innings', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    for (final secondInnings in [false, true]) {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            profileProvider.overrideWith(
              () => _TestProfileNotifier(
                UserProfile(id: 'profile-1', name: 'Owner', isLoggedIn: true),
              ),
            ),
            teamsProvider.overrideWith(_FakeTeamsNotifier.new),
          ],
          child: MaterialApp(
            home: OpeningLineupScreen(
              setupData: _setupData(),
              isSecondInnings: secondInnings,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('OFFICIAL SCORER'), findsNothing);
      expect(find.text('OPENING BAT 1'), findsOneWidget);
      expect(find.text('OPENING BAT 2'), findsOneWidget);
      expect(find.text('OPENING BOWLER'), findsOneWidget);
      expect(find.text('WICKETKEEPER'), findsOneWidget);
    }
  });
}
