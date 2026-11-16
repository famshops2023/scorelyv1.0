/// Canonical match lifecycle statuses.
///
/// These values are stored in `pending_matches.status` and must not be
/// conflated with innings state, scorer-assignment state or sync state.
class MatchStatus {
  MatchStatus._();

  static const String pending = 'pending';
  static const String live = 'live';
  static const String completed = 'completed';
  static const String abandoned = 'abandoned';

  /// Legacy status values that used to be persisted by older builds.
  static const Map<String, String> _legacy = {
    'draft': pending,
    'created': pending,
    'scheduled': pending,
    'waiting_for_team_b': pending,
    'waiting_for_squad': pending,
    'ready_for_toss': pending,
    'setup': pending,
    'in_progress': live,
    'scoring': live,
    'started': live,
    'finished': completed,
    'complete': completed,
  };

  /// Maps any historical / external status value onto a canonical value.
  ///
  /// Unknown values fall back to [pending] so a malformed row can never be
  /// treated as live or completed by accident.
  static String normalize(String? raw) {
    final value = (raw ?? '').trim().toLowerCase();
    if (value.isEmpty) return pending;
    if (value == pending || value == live || value == completed || value == abandoned) return value;
    return _legacy[value] ?? pending;
  }

  static bool isPending(String? raw) => normalize(raw) == pending;
  static bool isLive(String? raw) => normalize(raw) == live;
  static bool isCompleted(String? raw) => normalize(raw) == completed;
  static bool isAbandoned(String? raw) => normalize(raw) == abandoned;
}

/// Sub-state used while a match is still [MatchStatus.pending].
///
/// This is deliberately separate from the lifecycle status so squad selection
/// never makes a match look live.
class MatchSetupStage {
  MatchSetupStage._();

  /// Waiting for one or both squads to be selected.
  static const String squadSelection = 'squad_selection';

  /// Squads are ready; toss / opening lineup still pending.
  static const String readyForToss = 'ready_for_toss';

  static String normalize(String? raw) {
    final value = (raw ?? '').trim().toLowerCase();
    if (value == squadSelection || value == readyForToss) return value;
    // Legacy setup statuses.
    if (value == 'waiting_for_team_b' || value == 'waiting_for_squad') {
      return squadSelection;
    }
    if (value == 'ready_for_toss' || value == 'scheduled') {
      return readyForToss;
    }
    return readyForToss;
  }
}
