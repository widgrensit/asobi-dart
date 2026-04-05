class WorldInfo {
  final String worldId;
  final String status;
  final int playerCount;
  final int maxPlayers;
  final String mode;
  final int gridSize;
  final int? startedAt;
  final List<String> players;

  WorldInfo({
    required this.worldId,
    required this.status,
    required this.playerCount,
    required this.maxPlayers,
    required this.mode,
    required this.gridSize,
    this.startedAt,
    this.players = const [],
  });

  factory WorldInfo.fromJson(Map<String, dynamic> json) => WorldInfo(
        worldId: json['world_id'] as String? ?? '',
        status: (json['status'] as String?) ?? 'unknown',
        playerCount: (json['player_count'] as num?)?.toInt() ?? 0,
        maxPlayers: (json['max_players'] as num?)?.toInt() ?? 500,
        mode: json['mode'] as String? ?? 'default',
        gridSize: (json['grid_size'] as num?)?.toInt() ?? 10,
        startedAt: (json['started_at'] as num?)?.toInt(),
        players: (json['players'] as List<dynamic>?)
                ?.map((p) => p as String)
                .toList() ??
            [],
      );

  bool get hasCapacity => playerCount < maxPlayers;
}
