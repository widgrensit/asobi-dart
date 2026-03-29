class Tournament {
  final String id;
  final String name;
  final String leaderboardId;
  final int maxEntries;
  final String status;
  final String startAt;
  final String endAt;
  final String insertedAt;

  Tournament({
    required this.id,
    required this.name,
    required this.leaderboardId,
    required this.maxEntries,
    required this.status,
    required this.startAt,
    required this.endAt,
    required this.insertedAt,
  });

  factory Tournament.fromJson(Map<String, dynamic> json) => Tournament(
        id: json['id'] as String,
        name: json['name'] as String,
        leaderboardId: json['leaderboard_id'] as String,
        maxEntries: json['max_entries'] as int,
        status: json['status'] as String,
        startAt: json['start_at'] as String,
        endAt: json['end_at'] as String,
        insertedAt: json['inserted_at'] as String,
      );
}
