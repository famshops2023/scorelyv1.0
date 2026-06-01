class BatterStats {
  final String name;
  int runs;
  int balls;
  int fours;
  int sixes;
  bool isOut;
  String dismissalInfo;

  BatterStats({
    required this.name,
    this.runs = 0,
    this.balls = 0,
    this.fours = 0,
    this.sixes = 0,
    this.isOut = false,
    this.dismissalInfo = '',
  });

  double get strikeRate => balls == 0 ? 0.0 : (runs / balls) * 100;

  BatterStats clone() => BatterStats(
        name: name,
        runs: runs,
        balls: balls,
        fours: fours,
        sixes: sixes,
        isOut: isOut,
        dismissalInfo: dismissalInfo,
      );

  BatterStats copyWith({
    String? name,
    int? runs,
    int? balls,
    int? fours,
    int? sixes,
    bool? isOut,
    String? dismissalInfo,
  }) {
    return BatterStats(
      name: name ?? this.name,
      runs: runs ?? this.runs,
      balls: balls ?? this.balls,
      fours: fours ?? this.fours,
      sixes: sixes ?? this.sixes,
      isOut: isOut ?? this.isOut,
      dismissalInfo: dismissalInfo ?? this.dismissalInfo,
    );
  }
}

class BowlerStats {
  final String name;
  int ballsBowled;
  int maidens;
  int runsConceded;
  int wickets;

  BowlerStats({
    required this.name,
    this.ballsBowled = 0,
    this.maidens = 0,
    this.runsConceded = 0,
    this.wickets = 0,
  });

  String get oversDisplay {
    int ov = ballsBowled ~/ 6;
    int b = ballsBowled % 6;
    return '$ov.$b';
  }

  double get economy =>
      ballsBowled == 0 ? 0.0 : (runsConceded / (ballsBowled / 6));

  BowlerStats clone() => BowlerStats(
        name: name,
        ballsBowled: ballsBowled,
        runsConceded: runsConceded,
        wickets: wickets,
        maidens: maidens,
      );

  BowlerStats copyWith({
    String? name,
    int? ballsBowled,
    int? maidens,
    int? runsConceded,
    int? wickets,
  }) {
    return BowlerStats(
      name: name ?? this.name,
      ballsBowled: ballsBowled ?? this.ballsBowled,
      maidens: maidens ?? this.maidens,
      runsConceded: runsConceded ?? this.runsConceded,
      wickets: wickets ?? this.wickets,
    );
  }
}

class FallOfWicket {
  final int wicketNumber;
  final String playerName;
  final int score;
  final String overInfo;

  FallOfWicket({
    required this.wicketNumber,
    required this.playerName,
    required this.score,
    required this.overInfo,
  });
}

class InningsStats {
  final String teamName;
  final Map<String, BatterStats> batterStats;
  final Map<String, BowlerStats> bowlerStats;
  final List<FallOfWicket> fallOfWickets;
  final int totalRuns;
  final int totalWickets;
  final String totalOvers;
  final String extrasInfo;

  InningsStats({
    required this.teamName,
    required this.batterStats,
    required this.bowlerStats,
    required this.fallOfWickets,
    required this.totalRuns,
    required this.totalWickets,
    required this.totalOvers,
    required this.extrasInfo,
  });
}

class PlayerMvpStats {
  final String playerName;
  final String teamName;
  double battingPoints;
  double bowlingPoints;
  double allRounderPoints;
  double impactMultiplier;

  PlayerMvpStats({
    required this.playerName,
    required this.teamName,
    this.battingPoints = 0,
    this.bowlingPoints = 0,
    this.allRounderPoints = 0,
    this.impactMultiplier = 1.0,
  });

  double get totalPoints => (battingPoints + bowlingPoints + allRounderPoints) * impactMultiplier;
}
