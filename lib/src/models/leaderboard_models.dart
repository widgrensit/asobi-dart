class LeaderboardEntry {
  final String leaderboardId;
  final String playerId;
  final int score;
  final int subScore;
  final String updatedAt;

  LeaderboardEntry({
    required this.leaderboardId,
    required this.playerId,
    required this.score,
    required this.subScore,
    required this.updatedAt,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) => LeaderboardEntry(
        leaderboardId: json['leaderboard_id'] as String,
        playerId: json['player_id'] as String,
        score: json['score'] as int,
        subScore: json['sub_score'] as int,
        updatedAt: json['updated_at'] as String,
      );
}
