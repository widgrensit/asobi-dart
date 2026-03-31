class MatchRecord {
  final String id;
  final String mode;
  final String status;
  final String? startedAt;
  final String? finishedAt;
  final String insertedAt;

  MatchRecord({
    required this.id,
    required this.mode,
    required this.status,
    this.startedAt,
    this.finishedAt,
    required this.insertedAt,
  });

  factory MatchRecord.fromJson(Map<String, dynamic> json) => MatchRecord(
        id: json['id'] as String,
        mode: json['mode'] as String,
        status: json['status'] as String,
        startedAt: json['started_at'] as String?,
        finishedAt: json['finished_at'] as String?,
        insertedAt: json['inserted_at'] as String,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'mode': mode,
        'status': status,
        if (startedAt != null) 'started_at': startedAt,
        if (finishedAt != null) 'finished_at': finishedAt,
        'inserted_at': insertedAt,
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
