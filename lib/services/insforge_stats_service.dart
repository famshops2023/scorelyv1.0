import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/config/insforge_config.dart';
import '../providers/history_provider.dart';
import '../providers/career_stats_provider.dart';

class InsforgeScorerStats {
  final int totalMatches;
  final int totalRunsScored;
  final int totalWicketsTaken;
  final int thisMonthRuns;
  final int thisMonthWickets;

  const InsforgeScorerStats({
    this.totalMatches = 0,
    this.totalRunsScored = 0,
    this.totalWicketsTaken = 0,
    this.thisMonthRuns = 0,
    this.thisMonthWickets = 0,
  });
}

class InsforgeStatsService {
  static String get _recordsUrl => InsforgeConfig.recordsUrl;

  static bool _isTurf(String venue) {
    final v = venue.toLowerCase();
    return v.contains('turf') || v.contains('box');
  }

  /// Fetches Home Stats exclusively from InsForge for a signed-in user.
  /// Uses [InsforgeConfig.getWithFallback] on every request so that an expired
  /// JWT silently retries with the anonymous API key instead of returning empty.
  static Future<HomePersonalStats> fetchHomeStats(
    String creatorId,
    String userName,
  ) async {
    if (creatorId.isEmpty) return const HomePersonalStats();

    try {
      // Fetch matches where user is creator/active scorer, OR a squad participant
      // in player_profile_ids. Use getWithFallback() on all requests.
      final creatorUri = Uri.parse('$_recordsUrl/matches').replace(queryParameters: {
        'or': '(creator_id.eq.$creatorId,active_scorer_id.eq.$creatorId)',
        'status': 'eq.completed',
        'select': 'id,venue,match_date,match_result_summary',
      });
      final playerUri = Uri.parse('$_recordsUrl/matches').replace(queryParameters: {
        'player_profile_ids': 'cs.["$creatorId"]',
        'status': 'eq.completed',
        'select': 'id,venue,match_date,match_result_summary',
      });

      final responses = await Future.wait([
        InsforgeConfig.getWithFallback(creatorUri).catchError((_) => http.Response('[]', 200)),
        InsforgeConfig.getWithFallback(playerUri).catchError((_) => http.Response('[]', 200)),
      ]);

      final Map<String, Map<String, dynamic>> matchMap = {};
      for (final res in responses) {
        if (res.statusCode == 200) {
          try {
            final List list = jsonDecode(res.body);
            for (final m in list) {
              if (m is Map) {
                final id = m['id']?.toString() ?? '';
                if (id.isNotEmpty) matchMap[id] = m as Map<String, dynamic>;
              }
            }
          } catch (_) {}
        }
      }

      if (matchMap.isEmpty) return const HomePersonalStats();
      final matchIds = matchMap.keys.toList();
      final matches = matchMap.values.toList();

      // Fetch innings for these matches
      final inningsRes = await InsforgeConfig.getWithFallback(
        Uri.parse('$_recordsUrl/innings').replace(queryParameters: {
          'match_id': 'in.(${matchIds.join(',')})',
          'select': 'id,match_id,innings_number,total_runs,total_wickets',
        }),
      );

      final List<dynamic> innings = inningsRes.statusCode == 200 ? jsonDecode(inningsRes.body) : [];
      final inningsMap = <String, String>{}; // innings_id -> match_id
      for (var inn in innings) {
        inningsMap[inn['id'].toString()] = inn['match_id'].toString();
      }

      final inningsIds = inningsMap.keys.toList();
      List<dynamic> balls = [];
      if (inningsIds.isNotEmpty) {
        // Query up to first 50 innings to avoid URL length issues
        final chunk = inningsIds.take(50).join(',');
        final ballsRes = await InsforgeConfig.getWithFallback(
          Uri.parse('$_recordsUrl/balls').replace(queryParameters: {
            'innings_id': 'in.($chunk)',
            'select': 'innings_id,runs_scored,extras,extra_type,is_wicket,wicket_type,commentary',
          }),
        );
        if (ballsRes.statusCode == 200) {
          balls = jsonDecode(ballsRes.body);
        }
      }

      final myName = userName.trim().toLowerCase();
      bool hasPersonalBalls = false;
      int personalTurfRuns = 0, personalTurfWkts = 0;
      int personalGroundRuns = 0, personalGroundWkts = 0;
      final Set<String> turfMatchIds = {};
      final Set<String> groundMatchIds = {};

      if (myName.isNotEmpty && myName != 'scorely user') {
        for (var b in balls) {
          final comm = (b['commentary'] ?? '').toString().toLowerCase();
          final innId = b['innings_id'].toString();
          final mId = inningsMap[innId];
          final match = mId != null ? matchMap[mId] : null;
          final isT = match != null ? _isTurf(match['venue']?.toString() ?? '') : false;

          // Check batter: comm format "batter vs bowler"
          final parts = comm.split(' vs ');
          final batter = parts.isNotEmpty ? parts[0].trim() : '';
          final bowler = parts.length > 1 ? parts[1].trim() : '';

          final isWide = (b['extra_type'] ?? '').toString().toLowerCase() == 'wide';
          final runs = (b['runs_scored'] as num?)?.toInt() ?? 0;

          if (batter == myName && !isWide) {
            hasPersonalBalls = true;
            if (isT) {
              personalTurfRuns += runs;
              if (mId != null) turfMatchIds.add(mId);
            } else {
              personalGroundRuns += runs;
              if (mId != null) groundMatchIds.add(mId);
            }
          }

          final isWkt = b['is_wicket'] == true;
          final wType = (b['wicket_type'] ?? '').toString().toLowerCase();
          final bowlerWicket = wType != 'run out' && wType != 'stumped';
          if (bowler == myName && isWkt && bowlerWicket) {
            hasPersonalBalls = true;
            if (isT) {
              personalTurfWkts++;
              if (mId != null) turfMatchIds.add(mId);
            } else {
              personalGroundWkts++;
              if (mId != null) groundMatchIds.add(mId);
            }
          }
        }
      }

      if (hasPersonalBalls) {
        return HomePersonalStats(
          turfMatches: turfMatchIds.length,
          turfRuns: personalTurfRuns,
          turfWickets: personalTurfWkts,
          groundMatches: groundMatchIds.length,
          groundRuns: personalGroundRuns,
          groundWickets: personalGroundWkts,
        );
      }

      // If user is scorer (no personal balls), aggregate from match/innings totals
      int tM = 0, tR = 0, tW = 0;
      int gM = 0, gR = 0, gW = 0;

      // Group innings by match
      final matchInnings = <String, List<dynamic>>{};
      for (var inn in innings) {
        final mId = inn['match_id'].toString();
        matchInnings.putIfAbsent(mId, () => []).add(inn);
      }

      for (var m in matches) {
        final mId = m['id'].toString();
        final isT = _isTurf(m['venue']?.toString() ?? '');
        final inns = matchInnings[mId] ?? [];
        int mRuns = 0;
        int mWkts = 0;
        for (var inn in inns) {
          mRuns += (inn['total_runs'] as num?)?.toInt() ?? 0;
          mWkts += (inn['total_wickets'] as num?)?.toInt() ?? 0;
        }

        if (isT) {
          tM++;
          tR += mRuns;
          tW += mWkts;
        } else {
          gM++;
          gR += mRuns;
          gW += mWkts;
        }
      }

      return HomePersonalStats(
        turfMatches: tM,
        turfRuns: tR,
        turfWickets: tW,
        groundMatches: gM,
        groundRuns: gR,
        groundWickets: gW,
      );
    } catch (e) {
      debugPrint('InsforgeStatsService.fetchHomeStats error: $e');
      return const HomePersonalStats();
    }
  }

  /// Fetches Profile Scorer Performance exclusively from InsForge for a signed-in user.
  static Future<InsforgeScorerStats> fetchScorerStats(String creatorId) async {
    if (creatorId.isEmpty) return const InsforgeScorerStats();

    try {
      // Use OR filter to include matches where user is creator OR active scorer.
      // Use getWithFallback() so expired JWTs don't return empty.
      final matchRes = await InsforgeConfig.getWithFallback(
        Uri.parse('$_recordsUrl/matches').replace(queryParameters: {
          'or': '(creator_id.eq.$creatorId,active_scorer_id.eq.$creatorId)',
          'status': 'eq.completed',
          'select': 'id,venue,match_date,match_result_summary',
        }),
      );

      if (matchRes.statusCode != 200) {
        return const InsforgeScorerStats();
      }

      final List<dynamic> matches = jsonDecode(matchRes.body);
      if (matches.isEmpty) return const InsforgeScorerStats();

      final matchIds = matches.map((m) => m['id'].toString()).toList();

      final inningsRes = await InsforgeConfig.getWithFallback(
        Uri.parse('$_recordsUrl/innings').replace(queryParameters: {
          'match_id': 'in.(${matchIds.join(',')})',
          'select': 'match_id,innings_number,total_runs,total_wickets',
        }),
      );

      final List<dynamic> innings = inningsRes.statusCode == 200 ? jsonDecode(inningsRes.body) : [];
      final matchInnings = <String, List<dynamic>>{};
      for (var inn in innings) {
        final mId = inn['match_id'].toString();
        matchInnings.putIfAbsent(mId, () => []).add(inn);
      }

      final now = DateTime.now();
      int totalRuns = 0;
      int totalWickets = 0;
      int thisMonthRuns = 0;
      int thisMonthWickets = 0;

      for (var m in matches) {
        final mId = m['id'].toString();
        final inns = matchInnings[mId] ?? [];
        int mRuns = 0;
        int mWkts = 0;
        for (var inn in inns) {
          mRuns += (inn['total_runs'] as num?)?.toInt() ?? 0;
          mWkts += (inn['total_wickets'] as num?)?.toInt() ?? 0;
        }

        totalRuns += mRuns;
        totalWickets += mWkts;

        final dateStr = m['match_date']?.toString();
        if (dateStr != null) {
          final dt = DateTime.tryParse(dateStr);
          if (dt != null && dt.year == now.year && dt.month == now.month) {
            thisMonthRuns += mRuns;
            thisMonthWickets += mWkts;
          }
        }
      }

      return InsforgeScorerStats(
        totalMatches: matches.length,
        totalRunsScored: totalRuns,
        totalWicketsTaken: totalWickets,
        thisMonthRuns: thisMonthRuns,
        thisMonthWickets: thisMonthWickets,
      );
    } catch (e) {
      debugPrint('InsforgeStatsService.fetchScorerStats error: $e');
      return const InsforgeScorerStats();
    }
  }

  /// Fetches Career Stats exclusively from InsForge for a signed-in user.
  static Future<CareerStats> fetchCareerStats(
    String creatorId,
    String userName,
    MatchCategory category,
  ) async {
    if (creatorId.isEmpty) return const CareerStats();

    try {
      // Include matches where user is creator/scorer, OR squad participant in player_profile_ids.
      // Use getWithFallback() on all requests so expired JWTs don't silently block data.
      final creatorUri = Uri.parse('$_recordsUrl/matches').replace(queryParameters: {
        'or': '(creator_id.eq.$creatorId,active_scorer_id.eq.$creatorId)',
        'status': 'eq.completed',
        'select': 'id,venue,match_date,total_overs',
      });
      final playerUri = Uri.parse('$_recordsUrl/matches').replace(queryParameters: {
        'player_profile_ids': 'cs.["$creatorId"]',
        'status': 'eq.completed',
        'select': 'id,venue,match_date,total_overs',
      });

      final responses = await Future.wait([
        InsforgeConfig.getWithFallback(creatorUri).catchError((_) => http.Response('[]', 200)),
        InsforgeConfig.getWithFallback(playerUri).catchError((_) => http.Response('[]', 200)),
      ]);

      final Map<String, Map<String, dynamic>> matchMap = {};
      for (final res in responses) {
        if (res.statusCode == 200) {
          try {
            final List list = jsonDecode(res.body);
            for (final m in list) {
              if (m is Map) {
                final id = m['id']?.toString() ?? '';
                if (id.isNotEmpty) matchMap[id] = m as Map<String, dynamic>;
              }
            }
          } catch (_) {}
        }
      }

      final allMatches = matchMap.values.toList();
      final categoryMatches = allMatches.where((m) {
        final isT = _isTurf(m['venue']?.toString() ?? '');
        return category == MatchCategory.turfBox ? isT : !isT;
      }).toList();

      if (categoryMatches.isEmpty) return const CareerStats();

      final matchIds = categoryMatches.map((m) => m['id'].toString()).toList();
      final inningsRes = await InsforgeConfig.getWithFallback(
        Uri.parse('$_recordsUrl/innings').replace(queryParameters: {
          'match_id': 'in.(${matchIds.join(',')})',
          'select': 'id,match_id,innings_number,total_runs,total_wickets,overs_bowled',
        }),
      );

      final List<dynamic> innings = inningsRes.statusCode == 200 ? jsonDecode(inningsRes.body) : [];
      final inningsMap = <String, String>{};
      for (var inn in innings) {
        inningsMap[inn['id'].toString()] = inn['match_id'].toString();
      }

      final inningsIds = inningsMap.keys.toList();
      List<dynamic> balls = [];
      if (inningsIds.isNotEmpty) {
        final chunk = inningsIds.take(50).join(',');
        final ballsRes = await InsforgeConfig.getWithFallback(
          Uri.parse('$_recordsUrl/balls').replace(queryParameters: {
            'innings_id': 'in.($chunk)',
            'select': 'innings_id,runs_scored,extras,extra_type,is_wicket,wicket_type,commentary',
          }),
        );
        if (ballsRes.statusCode == 200) {
          balls = jsonDecode(ballsRes.body);
        }
      }

      final myName = userName.trim().toLowerCase();
      final myBatBalls = <Map<String, dynamic>>[];
      final myBowlBalls = <Map<String, dynamic>>[];

      if (myName.isNotEmpty && myName != 'scorely user') {
        for (var b in balls) {
          final comm = (b['commentary'] ?? '').toString().toLowerCase();
          final parts = comm.split(' vs ');
          final batter = parts.isNotEmpty ? parts[0].trim() : '';
          final bowler = parts.length > 1 ? parts[1].trim() : '';

          final isWide = (b['extra_type'] ?? '').toString().toLowerCase() == 'wide';
          if (batter == myName && !isWide) {
            myBatBalls.add(b as Map<String, dynamic>);
          }
          if (bowler == myName) {
            myBowlBalls.add(b as Map<String, dynamic>);
          }
        }
      }

      if (myBatBalls.isNotEmpty || myBowlBalls.isNotEmpty) {
        final totalRuns = myBatBalls.fold<int>(0, (s, b) => s + ((b['runs_scored'] as num?)?.toInt() ?? 0));
        final ballsFaced = myBatBalls.length;
        final fours = myBatBalls.where((b) => b['runs_scored'] == 4).length;
        final sixes = myBatBalls.where((b) => b['runs_scored'] == 6).length;

        int totalWickets = 0;
        int runsConceded = 0;
        int wides = 0;
        int noBalls = 0;

        for (var b in myBowlBalls) {
          final r = (b['runs_scored'] as num?)?.toInt() ?? 0;
          final ex = (b['extras'] as num?)?.toInt() ?? 0;
          runsConceded += (r + ex);

          final extType = (b['extra_type'] ?? '').toString().toLowerCase();
          if (extType == 'wide' || extType == 'wd') wides++;
          if (extType == 'noball' || extType == 'nb') noBalls++;

          final isWkt = b['is_wicket'] == true;
          final wType = (b['wicket_type'] ?? '').toString().toLowerCase();
          if (isWkt && wType != 'run out' && wType != 'stumped') {
            totalWickets++;
          }
        }

        final legalBowlBalls = myBowlBalls.where((b) {
          final t = (b['extra_type'] ?? '').toString().toLowerCase();
          return t != 'wide' && t != 'wd' && t != 'noball' && t != 'nb';
        }).length;
        final overs = legalBowlBalls ~/ 6;

        final Set<String> participated = {
          ...myBatBalls.map((b) => inningsMap[b['innings_id'].toString()] ?? ''),
          ...myBowlBalls.map((b) => inningsMap[b['innings_id'].toString()] ?? ''),
        }..remove('');

        return CareerStats(
          matches: participated.length,
          totalRuns: totalRuns,
          totalWickets: totalWickets,
          fours: fours,
          sixes: sixes,
          ballsFaced: ballsFaced,
          overs: overs,
          runsConceded: runsConceded,
          wides: wides,
          noBalls: noBalls,
        );
      }

      // Fallback for scorer (match totals from InsForge)
      int tRuns = 0, tWkts = 0, tOvers = 0;
      for (var inn in innings) {
        tRuns += (inn['total_runs'] as num?)?.toInt() ?? 0;
        tWkts += (inn['total_wickets'] as num?)?.toInt() ?? 0;
        tOvers += ((inn['overs_bowled'] as num?)?.toInt() ?? 0);
      }

      return CareerStats(
        matches: categoryMatches.length,
        totalRuns: tRuns,
        totalWickets: tWkts,
        overs: tOvers,
        runsConceded: tRuns,
      );
    } catch (e) {
      debugPrint('InsforgeStatsService.fetchCareerStats error: $e');
      return const CareerStats();
    }
  }
}
