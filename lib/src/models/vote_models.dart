class Vote {
  final String id;
  final String matchId;
  final String type;
  final Map<String, dynamic> options;
  final Map<String, dynamic>? result;
  final String status;
  final String insertedAt;

  Vote({
    required this.id,
    required this.matchId,
    required this.type,
    required this.options,
    this.result,
    required this.status,
    required this.insertedAt,
  });

  factory Vote.fromJson(Map<String, dynamic> json) => Vote(
        id: json['id'] as String,
        matchId: json['match_id'] as String,
        type: json['type'] as String,
        options: json['options'] as Map<String, dynamic>? ?? {},
        result: json['result'] as Map<String, dynamic>?,
        status: json['status'] as String,
        insertedAt: json['inserted_at'] as String,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'match_id': matchId,
        'type': type,
        'options': options,
        if (result != null) 'result': result,
        'status': status,
        'inserted_at': insertedAt,
      };
}

class VoteList {
  final List<Vote> votes;

  VoteList({required this.votes});

  factory VoteList.fromJson(Map<String, dynamic> json) => VoteList(
        votes: (json['votes'] as List<dynamic>)
            .map((v) => Vote.fromJson(v as Map<String, dynamic>))
            .toList(),
      );
}
