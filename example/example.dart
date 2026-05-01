import 'dart:async';

import 'package:asobi/asobi.dart';

/// Quick end-to-end demo against `widgrensit/sdk_demo_backend` running locally.
///
/// Backend: `git clone https://github.com/widgrensit/sdk_demo_backend && cd
/// sdk_demo_backend && docker compose up -d` — listens on :8084.
Future<void> main() async {
  final client = AsobiClient('localhost', port: 8084);

  // Register, or fall back to login if the username already exists.
  try {
    await client.auth.register('player1', 'secret123', displayName: 'Player One');
  } on AsobiException catch (e) {
    if (e.statusCode == 409) {
      await client.auth.login('player1', 'secret123');
    } else {
      rethrow;
    }
  }

  final player = await client.players.getSelf();
  print('Logged in as ${player.displayName}');

  // Wait until the WS handshake is complete before queuing.
  final connected = Completer<void>();
  client.realtime.onConnected.stream.listen((_) {
    if (!connected.isCompleted) connected.complete();
  });

  // Print state ticks as they arrive.
  client.realtime.onMatchState.stream.listen((state) {
    print('Tick — ${state.players.length} players');
  });

  // Print match-found events.
  client.realtime.onMatchmakerMatched.stream.listen((data) {
    print('Match found: ${data.matchId}');
  });

  await client.realtime.connect();
  await connected.future.timeout(const Duration(seconds: 5));

  await client.realtime.addToMatchmaker(mode: 'demo');
  print('Queued for "demo" mode. Waiting up to 30s for events…');

  // Sit on the connection for a bit so events have time to arrive.
  await Future<void>.delayed(const Duration(seconds: 30));
  await client.dispose();
}
