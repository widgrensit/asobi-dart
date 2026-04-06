class LeaderboardEntry {
  final String leaderboardId;
  final String playerId;
  final int score;
  final int subScore;
  final int? rank;
  final String? updatedAt;

  LeaderboardEntry({
    required this.leaderboardId,
    required this.playerId,
    required this.score,
    required this.subScore,
    this.rank,
    this.updatedAt,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) => LeaderboardEntry(
        leaderboardId: json['leaderboard_id'] as String? ?? '',
        playerId: json['player_id'] as String? ?? '',
        score: (json['score'] as num?)?.toInt() ?? 0,
        subScore: (json['sub_score'] as num?)?.toInt() ?? 0,
        rank: (json['rank'] as num?)?.toInt(),
        updatedAt: json['updated_at'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'leaderboard_id': leaderboardId,
        'player_id': playerId,
        'score': score,
        'sub_score': subScore,
        if (rank != null) 'rank': rank,
        if (updatedAt != null) 'updated_at': updatedAt,
      };
}
