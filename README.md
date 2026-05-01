# asobi

Dart client SDK for the [Asobi](https://github.com/widgrensit/asobi) game backend. Works with Flutter, Flame, and standalone Dart applications.

Pure Dart — no Flutter dependency. Minimal footprint (only `http` + `web_socket_channel`).

## Installation

```bash
dart pub add asobi
```

## Run a backend first

The SDK talks to an Asobi server. The fastest way to get one is the canonical SDK demo backend:

```bash
git clone https://github.com/widgrensit/sdk_demo_backend
cd sdk_demo_backend && docker compose up -d
```

That serves at `http://localhost:8084` (HTTP + WebSocket on `/ws`) with a 2-player `demo` mode. For the full reference game (arena shooter, boons, modifiers, bots) see [`asobi_arena_lua`](https://github.com/widgrensit/asobi_arena_lua).

## Quick Start

```dart
import 'dart:async';

import 'package:asobi/asobi.dart';

Future<void> main() async {
  final client = AsobiClient('localhost', port: 8084);

  // Register, falling back to login if the user already exists.
  try {
    await client.auth.register('player1', 'secret123', displayName: 'Player One');
  } on AsobiException catch (e) {
    if (e.statusCode == 409) {
      await client.auth.login('player1', 'secret123');
    } else {
      rethrow;
    }
  }

  // Wait for the WS handshake before queuing.
  final connected = Completer<void>();
  client.realtime.onConnected.stream.listen((_) {
    if (!connected.isCompleted) connected.complete();
  });

  // Server pushes match.matched (matchmaker push) or match.joined (reply to a
  // client-initiated match.join). Subscribe to both for the matchmade flow.
  client.realtime.onMatchmakerMatched.stream.listen((m) async {
    print('Matched into ${m.matchId} — joining…');
    await client.realtime.joinMatch(m.matchId);
  });

  client.realtime.onMatchState.stream.listen((state) {
    print('Tick — ${state.players.length} players');
  });

  await client.realtime.connect();
  await connected.future.timeout(const Duration(seconds: 5));
  await client.realtime.addToMatchmaker(mode: 'demo');
}
```

A complete runnable example is at [`example/example.dart`](example/example.dart). For an end-to-end console demo (register → matchmake → state → finish) see [`example/dart_console_demo.dart`](example/dart_console_demo.dart).

## Features

| Feature | REST | WebSocket |
|---------|------|-----------|
| Auth | Register, login, token refresh | - |
| Players | Profiles, updates | - |
| Matchmaker | Queue, status, cancel | Real-time match found |
| Matches | List, details | State sync, input, events |
| Leaderboards | Top scores, around player, submit | - |
| Economy | Wallets, store, purchases | - |
| Inventory | Items, consume | - |
| Social | Friends, groups, chat history | Chat messages, presence |
| Tournaments | List, join | - |
| Notifications | List, read, delete | Real-time push |
| Storage | Cloud saves, key-value | - |

## Flutter

The SDK is pure Dart but works fine inside Flutter apps. Hold the `AsobiClient` in whatever DI container you use (Riverpod, GetIt, an `InheritedWidget`) and dispose it when the app exits.

```dart
class _MyAppState extends State<MyApp> {
  late final AsobiClient _client = AsobiClient('localhost', port: 8084);

  @override
  void dispose() {
    _client.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      StreamBuilder<MatchState>(
        stream: _client.realtime.onMatchState.stream,
        builder: (_, snap) => Text('Players: ${snap.data?.players.length ?? 0}'),
      );
}
```

## Flame Integration

For Flame games, use [flame_asobi](https://github.com/widgrensit/flame_asobi) which provides Flame-native components and mixins on top of this SDK.

## Wire protocol

See the [WebSocket protocol guide](https://github.com/widgrensit/asobi/blob/main/guides/websocket-protocol.md).

## License

Apache-2.0
