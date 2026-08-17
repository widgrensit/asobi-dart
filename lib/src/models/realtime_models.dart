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

  /// The raw `match.state` payload as the server sent it. Use to read
  /// game-specific fields the typed view doesn't capture (e.g. `phase`,
  /// custom round/boon/vote state, world-specific arrays).
  final Map<String, dynamic> raw;

  MatchState({
    required this.players,
    required this.projectiles,
    required this.timeRemaining,
    this.raw = const {},
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
      raw: json,
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

/// Delivered on [AsobiRealtime.onMatchmakerMatched] when the matchmaker places
/// you into a match (server `match.matched`). The matchmaker auto-places you -
/// no explicit join is needed; `match.state` starts flowing on its own.
class MatchmakerMatch {
  final String matchId;
  final List<String> players;

  MatchmakerMatch({required this.matchId, this.players = const []});

  factory MatchmakerMatch.fromJson(Map<String, dynamic> json) {
    final p = json['players'];
    return MatchmakerMatch(
      matchId: json['match_id'] as String,
      players: p is List ? p.map((e) => e.toString()).toList() : const [],
    );
  }

  Map<String, dynamic> toJson() => {
        'match_id': matchId,
        'players': players,
      };
}

/// Delivered on [AsobiRealtime.onMatchFinished] when a match ends (server
/// `match.finished`).
class MatchResult {
  final String matchId;

  /// Whatever your game returned with `{finished, Result, State}`. asobi does
  /// not interpret it, other than reading `winners`/`winner` and
  /// `losers`/`loser` to move the `wins` and `losses` player stats, so the
  /// shape is game-specific and stays untyped here.
  final Map<String, dynamic> result;

  MatchResult({
    required this.matchId,
    this.result = const {},
  });

  factory MatchResult.fromJson(Map<String, dynamic> json) => MatchResult(
        matchId: json['match_id'] as String? ?? '',
        result: json['result'] as Map<String, dynamic>? ?? {},
      );

  Map<String, dynamic> toJson() => {
        'match_id': matchId,
        'result': result,
      };
}

class PresenceEvent {
  final String playerId;
  final String status;

  PresenceEvent({required this.playerId, required this.status});

  factory PresenceEvent.fromJson(Map<String, dynamic> json) => PresenceEvent(
        playerId: json['player_id'] as String? ?? '',
        status: json['status'] as String? ?? '',
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
        message: json['reason'] as String? ??
            json['message'] as String? ??
            json['error'] as String? ??
            'Unknown error',
        code: json['code'] as int?,
      );

  Map<String, dynamic> toJson() => {
        'message': message,
        if (code != null) 'code': code,
      };

  @override
  String toString() => 'RealtimeError($message${code != null ? ', code: $code' : ''})';
}

/// Delivered on [AsobiRealtime.onGameError] when a Lua game-script callback
/// fails while handling this player's input (server `game.error`). Dev-mode
/// only - the server only emits this when it runs with
/// `ASOBI_DEV_ERRORS=true`; production keeps script errors server-side.
class GameError {
  /// Which module raised it. The server renamed these frames
  /// `game.*` -> `module.*` so a second scripting runtime could use them, and
  /// carries this field on both names.
  final String module;
  final String callback;
  final String script;
  final String message;

  GameError(
      {this.module = 'lua',
      required this.callback,
      required this.script,
      required this.message});

  factory GameError.fromJson(Map<String, dynamic> json) => GameError(
        module: json['module'] as String? ?? 'lua',
        callback: json['callback'] as String? ?? '',
        script: json['script'] as String? ?? '',
        message: json['message'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'module': module,
        'callback': callback,
        'script': script,
        'message': message,
      };

  @override
  String toString() => 'GameError($script:$callback - $message)';
}

/// Delivered on [AsobiRealtime.onGameMessage] on `game.message` - a server
/// push whenever Lua calls `game.send(player_id, message)`. Sent
/// unconditionally in production, unlike [GameError]. `message` can be any
/// value the script passes: a string, a number, a boolean, `null`, or a
/// JSON object/array, so it stays untyped here - don't assume it's a
/// string.
class GameMessage {
  /// Which module sent it. See [GameError.module].
  final String module;
  final Object? message;

  GameMessage({this.module = 'lua', required this.message});

  factory GameMessage.fromJson(Map<String, dynamic> json) => GameMessage(
        module: json['module'] as String? ?? 'lua',
        message: json['message'],
      );

  Map<String, dynamic> toJson() => {'module': module, 'message': message};

  @override
  String toString() => 'GameMessage($module, $message)';
}

/// Delivered on [AsobiRealtime.onModuleEvent] on `module.event` - a named
/// server->client push from an extension module. Unlike a Lua
/// `game.broadcast`, both the module and the event name travel in the payload,
/// so [event] is the full dotted name the extension chose (`quests.completed`)
/// and the app branches on it. [data] is the extension-defined body and stays
/// untyped. There is no `game.event` alias; this frame arrives under one name.
class ModuleEvent {
  final String module;
  final String event;
  final Map<String, dynamic> data;

  ModuleEvent(
      {required this.module, required this.event, this.data = const {}});

  factory ModuleEvent.fromJson(Map<String, dynamic> json) => ModuleEvent(
        module: json['module'] as String? ?? '',
        event: json['event'] as String? ?? '',
        data: json['data'] as Map<String, dynamic>? ?? const {},
      );

  Map<String, dynamic> toJson() => {
        'module': module,
        'event': event,
        'data': data,
      };

  @override
  String toString() => 'ModuleEvent($module, $event, $data)';
}

/// Delivered on [AsobiRealtime.onMatchEvent] / [AsobiRealtime.onWorldEvent]
/// when a Lua script calls `game.broadcast(event, payload)`. The server sends
/// it as `match.<event>` / `world.<event>`, so [event] is the bare name the
/// script chose - `players_total` for `game.broadcast("players_total", ...)`.
/// Branch on it; asobi's own broadcasts (`match.state`, `match.finished`, the
/// `match.vote_*` family) have dedicated streams and never arrive here.
class GameBroadcast {
  final String event;
  final Map<String, dynamic> payload;

  GameBroadcast({required this.event, required this.payload});

  @override
  String toString() => 'GameBroadcast($event, $payload)';
}

class WorldTick {
  final int tick;
  final List<EntityDelta> updates;

  /// Which zone this frame came from, as `[x, y]`, or null from a server
  /// predating asobi v0.89.0 and from `match.state`, which has no zones.
  ///
  /// **Key your entities on this.** A player is subscribed to an interest ring
  /// of several zones at once, each an independent server process, and frames
  /// from two of them have no order relative to each other. A crossing emits
  /// `op: "r"` from the zone being left and `op: "a"` from the zone being
  /// entered, so merging every zone into one entity map is last-writer-wins -
  /// and when the remove lands last the entity is gone for good, because the
  /// server will not re-add something already in its own baseline. Keeping a
  /// map per zone, or recording which zone owns each id, makes that unreachable.
  final List<int>? zone;

  /// How many frames this zone has broadcast, or null from an older server.
  ///
  /// Gaps are what this is for: unlike [tick] it never skips, so a jump means
  /// frames were lost. [tick] skips on the server's `broadcast_interval` and is
  /// suppressed entirely on a tick that changed nothing, so a gap in it is
  /// ambiguous and cannot be used this way.
  ///
  /// Note it cannot see the crossing problem above. Both zones' sequences stay
  /// perfectly contiguous through an inverted remove/add pair, so this is no
  /// substitute for keying on [zone].
  final int? frameSeq;

  /// True when this frame is a complete baseline for its [zone] rather than an
  /// incremental delta: replace that zone's entities with these, do not merge.
  ///
  /// Adopt it unconditionally, including when [frameSeq] moves BACKWARDS. A zone
  /// restart resets the sequence while the zone's identity is unchanged, so
  /// rejecting a lower value here means rejecting the one frame that repairs it.
  final bool kf;

  WorldTick({
    required this.tick,
    required this.updates,
    this.zone,
    this.frameSeq,
    this.kf = false,
  });

  factory WorldTick.fromJson(Map<String, dynamic> json) => WorldTick(
        tick: (json['tick'] as num?)?.toInt() ?? 0,
        updates: (json['updates'] as List<dynamic>?)
                ?.map((u) => EntityDelta.fromJson(u as Map<String, dynamic>))
                .toList() ??
            [],
        zone: _zoneFrom(json['zone']),
        frameSeq: (json['frame_seq'] as num?)?.toInt(),
        kf: json['kf'] == true,
      );

  /// Null unless the value is a real two-element numeric pair. A malformed
  /// `zone` must read as absent rather than throw in a stream handler, where a
  /// raise would take the subscription down with it.
  static List<int>? _zoneFrom(dynamic value) {
    if (value is! List || value.length < 2) return null;
    final x = value[0], y = value[1];
    if (x is! num || y is! num) return null;
    return [x.toInt(), y.toInt()];
  }
}

/// `world.ack` - the server's acknowledgement of the highest `world.input`
/// [seq] it has consumed for you as of [tick]. Sent only to connections that
/// stamped a `seq`; use it to reconcile client-side prediction.
class WorldAck {
  final int tick;
  final int seq;

  WorldAck({required this.tick, required this.seq});

  factory WorldAck.fromJson(Map<String, dynamic> json) => WorldAck(
        tick: (json['tick'] as num?)?.toInt() ?? 0,
        seq: (json['seq'] as num?)?.toInt() ?? 0,
      );
}

class WorldTerrainChunk {
  final int coordX;
  final int coordY;

  /// Base64-encoded raw terrain bytes. Decode with [base64Decode].
  final String base64Data;

  WorldTerrainChunk({required this.coordX, required this.coordY, required this.base64Data});

  factory WorldTerrainChunk.fromJson(Map<String, dynamic> json) {
    final coords = json['coords'] as List<dynamic>? ?? const [0, 0];
    return WorldTerrainChunk(
      coordX: coords.isNotEmpty ? (coords[0] as num).toInt() : 0,
      coordY: coords.length > 1 ? (coords[1] as num).toInt() : 0,
      base64Data: json['data'] as String? ?? '',
    );
  }
}

class EntityDelta {
  /// "a" = added, "u" = updated, "r" = removed
  final String op;
  final String id;
  final Map<String, dynamic> data;

  EntityDelta({required this.op, required this.id, this.data = const {}});

  factory EntityDelta.fromJson(Map<String, dynamic> json) {
    final op = json['op'] as String? ?? 'u';
    final id = json['id'] as String? ?? '';
    final data = Map<String, dynamic>.from(json)
      ..remove('op')
      ..remove('id');
    return EntityDelta(op: op, id: id, data: data);
  }

  double get x => (data['x'] as num?)?.toDouble() ?? 0;
  double get y => (data['y'] as num?)?.toDouble() ?? 0;
  int get hp => (data['hp'] as num?)?.toInt() ?? (data['hull'] as num?)?.toInt() ?? 100;
  bool get docked => data['docked'] as bool? ?? false;
}

