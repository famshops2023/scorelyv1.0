/// Represents a player's Scorely Pro Rating for a specific match type (TURF or GROUND).
class PlayerProRating {
  final String playerUserId;
  final String matchType; // 'turf' or 'ground'
  final int rating; // 0 to 1000 clamped
  final String level; // Novice, Active, Aspirant, Senior, Elite, Legend
  final int matchesPlayed;
  final int runs;
  final int wickets;
  final int battingRating; // 0 to 100
  final int bowlingRating; // 0 to 100
  final int fieldingRating; // 0 to 100
  final int matchImpactRating; // 0 to 100
  final List<String> badges;
  final String? topBadge;
  final DateTime? updatedAt;
  final String calculationVersion;

  const PlayerProRating({
    required this.playerUserId,
    required this.matchType,
    this.rating = 0,
    this.level = 'Novice',
    this.matchesPlayed = 0,
    this.runs = 0,
    this.wickets = 0,
    this.battingRating = 0,
    this.bowlingRating = 0,
    this.fieldingRating = 0,
    this.matchImpactRating = 0,
    this.badges = const [],
    this.topBadge,
    this.updatedAt,
    this.calculationVersion = 'v1',
  });

  bool get hasRating => matchesPlayed > 0;

  factory PlayerProRating.unrated({
    required String playerUserId,
    required String matchType,
  }) {
    return PlayerProRating(
      playerUserId: playerUserId,
      matchType: matchType,
      rating: 0,
      level: 'Novice',
      matchesPlayed: 0,
    );
  }

  factory PlayerProRating.fromJson(Map<String, dynamic> json) {
    final rawBadges = json['badges'];
    List<String> parsedBadges = [];
    if (rawBadges is List) {
      parsedBadges = rawBadges.map((e) => e.toString()).toList();
    }

    return PlayerProRating(
      playerUserId: json['player_user_id']?.toString() ?? '',
      matchType: json['match_type']?.toString().toLowerCase() ?? 'turf',
      rating: (json['rating'] as num?)?.toInt() ?? 0,
      level: json['level']?.toString() ?? getPlayerLevel((json['rating'] as num?)?.toInt() ?? 0),
      matchesPlayed: (json['matches_played'] as num?)?.toInt() ?? 0,
      runs: (json['runs'] as num?)?.toInt() ?? 0,
      wickets: (json['wickets'] as num?)?.toInt() ?? 0,
      battingRating: (json['batting_rating'] as num?)?.toInt() ?? 0,
      bowlingRating: (json['bowling_rating'] as num?)?.toInt() ?? 0,
      fieldingRating: (json['fielding_rating'] as num?)?.toInt() ?? 0,
      matchImpactRating: (json['match_impact_rating'] as num?)?.toInt() ?? 0,
      badges: parsedBadges,
      topBadge: json['top_badge']?.toString() ?? (parsedBadges.isNotEmpty ? parsedBadges.first : null),
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'].toString()) : null,
      calculationVersion: json['calculation_version']?.toString() ?? 'v1',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'player_user_id': playerUserId,
      'match_type': matchType,
      'rating': rating,
      'level': level,
      'matches_played': matchesPlayed,
      'runs': runs,
      'wickets': wickets,
      'batting_rating': battingRating,
      'bowling_rating': bowlingRating,
      'fielding_rating': fieldingRating,
      'match_impact_rating': matchImpactRating,
      'badges': badges,
      'top_badge': topBadge,
      'calculation_version': calculationVersion,
      'updated_at': updatedAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
    };
  }

  static String getPlayerLevel(int rating) {
    if (rating >= 850) return 'Legend';
    if (rating >= 700) return 'Elite';
    if (rating >= 550) return 'Senior';
    if (rating >= 400) return 'Aspirant';
    if (rating >= 200) return 'Active';
    return 'Novice';
  }
}

/// Audit history entry for rating changes after a completed match
class PlayerRatingHistoryEntry {
  final String id;
  final String playerUserId;
  final String matchId;
  final String matchType;
  final int previousRating;
  final int ratingChange;
  final int newRating;
  final String calculationVersion;
  final DateTime createdAt;

  const PlayerRatingHistoryEntry({
    required this.id,
    required this.playerUserId,
    required this.matchId,
    required this.matchType,
    required this.previousRating,
    required this.ratingChange,
    required this.newRating,
    this.calculationVersion = 'v1',
    required this.createdAt,
  });

  factory PlayerRatingHistoryEntry.fromJson(Map<String, dynamic> json) {
    return PlayerRatingHistoryEntry(
      id: json['id']?.toString() ?? '',
      playerUserId: json['player_user_id']?.toString() ?? '',
      matchId: json['match_id']?.toString() ?? '',
      matchType: json['match_type']?.toString() ?? 'turf',
      previousRating: (json['previous_rating'] as num?)?.toInt() ?? 0,
      ratingChange: (json['rating_change'] as num?)?.toInt() ?? 0,
      newRating: (json['new_rating'] as num?)?.toInt() ?? 0,
      calculationVersion: json['calculation_version']?.toString() ?? 'v1',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'player_user_id': playerUserId,
      'match_id': matchId,
      'match_type': matchType,
      'previous_rating': previousRating,
      'rating_change': ratingChange,
      'new_rating': newRating,
      'calculation_version': calculationVersion,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
