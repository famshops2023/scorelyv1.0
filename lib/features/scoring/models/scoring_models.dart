import 'package:scorely/models/match_stats.dart';

export 'package:scorely/models/match_stats.dart';

class LocalBallEvent {
  final int runs;
  final bool isWicket;
  final String? wicketType;
  final bool isExtra;
  final String? extraType;
  final String batterName;
  final String bowlerName;

  LocalBallEvent({
    required this.runs,
    required this.isWicket,
    this.wicketType,
    required this.isExtra,
    this.extraType,
    required this.batterName,
    required this.bowlerName,
  });

  Map<String, dynamic> toJson() => {
        'runs': runs,
        'isWicket': isWicket,
        'wicketType': wicketType,
        'isExtra': isExtra,
        'extraType': extraType,
        'batterName': batterName,
        'bowlerName': bowlerName,
      };

  factory LocalBallEvent.fromJson(Map<String, dynamic> json) => LocalBallEvent(
        runs: json['runs'] as int? ?? 0,
        isWicket: json['isWicket'] as bool? ?? false,
        wicketType: json['wicketType'] as String?,
        isExtra: json['isExtra'] as bool? ?? false,
        extraType: json['extraType'] as String?,
        batterName: json['batterName'] as String? ?? '',
        bowlerName: json['bowlerName'] as String? ?? '',
      );
}

// --- Local Data Models for Stats & Undo Stack ---

class MatchState {
  final int runs;
  final int wickets;
  final int ballsBowled;
  final int extraRuns;
  final List<String> thisOver;
  final String striker;
  final String nonStriker;
  final String currentBowler;
  final Map<String, BatterStats> batterStats;
  final Map<String, BowlerStats> bowlerStats;
  final List<String> wicketsHistory;
  final List<String> batterOrder;
  final int nextBatterIndex;
  final List<LocalBallEvent> localBalls;

  MatchState({
    required this.runs,
    required this.wickets,
    required this.ballsBowled,
    required this.extraRuns,
    required this.thisOver,
    required this.striker,
    required this.nonStriker,
    required this.currentBowler,
    required this.batterStats,
    required this.bowlerStats,
    required this.wicketsHistory,
    required this.batterOrder,
    required this.nextBatterIndex,
    required this.localBalls,
  });

  MatchState clone() {
    return MatchState(
      runs: runs,
      wickets: wickets,
      ballsBowled: ballsBowled,
      extraRuns: extraRuns,
      thisOver: List.from(thisOver),
      striker: striker,
      nonStriker: nonStriker,
      currentBowler: currentBowler,
      batterStats: batterStats.map((k, v) => MapEntry(k, v.clone())),
      bowlerStats: bowlerStats.map((k, v) => MapEntry(k, v.clone())),
      wicketsHistory: List.from(wicketsHistory),
      batterOrder: List.from(batterOrder),
      nextBatterIndex: nextBatterIndex,
      localBalls: List.from(localBalls),
    );
  }
}
