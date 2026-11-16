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

class CompletedOverSummary {
  final int overNumber;
  final String bowlerName;
  final List<String> balls;
  final int runs;
  final int wickets;

  CompletedOverSummary({
    required this.overNumber,
    required this.bowlerName,
    required this.balls,
    required this.runs,
    required this.wickets,
  });

  bool get isMaiden {
    for (final ball in balls) {
      if (ball.contains('Wd') || ball.contains('Nb')) return false;
      if (ball == 'W' || ball == '.') continue;
      if (ball.endsWith('LB')) continue;
      if (ball.endsWith('B') && !ball.contains('N')) continue;
      final r = int.tryParse(ball);
      if (r != null && r > 0) return false;
    }
    return balls.isNotEmpty;
  }

  Map<String, dynamic> toJson() => {
        'overNumber': overNumber,
        'bowlerName': bowlerName,
        'balls': balls,
        'runs': runs,
        'wickets': wickets,
      };

  factory CompletedOverSummary.fromJson(Map<String, dynamic> json) =>
      CompletedOverSummary(
        overNumber: json['overNumber'] as int? ?? 1,
        bowlerName: json['bowlerName'] as String? ?? '',
        balls: (json['balls'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
        runs: json['runs'] as int? ?? 0,
        wickets: json['wickets'] as int? ?? 0,
      );

  CompletedOverSummary clone() => CompletedOverSummary(
        overNumber: overNumber,
        bowlerName: bowlerName,
        balls: List<String>.from(balls),
        runs: runs,
        wickets: wickets,
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
  final List<CompletedOverSummary> completedOvers;

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
    this.completedOvers = const [],
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
      completedOvers: completedOvers.map((o) => o.clone()).toList(),
    );
  }
}
