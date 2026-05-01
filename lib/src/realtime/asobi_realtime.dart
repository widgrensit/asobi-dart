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
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 10;
  static const Duration _baseReconnectDelay = Duration(seconds: 1);
  Timer? _reconnectTimer;

  bool get isConnected => _channel != null;

  final StreamController<void> onConnected = StreamController.broadcast();
  final StreamController<String> onDisconnected = StreamController.broadcast();
  final StreamController<MatchState> onMatchState = StreamController.broadcast();
  final StreamController<MatchStarted> onMatchStarted = StreamController.broadcast();
  final StreamController<MatchResult> onMatchFinished = StreamController.broadcast();
  final StreamController<ChatMessage> onChatMessage = StreamController.broadcast();
  final StreamController<Notification> onNotification = StreamController.broadcast();
  final StreamController<MatchmakerMatch> onMatchmakerMatched = StreamController.broadcast();
  final StreamController<PresenceEvent> onPresenceChanged = StreamController.broadcast();
  final StreamController<Map<String, dynamic>> onVoteStart = StreamController.broadcast();
  final StreamController<Map<String, dynamic>> onVoteTally = StreamController.broadcast();
  final StreamController<Map<String, dynamic>> onVoteResult = StreamController.broadcast();
  final StreamController<Map<String, dynamic>> onVoteVetoed = StreamController.broadcast();
  final StreamController<WorldTick> onWorldTick = StreamController.broadcast();
  final StreamController<WorldTerrainChunk> onWorldTerrain = StreamController.broadcast();
  final StreamController<Map<String, dynamic>> onWorldJoined = StreamController.broadcast();
  final StreamController<Map<String, dynamic>> onWorldLeft = StreamController.broadcast();
  final StreamController<Map<String, dynamic>> onWorldEvent = StreamController.broadcast();
  final StreamController<ChatMessage> onDmMessage = StreamController.broadcast();
  final StreamController<Map<String, dynamic>> onDmSent = StreamController.broadcast();
  final StreamController<Map<String, dynamic>> onChatJoined = StreamController.broadcast();
  final StreamController<Map<String, dynamic>> onChatLeft = StreamController.broadcast();
  final StreamController<Map<String, dynamic>> onMatchmakerQueued = StreamController.broadcast();
  final StreamController<Map<String, dynamic>> onMatchmakerRemoved = StreamController.broadcast();
  final StreamController<Map<String, dynamic>> onVoteCastOk = StreamController.broadcast();
  final StreamController<Map<String, dynamic>> onVoteVetoOk = StreamController.broadcast();
  final StreamController<Map<String, dynamic>> onMatchEvent = StreamController.broadcast();
  final StreamController<RealtimeError> onError = StreamController.broadcast();

  AsobiRealtime(this._client);

  Future<void> connect({bool autoReconnect = true}) async {
    _autoReconnect = autoReconnect;
    _reconnectAttempts = 0;
    await _connect();
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

    await _send('session.connect', {'token': _client.sessionToken});
    _reconnectAttempts = 0;
  }

  void _scheduleReconnect() {
    if (!_autoReconnect) return;
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

  void sendWorldInput(Map<String, dynamic> data) =>
      _sendFireAndForget('world.input', data);

  /// Lists running worlds, optionally filtered by mode and capacity.
  Future<Map<String, dynamic>> listWorlds({String? mode, bool? hasCapacity}) =>
      _send('world.list', {
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

  void _sendFireAndForget(String type, Map<String, dynamic> payload) {
    final msg = jsonEncode({'type': type, 'payload': payload});
    _channel!.sink.add(msg);
  }

  void _handleMessage(String raw) {
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final msg = WsMessage.fromJson(json);

    if (msg.cid != null && _pending.containsKey(msg.cid)) {
      final completer = _pending.remove(msg.cid)!;
      if (msg.type == 'error') {
        completer.completeError(AsobiException(-1, msg.payload['message'] as String? ?? 'Unknown error'));
      } else {
        completer.complete(msg.payload);
      }
    }

    switch (msg.type) {
      case 'session.connected':
        onConnected.add(null);
      case 'match.state':
        onMatchState.add(MatchState.fromJson(msg.payload));
      case 'match.started':
        onMatchStarted.add(MatchStarted.fromJson(msg.payload));
      case 'match.finished':
        onMatchFinished.add(MatchResult.fromJson(msg.payload));
      case 'match.vote_start':
        onVoteStart.add(msg.payload);
      case 'match.vote_tally':
        onVoteTally.add(msg.payload);
      case 'match.vote_result':
        onVoteResult.add(msg.payload);
      case 'match.vote_vetoed':
        onVoteVetoed.add(msg.payload);
      case 'chat.message':
        onChatMessage.add(ChatMessage.fromJson(msg.payload));
      case 'notification.new':
        onNotification.add(Notification.fromJson(msg.payload));
      case 'match.matched':
        onMatchmakerMatched.add(MatchmakerMatch.fromJson(msg.payload));
      case 'world.tick':
        onWorldTick.add(WorldTick.fromJson(msg.payload));
      case 'world.terrain':
        onWorldTerrain.add(WorldTerrainChunk.fromJson(msg.payload));
      case 'world.joined':
        onWorldJoined.add(msg.payload);
      case 'world.left':
        onWorldLeft.add(msg.payload);
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
      case 'presence.updated':
        onPresenceChanged.add(PresenceEvent.fromJson(msg.payload));
      case 'error':
        onError.add(RealtimeError.fromJson(msg.payload));
      default:
        if (msg.type.startsWith('match.')) {
          onMatchEvent.add(msg.payload);
        } else if (msg.type.startsWith('world.')) {
          onWorldEvent.add(msg.payload);
        }
    }
  }
}
