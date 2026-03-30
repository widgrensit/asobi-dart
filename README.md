# asobi

Dart client SDK for the [Asobi](https://github.com/widgrensit/asobi) game backend. Works with Flutter, Flame, and standalone Dart applications.

Pure Dart — no Flutter dependency. Minimal footprint (only `http` + `web_socket_channel`).

## Installation

```bash
dart pub add asobi
```

## Quick Start

```dart
import 'package:asobi/asobi.dart';

final client = AsobiClient('localhost', port: 8080);

// Auth
await client.auth.login('player1', 'secret123');

// REST APIs
final player = await client.players.getSelf();
final top = await client.leaderboards.getTop('weekly');
final wallets = await client.economy.getWallets();

// Real-time
client.realtime.onMatchState.stream.listen((state) {
  print('Tick: ${state['tick']}');
});

await client.realtime.connect();
await client.realtime.addToMatchmaker(mode: 'arena');
```

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

## Flame Integration

For Flame games, use [flame_asobi](https://github.com/widgrensit/flame_asobi) which provides Flame-native components and mixins on top of this SDK.

## License

Apache-2.0
