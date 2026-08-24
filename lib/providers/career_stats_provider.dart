import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

/// Aggregated career stats computed from local match data
class CareerStats {
  // Overview
  final int matches;
  final int totalRuns;
  final int totalWickets;
  final int catches;
  final List<String> recentForm; // 'W' or 'L'

  // Batting
  final int innings;
  final int notOuts;
  final int highScore;
  final int fifties;
  final int hundreds;
  final int fours;
  final int sixes;
  final int ballsFaced;
  final int ducks;
  final List<Map<String, dynamic>> recentInnings;

  // Bowling
  final int overs;
  final int maidens;
  final int runsConceded;
  final int wides;
  final int noBalls;
  final int fourWicketHauls;
  final int fiveWicketHauls;
  final String bestBowling;
  final List<Map<String, dynamic>> recentBowling;

  // Fielding
  final int catchesTaken;
  final int runOutInvolvements;
  final int stumpings;

  // Derived
  double get battingAvg => innings > notOuts ? totalRuns / (innings - notOuts) : totalRuns.toDouble();
  double get strikeRate => ballsFaced > 0 ? (totalRuns / ballsFaced) * 100 : 0;
  double get economy => overs > 0 ? runsConceded / overs : 0;
  double get bowlingAvg => totalWickets > 0 ? runsConceded / totalWickets : 0;
  double get boundaryPct => ballsFaced > 0 ? ((fours * 4 + sixes * 6) / totalRuns) * 100 : 0;

  // Chart data
  final List<double> runsPerMatch;
  final List<double> wicketsPerMatch;

  const CareerStats({
    this.matches = 0,
    this.totalRuns = 0,
    this.totalWickets = 0,
    this.catches = 0,
    this.recentForm = const [],
    this.innings = 0,
    this.notOuts = 0,
    this.highScore = 0,
    this.fifties = 0,
    this.hundreds = 0,
    this.fours = 0,
    this.sixes = 0,
    this.ballsFaced = 0,
    this.ducks = 0,
    this.recentInnings = const [],
    this.overs = 0,
    this.maidens = 0,
    this.runsConceded = 0,
    this.wides = 0,
    this.noBalls = 0,
    this.fourWicketHauls = 0,
    this.fiveWicketHauls = 0,
    this.bestBowling = '-',
    this.recentBowling = const [],
    this.catchesTaken = 0,
    this.runOutInvolvements = 0,
    this.stumpings = 0,
    this.runsPerMatch = const [],
    this.wicketsPerMatch = const [],
  });
}


final careerStatsProvider = FutureProvider<CareerStats>((ref) async {
  final url = 'https://ip53vj9s.ap-southeast.insforge.app/api/database/records/matches?status=eq.completed';
  final headers = {
    'apikey': 'ik_d23aa9a406864853f254a0722fc1e56b',
    'Authorization': 'Bearer ik_d23aa9a406864853f254a0722fc1e56b',
    'Content-Type': 'application/json',
  };

  List<dynamic> completedRaw = [];
  try {
    final res = await http.get(Uri.parse(url), headers: headers);
    if (res.statusCode == 200) {
      completedRaw = jsonDecode(res.body) as List<dynamic>;
    }
  } catch (e) {
    debugPrint('Error fetching from Insforge: $e');
  }

  if (completedRaw.isEmpty) return const CareerStats();

  int totalRuns = 0;
  int totalWickets = 0;
  int innings = 0;
  int notOuts = 0;
  int highScore = 0;
  int fifties = 0;
  int hundreds = 0;
  int fours = 0;
  int sixes = 0;
  int ballsFaced = 0;
  int ducks = 0;
  int overs = 0;
  int runsConceded = 0;
  int wides = 0;
  int noBalls = 0;
  int fourWicketHauls = 0;
  int fiveWicketHauls = 0;
  int bestWickets = 0;
  int bestRunsConceded = 9999;

  final List<String> recentForm = [];
  final List<double> runsPerMatch = [];
  final List<double> wicketsPerMatch = [];

  for (final m in completedRaw.take(20)) {
    int tARuns = 0, tAWickets = 0, tBRuns = 0, tBWickets = 0;
    
    final summary = m['match_result_summary'] as String?;
    if (summary != null && summary.contains(' vs ')) {
      final parts = summary.split(' vs ');
      if (parts.length == 2) {
        final aParts = parts[0].split('/');
        if (aParts.length == 2) {
          tARuns = int.tryParse(aParts[0]) ?? 0;
          tAWickets = int.tryParse(aParts[1]) ?? 0;
        }
        final bParts = parts[1].split('/');
        if (bParts.length == 2) {
          tBRuns = int.tryParse(bParts[0]) ?? 0;
          tBWickets = int.tryParse(bParts[1]) ?? 0;
        }
      }
    }

    final matchRuns = tARuns + tBRuns;
    final matchWickets = tAWickets + tBWickets;
    totalRuns += matchRuns;
    totalWickets += matchWickets;
    innings++;

    final thisMatchRuns = tARuns;
    runsPerMatch.add(thisMatchRuns.toDouble());
    wicketsPerMatch.add(tAWickets.toDouble());

    if (thisMatchRuns > highScore) highScore = thisMatchRuns;
    if (thisMatchRuns >= 50 && thisMatchRuns < 100) fifties++;
    if (thisMatchRuns >= 100) hundreds++;
    if (thisMatchRuns == 0) ducks++;

    final mOvers = m['total_overs'] as int? ?? 20;
    overs += mOvers;
    runsConceded += tBRuns;
    if (tAWickets >= 5) {
      fiveWicketHauls++;
    } else if (tAWickets >= 4) {
      fourWicketHauls++;
    }

    if (tAWickets > bestWickets ||
        (tAWickets == bestWickets && tBRuns < bestRunsConceded)) {
      bestWickets = tAWickets;
      bestRunsConceded = tBRuns;
    }

    // Rough approximation for form
    recentForm.add(tARuns > tBRuns ? 'W' : (tARuns < tBRuns ? 'L' : 'D'));
  }

  final String bestBowling = bestWickets > 0 ? '$bestWickets/$bestRunsConceded' : '-';

  final recentInnings = completedRaw.take(5).map((m) {
    int tARuns = 0;
    final summary = m['match_result_summary'] as String?;
    if (summary != null && summary.contains(' vs ')) {
      final aParts = summary.split(' vs ')[0].split('/');
      if (aParts.isNotEmpty) tARuns = int.tryParse(aParts[0]) ?? 0;
    }
    final mOvers = m['total_overs'] as int? ?? 20;
    final balls = mOvers * 6;
    final sr = balls > 0 ? (tARuns / balls * 100) : 0.0;
    return <String, dynamic>{
      'runs': tARuns,
      'balls': balls,
      'fours': 0,
      'sixes': 0,
      'sr': sr,
      'notOut': false,
    };
  }).toList();

  final recentBowling = completedRaw.take(5).map((m) {
    int tAWickets = 0, tBRuns = 0;
    final summary = m['match_result_summary'] as String?;
    if (summary != null && summary.contains(' vs ')) {
      final parts = summary.split(' vs ');
      if (parts.length == 2) {
        final aParts = parts[0].split('/');
        if (aParts.length == 2) tAWickets = int.tryParse(aParts[1]) ?? 0;
        final bParts = parts[1].split('/');
        if (bParts.length == 2) tBRuns = int.tryParse(bParts[0]) ?? 0;
      }
    }
    final mOvers = m['total_overs'] as int? ?? 20;
    return <String, dynamic>{
      'overs': mOvers,
      'maidens': 0,
      'runs': tBRuns,
      'wickets': tAWickets,
    };
  }).toList();

  return CareerStats(
    matches: completedRaw.length,
    totalRuns: totalRuns,
    totalWickets: totalWickets,
    catches: 0,
    recentForm: recentForm.take(5).toList(),
    innings: innings,
    notOuts: notOuts,
    highScore: highScore,
    fifties: fifties,
    hundreds: hundreds,
    fours: fours,
    sixes: sixes,
    ballsFaced: ballsFaced,
    ducks: ducks,
    recentInnings: recentInnings,
    overs: overs,
    maidens: 0,
    runsConceded: runsConceded,
    wides: wides,
    noBalls: noBalls,
    fourWicketHauls: fourWicketHauls,
    fiveWicketHauls: fiveWicketHauls,
    bestBowling: bestBowling,
    recentBowling: recentBowling,
    catchesTaken: 0,
    runOutInvolvements: 0,
    stumpings: 0,
    runsPerMatch: runsPerMatch,
    wicketsPerMatch: wicketsPerMatch,
  );
});
