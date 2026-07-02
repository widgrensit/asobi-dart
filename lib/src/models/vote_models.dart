class Vote {
  final String id;
  final String matchId;
  final String template;
  final String method;
  final List<dynamic> options;
  final Map<String, dynamic> votesCast;
  final Map<String, dynamic> result;
  final Map<String, dynamic> distribution;
  final double turnout;
  final int eligibleCount;
  final int windowMs;
  final String? openedAt;
  final String? closedAt;
  final String insertedAt;

  Vote({
    required this.id,
    required this.matchId,
    required this.template,
    required this.method,
    this.options = const [],
    this.votesCast = const {},
    this.result = const {},
    this.distribution = const {},
    this.turnout = 0.0,
    this.eligibleCount = 0,
    required this.windowMs,
    this.openedAt,
    this.closedAt,
    required this.insertedAt,
  });

  factory Vote.fromJson(Map<String, dynamic> json) => Vote(
        id: json['id'] as String? ?? '',
        matchId: json['match_id'] as String? ?? '',
        template: json['template'] as String? ?? '',
        method: json['method'] as String? ?? '',
        options: (json['options'] as List<dynamic>?) ?? const [],
        votesCast: (json['votes_cast'] as Map<String, dynamic>?) ?? const {},
        result: (json['result'] as Map<String, dynamic>?) ?? const {},
        distribution: (json['distribution'] as Map<String, dynamic>?) ?? const {},
        turnout: (json['turnout'] as num?)?.toDouble() ?? 0.0,
        eligibleCount: (json['eligible_count'] as num?)?.toInt() ?? 0,
        windowMs: (json['window_ms'] as num?)?.toInt() ?? 0,
        openedAt: json['opened_at'] as String?,
        closedAt: json['closed_at'] as String?,
        insertedAt: json['inserted_at'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'match_id': matchId,
        'template': template,
        'method': method,
        'options': options,
        'votes_cast': votesCast,
        'result': result,
        'distribution': distribution,
        'turnout': turnout,
        'eligible_count': eligibleCount,
        'window_ms': windowMs,
        if (openedAt != null) 'opened_at': openedAt,
        if (closedAt != null) 'closed_at': closedAt,
        'inserted_at': insertedAt,
      };
}

class VoteList {
  final List<Vote> votes;

  VoteList({required this.votes});

  factory VoteList.fromJson(Map<String, dynamic> json) => VoteList(
        votes: (json['votes'] as List<dynamic>?)
                ?.map((v) => Vote.fromJson(v as Map<String, dynamic>))
                .toList() ??
            const [],
      );
}
