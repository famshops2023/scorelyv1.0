// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $MatchesTable extends Matches
    with TableInfo<$MatchesTable, CricketMatch> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MatchesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _matchTitleMeta = const VerificationMeta(
    'matchTitle',
  );
  @override
  late final GeneratedColumn<String> matchTitle = GeneratedColumn<String>(
    'match_title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalOversMeta = const VerificationMeta(
    'totalOvers',
  );
  @override
  late final GeneratedColumn<int> totalOvers = GeneratedColumn<int>(
    'total_overs',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _teamAIdMeta = const VerificationMeta(
    'teamAId',
  );
  @override
  late final GeneratedColumn<int> teamAId = GeneratedColumn<int>(
    'team_a_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _teamBIdMeta = const VerificationMeta(
    'teamBId',
  );
  @override
  late final GeneratedColumn<int> teamBId = GeneratedColumn<int>(
    'team_b_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _isCompletedMeta = const VerificationMeta(
    'isCompleted',
  );
  @override
  late final GeneratedColumn<bool> isCompleted = GeneratedColumn<bool>(
    'is_completed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_completed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _winnerTeamNameMeta = const VerificationMeta(
    'winnerTeamName',
  );
  @override
  late final GeneratedColumn<String> winnerTeamName = GeneratedColumn<String>(
    'winner_team_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _currentInningsMeta = const VerificationMeta(
    'currentInnings',
  );
  @override
  late final GeneratedColumn<int> currentInnings = GeneratedColumn<int>(
    'current_innings',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _teamARunsMeta = const VerificationMeta(
    'teamARuns',
  );
  @override
  late final GeneratedColumn<int> teamARuns = GeneratedColumn<int>(
    'team_a_runs',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _teamAWicketsMeta = const VerificationMeta(
    'teamAWickets',
  );
  @override
  late final GeneratedColumn<int> teamAWickets = GeneratedColumn<int>(
    'team_a_wickets',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _teamAOversMeta = const VerificationMeta(
    'teamAOvers',
  );
  @override
  late final GeneratedColumn<int> teamAOvers = GeneratedColumn<int>(
    'team_a_overs',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _teamABallsMeta = const VerificationMeta(
    'teamABalls',
  );
  @override
  late final GeneratedColumn<int> teamABalls = GeneratedColumn<int>(
    'team_a_balls',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _teamBRunsMeta = const VerificationMeta(
    'teamBRuns',
  );
  @override
  late final GeneratedColumn<int> teamBRuns = GeneratedColumn<int>(
    'team_b_runs',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _teamBWicketsMeta = const VerificationMeta(
    'teamBWickets',
  );
  @override
  late final GeneratedColumn<int> teamBWickets = GeneratedColumn<int>(
    'team_b_wickets',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _teamBOversMeta = const VerificationMeta(
    'teamBOvers',
  );
  @override
  late final GeneratedColumn<int> teamBOvers = GeneratedColumn<int>(
    'team_b_overs',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _teamBBallsMeta = const VerificationMeta(
    'teamBBalls',
  );
  @override
  late final GeneratedColumn<int> teamBBalls = GeneratedColumn<int>(
    'team_b_balls',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    matchTitle,
    totalOvers,
    teamAId,
    teamBId,
    createdAt,
    isCompleted,
    winnerTeamName,
    currentInnings,
    teamARuns,
    teamAWickets,
    teamAOvers,
    teamABalls,
    teamBRuns,
    teamBWickets,
    teamBOvers,
    teamBBalls,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'matches';
  @override
  VerificationContext validateIntegrity(
    Insertable<CricketMatch> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('match_title')) {
      context.handle(
        _matchTitleMeta,
        matchTitle.isAcceptableOrUnknown(data['match_title']!, _matchTitleMeta),
      );
    } else if (isInserting) {
      context.missing(_matchTitleMeta);
    }
    if (data.containsKey('total_overs')) {
      context.handle(
        _totalOversMeta,
        totalOvers.isAcceptableOrUnknown(data['total_overs']!, _totalOversMeta),
      );
    } else if (isInserting) {
      context.missing(_totalOversMeta);
    }
    if (data.containsKey('team_a_id')) {
      context.handle(
        _teamAIdMeta,
        teamAId.isAcceptableOrUnknown(data['team_a_id']!, _teamAIdMeta),
      );
    }
    if (data.containsKey('team_b_id')) {
      context.handle(
        _teamBIdMeta,
        teamBId.isAcceptableOrUnknown(data['team_b_id']!, _teamBIdMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('is_completed')) {
      context.handle(
        _isCompletedMeta,
        isCompleted.isAcceptableOrUnknown(
          data['is_completed']!,
          _isCompletedMeta,
        ),
      );
    }
    if (data.containsKey('winner_team_name')) {
      context.handle(
        _winnerTeamNameMeta,
        winnerTeamName.isAcceptableOrUnknown(
          data['winner_team_name']!,
          _winnerTeamNameMeta,
        ),
      );
    }
    if (data.containsKey('current_innings')) {
      context.handle(
        _currentInningsMeta,
        currentInnings.isAcceptableOrUnknown(
          data['current_innings']!,
          _currentInningsMeta,
        ),
      );
    }
    if (data.containsKey('team_a_runs')) {
      context.handle(
        _teamARunsMeta,
        teamARuns.isAcceptableOrUnknown(data['team_a_runs']!, _teamARunsMeta),
      );
    }
    if (data.containsKey('team_a_wickets')) {
      context.handle(
        _teamAWicketsMeta,
        teamAWickets.isAcceptableOrUnknown(
          data['team_a_wickets']!,
          _teamAWicketsMeta,
        ),
      );
    }
    if (data.containsKey('team_a_overs')) {
      context.handle(
        _teamAOversMeta,
        teamAOvers.isAcceptableOrUnknown(
          data['team_a_overs']!,
          _teamAOversMeta,
        ),
      );
    }
    if (data.containsKey('team_a_balls')) {
      context.handle(
        _teamABallsMeta,
        teamABalls.isAcceptableOrUnknown(
          data['team_a_balls']!,
          _teamABallsMeta,
        ),
      );
    }
    if (data.containsKey('team_b_runs')) {
      context.handle(
        _teamBRunsMeta,
        teamBRuns.isAcceptableOrUnknown(data['team_b_runs']!, _teamBRunsMeta),
      );
    }
    if (data.containsKey('team_b_wickets')) {
      context.handle(
        _teamBWicketsMeta,
        teamBWickets.isAcceptableOrUnknown(
          data['team_b_wickets']!,
          _teamBWicketsMeta,
        ),
      );
    }
    if (data.containsKey('team_b_overs')) {
      context.handle(
        _teamBOversMeta,
        teamBOvers.isAcceptableOrUnknown(
          data['team_b_overs']!,
          _teamBOversMeta,
        ),
      );
    }
    if (data.containsKey('team_b_balls')) {
      context.handle(
        _teamBBallsMeta,
        teamBBalls.isAcceptableOrUnknown(
          data['team_b_balls']!,
          _teamBBallsMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CricketMatch map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CricketMatch(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      matchTitle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}match_title'],
      )!,
      totalOvers: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_overs'],
      )!,
      teamAId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}team_a_id'],
      ),
      teamBId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}team_b_id'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      isCompleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_completed'],
      )!,
      winnerTeamName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}winner_team_name'],
      ),
      currentInnings: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}current_innings'],
      )!,
      teamARuns: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}team_a_runs'],
      )!,
      teamAWickets: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}team_a_wickets'],
      )!,
      teamAOvers: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}team_a_overs'],
      )!,
      teamABalls: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}team_a_balls'],
      )!,
      teamBRuns: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}team_b_runs'],
      )!,
      teamBWickets: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}team_b_wickets'],
      )!,
      teamBOvers: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}team_b_overs'],
      )!,
      teamBBalls: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}team_b_balls'],
      )!,
    );
  }

  @override
  $MatchesTable createAlias(String alias) {
    return $MatchesTable(attachedDatabase, alias);
  }
}

class CricketMatch extends DataClass implements Insertable<CricketMatch> {
  final int id;
  final String matchTitle;
  final int totalOvers;
  final int? teamAId;
  final int? teamBId;
  final DateTime createdAt;
  final bool isCompleted;
  final String? winnerTeamName;
  final int currentInnings;
  final int teamARuns;
  final int teamAWickets;
  final int teamAOvers;
  final int teamABalls;
  final int teamBRuns;
  final int teamBWickets;
  final int teamBOvers;
  final int teamBBalls;
  const CricketMatch({
    required this.id,
    required this.matchTitle,
    required this.totalOvers,
    this.teamAId,
    this.teamBId,
    required this.createdAt,
    required this.isCompleted,
    this.winnerTeamName,
    required this.currentInnings,
    required this.teamARuns,
    required this.teamAWickets,
    required this.teamAOvers,
    required this.teamABalls,
    required this.teamBRuns,
    required this.teamBWickets,
    required this.teamBOvers,
    required this.teamBBalls,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['match_title'] = Variable<String>(matchTitle);
    map['total_overs'] = Variable<int>(totalOvers);
    if (!nullToAbsent || teamAId != null) {
      map['team_a_id'] = Variable<int>(teamAId);
    }
    if (!nullToAbsent || teamBId != null) {
      map['team_b_id'] = Variable<int>(teamBId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['is_completed'] = Variable<bool>(isCompleted);
    if (!nullToAbsent || winnerTeamName != null) {
      map['winner_team_name'] = Variable<String>(winnerTeamName);
    }
    map['current_innings'] = Variable<int>(currentInnings);
    map['team_a_runs'] = Variable<int>(teamARuns);
    map['team_a_wickets'] = Variable<int>(teamAWickets);
    map['team_a_overs'] = Variable<int>(teamAOvers);
    map['team_a_balls'] = Variable<int>(teamABalls);
    map['team_b_runs'] = Variable<int>(teamBRuns);
    map['team_b_wickets'] = Variable<int>(teamBWickets);
    map['team_b_overs'] = Variable<int>(teamBOvers);
    map['team_b_balls'] = Variable<int>(teamBBalls);
    return map;
  }

  MatchesCompanion toCompanion(bool nullToAbsent) {
    return MatchesCompanion(
      id: Value(id),
      matchTitle: Value(matchTitle),
      totalOvers: Value(totalOvers),
      teamAId: teamAId == null && nullToAbsent
          ? const Value.absent()
          : Value(teamAId),
      teamBId: teamBId == null && nullToAbsent
          ? const Value.absent()
          : Value(teamBId),
      createdAt: Value(createdAt),
      isCompleted: Value(isCompleted),
      winnerTeamName: winnerTeamName == null && nullToAbsent
          ? const Value.absent()
          : Value(winnerTeamName),
      currentInnings: Value(currentInnings),
      teamARuns: Value(teamARuns),
      teamAWickets: Value(teamAWickets),
      teamAOvers: Value(teamAOvers),
      teamABalls: Value(teamABalls),
      teamBRuns: Value(teamBRuns),
      teamBWickets: Value(teamBWickets),
      teamBOvers: Value(teamBOvers),
      teamBBalls: Value(teamBBalls),
    );
  }

  factory CricketMatch.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CricketMatch(
      id: serializer.fromJson<int>(json['id']),
      matchTitle: serializer.fromJson<String>(json['matchTitle']),
      totalOvers: serializer.fromJson<int>(json['totalOvers']),
      teamAId: serializer.fromJson<int?>(json['teamAId']),
      teamBId: serializer.fromJson<int?>(json['teamBId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      isCompleted: serializer.fromJson<bool>(json['isCompleted']),
      winnerTeamName: serializer.fromJson<String?>(json['winnerTeamName']),
      currentInnings: serializer.fromJson<int>(json['currentInnings']),
      teamARuns: serializer.fromJson<int>(json['teamARuns']),
      teamAWickets: serializer.fromJson<int>(json['teamAWickets']),
      teamAOvers: serializer.fromJson<int>(json['teamAOvers']),
      teamABalls: serializer.fromJson<int>(json['teamABalls']),
      teamBRuns: serializer.fromJson<int>(json['teamBRuns']),
      teamBWickets: serializer.fromJson<int>(json['teamBWickets']),
      teamBOvers: serializer.fromJson<int>(json['teamBOvers']),
      teamBBalls: serializer.fromJson<int>(json['teamBBalls']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'matchTitle': serializer.toJson<String>(matchTitle),
      'totalOvers': serializer.toJson<int>(totalOvers),
      'teamAId': serializer.toJson<int?>(teamAId),
      'teamBId': serializer.toJson<int?>(teamBId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'isCompleted': serializer.toJson<bool>(isCompleted),
      'winnerTeamName': serializer.toJson<String?>(winnerTeamName),
      'currentInnings': serializer.toJson<int>(currentInnings),
      'teamARuns': serializer.toJson<int>(teamARuns),
      'teamAWickets': serializer.toJson<int>(teamAWickets),
      'teamAOvers': serializer.toJson<int>(teamAOvers),
      'teamABalls': serializer.toJson<int>(teamABalls),
      'teamBRuns': serializer.toJson<int>(teamBRuns),
      'teamBWickets': serializer.toJson<int>(teamBWickets),
      'teamBOvers': serializer.toJson<int>(teamBOvers),
      'teamBBalls': serializer.toJson<int>(teamBBalls),
    };
  }

  CricketMatch copyWith({
    int? id,
    String? matchTitle,
    int? totalOvers,
    Value<int?> teamAId = const Value.absent(),
    Value<int?> teamBId = const Value.absent(),
    DateTime? createdAt,
    bool? isCompleted,
    Value<String?> winnerTeamName = const Value.absent(),
    int? currentInnings,
    int? teamARuns,
    int? teamAWickets,
    int? teamAOvers,
    int? teamABalls,
    int? teamBRuns,
    int? teamBWickets,
    int? teamBOvers,
    int? teamBBalls,
  }) => CricketMatch(
    id: id ?? this.id,
    matchTitle: matchTitle ?? this.matchTitle,
    totalOvers: totalOvers ?? this.totalOvers,
    teamAId: teamAId.present ? teamAId.value : this.teamAId,
    teamBId: teamBId.present ? teamBId.value : this.teamBId,
    createdAt: createdAt ?? this.createdAt,
    isCompleted: isCompleted ?? this.isCompleted,
    winnerTeamName: winnerTeamName.present
        ? winnerTeamName.value
        : this.winnerTeamName,
    currentInnings: currentInnings ?? this.currentInnings,
    teamARuns: teamARuns ?? this.teamARuns,
    teamAWickets: teamAWickets ?? this.teamAWickets,
    teamAOvers: teamAOvers ?? this.teamAOvers,
    teamABalls: teamABalls ?? this.teamABalls,
    teamBRuns: teamBRuns ?? this.teamBRuns,
    teamBWickets: teamBWickets ?? this.teamBWickets,
    teamBOvers: teamBOvers ?? this.teamBOvers,
    teamBBalls: teamBBalls ?? this.teamBBalls,
  );
  CricketMatch copyWithCompanion(MatchesCompanion data) {
    return CricketMatch(
      id: data.id.present ? data.id.value : this.id,
      matchTitle: data.matchTitle.present
          ? data.matchTitle.value
          : this.matchTitle,
      totalOvers: data.totalOvers.present
          ? data.totalOvers.value
          : this.totalOvers,
      teamAId: data.teamAId.present ? data.teamAId.value : this.teamAId,
      teamBId: data.teamBId.present ? data.teamBId.value : this.teamBId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      isCompleted: data.isCompleted.present
          ? data.isCompleted.value
          : this.isCompleted,
      winnerTeamName: data.winnerTeamName.present
          ? data.winnerTeamName.value
          : this.winnerTeamName,
      currentInnings: data.currentInnings.present
          ? data.currentInnings.value
          : this.currentInnings,
      teamARuns: data.teamARuns.present ? data.teamARuns.value : this.teamARuns,
      teamAWickets: data.teamAWickets.present
          ? data.teamAWickets.value
          : this.teamAWickets,
      teamAOvers: data.teamAOvers.present
          ? data.teamAOvers.value
          : this.teamAOvers,
      teamABalls: data.teamABalls.present
          ? data.teamABalls.value
          : this.teamABalls,
      teamBRuns: data.teamBRuns.present ? data.teamBRuns.value : this.teamBRuns,
      teamBWickets: data.teamBWickets.present
          ? data.teamBWickets.value
          : this.teamBWickets,
      teamBOvers: data.teamBOvers.present
          ? data.teamBOvers.value
          : this.teamBOvers,
      teamBBalls: data.teamBBalls.present
          ? data.teamBBalls.value
          : this.teamBBalls,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CricketMatch(')
          ..write('id: $id, ')
          ..write('matchTitle: $matchTitle, ')
          ..write('totalOvers: $totalOvers, ')
          ..write('teamAId: $teamAId, ')
          ..write('teamBId: $teamBId, ')
          ..write('createdAt: $createdAt, ')
          ..write('isCompleted: $isCompleted, ')
          ..write('winnerTeamName: $winnerTeamName, ')
          ..write('currentInnings: $currentInnings, ')
          ..write('teamARuns: $teamARuns, ')
          ..write('teamAWickets: $teamAWickets, ')
          ..write('teamAOvers: $teamAOvers, ')
          ..write('teamABalls: $teamABalls, ')
          ..write('teamBRuns: $teamBRuns, ')
          ..write('teamBWickets: $teamBWickets, ')
          ..write('teamBOvers: $teamBOvers, ')
          ..write('teamBBalls: $teamBBalls')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    matchTitle,
    totalOvers,
    teamAId,
    teamBId,
    createdAt,
    isCompleted,
    winnerTeamName,
    currentInnings,
    teamARuns,
    teamAWickets,
    teamAOvers,
    teamABalls,
    teamBRuns,
    teamBWickets,
    teamBOvers,
    teamBBalls,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CricketMatch &&
          other.id == this.id &&
          other.matchTitle == this.matchTitle &&
          other.totalOvers == this.totalOvers &&
          other.teamAId == this.teamAId &&
          other.teamBId == this.teamBId &&
          other.createdAt == this.createdAt &&
          other.isCompleted == this.isCompleted &&
          other.winnerTeamName == this.winnerTeamName &&
          other.currentInnings == this.currentInnings &&
          other.teamARuns == this.teamARuns &&
          other.teamAWickets == this.teamAWickets &&
          other.teamAOvers == this.teamAOvers &&
          other.teamABalls == this.teamABalls &&
          other.teamBRuns == this.teamBRuns &&
          other.teamBWickets == this.teamBWickets &&
          other.teamBOvers == this.teamBOvers &&
          other.teamBBalls == this.teamBBalls);
}

class MatchesCompanion extends UpdateCompanion<CricketMatch> {
  final Value<int> id;
  final Value<String> matchTitle;
  final Value<int> totalOvers;
  final Value<int?> teamAId;
  final Value<int?> teamBId;
  final Value<DateTime> createdAt;
  final Value<bool> isCompleted;
  final Value<String?> winnerTeamName;
  final Value<int> currentInnings;
  final Value<int> teamARuns;
  final Value<int> teamAWickets;
  final Value<int> teamAOvers;
  final Value<int> teamABalls;
  final Value<int> teamBRuns;
  final Value<int> teamBWickets;
  final Value<int> teamBOvers;
  final Value<int> teamBBalls;
  const MatchesCompanion({
    this.id = const Value.absent(),
    this.matchTitle = const Value.absent(),
    this.totalOvers = const Value.absent(),
    this.teamAId = const Value.absent(),
    this.teamBId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.isCompleted = const Value.absent(),
    this.winnerTeamName = const Value.absent(),
    this.currentInnings = const Value.absent(),
    this.teamARuns = const Value.absent(),
    this.teamAWickets = const Value.absent(),
    this.teamAOvers = const Value.absent(),
    this.teamABalls = const Value.absent(),
    this.teamBRuns = const Value.absent(),
    this.teamBWickets = const Value.absent(),
    this.teamBOvers = const Value.absent(),
    this.teamBBalls = const Value.absent(),
  });
  MatchesCompanion.insert({
    this.id = const Value.absent(),
    required String matchTitle,
    required int totalOvers,
    this.teamAId = const Value.absent(),
    this.teamBId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.isCompleted = const Value.absent(),
    this.winnerTeamName = const Value.absent(),
    this.currentInnings = const Value.absent(),
    this.teamARuns = const Value.absent(),
    this.teamAWickets = const Value.absent(),
    this.teamAOvers = const Value.absent(),
    this.teamABalls = const Value.absent(),
    this.teamBRuns = const Value.absent(),
    this.teamBWickets = const Value.absent(),
    this.teamBOvers = const Value.absent(),
    this.teamBBalls = const Value.absent(),
  }) : matchTitle = Value(matchTitle),
       totalOvers = Value(totalOvers);
  static Insertable<CricketMatch> custom({
    Expression<int>? id,
    Expression<String>? matchTitle,
    Expression<int>? totalOvers,
    Expression<int>? teamAId,
    Expression<int>? teamBId,
    Expression<DateTime>? createdAt,
    Expression<bool>? isCompleted,
    Expression<String>? winnerTeamName,
    Expression<int>? currentInnings,
    Expression<int>? teamARuns,
    Expression<int>? teamAWickets,
    Expression<int>? teamAOvers,
    Expression<int>? teamABalls,
    Expression<int>? teamBRuns,
    Expression<int>? teamBWickets,
    Expression<int>? teamBOvers,
    Expression<int>? teamBBalls,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (matchTitle != null) 'match_title': matchTitle,
      if (totalOvers != null) 'total_overs': totalOvers,
      if (teamAId != null) 'team_a_id': teamAId,
      if (teamBId != null) 'team_b_id': teamBId,
      if (createdAt != null) 'created_at': createdAt,
      if (isCompleted != null) 'is_completed': isCompleted,
      if (winnerTeamName != null) 'winner_team_name': winnerTeamName,
      if (currentInnings != null) 'current_innings': currentInnings,
      if (teamARuns != null) 'team_a_runs': teamARuns,
      if (teamAWickets != null) 'team_a_wickets': teamAWickets,
      if (teamAOvers != null) 'team_a_overs': teamAOvers,
      if (teamABalls != null) 'team_a_balls': teamABalls,
      if (teamBRuns != null) 'team_b_runs': teamBRuns,
      if (teamBWickets != null) 'team_b_wickets': teamBWickets,
      if (teamBOvers != null) 'team_b_overs': teamBOvers,
      if (teamBBalls != null) 'team_b_balls': teamBBalls,
    });
  }

  MatchesCompanion copyWith({
    Value<int>? id,
    Value<String>? matchTitle,
    Value<int>? totalOvers,
    Value<int?>? teamAId,
    Value<int?>? teamBId,
    Value<DateTime>? createdAt,
    Value<bool>? isCompleted,
    Value<String?>? winnerTeamName,
    Value<int>? currentInnings,
    Value<int>? teamARuns,
    Value<int>? teamAWickets,
    Value<int>? teamAOvers,
    Value<int>? teamABalls,
    Value<int>? teamBRuns,
    Value<int>? teamBWickets,
    Value<int>? teamBOvers,
    Value<int>? teamBBalls,
  }) {
    return MatchesCompanion(
      id: id ?? this.id,
      matchTitle: matchTitle ?? this.matchTitle,
      totalOvers: totalOvers ?? this.totalOvers,
      teamAId: teamAId ?? this.teamAId,
      teamBId: teamBId ?? this.teamBId,
      createdAt: createdAt ?? this.createdAt,
      isCompleted: isCompleted ?? this.isCompleted,
      winnerTeamName: winnerTeamName ?? this.winnerTeamName,
      currentInnings: currentInnings ?? this.currentInnings,
      teamARuns: teamARuns ?? this.teamARuns,
      teamAWickets: teamAWickets ?? this.teamAWickets,
      teamAOvers: teamAOvers ?? this.teamAOvers,
      teamABalls: teamABalls ?? this.teamABalls,
      teamBRuns: teamBRuns ?? this.teamBRuns,
      teamBWickets: teamBWickets ?? this.teamBWickets,
      teamBOvers: teamBOvers ?? this.teamBOvers,
      teamBBalls: teamBBalls ?? this.teamBBalls,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (matchTitle.present) {
      map['match_title'] = Variable<String>(matchTitle.value);
    }
    if (totalOvers.present) {
      map['total_overs'] = Variable<int>(totalOvers.value);
    }
    if (teamAId.present) {
      map['team_a_id'] = Variable<int>(teamAId.value);
    }
    if (teamBId.present) {
      map['team_b_id'] = Variable<int>(teamBId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (isCompleted.present) {
      map['is_completed'] = Variable<bool>(isCompleted.value);
    }
    if (winnerTeamName.present) {
      map['winner_team_name'] = Variable<String>(winnerTeamName.value);
    }
    if (currentInnings.present) {
      map['current_innings'] = Variable<int>(currentInnings.value);
    }
    if (teamARuns.present) {
      map['team_a_runs'] = Variable<int>(teamARuns.value);
    }
    if (teamAWickets.present) {
      map['team_a_wickets'] = Variable<int>(teamAWickets.value);
    }
    if (teamAOvers.present) {
      map['team_a_overs'] = Variable<int>(teamAOvers.value);
    }
    if (teamABalls.present) {
      map['team_a_balls'] = Variable<int>(teamABalls.value);
    }
    if (teamBRuns.present) {
      map['team_b_runs'] = Variable<int>(teamBRuns.value);
    }
    if (teamBWickets.present) {
      map['team_b_wickets'] = Variable<int>(teamBWickets.value);
    }
    if (teamBOvers.present) {
      map['team_b_overs'] = Variable<int>(teamBOvers.value);
    }
    if (teamBBalls.present) {
      map['team_b_balls'] = Variable<int>(teamBBalls.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MatchesCompanion(')
          ..write('id: $id, ')
          ..write('matchTitle: $matchTitle, ')
          ..write('totalOvers: $totalOvers, ')
          ..write('teamAId: $teamAId, ')
          ..write('teamBId: $teamBId, ')
          ..write('createdAt: $createdAt, ')
          ..write('isCompleted: $isCompleted, ')
          ..write('winnerTeamName: $winnerTeamName, ')
          ..write('currentInnings: $currentInnings, ')
          ..write('teamARuns: $teamARuns, ')
          ..write('teamAWickets: $teamAWickets, ')
          ..write('teamAOvers: $teamAOvers, ')
          ..write('teamABalls: $teamABalls, ')
          ..write('teamBRuns: $teamBRuns, ')
          ..write('teamBWickets: $teamBWickets, ')
          ..write('teamBOvers: $teamBOvers, ')
          ..write('teamBBalls: $teamBBalls')
          ..write(')'))
        .toString();
  }
}

class $TeamsTable extends Teams with TableInfo<$TeamsTable, Team> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TeamsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'teams';
  @override
  VerificationContext validateIntegrity(
    Insertable<Team> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Team map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Team(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
    );
  }

  @override
  $TeamsTable createAlias(String alias) {
    return $TeamsTable(attachedDatabase, alias);
  }
}

class Team extends DataClass implements Insertable<Team> {
  final int id;
  final String name;
  const Team({required this.id, required this.name});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    return map;
  }

  TeamsCompanion toCompanion(bool nullToAbsent) {
    return TeamsCompanion(id: Value(id), name: Value(name));
  }

  factory Team.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Team(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
    };
  }

  Team copyWith({int? id, String? name}) =>
      Team(id: id ?? this.id, name: name ?? this.name);
  Team copyWithCompanion(TeamsCompanion data) {
    return Team(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Team(')
          ..write('id: $id, ')
          ..write('name: $name')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Team && other.id == this.id && other.name == this.name);
}

class TeamsCompanion extends UpdateCompanion<Team> {
  final Value<int> id;
  final Value<String> name;
  const TeamsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
  });
  TeamsCompanion.insert({this.id = const Value.absent(), required String name})
    : name = Value(name);
  static Insertable<Team> custom({
    Expression<int>? id,
    Expression<String>? name,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
    });
  }

  TeamsCompanion copyWith({Value<int>? id, Value<String>? name}) {
    return TeamsCompanion(id: id ?? this.id, name: name ?? this.name);
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TeamsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name')
          ..write(')'))
        .toString();
  }
}

class $PlayersTable extends Players with TableInfo<$PlayersTable, Player> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlayersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _teamIdMeta = const VerificationMeta('teamId');
  @override
  late final GeneratedColumn<int> teamId = GeneratedColumn<int>(
    'team_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _runsConcededMeta = const VerificationMeta(
    'runsConceded',
  );
  @override
  late final GeneratedColumn<int> runsConceded = GeneratedColumn<int>(
    'runs_conceded',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _wicketsTakenMeta = const VerificationMeta(
    'wicketsTaken',
  );
  @override
  late final GeneratedColumn<int> wicketsTaken = GeneratedColumn<int>(
    'wickets_taken',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _runsScoredMeta = const VerificationMeta(
    'runsScored',
  );
  @override
  late final GeneratedColumn<int> runsScored = GeneratedColumn<int>(
    'runs_scored',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _ballsFacedMeta = const VerificationMeta(
    'ballsFaced',
  );
  @override
  late final GeneratedColumn<int> ballsFaced = GeneratedColumn<int>(
    'balls_faced',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _foursMeta = const VerificationMeta('fours');
  @override
  late final GeneratedColumn<int> fours = GeneratedColumn<int>(
    'fours',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _sixesMeta = const VerificationMeta('sixes');
  @override
  late final GeneratedColumn<int> sixes = GeneratedColumn<int>(
    'sixes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    teamId,
    runsConceded,
    wicketsTaken,
    runsScored,
    ballsFaced,
    fours,
    sixes,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'players';
  @override
  VerificationContext validateIntegrity(
    Insertable<Player> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('team_id')) {
      context.handle(
        _teamIdMeta,
        teamId.isAcceptableOrUnknown(data['team_id']!, _teamIdMeta),
      );
    }
    if (data.containsKey('runs_conceded')) {
      context.handle(
        _runsConcededMeta,
        runsConceded.isAcceptableOrUnknown(
          data['runs_conceded']!,
          _runsConcededMeta,
        ),
      );
    }
    if (data.containsKey('wickets_taken')) {
      context.handle(
        _wicketsTakenMeta,
        wicketsTaken.isAcceptableOrUnknown(
          data['wickets_taken']!,
          _wicketsTakenMeta,
        ),
      );
    }
    if (data.containsKey('runs_scored')) {
      context.handle(
        _runsScoredMeta,
        runsScored.isAcceptableOrUnknown(data['runs_scored']!, _runsScoredMeta),
      );
    }
    if (data.containsKey('balls_faced')) {
      context.handle(
        _ballsFacedMeta,
        ballsFaced.isAcceptableOrUnknown(data['balls_faced']!, _ballsFacedMeta),
      );
    }
    if (data.containsKey('fours')) {
      context.handle(
        _foursMeta,
        fours.isAcceptableOrUnknown(data['fours']!, _foursMeta),
      );
    }
    if (data.containsKey('sixes')) {
      context.handle(
        _sixesMeta,
        sixes.isAcceptableOrUnknown(data['sixes']!, _sixesMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Player map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Player(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      teamId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}team_id'],
      ),
      runsConceded: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}runs_conceded'],
      )!,
      wicketsTaken: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}wickets_taken'],
      )!,
      runsScored: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}runs_scored'],
      )!,
      ballsFaced: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}balls_faced'],
      )!,
      fours: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}fours'],
      )!,
      sixes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sixes'],
      )!,
    );
  }

  @override
  $PlayersTable createAlias(String alias) {
    return $PlayersTable(attachedDatabase, alias);
  }
}

class Player extends DataClass implements Insertable<Player> {
  final int id;
  final String name;
  final int? teamId;
  final int runsConceded;
  final int wicketsTaken;
  final int runsScored;
  final int ballsFaced;
  final int fours;
  final int sixes;
  const Player({
    required this.id,
    required this.name,
    this.teamId,
    required this.runsConceded,
    required this.wicketsTaken,
    required this.runsScored,
    required this.ballsFaced,
    required this.fours,
    required this.sixes,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || teamId != null) {
      map['team_id'] = Variable<int>(teamId);
    }
    map['runs_conceded'] = Variable<int>(runsConceded);
    map['wickets_taken'] = Variable<int>(wicketsTaken);
    map['runs_scored'] = Variable<int>(runsScored);
    map['balls_faced'] = Variable<int>(ballsFaced);
    map['fours'] = Variable<int>(fours);
    map['sixes'] = Variable<int>(sixes);
    return map;
  }

  PlayersCompanion toCompanion(bool nullToAbsent) {
    return PlayersCompanion(
      id: Value(id),
      name: Value(name),
      teamId: teamId == null && nullToAbsent
          ? const Value.absent()
          : Value(teamId),
      runsConceded: Value(runsConceded),
      wicketsTaken: Value(wicketsTaken),
      runsScored: Value(runsScored),
      ballsFaced: Value(ballsFaced),
      fours: Value(fours),
      sixes: Value(sixes),
    );
  }

  factory Player.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Player(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      teamId: serializer.fromJson<int?>(json['teamId']),
      runsConceded: serializer.fromJson<int>(json['runsConceded']),
      wicketsTaken: serializer.fromJson<int>(json['wicketsTaken']),
      runsScored: serializer.fromJson<int>(json['runsScored']),
      ballsFaced: serializer.fromJson<int>(json['ballsFaced']),
      fours: serializer.fromJson<int>(json['fours']),
      sixes: serializer.fromJson<int>(json['sixes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'teamId': serializer.toJson<int?>(teamId),
      'runsConceded': serializer.toJson<int>(runsConceded),
      'wicketsTaken': serializer.toJson<int>(wicketsTaken),
      'runsScored': serializer.toJson<int>(runsScored),
      'ballsFaced': serializer.toJson<int>(ballsFaced),
      'fours': serializer.toJson<int>(fours),
      'sixes': serializer.toJson<int>(sixes),
    };
  }

  Player copyWith({
    int? id,
    String? name,
    Value<int?> teamId = const Value.absent(),
    int? runsConceded,
    int? wicketsTaken,
    int? runsScored,
    int? ballsFaced,
    int? fours,
    int? sixes,
  }) => Player(
    id: id ?? this.id,
    name: name ?? this.name,
    teamId: teamId.present ? teamId.value : this.teamId,
    runsConceded: runsConceded ?? this.runsConceded,
    wicketsTaken: wicketsTaken ?? this.wicketsTaken,
    runsScored: runsScored ?? this.runsScored,
    ballsFaced: ballsFaced ?? this.ballsFaced,
    fours: fours ?? this.fours,
    sixes: sixes ?? this.sixes,
  );
  Player copyWithCompanion(PlayersCompanion data) {
    return Player(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      teamId: data.teamId.present ? data.teamId.value : this.teamId,
      runsConceded: data.runsConceded.present
          ? data.runsConceded.value
          : this.runsConceded,
      wicketsTaken: data.wicketsTaken.present
          ? data.wicketsTaken.value
          : this.wicketsTaken,
      runsScored: data.runsScored.present
          ? data.runsScored.value
          : this.runsScored,
      ballsFaced: data.ballsFaced.present
          ? data.ballsFaced.value
          : this.ballsFaced,
      fours: data.fours.present ? data.fours.value : this.fours,
      sixes: data.sixes.present ? data.sixes.value : this.sixes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Player(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('teamId: $teamId, ')
          ..write('runsConceded: $runsConceded, ')
          ..write('wicketsTaken: $wicketsTaken, ')
          ..write('runsScored: $runsScored, ')
          ..write('ballsFaced: $ballsFaced, ')
          ..write('fours: $fours, ')
          ..write('sixes: $sixes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    teamId,
    runsConceded,
    wicketsTaken,
    runsScored,
    ballsFaced,
    fours,
    sixes,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Player &&
          other.id == this.id &&
          other.name == this.name &&
          other.teamId == this.teamId &&
          other.runsConceded == this.runsConceded &&
          other.wicketsTaken == this.wicketsTaken &&
          other.runsScored == this.runsScored &&
          other.ballsFaced == this.ballsFaced &&
          other.fours == this.fours &&
          other.sixes == this.sixes);
}

class PlayersCompanion extends UpdateCompanion<Player> {
  final Value<int> id;
  final Value<String> name;
  final Value<int?> teamId;
  final Value<int> runsConceded;
  final Value<int> wicketsTaken;
  final Value<int> runsScored;
  final Value<int> ballsFaced;
  final Value<int> fours;
  final Value<int> sixes;
  const PlayersCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.teamId = const Value.absent(),
    this.runsConceded = const Value.absent(),
    this.wicketsTaken = const Value.absent(),
    this.runsScored = const Value.absent(),
    this.ballsFaced = const Value.absent(),
    this.fours = const Value.absent(),
    this.sixes = const Value.absent(),
  });
  PlayersCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.teamId = const Value.absent(),
    this.runsConceded = const Value.absent(),
    this.wicketsTaken = const Value.absent(),
    this.runsScored = const Value.absent(),
    this.ballsFaced = const Value.absent(),
    this.fours = const Value.absent(),
    this.sixes = const Value.absent(),
  }) : name = Value(name);
  static Insertable<Player> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<int>? teamId,
    Expression<int>? runsConceded,
    Expression<int>? wicketsTaken,
    Expression<int>? runsScored,
    Expression<int>? ballsFaced,
    Expression<int>? fours,
    Expression<int>? sixes,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (teamId != null) 'team_id': teamId,
      if (runsConceded != null) 'runs_conceded': runsConceded,
      if (wicketsTaken != null) 'wickets_taken': wicketsTaken,
      if (runsScored != null) 'runs_scored': runsScored,
      if (ballsFaced != null) 'balls_faced': ballsFaced,
      if (fours != null) 'fours': fours,
      if (sixes != null) 'sixes': sixes,
    });
  }

  PlayersCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<int?>? teamId,
    Value<int>? runsConceded,
    Value<int>? wicketsTaken,
    Value<int>? runsScored,
    Value<int>? ballsFaced,
    Value<int>? fours,
    Value<int>? sixes,
  }) {
    return PlayersCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      teamId: teamId ?? this.teamId,
      runsConceded: runsConceded ?? this.runsConceded,
      wicketsTaken: wicketsTaken ?? this.wicketsTaken,
      runsScored: runsScored ?? this.runsScored,
      ballsFaced: ballsFaced ?? this.ballsFaced,
      fours: fours ?? this.fours,
      sixes: sixes ?? this.sixes,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (teamId.present) {
      map['team_id'] = Variable<int>(teamId.value);
    }
    if (runsConceded.present) {
      map['runs_conceded'] = Variable<int>(runsConceded.value);
    }
    if (wicketsTaken.present) {
      map['wickets_taken'] = Variable<int>(wicketsTaken.value);
    }
    if (runsScored.present) {
      map['runs_scored'] = Variable<int>(runsScored.value);
    }
    if (ballsFaced.present) {
      map['balls_faced'] = Variable<int>(ballsFaced.value);
    }
    if (fours.present) {
      map['fours'] = Variable<int>(fours.value);
    }
    if (sixes.present) {
      map['sixes'] = Variable<int>(sixes.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlayersCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('teamId: $teamId, ')
          ..write('runsConceded: $runsConceded, ')
          ..write('wicketsTaken: $wicketsTaken, ')
          ..write('runsScored: $runsScored, ')
          ..write('ballsFaced: $ballsFaced, ')
          ..write('fours: $fours, ')
          ..write('sixes: $sixes')
          ..write(')'))
        .toString();
  }
}

class $BallEventsTable extends BallEvents
    with TableInfo<$BallEventsTable, BallEvent> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BallEventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _matchIdMeta = const VerificationMeta(
    'matchId',
  );
  @override
  late final GeneratedColumn<int> matchId = GeneratedColumn<int>(
    'match_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _overNumberMeta = const VerificationMeta(
    'overNumber',
  );
  @override
  late final GeneratedColumn<int> overNumber = GeneratedColumn<int>(
    'over_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _ballNumberMeta = const VerificationMeta(
    'ballNumber',
  );
  @override
  late final GeneratedColumn<int> ballNumber = GeneratedColumn<int>(
    'ball_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _runsMeta = const VerificationMeta('runs');
  @override
  late final GeneratedColumn<int> runs = GeneratedColumn<int>(
    'runs',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _isWicketMeta = const VerificationMeta(
    'isWicket',
  );
  @override
  late final GeneratedColumn<bool> isWicket = GeneratedColumn<bool>(
    'is_wicket',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_wicket" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _wicketTypeMeta = const VerificationMeta(
    'wicketType',
  );
  @override
  late final GeneratedColumn<String> wicketType = GeneratedColumn<String>(
    'wicket_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isExtraMeta = const VerificationMeta(
    'isExtra',
  );
  @override
  late final GeneratedColumn<bool> isExtra = GeneratedColumn<bool>(
    'is_extra',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_extra" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _extraTypeMeta = const VerificationMeta(
    'extraType',
  );
  @override
  late final GeneratedColumn<String> extraType = GeneratedColumn<String>(
    'extra_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _batterIdMeta = const VerificationMeta(
    'batterId',
  );
  @override
  late final GeneratedColumn<int> batterId = GeneratedColumn<int>(
    'batter_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bowlerIdMeta = const VerificationMeta(
    'bowlerId',
  );
  @override
  late final GeneratedColumn<int> bowlerId = GeneratedColumn<int>(
    'bowler_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _timestampMeta = const VerificationMeta(
    'timestamp',
  );
  @override
  late final GeneratedColumn<DateTime> timestamp = GeneratedColumn<DateTime>(
    'timestamp',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    matchId,
    overNumber,
    ballNumber,
    runs,
    isWicket,
    wicketType,
    isExtra,
    extraType,
    batterId,
    bowlerId,
    timestamp,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ball_events';
  @override
  VerificationContext validateIntegrity(
    Insertable<BallEvent> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('match_id')) {
      context.handle(
        _matchIdMeta,
        matchId.isAcceptableOrUnknown(data['match_id']!, _matchIdMeta),
      );
    } else if (isInserting) {
      context.missing(_matchIdMeta);
    }
    if (data.containsKey('over_number')) {
      context.handle(
        _overNumberMeta,
        overNumber.isAcceptableOrUnknown(data['over_number']!, _overNumberMeta),
      );
    }
    if (data.containsKey('ball_number')) {
      context.handle(
        _ballNumberMeta,
        ballNumber.isAcceptableOrUnknown(data['ball_number']!, _ballNumberMeta),
      );
    }
    if (data.containsKey('runs')) {
      context.handle(
        _runsMeta,
        runs.isAcceptableOrUnknown(data['runs']!, _runsMeta),
      );
    }
    if (data.containsKey('is_wicket')) {
      context.handle(
        _isWicketMeta,
        isWicket.isAcceptableOrUnknown(data['is_wicket']!, _isWicketMeta),
      );
    }
    if (data.containsKey('wicket_type')) {
      context.handle(
        _wicketTypeMeta,
        wicketType.isAcceptableOrUnknown(data['wicket_type']!, _wicketTypeMeta),
      );
    }
    if (data.containsKey('is_extra')) {
      context.handle(
        _isExtraMeta,
        isExtra.isAcceptableOrUnknown(data['is_extra']!, _isExtraMeta),
      );
    }
    if (data.containsKey('extra_type')) {
      context.handle(
        _extraTypeMeta,
        extraType.isAcceptableOrUnknown(data['extra_type']!, _extraTypeMeta),
      );
    }
    if (data.containsKey('batter_id')) {
      context.handle(
        _batterIdMeta,
        batterId.isAcceptableOrUnknown(data['batter_id']!, _batterIdMeta),
      );
    } else if (isInserting) {
      context.missing(_batterIdMeta);
    }
    if (data.containsKey('bowler_id')) {
      context.handle(
        _bowlerIdMeta,
        bowlerId.isAcceptableOrUnknown(data['bowler_id']!, _bowlerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_bowlerIdMeta);
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BallEvent map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BallEvent(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      matchId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}match_id'],
      )!,
      overNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}over_number'],
      )!,
      ballNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ball_number'],
      )!,
      runs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}runs'],
      )!,
      isWicket: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_wicket'],
      )!,
      wicketType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}wicket_type'],
      ),
      isExtra: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_extra'],
      )!,
      extraType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}extra_type'],
      ),
      batterId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}batter_id'],
      )!,
      bowlerId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}bowler_id'],
      )!,
      timestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}timestamp'],
      )!,
    );
  }

  @override
  $BallEventsTable createAlias(String alias) {
    return $BallEventsTable(attachedDatabase, alias);
  }
}

class BallEvent extends DataClass implements Insertable<BallEvent> {
  final int id;
  final int matchId;
  final int overNumber;
  final int ballNumber;
  final int runs;
  final bool isWicket;
  final String? wicketType;
  final bool isExtra;
  final String? extraType;
  final int batterId;
  final int bowlerId;
  final DateTime timestamp;
  const BallEvent({
    required this.id,
    required this.matchId,
    required this.overNumber,
    required this.ballNumber,
    required this.runs,
    required this.isWicket,
    this.wicketType,
    required this.isExtra,
    this.extraType,
    required this.batterId,
    required this.bowlerId,
    required this.timestamp,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['match_id'] = Variable<int>(matchId);
    map['over_number'] = Variable<int>(overNumber);
    map['ball_number'] = Variable<int>(ballNumber);
    map['runs'] = Variable<int>(runs);
    map['is_wicket'] = Variable<bool>(isWicket);
    if (!nullToAbsent || wicketType != null) {
      map['wicket_type'] = Variable<String>(wicketType);
    }
    map['is_extra'] = Variable<bool>(isExtra);
    if (!nullToAbsent || extraType != null) {
      map['extra_type'] = Variable<String>(extraType);
    }
    map['batter_id'] = Variable<int>(batterId);
    map['bowler_id'] = Variable<int>(bowlerId);
    map['timestamp'] = Variable<DateTime>(timestamp);
    return map;
  }

  BallEventsCompanion toCompanion(bool nullToAbsent) {
    return BallEventsCompanion(
      id: Value(id),
      matchId: Value(matchId),
      overNumber: Value(overNumber),
      ballNumber: Value(ballNumber),
      runs: Value(runs),
      isWicket: Value(isWicket),
      wicketType: wicketType == null && nullToAbsent
          ? const Value.absent()
          : Value(wicketType),
      isExtra: Value(isExtra),
      extraType: extraType == null && nullToAbsent
          ? const Value.absent()
          : Value(extraType),
      batterId: Value(batterId),
      bowlerId: Value(bowlerId),
      timestamp: Value(timestamp),
    );
  }

  factory BallEvent.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BallEvent(
      id: serializer.fromJson<int>(json['id']),
      matchId: serializer.fromJson<int>(json['matchId']),
      overNumber: serializer.fromJson<int>(json['overNumber']),
      ballNumber: serializer.fromJson<int>(json['ballNumber']),
      runs: serializer.fromJson<int>(json['runs']),
      isWicket: serializer.fromJson<bool>(json['isWicket']),
      wicketType: serializer.fromJson<String?>(json['wicketType']),
      isExtra: serializer.fromJson<bool>(json['isExtra']),
      extraType: serializer.fromJson<String?>(json['extraType']),
      batterId: serializer.fromJson<int>(json['batterId']),
      bowlerId: serializer.fromJson<int>(json['bowlerId']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'matchId': serializer.toJson<int>(matchId),
      'overNumber': serializer.toJson<int>(overNumber),
      'ballNumber': serializer.toJson<int>(ballNumber),
      'runs': serializer.toJson<int>(runs),
      'isWicket': serializer.toJson<bool>(isWicket),
      'wicketType': serializer.toJson<String?>(wicketType),
      'isExtra': serializer.toJson<bool>(isExtra),
      'extraType': serializer.toJson<String?>(extraType),
      'batterId': serializer.toJson<int>(batterId),
      'bowlerId': serializer.toJson<int>(bowlerId),
      'timestamp': serializer.toJson<DateTime>(timestamp),
    };
  }

  BallEvent copyWith({
    int? id,
    int? matchId,
    int? overNumber,
    int? ballNumber,
    int? runs,
    bool? isWicket,
    Value<String?> wicketType = const Value.absent(),
    bool? isExtra,
    Value<String?> extraType = const Value.absent(),
    int? batterId,
    int? bowlerId,
    DateTime? timestamp,
  }) => BallEvent(
    id: id ?? this.id,
    matchId: matchId ?? this.matchId,
    overNumber: overNumber ?? this.overNumber,
    ballNumber: ballNumber ?? this.ballNumber,
    runs: runs ?? this.runs,
    isWicket: isWicket ?? this.isWicket,
    wicketType: wicketType.present ? wicketType.value : this.wicketType,
    isExtra: isExtra ?? this.isExtra,
    extraType: extraType.present ? extraType.value : this.extraType,
    batterId: batterId ?? this.batterId,
    bowlerId: bowlerId ?? this.bowlerId,
    timestamp: timestamp ?? this.timestamp,
  );
  BallEvent copyWithCompanion(BallEventsCompanion data) {
    return BallEvent(
      id: data.id.present ? data.id.value : this.id,
      matchId: data.matchId.present ? data.matchId.value : this.matchId,
      overNumber: data.overNumber.present
          ? data.overNumber.value
          : this.overNumber,
      ballNumber: data.ballNumber.present
          ? data.ballNumber.value
          : this.ballNumber,
      runs: data.runs.present ? data.runs.value : this.runs,
      isWicket: data.isWicket.present ? data.isWicket.value : this.isWicket,
      wicketType: data.wicketType.present
          ? data.wicketType.value
          : this.wicketType,
      isExtra: data.isExtra.present ? data.isExtra.value : this.isExtra,
      extraType: data.extraType.present ? data.extraType.value : this.extraType,
      batterId: data.batterId.present ? data.batterId.value : this.batterId,
      bowlerId: data.bowlerId.present ? data.bowlerId.value : this.bowlerId,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BallEvent(')
          ..write('id: $id, ')
          ..write('matchId: $matchId, ')
          ..write('overNumber: $overNumber, ')
          ..write('ballNumber: $ballNumber, ')
          ..write('runs: $runs, ')
          ..write('isWicket: $isWicket, ')
          ..write('wicketType: $wicketType, ')
          ..write('isExtra: $isExtra, ')
          ..write('extraType: $extraType, ')
          ..write('batterId: $batterId, ')
          ..write('bowlerId: $bowlerId, ')
          ..write('timestamp: $timestamp')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    matchId,
    overNumber,
    ballNumber,
    runs,
    isWicket,
    wicketType,
    isExtra,
    extraType,
    batterId,
    bowlerId,
    timestamp,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BallEvent &&
          other.id == this.id &&
          other.matchId == this.matchId &&
          other.overNumber == this.overNumber &&
          other.ballNumber == this.ballNumber &&
          other.runs == this.runs &&
          other.isWicket == this.isWicket &&
          other.wicketType == this.wicketType &&
          other.isExtra == this.isExtra &&
          other.extraType == this.extraType &&
          other.batterId == this.batterId &&
          other.bowlerId == this.bowlerId &&
          other.timestamp == this.timestamp);
}

class BallEventsCompanion extends UpdateCompanion<BallEvent> {
  final Value<int> id;
  final Value<int> matchId;
  final Value<int> overNumber;
  final Value<int> ballNumber;
  final Value<int> runs;
  final Value<bool> isWicket;
  final Value<String?> wicketType;
  final Value<bool> isExtra;
  final Value<String?> extraType;
  final Value<int> batterId;
  final Value<int> bowlerId;
  final Value<DateTime> timestamp;
  const BallEventsCompanion({
    this.id = const Value.absent(),
    this.matchId = const Value.absent(),
    this.overNumber = const Value.absent(),
    this.ballNumber = const Value.absent(),
    this.runs = const Value.absent(),
    this.isWicket = const Value.absent(),
    this.wicketType = const Value.absent(),
    this.isExtra = const Value.absent(),
    this.extraType = const Value.absent(),
    this.batterId = const Value.absent(),
    this.bowlerId = const Value.absent(),
    this.timestamp = const Value.absent(),
  });
  BallEventsCompanion.insert({
    this.id = const Value.absent(),
    required int matchId,
    this.overNumber = const Value.absent(),
    this.ballNumber = const Value.absent(),
    this.runs = const Value.absent(),
    this.isWicket = const Value.absent(),
    this.wicketType = const Value.absent(),
    this.isExtra = const Value.absent(),
    this.extraType = const Value.absent(),
    required int batterId,
    required int bowlerId,
    this.timestamp = const Value.absent(),
  }) : matchId = Value(matchId),
       batterId = Value(batterId),
       bowlerId = Value(bowlerId);
  static Insertable<BallEvent> custom({
    Expression<int>? id,
    Expression<int>? matchId,
    Expression<int>? overNumber,
    Expression<int>? ballNumber,
    Expression<int>? runs,
    Expression<bool>? isWicket,
    Expression<String>? wicketType,
    Expression<bool>? isExtra,
    Expression<String>? extraType,
    Expression<int>? batterId,
    Expression<int>? bowlerId,
    Expression<DateTime>? timestamp,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (matchId != null) 'match_id': matchId,
      if (overNumber != null) 'over_number': overNumber,
      if (ballNumber != null) 'ball_number': ballNumber,
      if (runs != null) 'runs': runs,
      if (isWicket != null) 'is_wicket': isWicket,
      if (wicketType != null) 'wicket_type': wicketType,
      if (isExtra != null) 'is_extra': isExtra,
      if (extraType != null) 'extra_type': extraType,
      if (batterId != null) 'batter_id': batterId,
      if (bowlerId != null) 'bowler_id': bowlerId,
      if (timestamp != null) 'timestamp': timestamp,
    });
  }

  BallEventsCompanion copyWith({
    Value<int>? id,
    Value<int>? matchId,
    Value<int>? overNumber,
    Value<int>? ballNumber,
    Value<int>? runs,
    Value<bool>? isWicket,
    Value<String?>? wicketType,
    Value<bool>? isExtra,
    Value<String?>? extraType,
    Value<int>? batterId,
    Value<int>? bowlerId,
    Value<DateTime>? timestamp,
  }) {
    return BallEventsCompanion(
      id: id ?? this.id,
      matchId: matchId ?? this.matchId,
      overNumber: overNumber ?? this.overNumber,
      ballNumber: ballNumber ?? this.ballNumber,
      runs: runs ?? this.runs,
      isWicket: isWicket ?? this.isWicket,
      wicketType: wicketType ?? this.wicketType,
      isExtra: isExtra ?? this.isExtra,
      extraType: extraType ?? this.extraType,
      batterId: batterId ?? this.batterId,
      bowlerId: bowlerId ?? this.bowlerId,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (matchId.present) {
      map['match_id'] = Variable<int>(matchId.value);
    }
    if (overNumber.present) {
      map['over_number'] = Variable<int>(overNumber.value);
    }
    if (ballNumber.present) {
      map['ball_number'] = Variable<int>(ballNumber.value);
    }
    if (runs.present) {
      map['runs'] = Variable<int>(runs.value);
    }
    if (isWicket.present) {
      map['is_wicket'] = Variable<bool>(isWicket.value);
    }
    if (wicketType.present) {
      map['wicket_type'] = Variable<String>(wicketType.value);
    }
    if (isExtra.present) {
      map['is_extra'] = Variable<bool>(isExtra.value);
    }
    if (extraType.present) {
      map['extra_type'] = Variable<String>(extraType.value);
    }
    if (batterId.present) {
      map['batter_id'] = Variable<int>(batterId.value);
    }
    if (bowlerId.present) {
      map['bowler_id'] = Variable<int>(bowlerId.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BallEventsCompanion(')
          ..write('id: $id, ')
          ..write('matchId: $matchId, ')
          ..write('overNumber: $overNumber, ')
          ..write('ballNumber: $ballNumber, ')
          ..write('runs: $runs, ')
          ..write('isWicket: $isWicket, ')
          ..write('wicketType: $wicketType, ')
          ..write('isExtra: $isExtra, ')
          ..write('extraType: $extraType, ')
          ..write('batterId: $batterId, ')
          ..write('bowlerId: $bowlerId, ')
          ..write('timestamp: $timestamp')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $MatchesTable matches = $MatchesTable(this);
  late final $TeamsTable teams = $TeamsTable(this);
  late final $PlayersTable players = $PlayersTable(this);
  late final $BallEventsTable ballEvents = $BallEventsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    matches,
    teams,
    players,
    ballEvents,
  ];
}

typedef $$MatchesTableCreateCompanionBuilder =
    MatchesCompanion Function({
      Value<int> id,
      required String matchTitle,
      required int totalOvers,
      Value<int?> teamAId,
      Value<int?> teamBId,
      Value<DateTime> createdAt,
      Value<bool> isCompleted,
      Value<String?> winnerTeamName,
      Value<int> currentInnings,
      Value<int> teamARuns,
      Value<int> teamAWickets,
      Value<int> teamAOvers,
      Value<int> teamABalls,
      Value<int> teamBRuns,
      Value<int> teamBWickets,
      Value<int> teamBOvers,
      Value<int> teamBBalls,
    });
typedef $$MatchesTableUpdateCompanionBuilder =
    MatchesCompanion Function({
      Value<int> id,
      Value<String> matchTitle,
      Value<int> totalOvers,
      Value<int?> teamAId,
      Value<int?> teamBId,
      Value<DateTime> createdAt,
      Value<bool> isCompleted,
      Value<String?> winnerTeamName,
      Value<int> currentInnings,
      Value<int> teamARuns,
      Value<int> teamAWickets,
      Value<int> teamAOvers,
      Value<int> teamABalls,
      Value<int> teamBRuns,
      Value<int> teamBWickets,
      Value<int> teamBOvers,
      Value<int> teamBBalls,
    });

class $$MatchesTableFilterComposer
    extends Composer<_$AppDatabase, $MatchesTable> {
  $$MatchesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get matchTitle => $composableBuilder(
    column: $table.matchTitle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalOvers => $composableBuilder(
    column: $table.totalOvers,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get teamAId => $composableBuilder(
    column: $table.teamAId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get teamBId => $composableBuilder(
    column: $table.teamBId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get winnerTeamName => $composableBuilder(
    column: $table.winnerTeamName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get currentInnings => $composableBuilder(
    column: $table.currentInnings,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get teamARuns => $composableBuilder(
    column: $table.teamARuns,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get teamAWickets => $composableBuilder(
    column: $table.teamAWickets,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get teamAOvers => $composableBuilder(
    column: $table.teamAOvers,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get teamABalls => $composableBuilder(
    column: $table.teamABalls,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get teamBRuns => $composableBuilder(
    column: $table.teamBRuns,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get teamBWickets => $composableBuilder(
    column: $table.teamBWickets,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get teamBOvers => $composableBuilder(
    column: $table.teamBOvers,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get teamBBalls => $composableBuilder(
    column: $table.teamBBalls,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MatchesTableOrderingComposer
    extends Composer<_$AppDatabase, $MatchesTable> {
  $$MatchesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get matchTitle => $composableBuilder(
    column: $table.matchTitle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalOvers => $composableBuilder(
    column: $table.totalOvers,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get teamAId => $composableBuilder(
    column: $table.teamAId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get teamBId => $composableBuilder(
    column: $table.teamBId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get winnerTeamName => $composableBuilder(
    column: $table.winnerTeamName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get currentInnings => $composableBuilder(
    column: $table.currentInnings,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get teamARuns => $composableBuilder(
    column: $table.teamARuns,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get teamAWickets => $composableBuilder(
    column: $table.teamAWickets,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get teamAOvers => $composableBuilder(
    column: $table.teamAOvers,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get teamABalls => $composableBuilder(
    column: $table.teamABalls,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get teamBRuns => $composableBuilder(
    column: $table.teamBRuns,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get teamBWickets => $composableBuilder(
    column: $table.teamBWickets,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get teamBOvers => $composableBuilder(
    column: $table.teamBOvers,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get teamBBalls => $composableBuilder(
    column: $table.teamBBalls,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MatchesTableAnnotationComposer
    extends Composer<_$AppDatabase, $MatchesTable> {
  $$MatchesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get matchTitle => $composableBuilder(
    column: $table.matchTitle,
    builder: (column) => column,
  );

  GeneratedColumn<int> get totalOvers => $composableBuilder(
    column: $table.totalOvers,
    builder: (column) => column,
  );

  GeneratedColumn<int> get teamAId =>
      $composableBuilder(column: $table.teamAId, builder: (column) => column);

  GeneratedColumn<int> get teamBId =>
      $composableBuilder(column: $table.teamBId, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => column,
  );

  GeneratedColumn<String> get winnerTeamName => $composableBuilder(
    column: $table.winnerTeamName,
    builder: (column) => column,
  );

  GeneratedColumn<int> get currentInnings => $composableBuilder(
    column: $table.currentInnings,
    builder: (column) => column,
  );

  GeneratedColumn<int> get teamARuns =>
      $composableBuilder(column: $table.teamARuns, builder: (column) => column);

  GeneratedColumn<int> get teamAWickets => $composableBuilder(
    column: $table.teamAWickets,
    builder: (column) => column,
  );

  GeneratedColumn<int> get teamAOvers => $composableBuilder(
    column: $table.teamAOvers,
    builder: (column) => column,
  );

  GeneratedColumn<int> get teamABalls => $composableBuilder(
    column: $table.teamABalls,
    builder: (column) => column,
  );

  GeneratedColumn<int> get teamBRuns =>
      $composableBuilder(column: $table.teamBRuns, builder: (column) => column);

  GeneratedColumn<int> get teamBWickets => $composableBuilder(
    column: $table.teamBWickets,
    builder: (column) => column,
  );

  GeneratedColumn<int> get teamBOvers => $composableBuilder(
    column: $table.teamBOvers,
    builder: (column) => column,
  );

  GeneratedColumn<int> get teamBBalls => $composableBuilder(
    column: $table.teamBBalls,
    builder: (column) => column,
  );
}

class $$MatchesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MatchesTable,
          CricketMatch,
          $$MatchesTableFilterComposer,
          $$MatchesTableOrderingComposer,
          $$MatchesTableAnnotationComposer,
          $$MatchesTableCreateCompanionBuilder,
          $$MatchesTableUpdateCompanionBuilder,
          (
            CricketMatch,
            BaseReferences<_$AppDatabase, $MatchesTable, CricketMatch>,
          ),
          CricketMatch,
          PrefetchHooks Function()
        > {
  $$MatchesTableTableManager(_$AppDatabase db, $MatchesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MatchesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MatchesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MatchesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> matchTitle = const Value.absent(),
                Value<int> totalOvers = const Value.absent(),
                Value<int?> teamAId = const Value.absent(),
                Value<int?> teamBId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<bool> isCompleted = const Value.absent(),
                Value<String?> winnerTeamName = const Value.absent(),
                Value<int> currentInnings = const Value.absent(),
                Value<int> teamARuns = const Value.absent(),
                Value<int> teamAWickets = const Value.absent(),
                Value<int> teamAOvers = const Value.absent(),
                Value<int> teamABalls = const Value.absent(),
                Value<int> teamBRuns = const Value.absent(),
                Value<int> teamBWickets = const Value.absent(),
                Value<int> teamBOvers = const Value.absent(),
                Value<int> teamBBalls = const Value.absent(),
              }) => MatchesCompanion(
                id: id,
                matchTitle: matchTitle,
                totalOvers: totalOvers,
                teamAId: teamAId,
                teamBId: teamBId,
                createdAt: createdAt,
                isCompleted: isCompleted,
                winnerTeamName: winnerTeamName,
                currentInnings: currentInnings,
                teamARuns: teamARuns,
                teamAWickets: teamAWickets,
                teamAOvers: teamAOvers,
                teamABalls: teamABalls,
                teamBRuns: teamBRuns,
                teamBWickets: teamBWickets,
                teamBOvers: teamBOvers,
                teamBBalls: teamBBalls,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String matchTitle,
                required int totalOvers,
                Value<int?> teamAId = const Value.absent(),
                Value<int?> teamBId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<bool> isCompleted = const Value.absent(),
                Value<String?> winnerTeamName = const Value.absent(),
                Value<int> currentInnings = const Value.absent(),
                Value<int> teamARuns = const Value.absent(),
                Value<int> teamAWickets = const Value.absent(),
                Value<int> teamAOvers = const Value.absent(),
                Value<int> teamABalls = const Value.absent(),
                Value<int> teamBRuns = const Value.absent(),
                Value<int> teamBWickets = const Value.absent(),
                Value<int> teamBOvers = const Value.absent(),
                Value<int> teamBBalls = const Value.absent(),
              }) => MatchesCompanion.insert(
                id: id,
                matchTitle: matchTitle,
                totalOvers: totalOvers,
                teamAId: teamAId,
                teamBId: teamBId,
                createdAt: createdAt,
                isCompleted: isCompleted,
                winnerTeamName: winnerTeamName,
                currentInnings: currentInnings,
                teamARuns: teamARuns,
                teamAWickets: teamAWickets,
                teamAOvers: teamAOvers,
                teamABalls: teamABalls,
                teamBRuns: teamBRuns,
                teamBWickets: teamBWickets,
                teamBOvers: teamBOvers,
                teamBBalls: teamBBalls,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MatchesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MatchesTable,
      CricketMatch,
      $$MatchesTableFilterComposer,
      $$MatchesTableOrderingComposer,
      $$MatchesTableAnnotationComposer,
      $$MatchesTableCreateCompanionBuilder,
      $$MatchesTableUpdateCompanionBuilder,
      (
        CricketMatch,
        BaseReferences<_$AppDatabase, $MatchesTable, CricketMatch>,
      ),
      CricketMatch,
      PrefetchHooks Function()
    >;
typedef $$TeamsTableCreateCompanionBuilder =
    TeamsCompanion Function({Value<int> id, required String name});
typedef $$TeamsTableUpdateCompanionBuilder =
    TeamsCompanion Function({Value<int> id, Value<String> name});

class $$TeamsTableFilterComposer extends Composer<_$AppDatabase, $TeamsTable> {
  $$TeamsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TeamsTableOrderingComposer
    extends Composer<_$AppDatabase, $TeamsTable> {
  $$TeamsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TeamsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TeamsTable> {
  $$TeamsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);
}

class $$TeamsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TeamsTable,
          Team,
          $$TeamsTableFilterComposer,
          $$TeamsTableOrderingComposer,
          $$TeamsTableAnnotationComposer,
          $$TeamsTableCreateCompanionBuilder,
          $$TeamsTableUpdateCompanionBuilder,
          (Team, BaseReferences<_$AppDatabase, $TeamsTable, Team>),
          Team,
          PrefetchHooks Function()
        > {
  $$TeamsTableTableManager(_$AppDatabase db, $TeamsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TeamsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TeamsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TeamsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
              }) => TeamsCompanion(id: id, name: name),
          createCompanionCallback:
              ({Value<int> id = const Value.absent(), required String name}) =>
                  TeamsCompanion.insert(id: id, name: name),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TeamsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TeamsTable,
      Team,
      $$TeamsTableFilterComposer,
      $$TeamsTableOrderingComposer,
      $$TeamsTableAnnotationComposer,
      $$TeamsTableCreateCompanionBuilder,
      $$TeamsTableUpdateCompanionBuilder,
      (Team, BaseReferences<_$AppDatabase, $TeamsTable, Team>),
      Team,
      PrefetchHooks Function()
    >;
typedef $$PlayersTableCreateCompanionBuilder =
    PlayersCompanion Function({
      Value<int> id,
      required String name,
      Value<int?> teamId,
      Value<int> runsConceded,
      Value<int> wicketsTaken,
      Value<int> runsScored,
      Value<int> ballsFaced,
      Value<int> fours,
      Value<int> sixes,
    });
typedef $$PlayersTableUpdateCompanionBuilder =
    PlayersCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<int?> teamId,
      Value<int> runsConceded,
      Value<int> wicketsTaken,
      Value<int> runsScored,
      Value<int> ballsFaced,
      Value<int> fours,
      Value<int> sixes,
    });

class $$PlayersTableFilterComposer
    extends Composer<_$AppDatabase, $PlayersTable> {
  $$PlayersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get teamId => $composableBuilder(
    column: $table.teamId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get runsConceded => $composableBuilder(
    column: $table.runsConceded,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get wicketsTaken => $composableBuilder(
    column: $table.wicketsTaken,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get runsScored => $composableBuilder(
    column: $table.runsScored,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ballsFaced => $composableBuilder(
    column: $table.ballsFaced,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fours => $composableBuilder(
    column: $table.fours,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sixes => $composableBuilder(
    column: $table.sixes,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PlayersTableOrderingComposer
    extends Composer<_$AppDatabase, $PlayersTable> {
  $$PlayersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get teamId => $composableBuilder(
    column: $table.teamId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get runsConceded => $composableBuilder(
    column: $table.runsConceded,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get wicketsTaken => $composableBuilder(
    column: $table.wicketsTaken,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get runsScored => $composableBuilder(
    column: $table.runsScored,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ballsFaced => $composableBuilder(
    column: $table.ballsFaced,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fours => $composableBuilder(
    column: $table.fours,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sixes => $composableBuilder(
    column: $table.sixes,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PlayersTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlayersTable> {
  $$PlayersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get teamId =>
      $composableBuilder(column: $table.teamId, builder: (column) => column);

  GeneratedColumn<int> get runsConceded => $composableBuilder(
    column: $table.runsConceded,
    builder: (column) => column,
  );

  GeneratedColumn<int> get wicketsTaken => $composableBuilder(
    column: $table.wicketsTaken,
    builder: (column) => column,
  );

  GeneratedColumn<int> get runsScored => $composableBuilder(
    column: $table.runsScored,
    builder: (column) => column,
  );

  GeneratedColumn<int> get ballsFaced => $composableBuilder(
    column: $table.ballsFaced,
    builder: (column) => column,
  );

  GeneratedColumn<int> get fours =>
      $composableBuilder(column: $table.fours, builder: (column) => column);

  GeneratedColumn<int> get sixes =>
      $composableBuilder(column: $table.sixes, builder: (column) => column);
}

class $$PlayersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PlayersTable,
          Player,
          $$PlayersTableFilterComposer,
          $$PlayersTableOrderingComposer,
          $$PlayersTableAnnotationComposer,
          $$PlayersTableCreateCompanionBuilder,
          $$PlayersTableUpdateCompanionBuilder,
          (Player, BaseReferences<_$AppDatabase, $PlayersTable, Player>),
          Player,
          PrefetchHooks Function()
        > {
  $$PlayersTableTableManager(_$AppDatabase db, $PlayersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlayersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlayersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlayersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int?> teamId = const Value.absent(),
                Value<int> runsConceded = const Value.absent(),
                Value<int> wicketsTaken = const Value.absent(),
                Value<int> runsScored = const Value.absent(),
                Value<int> ballsFaced = const Value.absent(),
                Value<int> fours = const Value.absent(),
                Value<int> sixes = const Value.absent(),
              }) => PlayersCompanion(
                id: id,
                name: name,
                teamId: teamId,
                runsConceded: runsConceded,
                wicketsTaken: wicketsTaken,
                runsScored: runsScored,
                ballsFaced: ballsFaced,
                fours: fours,
                sixes: sixes,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                Value<int?> teamId = const Value.absent(),
                Value<int> runsConceded = const Value.absent(),
                Value<int> wicketsTaken = const Value.absent(),
                Value<int> runsScored = const Value.absent(),
                Value<int> ballsFaced = const Value.absent(),
                Value<int> fours = const Value.absent(),
                Value<int> sixes = const Value.absent(),
              }) => PlayersCompanion.insert(
                id: id,
                name: name,
                teamId: teamId,
                runsConceded: runsConceded,
                wicketsTaken: wicketsTaken,
                runsScored: runsScored,
                ballsFaced: ballsFaced,
                fours: fours,
                sixes: sixes,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PlayersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PlayersTable,
      Player,
      $$PlayersTableFilterComposer,
      $$PlayersTableOrderingComposer,
      $$PlayersTableAnnotationComposer,
      $$PlayersTableCreateCompanionBuilder,
      $$PlayersTableUpdateCompanionBuilder,
      (Player, BaseReferences<_$AppDatabase, $PlayersTable, Player>),
      Player,
      PrefetchHooks Function()
    >;
typedef $$BallEventsTableCreateCompanionBuilder =
    BallEventsCompanion Function({
      Value<int> id,
      required int matchId,
      Value<int> overNumber,
      Value<int> ballNumber,
      Value<int> runs,
      Value<bool> isWicket,
      Value<String?> wicketType,
      Value<bool> isExtra,
      Value<String?> extraType,
      required int batterId,
      required int bowlerId,
      Value<DateTime> timestamp,
    });
typedef $$BallEventsTableUpdateCompanionBuilder =
    BallEventsCompanion Function({
      Value<int> id,
      Value<int> matchId,
      Value<int> overNumber,
      Value<int> ballNumber,
      Value<int> runs,
      Value<bool> isWicket,
      Value<String?> wicketType,
      Value<bool> isExtra,
      Value<String?> extraType,
      Value<int> batterId,
      Value<int> bowlerId,
      Value<DateTime> timestamp,
    });

class $$BallEventsTableFilterComposer
    extends Composer<_$AppDatabase, $BallEventsTable> {
  $$BallEventsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get matchId => $composableBuilder(
    column: $table.matchId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get overNumber => $composableBuilder(
    column: $table.overNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ballNumber => $composableBuilder(
    column: $table.ballNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get runs => $composableBuilder(
    column: $table.runs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isWicket => $composableBuilder(
    column: $table.isWicket,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get wicketType => $composableBuilder(
    column: $table.wicketType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isExtra => $composableBuilder(
    column: $table.isExtra,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get extraType => $composableBuilder(
    column: $table.extraType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get batterId => $composableBuilder(
    column: $table.batterId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get bowlerId => $composableBuilder(
    column: $table.bowlerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BallEventsTableOrderingComposer
    extends Composer<_$AppDatabase, $BallEventsTable> {
  $$BallEventsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get matchId => $composableBuilder(
    column: $table.matchId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get overNumber => $composableBuilder(
    column: $table.overNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ballNumber => $composableBuilder(
    column: $table.ballNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get runs => $composableBuilder(
    column: $table.runs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isWicket => $composableBuilder(
    column: $table.isWicket,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get wicketType => $composableBuilder(
    column: $table.wicketType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isExtra => $composableBuilder(
    column: $table.isExtra,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get extraType => $composableBuilder(
    column: $table.extraType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get batterId => $composableBuilder(
    column: $table.batterId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get bowlerId => $composableBuilder(
    column: $table.bowlerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BallEventsTableAnnotationComposer
    extends Composer<_$AppDatabase, $BallEventsTable> {
  $$BallEventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get matchId =>
      $composableBuilder(column: $table.matchId, builder: (column) => column);

  GeneratedColumn<int> get overNumber => $composableBuilder(
    column: $table.overNumber,
    builder: (column) => column,
  );

  GeneratedColumn<int> get ballNumber => $composableBuilder(
    column: $table.ballNumber,
    builder: (column) => column,
  );

  GeneratedColumn<int> get runs =>
      $composableBuilder(column: $table.runs, builder: (column) => column);

  GeneratedColumn<bool> get isWicket =>
      $composableBuilder(column: $table.isWicket, builder: (column) => column);

  GeneratedColumn<String> get wicketType => $composableBuilder(
    column: $table.wicketType,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isExtra =>
      $composableBuilder(column: $table.isExtra, builder: (column) => column);

  GeneratedColumn<String> get extraType =>
      $composableBuilder(column: $table.extraType, builder: (column) => column);

  GeneratedColumn<int> get batterId =>
      $composableBuilder(column: $table.batterId, builder: (column) => column);

  GeneratedColumn<int> get bowlerId =>
      $composableBuilder(column: $table.bowlerId, builder: (column) => column);

  GeneratedColumn<DateTime> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);
}

class $$BallEventsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BallEventsTable,
          BallEvent,
          $$BallEventsTableFilterComposer,
          $$BallEventsTableOrderingComposer,
          $$BallEventsTableAnnotationComposer,
          $$BallEventsTableCreateCompanionBuilder,
          $$BallEventsTableUpdateCompanionBuilder,
          (
            BallEvent,
            BaseReferences<_$AppDatabase, $BallEventsTable, BallEvent>,
          ),
          BallEvent,
          PrefetchHooks Function()
        > {
  $$BallEventsTableTableManager(_$AppDatabase db, $BallEventsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BallEventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BallEventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BallEventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> matchId = const Value.absent(),
                Value<int> overNumber = const Value.absent(),
                Value<int> ballNumber = const Value.absent(),
                Value<int> runs = const Value.absent(),
                Value<bool> isWicket = const Value.absent(),
                Value<String?> wicketType = const Value.absent(),
                Value<bool> isExtra = const Value.absent(),
                Value<String?> extraType = const Value.absent(),
                Value<int> batterId = const Value.absent(),
                Value<int> bowlerId = const Value.absent(),
                Value<DateTime> timestamp = const Value.absent(),
              }) => BallEventsCompanion(
                id: id,
                matchId: matchId,
                overNumber: overNumber,
                ballNumber: ballNumber,
                runs: runs,
                isWicket: isWicket,
                wicketType: wicketType,
                isExtra: isExtra,
                extraType: extraType,
                batterId: batterId,
                bowlerId: bowlerId,
                timestamp: timestamp,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int matchId,
                Value<int> overNumber = const Value.absent(),
                Value<int> ballNumber = const Value.absent(),
                Value<int> runs = const Value.absent(),
                Value<bool> isWicket = const Value.absent(),
                Value<String?> wicketType = const Value.absent(),
                Value<bool> isExtra = const Value.absent(),
                Value<String?> extraType = const Value.absent(),
                required int batterId,
                required int bowlerId,
                Value<DateTime> timestamp = const Value.absent(),
              }) => BallEventsCompanion.insert(
                id: id,
                matchId: matchId,
                overNumber: overNumber,
                ballNumber: ballNumber,
                runs: runs,
                isWicket: isWicket,
                wicketType: wicketType,
                isExtra: isExtra,
                extraType: extraType,
                batterId: batterId,
                bowlerId: bowlerId,
                timestamp: timestamp,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BallEventsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BallEventsTable,
      BallEvent,
      $$BallEventsTableFilterComposer,
      $$BallEventsTableOrderingComposer,
      $$BallEventsTableAnnotationComposer,
      $$BallEventsTableCreateCompanionBuilder,
      $$BallEventsTableUpdateCompanionBuilder,
      (BallEvent, BaseReferences<_$AppDatabase, $BallEventsTable, BallEvent>),
      BallEvent,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$MatchesTableTableManager get matches =>
      $$MatchesTableTableManager(_db, _db.matches);
  $$TeamsTableTableManager get teams =>
      $$TeamsTableTableManager(_db, _db.teams);
  $$PlayersTableTableManager get players =>
      $$PlayersTableTableManager(_db, _db.players);
  $$BallEventsTableTableManager get ballEvents =>
      $$BallEventsTableTableManager(_db, _db.ballEvents);
}
