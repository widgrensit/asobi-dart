import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../asobi_client.dart';
import '../http_client.dart';
import '../models/notification_models.dart';
import '../models/realtime_models.dart';
import '../models/social_models.dart';

/// WebSocket realtime client for live match state, chat, matchmaking, and presence.
///
/// Supports automatic reconnection with exponential backoff. All server-push
/// events are exposed as broadcast [Stream]s.
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

  /// Whether the WebSocket connection is currently open.
  bool get isConnected => _channel != null;

  /// Fires when the session is authenticated over WebSocket.
  final StreamController<void> onConnected = StreamController.broadcast();

  /// Fires when the connection is closed, with a reason string.
  final StreamController<String> onDisconnected = StreamController.broadcast();

  /// Fires on every match game-state tick from the server.
  final StreamController<MatchState> onMatchState =
      StreamController.broadcast();

  /// Fires when a match begins.
  final StreamController<MatchStarted> onMatchStarted =
      StreamController.broadcast();

  /// Fires when a match ends with final results.
  final StreamController<MatchResult> onMatchFinished =
      StreamController.broadcast();

  /// Fires when a chat message is received in a joined channel.
  final StreamController<ChatMessage> onChatMessage =
      StreamController.broadcast();

  /// Fires when a new notification arrives.
  final StreamController<Notification> onNotification =
      StreamController.broadcast();

  /// Fires when the matchmaker finds a match.
  final StreamController<MatchmakerMatch> onMatchmakerMatched =
      StreamController.broadcast();

  /// Fires when a player's presence status changes.
  final StreamController<PresenceEvent> onPresenceChanged =
      StreamController.broadcast();

  /// Fires when a vote session starts in the current match.
  final StreamController<Map<String, dynamic>> onVoteStart =
      StreamController.broadcast();

  /// Fires when the server broadcasts an interim vote tally.
  final StreamController<Map<String, dynamic>> onVoteTally =
      StreamController.broadcast();

  /// Fires when a vote session concludes with a final result.
  final StreamController<Map<String, dynamic>> onVoteResult =
      StreamController.broadcast();

  /// Fires when a vote is vetoed by a player.
  final StreamController<Map<String, dynamic>> onVoteVetoed =
      StreamController.broadcast();

  /// Fires on WebSocket or server errors.
  final StreamController<RealtimeError> onError = StreamController.broadcast();

  AsobiRealtime(this._client);

  /// Opens the WebSocket connection and authenticates the session.
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

  /// Joins a live match by [matchId] to start receiving state updates.
  Future<void> joinMatch(String matchId) =>
      _send('match.join', {'match_id': matchId});

  /// Sends player input to the current match (fire-and-forget).
  void sendMatchInput(MatchInput input) =>
      _sendFireAndForget('match.input', input.toJson());

  /// Leaves the current match.
  Future<void> leaveMatch() => _send('match.leave', {});

  /// Casts a vote in an active vote session.
  ///
  /// [optionId] may be a single `String` or a `List<String>` for multi-select.
  void castVote(String voteId, dynamic optionId) =>
      _sendFireAndForget('match.vote', {'vote_id': voteId, 'option_id': optionId});

  /// Vetoes an active vote session.
  void castVeto(String voteId) =>
      _sendFireAndForget('match.veto', {'vote_id': voteId});

  /// Adds the player to the matchmaking queue for the given [mode].
  Future<void> addToMatchmaker({String mode = 'default'}) =>
      _send('matchmaker.add', {'mode': mode});

  /// Removes the player from the matchmaking queue.
  Future<void> removeFromMatchmaker(String ticketId) =>
      _send('matchmaker.remove', {'ticket_id': ticketId});

  /// Joins a chat channel to receive messages.
  Future<void> joinChat(String channelId) =>
      _send('chat.join', {'channel_id': channelId});

  /// Sends a chat message to a channel (fire-and-forget).
  void sendChatMessage(String channelId, String content) => _sendFireAndForget(
      'chat.send', {'channel_id': channelId, 'content': content});

  /// Leaves a chat channel.
  Future<void> leaveChat(String channelId) =>
      _send('chat.leave', {'channel_id': channelId});

  /// Updates the player's online presence status.
  Future<void> updatePresence({String status = 'online'}) =>
      _send('presence.update', {'status': status});

  /// Sends a keepalive heartbeat to the server.
  void sendHeartbeat() => _sendFireAndForget('session.heartbeat', {});

  /// Closes the WebSocket connection and cancels any pending requests.
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

  Future<Map<String, dynamic>> _send(
      String type, Map<String, dynamic> payload) {
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
        completer.completeError(AsobiException(
            -1, msg.payload['message'] as String? ?? 'Unknown error'));
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
      case 'presence.changed':
        onPresenceChanged.add(PresenceEvent.fromJson(msg.payload));
      case 'error':
        onError.add(RealtimeError.fromJson(msg.payload));
    }
  }
}
