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

One key is reserved. The transport treats a top-level `data` key as a wrapper:
if the map you pass has `data` mapped to another map, your script receives only
that inner map and every sibling key is dropped. Passing
`{'data': {'dx': 1}, 'kind': 'move'}` delivers `{'dx': 1}` and loses `kind`. If
`data` is present but is not a map, the script receives an empty map instead.
Either send your fields at the top level, as above, or put all of them inside
`data` - never both.

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

`WorldAck.seq` is a high-water mark, the highest `seq` that one zone consumed
for you as of `WorldAck.tick`, not a receipt per input. An input your script
rejects still advances it, so a refused input never strands the client. Both
fields decode as Dart `int`, so no numeric cast is needed.

The frame is private to your connection: it never rides the shared `world.tick`
broadcast, and it goes only to connections that have stamped a `seq`. A
connection that has never stamped one gets no `world.ack` at all, and no error
either.

It is not, however, one ack per connection. The high-water mark is per zone, and
you are subscribed to several zones at once, so expect more than one `world.ack`
per broadcast tick once you have moved, and nothing in the frame says which zone
sent it. See [Acks are per zone](#acks-are-per-zone) before you write the prune
rule.

### Reconciling a prediction

`world.tick` is a delta frame. `WorldTick.updates` carries `EntityDelta`s whose
`op` is `"a"` (added, full state), `"u"` (updated, changed fields only) or `"r"`
(removed).

A full `op:"a"` snapshot arrives on every new zone subscription, which is not a
once-per-session event. The default world is a grid of zones and you are
subscribed to the ring around your own, a 3x3 block of up to 9 zones at the
default `view_radius` of 1. So joining subscribes you to the whole ring at once
and you get a snapshot per loaded, non-empty zone in it - typically several
frames, not one. A zone holding no entities sends no snapshot, but the terrain
push is a separate step, so a world with a terrain provider still delivers that
zone's chunk on `onWorldTerrain`.

After that, a snapshot arrives every time a zone enters your ring, not only the
first time it does. A crossing recomputes the ring and subscribes the band of
zones that just entered it, and each of those replays a full snapshot: at
`view_radius` 1 an orthogonal step keeps 6 of the 9 zones and brings in 3. Only
the destination zone is a no-op, because at radius 1 it was already in the old
ring; do not generalise that one no-op to the crossing as a whole. A zone
leaving the ring unsubscribes you and sends `op:"r"` for each of its entities,
so stepping back over the same boundary re-subscribes and re-snapshots it. A
player oscillating across a boundary re-snapshots on every crossing. Ticks in
between are deltas.

So accumulate updates into one local map keyed by entity id, which absorbs the
separate frames arriving from every zone you are subscribed to. Assigning a tick
wholesale to an "authoritative state" variable instead drops every entity that
tick did not mention.

Then buffer each predicted input under its `seq`. When an ack lands, keep a
running maximum of the `seq` you have accepted and ignore any ack that does not
beat it; only then drop everything up to that mark and replay the remainder on
top of the accumulated state. Acks arrive from several zones and can go
backwards, so the running maximum is what makes the prune safe - see
[Acks are per zone](#acks-are-per-zone).

```dart
final entities = <String, Map<String, dynamic>>{}; // authoritative, accumulated
final pending = <int, Map<String, dynamic>>{};     // predicted, not yet acked
final myEntityId = client.playerId!;               // set by auth
var predicted = <String, dynamic>{};               // what you render
var seq = 0;
var ackedSeq = -1;                                 // running max across zones

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
  if (ack.seq <= ackedSeq) return; // a stale zone's mark: ignore, never prune
  ackedSeq = ack.seq;
  pending.removeWhere((s, _) => s <= ackedSeq); // prune here: an ack always fires
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

Prune in the ack handler, not the tick handler. On a zone's broadcast tick where
something changed in that zone since its last broadcast, the server sends
`world.tick` first and `world.ack` second; on a tick where nothing changed it
sends the ack alone, with no `world.tick` in front of it. The ack handler is the
one that always runs.

Acks follow the broadcast tick, not each input: every `broadcast_interval`
simulation ticks (default 3) each subscribed zone acks, repeating the same `seq`
until it advances. Set
[`broadcast_interval`](https://asobi.dev/docs/world-server) to 1 for an ack
every tick. One ticker drives the whole world and `broadcast_interval` is a
single world-level value copied into every zone, so zones are not on independent
schedules and there is no ticker per zone: the several acks a multi-zone
subscriber receives arrive together on the same broadcast tick, not interleaved
across different cadences.

### Acks are per zone

Each zone keeps its own high-water mark for you and acks its own subscribers, so
what you receive is one ack per subscribed zone that holds a recorded `seq` for
you, not one per connection. Two consequences:

- You will see more than one `world.ack` per broadcast tick once you have moved,
  all of them arriving together on that tick.
- `WorldAck.seq` can go backwards between consecutive acks. Moving away from a
  zone does not unsubscribe you from it, so it keeps emitting its own frozen
  high-water mark while the zone now taking your input emits a higher one.

Nothing in the frame identifies the sending zone, so you cannot filter by
origin. Keep a running maximum of the `seq` you have accepted and ignore any ack
that does not exceed it, as the sample above does. "Drop everything `<= ack.seq`
and replay the rest" is only safe against a monotonic mark; applied to a raw ack
it re-applies inputs you had already consumed as soon as a stale zone acks.

Your own counter never goes backwards. It is what you receive that can, which is
why the running maximum lives in the ack handler rather than in the counter.

The server calls this ack "per-connection" in its own source comment and in the
protocol guide. That wording is wrong for any multi-zone world; it is tracked
upstream as
[widgrensit/asobi#477](https://github.com/widgrensit/asobi/issues/477).

`seq` must be an integer from 0 to 2^53 - 1. On the native VM Dart's `int` is
64-bit and holds far more than that, so an oversized value reaches the server
intact and lands outside the accepted range; compiled to JavaScript `int` is a
double and stays exact only to 2^53, the same ceiling. Start the counter at 0
and increment it rather than seeding it from a clock.

Out of range, it is the `seq` that is ignored, not the input. The server drops
the `seq` and still queues and applies that input exactly as normal; it simply
records no acknowledgement for it. Nor do the acks go quiet: if you had already
sent a valid `seq`, `world.ack` keeps arriving from each subscribed zone on
every broadcast tick carrying the old high-water mark, and stops advancing
rather than stopping.

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
