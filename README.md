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

  // The matchmaker places you into a match and pushes match.matched. It
  // auto-places you, so there is no join step - match.state starts flowing.
  client.realtime.onMatchmakerMatched.stream.listen((m) {
    print('Matched into ${m.matchId}');
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

## Guest / anonymous auth

Sign a player in with no username or password using a device-scoped credential. Generate `deviceSecret` once (>= 32 CSPRNG bytes, base64-encoded), persist it in secure device storage, and pass it in on every call — the same `deviceId` + `deviceSecret` resumes the existing guest, a new pair creates one.

```dart
final auth = await client.auth.guest(deviceId, deviceSecret);
// auth.playerId, auth.accessToken, auth.refreshToken now stored on the client.

// Later, let the guest claim a permanent account (keeps the same player_id):
await client.auth.upgradeGuest('player1', 'secret123');
```

`deviceSecret` must be **standard base64** (RFC 4648, `+/` alphabet with `=` padding) of 32-128 random bytes — the server rejects anything shorter as `weak_device_secret`.

### Guest device (managed keypair)

Rather than hand-roll base64, entropy, and persistence, let the SDK manage the keypair. `guestDevice` generates a `{deviceId, deviceSecret}` pair on first run (CSPRNG via `Random.secure()`), persists it, reuses it on every launch, and signs in — all in one call:

```dart
final auth = await client.auth.guestDevice();
if (auth.created) {
  // brand-new guest — run first-time onboarding
} else {
  // returning guest — same playerId as last launch
}
```

Persistence is pluggable via a `DeviceStore`, mirroring `TokenStore`. Standalone Dart defaults to a `FileDeviceStore` under the OS app-support directory. Inject your own — e.g. a `shared_preferences`-backed store on mobile, or an `InMemoryDeviceStore` in tests:

```dart
await client.auth.guestDevice(store: myDeviceStore);
```

To switch guest / "forget me", erase the stored pair — the next `guestDevice` mints a brand-new guest. This is local-only; pair it with `logout`, or `upgradeGuest` first if the player wants to keep the account:

```dart
await client.auth.logout();
await AsobiDevice.clear(store);
```

Prefer to manage the keypair yourself (e.g. an OS keychain)? Skip the helper and call `guest(deviceId, deviceSecret)` directly — `AsobiDevice.generate()` still gives you a correctly-shaped pair if you only need the bytes. See [`example/guest.dart`](example/guest.dart).

### Deleting an account

Clearing the device pair is local only — the account stays on the server. `eraseSelf` deletes it, along with everything the server holds for it. Irreversible.

```dart
await client.players.eraseSelf();                        // guest or provider-only
await client.players.eraseSelf(password: 'secret123');   // account with a password
```

Pass `password` only for an account that has one; a guest has no credential to re-present, so its session is the confirmation. A wrong password throws `AsobiException` with `code == 'player.confirmation_failed'` (403) and changes nothing.

On success the local session is cleared, because the server deleted the token pair in the same transaction. Anything afterwards on that session is a `401` — for a retried erase, read that as "it already worked".

Requires a server with `POST /api/v1/players/me/erase`; older deployments answer `404`.

## Features

| Feature | REST | WebSocket |
|---------|------|-----------|
| Auth | Register, login, guest (create/resume + managed device keypair + upgrade), token refresh | - |
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

## Server-pushed game events

A Lua game script pushes to clients two ways, and they land on different streams.

`game.send(player_id, message)` targets one player and arrives on `onGameMessage`:

```dart
client.realtime.onGameMessage.stream.listen((m) => print(m.message));
```

`game.broadcast(event, payload)` goes to everyone in the match or world. The
event name is chosen by your script, so it arrives on `onMatchEvent` (or
`onWorldEvent` from a world script) as a `GameBroadcast` carrying that name:

```dart
// server: game.broadcast("players_total", { value = state.players_total })
client.realtime.onMatchEvent.stream.listen((e) {
  if (e.event == 'players_total') {
    print('players: ${e.payload['value']}');
  }
});
```

Events asobi itself broadcasts (`match.state`, `match.finished`, the
`match.vote_*` family, and so on) have their own typed streams and do not also
reach `onMatchEvent`.

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
