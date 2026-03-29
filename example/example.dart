import 'package:asobi/asobi.dart';

Future<void> main() async {
  final client = AsobiClient('localhost', port: 8080);

  // Register or login
  await client.auth.register('player1', 'secret123', displayName: 'Player One');

  // Get own profile
  final player = await client.players.getSelf();
  print('Logged in as ${player.displayName}');

  // Submit a score
  await client.leaderboards.submitScore('weekly', 1500);

  // Connect realtime
  client.realtime.onMatchmakerMatched.stream.listen((data) {
    print('Match found: ${data['match_id']}');
  });

  client.realtime.onMatchState.stream.listen((state) {
    print('Game tick: ${state['tick']}');
  });

  await client.realtime.connect();
  await client.realtime.addToMatchmaker(mode: 'arena');

  // Cleanup
  await client.dispose();
}
