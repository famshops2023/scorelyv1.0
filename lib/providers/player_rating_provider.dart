import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/player_pro_rating.dart';
import '../models/user_profile.dart';
import '../services/ratings/player_rating_repository.dart';
import 'profile_provider.dart';

/// Active match type selected in the My Profile Pro Rating section ('turf' or 'ground')
class ProfileRatingCategoryNotifier extends Notifier<String> {
  @override
  String build() => 'turf';

  void selectCategory(String category) => state = category.toLowerCase();
}

final profileRatingCategoryProvider =
    NotifierProvider<ProfileRatingCategoryNotifier, String>(
  ProfileRatingCategoryNotifier.new,
);

/// Rating provider for the signed-in user for a specific match type ('turf' or 'ground')
final userProRatingProvider =
    FutureProvider.family<PlayerProRating, String>((ref, matchType) async {
  final UserProfile profile = ref.watch(profileProvider);
  if (!profile.isLoggedIn || profile.id.isEmpty) {
    return PlayerProRating.unrated(
      playerUserId: profile.id,
      matchType: matchType,
    );
  }

  return await PlayerRatingRepository.getPlayerRating(
    playerUserId: profile.id,
    matchType: matchType,
    playerName: profile.name,
    playerRole: profile.playingRole.isNotEmpty ? profile.playingRole : profile.role,
  );
});

/// Batch ratings provider for a list of player IDs (e.g. for Discovery and Squad)
final batchPlayerRatingsProvider =
    FutureProvider.family<Map<String, Map<String, PlayerProRating>>, List<String>>(
  (ref, userIds) async {
    if (userIds.isEmpty) return {};
    return await PlayerRatingRepository.batchFetchRatings(userIds);
  },
);
