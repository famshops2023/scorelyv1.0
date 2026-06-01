import 'package:flutter/material.dart';

enum PlayerRole {
  batsman,
  bowler,
  allRounder,
  wicketKeeper,
}

extension PlayerRoleExtension on PlayerRole {
  String get displayName {
    switch (this) {
      case PlayerRole.batsman:
        return 'Batsman';
      case PlayerRole.bowler:
        return 'Bowler';
      case PlayerRole.allRounder:
        return 'All-Rounder';
      case PlayerRole.wicketKeeper:
        return 'Wicket Keeper';
    }
  }

  IconData get icon {
    switch (this) {
      case PlayerRole.batsman:
        return Icons.sports_cricket;
      case PlayerRole.bowler:
        return Icons.sports_baseball; // closest to cricket ball in standard icons
      case PlayerRole.allRounder:
        return Icons.star_border;
      case PlayerRole.wicketKeeper:
        return Icons.pan_tool; // representing gloves
    }
  }
}

class PlayerSetupData {
  final String name;
  final PlayerRole role;
  final bool isCaptain;

  const PlayerSetupData({
    required this.name,
    this.role = PlayerRole.batsman,
    this.isCaptain = false,
  });

  PlayerSetupData copyWith({
    String? name,
    PlayerRole? role,
    bool? isCaptain,
  }) {
    return PlayerSetupData(
      name: name ?? this.name,
      role: role ?? this.role,
      isCaptain: isCaptain ?? this.isCaptain,
    );
  }
}
