class MatchRecord {
  final String id;
  final String mode;
  final String status;
  final Map<String, dynamic> result;
  final String? startedAt;
  final String? finishedAt;
  final String insertedAt;

  MatchRecord({
    required this.id,
    required this.mode,
    required this.status,
    this.result = const {},
    this.startedAt,
    this.finishedAt,
    required this.insertedAt,
  });

  factory MatchRecord.fromJson(Map<String, dynamic> json) => MatchRecord(
        id: json['id'] as String,
        mode: json['mode'] as String,
        status: json['status'] as String,
        result: (json['result'] as Map<String, dynamic>?) ?? const {},
        startedAt: json['started_at'] as String?,
        finishedAt: json['finished_at'] as String?,
        insertedAt: json['inserted_at'] as String,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'mode': mode,
        'status': status,
        'result': result,
        if (startedAt != null) 'started_at': startedAt,
        if (finishedAt != null) 'finished_at': finishedAt,
        'inserted_at': insertedAt,
      };
}

class LiveMatch {
  final String matchId;
  final String mode;
  final String status;
  final int playerCount;
  final int maxPlayers;

  LiveMatch({
    required this.matchId,
    required this.mode,
    required this.status,
    required this.playerCount,
    required this.maxPlayers,
  });

  factory LiveMatch.fromJson(Map<String, dynamic> json) => LiveMatch(
        matchId: json['match_id'] as String,
        mode: json['mode'] as String? ?? '',
        status: json['status'] as String? ?? '',
        playerCount: (json['player_count'] as num?)?.toInt() ?? 0,
        maxPlayers: (json['max_players'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'match_id': matchId,
        'mode': mode,
        'status': status,
        'player_count': playerCount,
        'max_players': maxPlayers,
      };
}

class MatchmakerTicket {
  final String ticketId;
  final String status;

  MatchmakerTicket({required this.ticketId, required this.status});

  factory MatchmakerTicket.fromJson(Map<String, dynamic> json) => MatchmakerTicket(
        ticketId: json['ticket_id'] as String,
        status: json['status'] as String,
      );

  Map<String, dynamic> toJson() => {
        'ticket_id': ticketId,
        'status': status,
      };
}
