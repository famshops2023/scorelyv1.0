import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:scorely/features/match/match_setup_screen.dart';
import 'package:scorely/features/match/providers/quick_match_storage.dart';
import 'package:scorely/models/match_status.dart';
import 'package:scorely/services/duplicate_match_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Duplicate Match Detection & Storage Tests', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
    });

    test('MatchSetupData correctly serializes and deserializes creationRequestId', () {
      final now = DateTime.now();
      final setup = MatchSetupData(
        id: 'match-123',
        creationRequestId: 'req-abc-456',
        teamAName: 'Warriors',
        teamBName: 'Titans',
        teamAPlayers: [],
        teamBPlayers: [],
        overs: 20,
        tossWonBy: 'Warriors',
        maxOversPerBowler: 4,
        powerplayOvers: 6,
        battingFirstTeam: 'Warriors',
        matchType: 'T20',
        ballType: 'Leather',
        venue: 'Eden Gardens',
        matchDate: now,
      );

      final json = setup.toJson();
      expect(json['creationRequestId'], equals('req-abc-456'));

      final reconstructed = MatchSetupData.fromJson(json);
      expect(reconstructed.creationRequestId, equals('req-abc-456'));
      expect(reconstructed.id, equals('match-123'));
      expect(reconstructed.teamAName, equals('Warriors'));
      expect(reconstructed.teamBName, equals('Titans'));
    });

    test('DuplicateMatchService normalizeTeamName normalizes case and whitespace', () {
      expect(
        DuplicateMatchService.normalizeTeamName('  Chennai  Super   Kings '),
        equals('chennai super kings'),
      );
      expect(
        DuplicateMatchService.normalizeTeamName('MUMBAI INDIANS'),
        equals('mumbai indians'),
      );
    });

    test('QuickMatchStorage does NOT insert duplicates when same match ID or creationRequestId is saved', () async {
      final now = DateTime.now();
      final match1 = MatchSetupData(
        id: 'qm-001',
        creationRequestId: 'req-001',
        teamAName: 'Team Alpha',
        teamBName: 'Team Bravo',
        teamAPlayers: [],
        teamBPlayers: [],
        overs: 10,
        tossWonBy: '',
        maxOversPerBowler: 2,
        powerplayOvers: 3,
        battingFirstTeam: '',
        matchType: 'Box/Turf',
        ballType: 'Tennis',
        venue: 'Local Turf',
        matchDate: now,
        isQuickMatch: true,
      );

      // Save match first time
      await QuickMatchStorage.saveQuickMatch(match1);

      var last = await QuickMatchStorage.getLastQuickMatch();
      expect(last, isNotNull);
      expect(last!.id, equals('qm-001'));
      expect(last.overs, equals(10));

      // Update match (e.g. user navigated back, changed overs to 12, and proceeded)
      final match1Updated = MatchSetupData.fromJson({
        ...match1.toJson(),
        'overs': 12,
      });
      await QuickMatchStorage.saveQuickMatch(match1Updated);

      // Verify that the record was updated in-place and not duplicated
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString('quick_matches_history');
      expect(jsonStr, isNotNull);

      last = await QuickMatchStorage.getLastQuickMatch();
      expect(last, isNotNull);
      expect(last!.id, equals('qm-001'));
      expect(last.overs, equals(12));
    });

    test('DuplicateMatchService identifies same active session without false duplicate alert', () async {
      final now = DateTime.now();
      final match = MatchSetupData(
        id: 'session-match-id',
        creationRequestId: 'session-req-id',
        teamAName: 'Royal Challengers',
        teamBName: 'Knight Riders',
        teamAPlayers: [],
        teamBPlayers: [],
        overs: 20,
        tossWonBy: '',
        maxOversPerBowler: 4,
        powerplayOvers: 6,
        battingFirstTeam: '',
        matchType: 'T20',
        ballType: 'Leather',
        venue: 'Chinnaswamy Stadium',
        matchDate: now,
        isQuickMatch: true,
      );

      // Save into quick match storage
      await QuickMatchStorage.saveQuickMatch(match);

      // Check with the same session match ID and creation request ID
      final result = await DuplicateMatchService.instance.checkForDuplicate(
        creatorProfileId: 'creator-user-id',
        teamAName: 'Royal Challengers',
        teamBName: 'Knight Riders',
        isQuickMatch: true,
        matchDate: now,
        currentSessionMatchId: 'session-match-id',
        currentCreationRequestId: 'session-req-id',
      );

      // Must be classified as sameSession, NOT duplicateFound!
      expect(result.isSameSession, isTrue);
      expect(result.isDuplicate, isFalse);
    });

    test('DuplicateMatchService detects separate match with same teams as duplicateFound', () async {
      final now = DateTime.now();
      final priorMatch = MatchSetupData(
        id: 'prior-match-id',
        creationRequestId: 'prior-req-id',
        creatorProfileId: 'creator-user-id',
        teamAName: 'Royal Challengers',
        teamBName: 'Knight Riders',
        teamAPlayers: [],
        teamBPlayers: [],
        overs: 20,
        tossWonBy: '',
        maxOversPerBowler: 4,
        powerplayOvers: 6,
        battingFirstTeam: '',
        matchType: 'T20',
        ballType: 'Leather',
        venue: 'Chinnaswamy Stadium',
        matchDate: now,
        isQuickMatch: true,
      );

      // Prior match saved in storage
      await QuickMatchStorage.saveQuickMatch(priorMatch);

      // New match creation session starts with distinct IDs for the same teams
      final result = await DuplicateMatchService.instance.checkForDuplicate(
        creatorProfileId: 'creator-user-id',
        teamAName: 'Royal Challengers',
        teamBName: 'Knight Riders',
        isQuickMatch: true,
        matchDate: now,
        currentSessionMatchId: 'fresh-match-id',
        currentCreationRequestId: 'fresh-req-id',
      );

      // Must be detected as a duplicate candidate so confirmation popup is shown
      expect(result.isDuplicate, isTrue);
      expect(result.existingMatch, isNotNull);
      expect(result.existingMatch!.id, equals('prior-match-id'));
    });

    test('MatchStatus canonicalizes abandoned and MatchSetupData recognizes isAbandoned', () {
      expect(MatchStatus.normalize('abandoned'), equals('abandoned'));
      expect(MatchStatus.isAbandoned('abandoned'), isTrue);
      expect(MatchStatus.isCompleted('abandoned'), isFalse);

      final now = DateTime.now();
      final match = MatchSetupData(
        id: 'ab-123',
        status: MatchStatus.abandoned,
        teamAName: 'Team A',
        teamBName: 'Team B',
        teamAPlayers: [],
        teamBPlayers: [],
        overs: 20,
        tossWonBy: '',
        maxOversPerBowler: 4,
        powerplayOvers: 6,
        battingFirstTeam: '',
        matchType: 'T20',
        ballType: 'Tennis',
        venue: 'Turf',
        matchDate: now,
      );

      expect(match.isAbandoned, isTrue);
      expect(match.isCompleted, isFalse);
    });

    test('QuickMatchStorage.getAllMatches returns all stored matches', () async {
      final now = DateTime.now();
      final match1 = MatchSetupData(
        id: 'qm-all-1',
        teamAName: 'Team 1',
        teamBName: 'Team 2',
        teamAPlayers: [],
        teamBPlayers: [],
        overs: 10,
        tossWonBy: '',
        maxOversPerBowler: 2,
        powerplayOvers: 3,
        battingFirstTeam: '',
        matchType: 'T10',
        ballType: 'Tennis',
        venue: 'Ground',
        matchDate: now,
      );
      final match2 = MatchSetupData(
        id: 'qm-all-2',
        teamAName: 'Team 3',
        teamBName: 'Team 4',
        teamAPlayers: [],
        teamBPlayers: [],
        overs: 10,
        tossWonBy: '',
        maxOversPerBowler: 2,
        powerplayOvers: 3,
        battingFirstTeam: '',
        matchType: 'T10',
        ballType: 'Tennis',
        venue: 'Ground',
        matchDate: now,
      );

      await QuickMatchStorage.saveQuickMatch(match1);
      await QuickMatchStorage.saveQuickMatch(match2);

      final all = await QuickMatchStorage.getAllMatches();
      expect(all.length, equals(2));
      expect(all.any((m) => m.id == 'qm-all-1'), isTrue);
      expect(all.any((m) => m.id == 'qm-all-2'), isTrue);
    });
  });
}

