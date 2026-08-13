import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../asobi_client.dart';
import '../http_client.dart';
import '../models/notification_models.dart';
import '../models/realtime_models.dart';
import '../models/social_models.dart';

class AsobiRealtime {
  final AsobiClient _client;
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  int _cidCounter = 0;
  final Map<String, Completer<Map<String, dynamic>>> _pending = {};

  bool _autoReconnect = true;
  bool _authExpired = false;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 10;
  static const Duration _baseReconnectDelay = Duration(seconds: 1);
  Timer? _reconnectTimer;

  bool get isConnected => _channel != null;

  final StreamController<void> onConnected = StreamController.broadcast();
  final StreamController<String> onDisconnected = StreamController.broadcast();
  final StreamController<void> onAuthExpired = StreamController.broadcast();
  final StreamController<Map<String, dynamic>> onHeartbeat = StreamController.broadcast();
  final StreamController<MatchState> onMatchState = StreamController.broadcast();
  final StreamController<MatchmakerMatch> onMatchmakerMatched = StreamController.broadcast();
  final StreamController<MatchResult> onMatchFinished = StreamController.broadcast();
  final StreamController<Map<String, dynamic>> onMatchJoined = StreamController.broadcast();
  final StreamController<Map<String, dynamic>> onMatchLeft = StreamController.broadcast();
  final StreamController<Map<String, dynamic>> onMatchmakerExpired = StreamController.broadcast();
  final StreamController<Map<String, dynamic>> onMatchmakerFailed = StreamController.broadcast();
  final StreamController<ChatMessage> onChatMessage = StreamController.broadcast();
  final StreamController<Notification> onNotification = StreamController.broadcast();
  final StreamController<PresenceEvent> onPresenceChanged = StreamController.broadcast();
  final StreamController<WorldTick> onWorldTick = StreamController.broadcast();

  /// Fires on `world.ack` - one zone's ack of the highest `world.input`
  /// [WorldAck.seq] it consumed for you as of [WorldAck.tick]. Fires only if
  /// you stamped a `seq` on your input; use it to reconcile client-side
  /// prediction.
  ///
  /// The mark is held per zone, not per connection, and you are subscribed to
  /// the ring of zones around your own. Each subscribed zone acks every
  /// `broadcast_interval` simulation ticks (default 3), so once you have moved
  /// this fires more than once per tick, and [WorldAck.seq] can go backwards
  /// as a zone you left keeps emitting its own frozen mark. Nothing in the
  /// frame says which zone sent it. Keep a running maximum and ignore any ack
  /// that does not exceed it before pruning your pending-input buffer.
  ///
  /// A zone tick that changed something sends `world.tick` first and this
  /// second; a tick that changed nothing sends this alone, so prune here
  /// rather than in the [onWorldTick] handler.
  final StreamController<WorldAck> onWorldAck = StreamController.broadcast();
  final StreamController<WorldTerrainChunk> onWorldTerrain = StreamController.broadcast();
  final StreamController<Map<String, dynamic>> onWorldJoined = StreamController.broadcast();
  final StreamController<Map<String, dynamic>> onWorldLeft = StreamController.broadcast();
  final StreamController<Map<String, dynamic>> onWorldList = StreamController.broadcast();
  final StreamController<Map<String, dynamic>> onWorldPhaseChanged = StreamController.broadcast();
  final StreamController<Map<String, dynamic>> onWorldFinished = StreamController.broadcast();
  /// Fires on `world.<event>` - a world script's
  /// `game.broadcast(event, payload)`. Carries the script-chosen event name;
  /// see [GameBroadcast].
  final StreamController<GameBroadcast> onWorldEvent = StreamController.broadcast();
  final StreamController<ChatMessage> onDmMessage = StreamController.broadcast();
  final StreamController<Map<String, dynamic>> onDmSent = StreamController.broadcast();
  final StreamController<Map<String, dynamic>> onChatJoined = StreamController.broadcast();
  final StreamController<Map<String, dynamic>> onChatLeft = StreamController.broadcast();
  final StreamController<Map<String, dynamic>> onMatchmakerQueued = StreamController.broadcast();
  final StreamController<Map<String, dynamic>> onMatchmakerRemoved = StreamController.broadcast();
  final StreamController<Map<String, dynamic>> onVoteCastOk = StreamController.broadcast();
  final StreamController<Map<String, dynamic>> onVoteVetoOk = StreamController.broadcast();
  final StreamController<Map<String, dynamic>> onVoteStart = StreamController.broadcast();
  final StreamController<Map<String, dynamic>> onVoteTally = StreamController.broadcast();
  final StreamController<Map<String, dynamic>> onVoteResult = StreamController.broadcast();
  final StreamController<Map<String, dynamic>> onVoteVetoed = StreamController.broadcast();
  final StreamController<Map<String, dynamic>> onMatchList = StreamController.broadcast();
  /// Fires on `match.<event>` - a match script's
  /// `game.broadcast(event, payload)`. Carries the script-chosen event name;
  /// see [GameBroadcast].
  final StreamController<GameBroadcast> onMatchEvent = StreamController.broadcast();
  final StreamController<RealtimeError> onError = StreamController.broadcast();

  /// Fires on `game.error` - a Lua game-script callback failure for input
  /// this player sent. Dev-mode only (`ASOBI_DEV_ERRORS=true` server-side);
  /// wire it up to a dev console, not production UI.
  final StreamController<GameError> onGameError = StreamController.broadcast();

  /// Fires on `game.message` - a server push whenever Lua calls
  /// `game.send(player_id, message)`. Sent unconditionally in production.
  final StreamController<GameMessage> onGameMessage =
      StreamController.broadcast();

  /// Fires on `module.event` - a named push from an extension module. The
  /// whole payload is surfaced ([ModuleEvent.module], [ModuleEvent.event],
  /// [ModuleEvent.data]); branch on [ModuleEvent.event]. Unlike `module.*`
  /// twins, this frame has no `game.event` alias.
  final StreamController<ModuleEvent> onModuleEvent =
      StreamController.broadcast();

  AsobiRealtime(this._client);

  Future<void> connect({bool autoReconnect = true}) async {
    _autoReconnect = autoReconnect;
    _authExpired = false;
    _reconnectAttempts = 0;
    await _connect();
  }

  /// Re-sends `session.connect` with a rotated access token so an open
  /// socket keeps a valid session after a token refresh. Clears any prior
  /// auth-expired state.
  Future<void> reauthenticate(String token) async {
    _authExpired = false;
    if (!isConnected) return;
    await _send('session.connect', {'token': token});
  }

  Future<void> _connect() async {
    if (isConnected) return;

    _channel = WebSocketChannel.connect(Uri.parse(_client.config.wsUrl));
    await _channel!.ready;

    _subscription = _channel!.stream.listen(
      (data) => _handleMessage(data as String),
      onDone: () {
        _channel = null;
        onDisconnected.add('closed');
        _scheduleReconnect();
      },
      onError: (error) {
        onError.add(RealtimeError(message: error.toString()));
        _channel = null;
        _scheduleReconnect();
      },
    );

    await _send('session.connect', {'token': _client.accessToken});
    _reconnectAttempts = 0;
  }

  void _handleAuthExpired() {
    _authExpired = true;
    _autoReconnect = false;
    _reconnectTimer?.cancel();
    onAuthExpired.add(null);
  }

  void _scheduleReconnect() {
    if (!_autoReconnect || _authExpired) return;
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      onError.add(RealtimeError(
        message: 'Max reconnect attempts ($_maxReconnectAttempts) exceeded',
      ));
      return;
    }

    final delay = _baseReconnectDelay * pow(2, _reconnectAttempts);
    _reconnectAttempts++;
    _reconnectTimer = Timer(delay, () async {
      try {
        await _connect();
      } catch (_) {
        _scheduleReconnect();
      }
    });
  }

  Future<void> joinMatch(String matchId) =>
      _send('match.join', {'match_id': matchId});

  /// Sends a `match.input` envelope. The payload shape is game-specific —
  /// each backend (sdk_demo_backend uses `{move_x, move_y}`, asobi_arena
  /// uses `{up, down, left, right, shoot, aim_x, aim_y}`, etc.) defines
  /// what its match script reads.
  void sendMatchInput(Map<String, dynamic> input) =>
      _sendFireAndForget('match.input', input);

  Future<void> leaveMatch() => _send('match.leave', {});

  /// Joins an existing world by ID.
  Future<Map<String, dynamic>> joinWorld(String worldId) =>
      _send('world.join', {'world_id': worldId});

  /// Creates a new world and auto-joins it.
  Future<Map<String, dynamic>> createWorld(String mode) =>
      _send('world.create', {'mode': mode});

  /// Finds a world with capacity or creates one, then auto-joins.
  Future<Map<String, dynamic>> findOrCreateWorld(String mode) =>
      _send('world.find_or_create', {'mode': mode});

  void castVote(String voteId, dynamic optionId) =>
      _sendFireAndForget('vote.cast', {'vote_id': voteId, 'option_id': optionId});

  void castVeto(String voteId) =>
      _sendFireAndForget('vote.veto', {'vote_id': voteId});

  Future<void> addToMatchmaker({
    String mode = 'default',
    Map<String, dynamic>? properties,
    List<String>? party,
  }) {
    final payload = <String, dynamic>{'mode': mode};
    if (properties != null) payload['properties'] = properties;
    if (party != null) payload['party'] = party;
    return _send('matchmaker.add', payload);
  }

  Future<void> removeFromMatchmaker(String ticketId) =>
      _send('matchmaker.remove', {'ticket_id': ticketId});

  Future<void> joinChat(String channelId) =>
      _send('chat.join', {'channel_id': channelId});

  void sendChatMessage(String channelId, String content) =>
      _sendFireAndForget('chat.send', {'channel_id': channelId, 'content': content});

  Future<void> leaveChat(String channelId) =>
      _send('chat.leave', {'channel_id': channelId});

  void sendDm(String recipientId, String content) =>
      _sendFireAndForget('dm.send', {'recipient_id': recipientId, 'content': content});

  Future<void> leaveWorld() => _send('world.leave', {});

  /// Send input to your zone. Pass [seq] - a per-input sequence number your
  /// client increments - to opt into `world.ack` reconciliation; the server
  /// echoes back the highest seq it has consumed (see [onWorldAck]). [seq]
  /// must be an integer from 0 to 2^53 - 1. Out of that range it is the `seq`
  /// that is discarded, not the input: the input is still queued and applied
  /// as normal, it just records no ack.
  void sendWorldInput(Map<String, dynamic> data, {int? seq}) =>
      _sendFireAndForget('world.input', data, seq: seq);

  /// Lists running worlds, optionally filtered by mode and capacity.
  Future<Map<String, dynamic>> listWorlds({String? mode, bool? hasCapacity}) =>
      _send('world.list', {
        if (mode != null) 'mode': mode,
        if (hasCapacity != null) 'has_capacity': hasCapacity,
      });

  /// Lists live, joinable matches, optionally filtered by mode and capacity.
  Future<Map<String, dynamic>> listMatches({String? mode, bool? hasCapacity}) =>
      _send('match.list', {
        if (mode != null) 'mode': mode,
        if (hasCapacity != null) 'has_capacity': hasCapacity,
      });

  Future<void> updatePresence({String status = 'online'}) =>
      _send('presence.update', {'status': status});

  void sendHeartbeat() => _sendFireAndForget('session.heartbeat', {});

  Future<void> disconnect() async {
    _autoReconnect = false;
    _reconnectTimer?.cancel();
    await _subscription?.cancel();
    await _channel?.sink.close();
    _channel = null;
    for (final completer in _pending.values) {
      completer.completeError(AsobiException(-1, 'Disconnected'));
    }
    _pending.clear();
  }

  /// Call an extension's RPC method and await its reply.
  ///
  /// ```dart
  /// final result = await rt.rpc('quests.claim', {'quest_key': 'daily'});
  /// ```
  ///
  /// Correlated by `cid` like every other request, so concurrent calls are
  /// safe and may answer out of order. `params` and the returned `result` are
  /// always objects, so either can grow a field without breaking a shipped
  /// client.
  ///
  /// Throws [AsobiRpcException] when the handler answers `rpc.error`, so a
  /// domain outcome (`quests.already_claimed`) is catchable by code rather
  /// than by matching on prose.
  Future<Map<String, dynamic>> rpc(String method,
      [Map<String, dynamic> params = const {}]) async {
    final payload = await _send('rpc.call', debugRpcPayload(method, params));
    return (payload['result'] as Map<String, dynamic>?) ?? const {};
  }

  Future<Map<String, dynamic>> _send(String type, Map<String, dynamic> payload) {
    final cid = (++_cidCounter).toString();
    final completer = Completer<Map<String, dynamic>>();
    _pending[cid] = completer;

    final msg = jsonEncode({'type': type, 'payload': payload, 'cid': cid});
    _channel!.sink.add(msg);

    return completer.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        _pending.remove(cid);
        throw TimeoutException('WebSocket request "$type" timed out');
      },
    );
  }

  void _sendFireAndForget(String type, Map<String, dynamic> payload,
      {int? seq}) {
    _channel!.sink.add(debugFireAndForgetFrame(type, payload, seq: seq));
  }

  /// Test seam: the exact fire-and-forget frame bytes, without a socket. `seq`
  /// is a top-level sibling of `payload`, omitted when null.
  String debugFireAndForgetFrame(String type, Map<String, dynamic> payload,
          {int? seq}) =>
      jsonEncode({
        'type': type,
        if (seq != null) 'seq': seq,
        'payload': payload,
      });

  void _handleMessage(String raw) {
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final msg = WsMessage.fromJson(json);

    if (msg.cid != null && _pending.containsKey(msg.cid)) {
      final completer = _pending.remove(msg.cid)!;
      if (msg.type == 'rpc.error') {
        // The shared error object: {code, message, details}. Completing with
        // a generic exception would throw away the code, which is the only
        // part a caller can branch on.
        final error =
            (msg.payload['error'] as Map<String, dynamic>?) ?? const {};
        completer.completeError(AsobiRpcException(
          error['code'] as String? ?? 'internal',
          error['message'] as String? ?? '',
          (error['details'] as Map<String, dynamic>?) ?? const {},
        ));
      } else if (msg.type == 'error') {
        completer.completeError(AsobiException(
            -1,
            msg.payload['reason'] as String? ??
                msg.payload['message'] as String? ??
                'Unknown error'));
      } else {
        completer.complete(msg.payload);
      }
    }

    switch (msg.type) {
      case 'session.connected':
        onConnected.add(null);
      case 'session.heartbeat':
        onHeartbeat.add(msg.payload);
      case 'match.state':
        onMatchState.add(MatchState.fromJson(msg.payload));
      case 'match.matched':
        onMatchmakerMatched.add(MatchmakerMatch.fromJson(msg.payload));
      case 'match.joined':
        onMatchJoined.add(msg.payload);
      case 'match.left':
        onMatchLeft.add(msg.payload);
      case 'match.finished':
        onMatchFinished.add(MatchResult.fromJson(msg.payload));
      case 'match.matchmaker_expired':
        onMatchmakerExpired.add(msg.payload);
      case 'match.matchmaker_failed':
        onMatchmakerFailed.add(msg.payload);
      case 'match.list':
        onMatchList.add(msg.payload);
      case 'chat.message':
        onChatMessage.add(ChatMessage.fromJson(msg.payload));
      case 'notification.new':
        onNotification.add(Notification.fromJson(msg.payload));
      case 'world.tick':
        onWorldTick.add(WorldTick.fromJson(msg.payload));
      case 'world.ack':
        onWorldAck.add(WorldAck.fromJson(msg.payload));
      case 'world.terrain':
        onWorldTerrain.add(WorldTerrainChunk.fromJson(msg.payload));
      case 'world.joined':
        onWorldJoined.add(msg.payload);
      case 'world.left':
        onWorldLeft.add(msg.payload);
      case 'world.list':
        onWorldList.add(msg.payload);
      case 'world.phase_changed':
        onWorldPhaseChanged.add(msg.payload);
      case 'world.finished':
        onWorldFinished.add(msg.payload);
      case 'dm.message':
        onDmMessage.add(ChatMessage.fromJson(msg.payload));
      case 'dm.sent':
        onDmSent.add(msg.payload);
      case 'chat.joined':
        onChatJoined.add(msg.payload);
      case 'chat.left':
        onChatLeft.add(msg.payload);
      case 'matchmaker.queued':
        onMatchmakerQueued.add(msg.payload);
      case 'matchmaker.removed':
        onMatchmakerRemoved.add(msg.payload);
      case 'vote.cast_ok':
        onVoteCastOk.add(msg.payload);
      case 'vote.veto_ok':
        onVoteVetoOk.add(msg.payload);
      case 'match.vote_start':
        onVoteStart.add(msg.payload);
      case 'match.vote_tally':
        onVoteTally.add(msg.payload);
      case 'match.vote_result':
        onVoteResult.add(msg.payload);
      case 'match.vote_vetoed':
        onVoteVetoed.add(msg.payload);
      case 'presence.updated':
        onPresenceChanged.add(PresenceEvent.fromJson(msg.payload));
      // `module.*` is the current name; `game.*` is the alias the server
      // still emits. One stream each, so a listener does not have to know
      // which name its server is on.
      case 'game.error':
      case 'module.error':
        onGameError.add(GameError.fromJson(msg.payload));
      case 'game.message':
      case 'module.message':
        onGameMessage.add(GameMessage.fromJson(msg.payload));
      // A named extension push. Keyed on the outer `type` only, so an
      // unfamiliar inner `event` still surfaces - the event name is data the
      // app routes on, not a dispatch gate. No `game.event` twin, and no
      // `module.` passthrough, so it must be enumerated here or it is dropped.
      case 'module.event':
        onModuleEvent.add(ModuleEvent.fromJson(msg.payload));
      case 'error':
        final reason = msg.payload['reason'] as String?;
        if (reason == 'invalid_token' || reason == 'session_revoked') {
          _handleAuthExpired();
        }
        onError.add(RealtimeError.fromJson(msg.payload));
      default:
        // A Lua script's `game.broadcast(name, payload)`. The name is
        // script-chosen, so it can never have a case above - strip the
        // namespace and hand it to the listener, which has no other way to
        // tell one broadcast from another.
        if (msg.type.startsWith('match.')) {
          onMatchEvent.add(
              GameBroadcast(event: msg.type.substring(6), payload: msg.payload));
        } else if (msg.type.startsWith('world.')) {
          onWorldEvent.add(
              GameBroadcast(event: msg.type.substring(6), payload: msg.payload));
        }
    }
  }

  /// Test-only entry point for feeding raw WebSocket frames into the
  /// dispatch switch without opening a real connection. Exercised by
  /// `test/dispatch_test.dart` against the canonical fixture corpus.
  void debugHandleMessage(String raw) => _handleMessage(raw);

  /// Test-only: register a pending reply under `cid` exactly as `_send` does,
  /// so reply correlation can be exercised without opening a socket.
  Future<Map<String, dynamic>> debugAwaitReply(String cid) {
    final completer = Completer<Map<String, dynamic>>();
    _pending[cid] = completer;
    return completer.future;
  }

  /// Test-only: the `rpc.call` payload [rpc] builds, without a socket.
  static Map<String, dynamic> debugRpcPayload(
          String method, Map<String, dynamic> params) =>
      {'protocol': 1, 'method': method, 'params': params};
}
