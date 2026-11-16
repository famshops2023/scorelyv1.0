import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import '../core/config/insforge_config.dart';
import '../models/scorer_assignment_request.dart';

class ScorerHandoverService {
  ScorerHandoverService._();
  static final ScorerHandoverService instance = ScorerHandoverService._();

  static String get _requestsUrl =>
      '${InsforgeConfig.recordsUrl}/scorer_assignment_requests';
  static String get _rpcUrl => '${InsforgeConfig.baseUrl}/api/database/rpc';
  static Map<String, String> get _headers => InsforgeConfig.headers;

  /// Default expiry duration: 2 hours (long enough for Demo1 to open the app)
  static const Duration requestExpiryDuration = Duration(hours: 2);

  /// Local in-memory store for requests (offline-first & fallback support)
  final Map<String, ScorerAssignmentRequest> _localRequests = {};

  bool _isValidUuid(String? val) {
    if (val == null || val.isEmpty) return false;
    final uuidRegex = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    );
    return uuidRegex.hasMatch(val);
  }

  /// 1. Create a scorer assignment request in InsForge
  Future<ScorerAssignmentRequest?> createRequest({
    required String matchId,
    String? inningsId,
    required String requestedByUserId,
    required String requestedByName,
    required String requestedScorerUserId,
    required String requestedScorerName,
    required String currentScorerUserId,
    String? matchTitle,
    String? requestedScorerEmail,
    Map<String, dynamic>? payload,
  }) async {
    final now = DateTime.now().toUtc();
    final expiresAt = now.add(requestExpiryDuration);
    final requestId = const Uuid().v4();

    final safeMatchId = _isValidUuid(matchId) ? matchId : const Uuid().v4();
    final safeInningsId = _isValidUuid(inningsId) ? inningsId : null;
    final safeRequestedBy = _isValidUuid(requestedByUserId)
        ? requestedByUserId
        : const Uuid().v4();

    // Best-effort player lookup: if requestedScorerUserId is a players row ID or name, get the auth profile_id
    String effectiveTargetUserId = requestedScorerUserId.trim();
    String? effectiveTargetEmail = requestedScorerEmail;

    if (!_isValidUuid(effectiveTargetUserId)) {
      try {
        final queryParams = <String, String>{
          'limit': '1',
          'select': 'id,name,email',
        };
        if (requestedScorerName.isNotEmpty) {
          queryParams['name'] = 'ilike.*${requestedScorerName.trim()}*';
        }
        final profUri = Uri.parse('${InsforgeConfig.recordsUrl}/public_profiles')
            .replace(queryParameters: queryParams);
        final profRes = await InsforgeConfig.getWithFallback(profUri)
            .timeout(const Duration(seconds: 3));
        if (profRes.statusCode == 200) {
          final data = jsonDecode(profRes.body);
          if (data is List && data.isNotEmpty) {
            final row = data.first as Map<String, dynamic>;
            final pid = row['id']?.toString();
            if (pid != null && pid.isNotEmpty) {
              effectiveTargetUserId = pid;
              if (effectiveTargetEmail == null || effectiveTargetEmail.isEmpty) {
                effectiveTargetEmail = row['email']?.toString();
              }
            }
          }
        }
      } catch (_) {}
    }

    final safeRequestedScorer = _isValidUuid(effectiveTargetUserId)
        ? effectiveTargetUserId
        : const Uuid().v4();
    final safeCurrentScorer = _isValidUuid(currentScorerUserId)
        ? currentScorerUserId
        : safeRequestedBy;

    final created = ScorerAssignmentRequest(
      id: requestId,
      matchId: safeMatchId,
      inningsId: safeInningsId,
      requestedByUserId: safeRequestedBy,
      requestedByName: requestedByName,
      requestedScorerUserId: safeRequestedScorer,
      requestedScorerName: requestedScorerName,
      requestedScorerEmail: effectiveTargetEmail,
      currentScorerUserId: safeCurrentScorer,
      status: 'pending',
      createdAt: now,
      expiresAt: expiresAt,
      matchTitle: matchTitle,
      payload: payload,
    );

    _localRequests[requestId] = created;

    try {
      final requestBody = {
        'id': requestId,
        'match_id': safeMatchId,
        'innings_id': safeInningsId,
        'requested_by_user_id': safeRequestedBy,
        'requested_by_name': requestedByName,
        'requested_scorer_user_id': safeRequestedScorer,
        'requested_scorer_name': requestedScorerName,
        if (effectiveTargetEmail != null && effectiveTargetEmail.isNotEmpty)
          'requested_scorer_email': effectiveTargetEmail,
        'current_scorer_user_id': safeCurrentScorer,
        'status': 'pending',
        'match_title': matchTitle,
        'version': 1,
        'created_at': now.toIso8601String(),
        'expires_at': expiresAt.toIso8601String(),
        'payload': payload,
      };

      // InsForge PostgREST insert takes an array
      var res = await http
          .post(
            Uri.parse(_requestsUrl),
            headers: _headers,
            body: jsonEncode([requestBody]),
          )
          .timeout(const Duration(seconds: 5));

      if (res.statusCode == 401) {
        // Expired user token fallback to anonymous API key
        res = await http
            .post(
              Uri.parse(_requestsUrl),
              headers: InsforgeConfig.anonHeaders,
              body: jsonEncode([requestBody]),
            )
            .timeout(const Duration(seconds: 5));
      }

      if (res.statusCode == 200 || res.statusCode == 201) {
        debugPrint(
          'ScorerHandoverService: Created request $requestId in InsForge',
        );
      } else {
        debugPrint(
          'ScorerHandoverService.createRequest non-200 (${res.statusCode}): ${res.body}. Continuing with local request.',
        );
      }
      return created;
    } catch (e) {
      debugPrint(
        'ScorerHandoverService.createRequest network note: $e. Operating in offline/local mode.',
      );
      return created;
    }
  }

  /// 2. Check latest status of a request
  Future<ScorerAssignmentRequest?> getRequestById(String requestId) async {
    try {
      final uri = Uri.parse(_requestsUrl).replace(queryParameters: {
        'id': 'eq.$requestId',
      });
      final res = await InsforgeConfig.getWithFallback(uri)
          .timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is List && data.isNotEmpty) {
          final fromRemote = ScorerAssignmentRequest.fromJson(
            data[0] as Map<String, dynamic>,
          );
          _localRequests[requestId] = fromRemote;
          return fromRemote;
        }
      }
    } catch (e) {
      debugPrint('ScorerHandoverService.getRequestById offline/timeout: $e');
    }
    return _localRequests[requestId];
  }

  /// 3. Fetch pending requests for the authenticated recipient user
  Future<List<ScorerAssignmentRequest>> getPendingRequestsForUser(
    String userId, {
    String? email,
    String? name,
  }) async {
    final cleanUserId = userId.trim();
    if (cleanUserId.isEmpty &&
        (email == null || email.trim().isEmpty) &&
        (name == null || name.trim().isEmpty)) {
      return [];
    }
    try {
      final nowIso = DateTime.now().toUtc().toIso8601String();

      // UUID candidates — only valid UUIDs can be compared against the uuid column
      final candidateUuids = <String>{};
      if (cleanUserId.isNotEmpty && _isValidUuid(cleanUserId)) {
        candidateUuids.add(cleanUserId);
      }

      // Look up any player IDs (also UUIDs) associated with this user's profile ID
      if (cleanUserId.isNotEmpty) {
        try {
          final pUri = Uri.parse('${InsforgeConfig.recordsUrl}/players').replace(queryParameters: {
            'profile_id': 'eq.$cleanUserId',
            'select': 'id',
          });
          final plRes = await InsforgeConfig.getWithFallback(pUri)
              .timeout(const Duration(seconds: 3));
          if (plRes.statusCode == 200) {
            final pList = jsonDecode(plRes.body);
            if (pList is List) {
              for (final p in pList) {
                final id = p['id']?.toString();
                // Only add valid UUIDs — SP-IDs (SP-XXXX) must NOT be included
                if (id != null && id.isNotEmpty && _isValidUuid(id)) {
                  candidateUuids.add(id);
                }
              }
            }
          }
        } catch (_) {}
      }

      final orFilters = <String>[];
      // Add only valid UUID filters for the uuid column
      for (final id in candidateUuids) {
        orFilters.add('requested_scorer_user_id.eq.$id');
      }
      if (email != null && email.trim().isNotEmpty) {
        orFilters.add('requested_scorer_email.eq.${email.trim()}');
      }
      if (name != null && name.trim().isNotEmpty) {
        orFilters.add('requested_scorer_name.ilike.*${name.trim()}*');
      }

      final queryParams = <String, String>{
        'status': 'eq.pending',
        'expires_at': 'gt.$nowIso',
        'order': 'created_at.desc',
      };
      if (orFilters.isNotEmpty) {
        queryParams['or'] = '(${orFilters.join(',')})';
      }

      final searchUri = Uri.parse(_requestsUrl).replace(queryParameters: queryParams);

      final res = await InsforgeConfig.getWithFallback(searchUri)
          .timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is List) {
          final remoteList = data
              .map(
                (item) => ScorerAssignmentRequest.fromJson(
                  item as Map<String, dynamic>,
                ),
              )
              .toList();
          for (final req in remoteList) {
            _localRequests[req.id] = req;
          }
          return remoteList;
        }
      }
    } catch (e) {
      debugPrint('ScorerHandoverService.getPendingRequestsForUser error: $e');
    }

    // Fallback to local memory store
    return _localRequests.values
        .where(
          (r) =>
              r.isPending &&
              (r.requestedScorerUserId == cleanUserId ||
                  (email != null &&
                      email.isNotEmpty &&
                      r.requestedScorerEmail == email) ||
                  (name != null &&
                      name.isNotEmpty &&
                      r.requestedScorerName?.toLowerCase() ==
                          name.toLowerCase())),
        )
        .toList();
  }

  /// 4. Accept a request (server-authoritative).
  ///
  /// Acceptance MUST be atomic. It is performed exclusively by the
  /// `accept_scorer_assignment` RPC which verifies the request, the match
  /// state, the recipient's authorization, swaps the active scorer and
  /// revokes any competing request in one transaction.
  Future<bool> acceptRequest({
    required String requestId,
    required String userId,
    required String matchId,
    String? inningsId,
  }) async {
    if (requestId.isEmpty || userId.isEmpty) return false;
    try {
      final rpcRes = await http
          .post(
            Uri.parse('$_rpcUrl/accept_scorer_assignment'),
            headers: _headers,
            body: jsonEncode({
              'p_request_id': requestId,
              'p_user_id': userId,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (rpcRes.statusCode == 200) {
        final result = jsonDecode(rpcRes.body);
        if (result is Map && result['success'] == true) {
          debugPrint('ScorerHandoverService: Accepted via RPC successfully.');
          _updateLocalStatus(requestId, 'accepted');
          return true;
        }
        debugPrint(
          'ScorerHandoverService: RPC rejected acceptance: ${rpcRes.body}',
        );
      } else {
        debugPrint(
          'ScorerHandoverService: accept RPC failed (${rpcRes.statusCode}): ${rpcRes.body}',
        );
      }
    } catch (e) {
      debugPrint('ScorerHandoverService.acceptRequest error: $e');
    }
    // Deliberately no multi-step client fallback: partial handovers are worse
    // than a retry. The caller keeps the request pending.
    return false;
  }

  /// 5. Decline a request.
  ///
  /// Declining never changes the active scorer. The RPC is preferred so the
  /// server can validate that the caller is the requested recipient.
  Future<bool> declineRequest({
    required String requestId,
    String? userId,
    String? reason,
  }) async {
    final resolvedReason = reason ?? 'Declined by recipient';
    if (userId != null && userId.isNotEmpty) {
      try {
        final rpcRes = await http
            .post(
              Uri.parse('$_rpcUrl/decline_scorer_assignment'),
              headers: _headers,
              body: jsonEncode({
                'p_request_id': requestId,
                'p_user_id': userId,
                'p_reason': resolvedReason,
              }),
            )
            .timeout(const Duration(seconds: 8));
        if (rpcRes.statusCode == 200) {
          final result = jsonDecode(rpcRes.body);
          if (result is Map && result['success'] == true) {
            _updateLocalStatus(requestId, 'declined');
            return true;
          }
        }
      } catch (e) {
        debugPrint('ScorerHandoverService.declineRequest RPC error: $e');
      }
    }

    // Fallback: mark declined directly (does not touch the active scorer).
    _updateLocalStatus(requestId, 'declined');
    try {
      final now = DateTime.now().toUtc().toIso8601String();
      final uri = Uri.parse(_requestsUrl).replace(queryParameters: {
        'id': 'eq.$requestId',
        'status': 'eq.pending',
      });
      final body = jsonEncode({
        'status': 'declined',
        'responded_at': now,
        'response_reason': resolvedReason,
      });
      var res = await http.patch(uri, headers: _headers, body: body)
          .timeout(const Duration(seconds: 4));
      if (res.statusCode == 401) {
        res = await http.patch(uri, headers: InsforgeConfig.anonHeaders, body: body)
            .timeout(const Duration(seconds: 4));
      }

      return res.statusCode == 200 || res.statusCode == 204;
    } catch (e) {
      debugPrint('ScorerHandoverService.declineRequest error: $e');
      return true;
    }
  }

  /// 6. Cancel a request (by primary scorer)
  Future<bool> cancelRequest(String requestId) async {
    _updateLocalStatus(requestId, 'cancelled');
    try {
      final now = DateTime.now().toUtc().toIso8601String();
      final uri = Uri.parse(_requestsUrl).replace(queryParameters: {
        'id': 'eq.$requestId',
        'status': 'eq.pending',
      });
      final body = jsonEncode({'status': 'cancelled', 'responded_at': now});
      var res = await http.patch(uri, headers: _headers, body: body)
          .timeout(const Duration(seconds: 4));
      if (res.statusCode == 401) {
        res = await http.patch(uri, headers: InsforgeConfig.anonHeaders, body: body)
            .timeout(const Duration(seconds: 4));
      }

      return res.statusCode == 200 || res.statusCode == 204;
    } catch (e) {
      debugPrint('ScorerHandoverService.cancelRequest error: $e');
      return true;
    }
  }

  /// Helper to update status in in-memory cache
  void _updateLocalStatus(String requestId, String status) {
    if (_localRequests.containsKey(requestId)) {
      final c = _localRequests[requestId]!;
      _localRequests[requestId] = ScorerAssignmentRequest(
        id: c.id,
        matchId: c.matchId,
        inningsId: c.inningsId,
        requestedByUserId: c.requestedByUserId,
        requestedByName: c.requestedByName,
        requestedScorerUserId: c.requestedScorerUserId,
        requestedScorerName: c.requestedScorerName,
        requestedScorerEmail: c.requestedScorerEmail,
        currentScorerUserId: c.currentScorerUserId,
        status: status,
        createdAt: c.createdAt,
        expiresAt: c.expiresAt,
        matchTitle: c.matchTitle,
        payload: c.payload,
      );
    }
  }

  /// Simulate acceptance locally (e.g. for testing / demo)
  void simulateAcceptance(String requestId) {
    _updateLocalStatus(requestId, 'accepted');
  }
}
