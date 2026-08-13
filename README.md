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
| Worlds | List, get, create | Join, tick deltas, input + ack, terrain |
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

## World input and client-side prediction

`sendWorldInput` sends a `world.input` frame to whichever zone owns your player
entity. The payload shape is game-specific: your world script decides what it
reads.

```dart
client.realtime.sendWorldInput({'kind': 'move', 'dx': 1, 'dy': 0});
```

Pass `seq`, your own counter incremented once per input and never reused, to opt
into acknowledgement. It goes on the wire as a top-level sibling of `payload`
(`{"type":"world.input","seq":412,"payload":{...}}`), and the server answers on
`onWorldAck` with a `WorldAck`:

```dart
client.realtime.sendWorldInput({'kind': 'move', 'dx': 1, 'dy': 0}, seq: 412);

client.realtime.onWorldAck.stream.listen((ack) {
  print('consumed up to ${ack.seq} as of tick ${ack.tick}');
});
```

`WorldAck.seq` is a high-water mark, the highest `seq` the server consumed for
you as of `WorldAck.tick`, not a receipt per input. An input your script rejects
still advances it, so a refused input never strands the client. Both fields
decode as Dart `int`, so no numeric cast is needed.

The frame is per-connection: it never rides the shared `world.tick` broadcast,
and it goes only to connections that have stamped a `seq`. A connection that has
never stamped one gets no `world.ack` at all, and no error either.

### Reconciling a prediction

`world.tick` is a delta frame. `WorldTick.updates` carries `EntityDelta`s whose
`op` is `"a"` (added, full state), `"u"` (updated, changed fields only) or `"r"`
(removed).

Every new zone subscription opens with a full `op:"a"` snapshot of that zone's
entities, and that is not a once-per-session event. The default world is a grid
of zones and you are subscribed to the ring around your own, so crossing a zone
boundary brings new zones into that ring and each one opens with its own
snapshot; zones leaving the ring send `op:"r"` for everything in them.
Re-affirming a subscription you already hold sends nothing. Ticks in between are
deltas.

So accumulate updates into one local map keyed by entity id, which absorbs
interleaved frames from every zone you are subscribed to. Assigning a tick
wholesale to an "authoritative state" variable instead drops every entity that
tick did not mention.

Then buffer each predicted input under its `seq`, drop everything up to
`ack.seq` when the ack lands, and replay the remainder on top of the accumulated
state.

```dart
final entities = <String, Map<String, dynamic>>{}; // authoritative, accumulated
final pending = <int, Map<String, dynamic>>{};     // predicted, not yet acked
final myEntityId = client.playerId!;               // set by auth
var predicted = <String, dynamic>{};               // what you render
var seq = 0;

void apply(Map<String, dynamic> entity, Map<String, dynamic> input) {
  entity['x'] = ((entity['x'] as num?) ?? 0) + (input['dx'] as num);
  entity['y'] = ((entity['y'] as num?) ?? 0) + (input['dy'] as num);
}

Map<String, dynamic> replayPending() {
  final me = Map<String, dynamic>.from(entities[myEntityId] ?? const {});
  for (final s in pending.keys.toList()..sort()) {
    apply(me, pending[s]!);
  }
  return me;
}

client.realtime.onWorldTick.stream.listen((tick) {
  for (final u in tick.updates) {
    switch (u.op) {
      case 'a':
        entities[u.id] = Map<String, dynamic>.from(u.data);
      case 'u':
        (entities[u.id] ??= <String, dynamic>{}).addAll(u.data);
      case 'r':
        entities.remove(u.id);
    }
  }
  predicted = replayPending(); // newer authoritative state, same pending buffer
});

client.realtime.onWorldAck.stream.listen((ack) {
  pending.removeWhere((s, _) => s <= ack.seq); // prune here: this always fires
  predicted = replayPending();
});

void move(num dx, num dy) {
  final input = <String, dynamic>{'kind': 'move', 'dx': dx, 'dy': dy};
  pending[++seq] = input;
  apply(predicted, input); // predict locally, before the server has seen it
  client.realtime.sendWorldInput(input, seq: seq);
}
```

asobi adds your player entity to its zone keyed by your player id, so
`client.playerId` is the entity id to reconcile against.

Prune in the ack handler, not the tick handler. On a broadcast tick
where something changed since the last broadcast, the server sends `world.tick`
first and `world.ack` second on the same connection; on a tick where nothing
changed it sends the ack alone, with no `world.tick` in front of it. The ack
handler is the one that always runs.

Acks follow the zone's broadcast tick, not each input: one every
`broadcast_interval` simulation ticks (default 3), repeating the same `seq`
until it advances. Set
[`broadcast_interval`](https://asobi.dev/docs/world-server) to 1 for an ack
every tick.

The high-water mark is held per zone, so crossing into a new zone pauses the ack
stream until your next `seq`-stamped input reaches that zone, which resumes it
from that `seq`. Your counter is yours alone and never goes backwards, so the
prune rule holds across a crossing.

`seq` must be an integer from 0 to 2^53 - 1. On the native VM Dart's `int` is
64-bit and holds far more than that, so an oversized value reaches the server
intact and lands outside the accepted range; compiled to JavaScript `int` is a
double and stays exact only to 2^53, the same ceiling. Start the counter at 0
and increment it rather than seeding it from a clock.

Out of range, it is the `seq` that is ignored, not the input. The server drops
the `seq` and still queues and applies that input exactly as normal; it simply
records no acknowledgement for it. Nor does the ack stream go quiet: if you had
already sent a valid `seq`, `world.ack` keeps arriving every broadcast tick
carrying the old high-water mark, and stops advancing rather than stopping.

Requires a server that emits `world.ack`, asobi core v0.84.0 or later; older
deployments stay silent rather than erroring. On the client side `onWorldAck`
first shipped in release
[v2.4.0](https://github.com/widgrensit/asobi-dart/releases/tag/v2.4.0).

Frame reference:
[client-side prediction](https://asobi.dev/docs/protocols/websocket#client-side-prediction).

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
