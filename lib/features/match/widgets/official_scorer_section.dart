import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/colors.dart';
import '../../../providers/profile_provider.dart';
import '../../teams/providers/teams_provider.dart';
import '../match_setup_screen.dart';
import 'match_role_card.dart';

/// Official Scorer selection card.
///
/// Moved from Opening Lineup to the Toss screen. Uses the same [MatchRoleCard]
/// widget and the same squad-selection flow (single selection + signed-up only)
/// so scorer assignment has a single implementation.
class OfficialScorerSection extends ConsumerWidget {
  final MatchSetupData setupData;
  final TeamMember? scorer;
  final String teamName;
  final ValueChanged<TeamMember> onChanged;

  const OfficialScorerSection({
    super.key,
    required this.setupData,
    required this.scorer,
    required this.teamName,
    required this.onChanged,
  });

  Future<void> _selectScorer(BuildContext context, WidgetRef ref) async {
    final profile = ref.read(profileProvider);

    // If the player is playing without signing in, they can assign themselves
    // but do not have the option to assign / handover to other players.
    if (!profile.isLoggedIn || profile.id.isEmpty) {
      onChanged(
        TeamMember(
          id: 'scorer_myself',
          profileId: 'scorer_myself',
          name: profile.name.isNotEmpty ? profile.name : 'Scorer (Myself)',
          roles: const ['Official Scorer'],
        ),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Guest scorers are set to "Myself". Please sign in to assign other official scorers.',
          ),
          backgroundColor: AppColors.primary,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    if (setupData.isQuickMatch) {
      final selectedPlayer = await context.push<TeamMember?>(
        '/team-squad',
        extra: {
          'teamId': '', // Not used for Quick Match
          'readOnly': false,
          'singleSelectionMode': true,
          'setupData': setupData,
          'teamType': teamName,
          'signedUpOnly': true,
        },
      );

      if (selectedPlayer != null) {
        onChanged(selectedPlayer);
      }
      return;
    }

    final teams = ref.read(teamsProvider).value ?? [];

    final team = teams.firstWhere(
      (t) => t.name == teamName,
      orElse: () => TeamData(
        id: '',
        name: '',
        location: '',
        dateActive: DateTime.now(),
        members: [],
      ),
    );

    if (team.id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Team "$teamName" not found in database.'),
          backgroundColor: AppColors.primary,
        ),
      );
      return;
    }

    final selectedPlayer = await context.push<TeamMember?>(
      '/team-squad',
      extra: {
        'teamId': team.id,
        'readOnly': false,
        'singleSelectionMode': true,
        'signedUpOnly': true,
      },
    );

    if (selectedPlayer != null) {
      onChanged(selectedPlayer);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: 160,
      height: 188,
      child: MatchRoleCard(
        title: 'OFFICIAL SCORER',
        icon: Icons.description,
        player: scorer,
        onSelect: () => _selectScorer(context, ref),
      ),
    );
  }
}
