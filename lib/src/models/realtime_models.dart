class WsMessage {
  final String type;
  final Map<String, dynamic> payload;
  final String? cid;

  WsMessage({required this.type, required this.payload, this.cid});

  factory WsMessage.fromJson(Map<String, dynamic> json) => WsMessage(
        type: json['type'] as String,
        payload: json['payload'] as Map<String, dynamic>? ?? {},
        cid: json['cid'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'type': type,
        'payload': payload,
        if (cid != null) 'cid': cid,
      };
}

class PlayerState {
  final double x;
  final double y;
  final int hp;
  final int kills;
  final int deaths;

  PlayerState({
    required this.x,
    required this.y,
    required this.hp,
    required this.kills,
    required this.deaths,
  });

  factory PlayerState.fromJson(Map<String, dynamic> json) => PlayerState(
        x: (json['x'] as num).toDouble(),
        y: (json['y'] as num).toDouble(),
        hp: (json['hp'] as num?)?.toInt() ?? 0,
        kills: (json['kills'] as num?)?.toInt() ?? 0,
        deaths: (json['deaths'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'x': x,
        'y': y,
        'hp': hp,
        'kills': kills,
        'deaths': deaths,
      };
}

class ProjectileState {
  final int id;
  final String owner;
  final double x;
  final double y;

  ProjectileState({
    required this.id,
    required this.owner,
    required this.x,
    required this.y,
  });

  factory ProjectileState.fromJson(Map<String, dynamic> json) =>
      ProjectileState(
        id: (json['id'] as num).toInt(),
        owner: json['owner'] as String? ?? '',
        x: (json['x'] as num).toDouble(),
        y: (json['y'] as num).toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'owner': owner,
        'x': x,
        'y': y,
      };
}

class MatchState {
  final Map<String, PlayerState> players;
  final List<ProjectileState> projectiles;
  final double timeRemaining;

  MatchState({
    required this.players,
    required this.projectiles,
    required this.timeRemaining,
  });

  factory MatchState.fromJson(Map<String, dynamic> json) {
    final playersJson = json['players'] as Map<String, dynamic>? ?? {};
    final projectilesJson = json['projectiles'] as List<dynamic>? ?? [];

    return MatchState(
      players: playersJson.map((key, value) =>
          MapEntry(key, PlayerState.fromJson(value as Map<String, dynamic>))),
      projectiles: projectilesJson
          .map((projectile) =>
              ProjectileState.fromJson(projectile as Map<String, dynamic>))
          .toList(),
      timeRemaining:
          (json['time_remaining'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'players':
            players.map((key, value) => MapEntry(key, value.toJson())),
        'projectiles':
            projectiles.map((projectile) => projectile.toJson()).toList(),
        'time_remaining': timeRemaining,
      };
}

class MatchStarted {
  final String matchId;
  final String mode;

  MatchStarted({required this.matchId, required this.mode});

  factory MatchStarted.fromJson(Map<String, dynamic> json) => MatchStarted(
        matchId: json['match_id'] as String,
        mode: json['mode'] as String? ?? 'default',
      );

  Map<String, dynamic> toJson() => {
        'match_id': matchId,
        'mode': mode,
      };
}

class MatchResult {
  final String matchId;
  final String? winnerId;
  final Map<String, PlayerState> players;

  MatchResult({
    required this.matchId,
    this.winnerId,
    required this.players,
  });

  factory MatchResult.fromJson(Map<String, dynamic> json) {
    final playersJson = json['players'] as Map<String, dynamic>? ?? {};
    return MatchResult(
      matchId: json['match_id'] as String? ?? '',
      winnerId: json['winner_id'] as String?,
      players: playersJson.map((key, value) =>
          MapEntry(key, PlayerState.fromJson(value as Map<String, dynamic>))),
    );
  }

  Map<String, dynamic> toJson() => {
        'match_id': matchId,
        if (winnerId != null) 'winner_id': winnerId,
        'players':
            players.map((key, value) => MapEntry(key, value.toJson())),
      };
}

class MatchmakerMatch {
  final String matchId;
  final String mode;
  final List<String> playerIds;

  MatchmakerMatch({
    required this.matchId,
    required this.mode,
    required this.playerIds,
  });

  factory MatchmakerMatch.fromJson(Map<String, dynamic> json) =>
      MatchmakerMatch(
        matchId: json['match_id'] as String,
        mode: json['mode'] as String? ?? 'default',
        playerIds: (json['player_ids'] as List<dynamic>?)
                ?.map((playerId) => playerId as String)
                .toList() ??
            [],
      );

  Map<String, dynamic> toJson() => {
        'match_id': matchId,
        'mode': mode,
        'player_ids': playerIds,
      };
}

class PresenceEvent {
  final String playerId;
  final String status;

  PresenceEvent({required this.playerId, required this.status});

  factory PresenceEvent.fromJson(Map<String, dynamic> json) => PresenceEvent(
        playerId: json['player_id'] as String,
        status: json['status'] as String,
      );

  Map<String, dynamic> toJson() => {
        'player_id': playerId,
        'status': status,
      };
}

class RealtimeError {
  final String message;
  final int? code;

  RealtimeError({required this.message, this.code});

  factory RealtimeError.fromJson(Map<String, dynamic> json) => RealtimeError(
        message: json['message'] as String? ?? json['error'] as String? ?? 'Unknown error',
        code: json['code'] as int?,
      );

  Map<String, dynamic> toJson() => {
        'message': message,
        if (code != null) 'code': code,
      };

  @override
  String toString() => 'RealtimeError($message${code != null ? ', code: $code' : ''})';
}

class MatchInput {
  final bool up;
  final bool down;
  final bool left;
  final bool right;
  final bool shoot;
  final double aimX;
  final double aimY;

  MatchInput({
    this.up = false,
    this.down = false,
    this.left = false,
    this.right = false,
    this.shoot = false,
    this.aimX = 0,
    this.aimY = 0,
  });

  Map<String, dynamic> toJson() => {
        'up': up,
        'down': down,
        'left': left,
        'right': right,
        'shoot': shoot,
        'aim_x': aimX,
        'aim_y': aimY,
      };
}
