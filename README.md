# asobi-dart

Dart client SDK for the [Asobi](https://github.com/widgrensit/asobi) game backend. Works with Flutter, Flame, and standalone Dart applications.

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  asobi:
    git:
      url: https://github.com/widgrensit/asobi-dart.git
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

- **Auth** - Register, login, token refresh
- **Players** - Profiles, updates
- **Matchmaker** - Queue, status, cancel
- **Matches** - List, details
- **Leaderboards** - Top scores, around player, submit
- **Economy** - Wallets, store, purchases
- **Inventory** - Items, consume
- **Social** - Friends, groups, chat history
- **Tournaments** - List, join
- **Notifications** - List, read, delete
- **Storage** - Cloud saves, generic key-value
- **Realtime** - WebSocket for matches, chat, presence, matchmaking

## License

Apache-2.0
