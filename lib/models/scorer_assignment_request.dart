import 'dart:convert';

class ScorerAssignmentRequest {
  final String id;
  final String matchId;
  final String? inningsId;
  final String requestedByUserId;
  final String? requestedByName;
  final String requestedScorerUserId;
  final String? requestedScorerName;
  final String? requestedScorerEmail;
  final String currentScorerUserId;
  final String status; // 'pending' | 'accepted' | 'declined' | 'cancelled' | 'expired'
  final String? responseReason;
  final String? notificationId;
  final int version;
  final DateTime createdAt;
  final DateTime? respondedAt;
  final DateTime expiresAt;
  final String? matchTitle;
  final Map<String, dynamic>? payload;

  const ScorerAssignmentRequest({
    required this.id,
    required this.matchId,
    this.inningsId,
    required this.requestedByUserId,
    this.requestedByName,
    required this.requestedScorerUserId,
    this.requestedScorerName,
    this.requestedScorerEmail,
    required this.currentScorerUserId,
    this.status = 'pending',
    this.responseReason,
    this.notificationId,
    this.version = 1,
    required this.createdAt,
    this.respondedAt,
    required this.expiresAt,
    this.matchTitle,
    this.payload,
  });

  bool get isPending => status == 'pending' && !isExpired;
  bool get isAccepted => status == 'accepted';
  bool get isDeclined => status == 'declined';
  bool get isCancelled => status == 'cancelled';
  bool get isExpired => status == 'expired' || DateTime.now().isAfter(expiresAt);

  Duration get remainingDuration {
    final diff = expiresAt.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

  factory ScorerAssignmentRequest.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? parsedPayload;
    if (json['payload'] is Map) {
      parsedPayload = Map<String, dynamic>.from(json['payload'] as Map);
    } else if (json['payload'] is String && (json['payload'] as String).isNotEmpty) {
      try {
        parsedPayload = jsonDecode(json['payload'] as String) as Map<String, dynamic>?;
      } catch (_) {}
    }

    return ScorerAssignmentRequest(
      id: json['id']?.toString() ?? '',
      matchId: json['match_id']?.toString() ?? '',
      inningsId: json['innings_id']?.toString(),
      requestedByUserId: json['requested_by_user_id']?.toString() ?? '',
      requestedByName: json['requested_by_name']?.toString() ??
          (json['requester'] is Map ? json['requester']['name']?.toString() : null),
      requestedScorerUserId: json['requested_scorer_user_id']?.toString() ?? '',
      requestedScorerName: json['requested_scorer_name']?.toString() ??
          (json['target_scorer'] is Map ? json['target_scorer']['name']?.toString() : null),
      requestedScorerEmail: json['requested_scorer_email']?.toString() ??
          json['requestedScorerEmail']?.toString() ??
          (parsedPayload?['requested_scorer_email']?.toString()),
      currentScorerUserId: json['current_scorer_user_id']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      responseReason: json['response_reason']?.toString(),
      notificationId: json['notification_id']?.toString(),
      version: (json['version'] as num?)?.toInt() ?? 1,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      respondedAt: json['responded_at'] != null
          ? DateTime.tryParse(json['responded_at'].toString())
          : null,
      expiresAt: json['expires_at'] != null
          ? DateTime.tryParse(json['expires_at'].toString()) ??
              DateTime.now().add(const Duration(hours: 2))
          : DateTime.now().add(const Duration(hours: 2)),
      matchTitle: json['match_title']?.toString(),
      payload: parsedPayload,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'match_id': matchId,
      'innings_id': inningsId,
      'requested_by_user_id': requestedByUserId,
      'requested_by_name': requestedByName,
      'requested_scorer_user_id': requestedScorerUserId,
      'requested_scorer_name': requestedScorerName,
      if (requestedScorerEmail != null) 'requested_scorer_email': requestedScorerEmail,
      'current_scorer_user_id': currentScorerUserId,
      'status': status,
      'response_reason': responseReason,
      'notification_id': notificationId,
      'version': version,
      'created_at': createdAt.toIso8601String(),
      'responded_at': respondedAt?.toIso8601String(),
      'expires_at': expiresAt.toIso8601String(),
      'match_title': matchTitle,
      if (payload != null) 'payload': payload,
    };
  }
}
