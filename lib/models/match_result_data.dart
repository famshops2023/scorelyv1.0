class MatchResultData {
  final int? matchId;
  final String? winningTeam;
  final String matchStatusText;
  final String team1Name;
  final String team1Score;
  final String team1Overs;
  final String team2Name;
  final String team2Score;
  final String team2Overs;
  final String format;
  final String venue;
  final int totalOvers;
  final String innings1Team;
  final String innings1Score;
  final String innings1Overs;
  final String innings2Team;
  final String innings2Score;
  final String innings2Overs;

  const MatchResultData({
    this.matchId,
    required this.winningTeam,
    required this.matchStatusText,
    required this.team1Name,
    required this.team1Score,
    required this.team1Overs,
    required this.team2Name,
    required this.team2Score,
    required this.team2Overs,
    required this.format,
    required this.venue,
    required this.totalOvers,
    required this.innings1Team,
    required this.innings1Score,
    required this.innings1Overs,
    required this.innings2Team,
    required this.innings2Score,
    required this.innings2Overs,
  });
}
