// Dispatch unit test: feeds every canonical fixture through the SDK's
// realtime message handler and asserts the right stream fires.
//
// Pure unit test — no network. Catches the doc-vs-server drift class of
// bugs (a fixture with no dispatch mapping, or a mapping with no fixture)
// before any user reports a silent failure. Custom/unenumerated match.*
// and world.* events flow through the generic passthrough (see the
// passthrough group below).

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:asobi/src/asobi_client.dart';
import 'package:asobi/src/realtime/asobi_realtime.dart';
import 'package:test/test.dart';

const fixtureDir = 'test/fixtures';

// For each server wire `type`, the AsobiRealtime stream a user subscribes
// to. Mirrors the dispatch switch in asobi_realtime.dart. Drift between
// this map and the SDK is caught by the assertions below.
Stream<dynamic> streamFor(AsobiRealtime rt, String type) {
  switch (type) {
    case 'error':
      return rt.onError.stream;
    case 'game.error':
    case 'module.error':
      return rt.onGameError.stream;
    case 'game.message':
    case 'module.message':
      return rt.onGameMessage.stream;
    case 'session.connected':
      return rt.onConnected.stream;
    case 'session.heartbeat':
      return rt.onHeartbeat.stream;
    case 'match.state':
      return rt.onMatchState.stream;
    case 'match.joined':
      return rt.onMatchJoined.stream;
    case 'match.left':
      return rt.onMatchLeft.stream;
    case 'match.finished':
      return rt.onMatchFinished.stream;
    case 'match.matched':
      return rt.onMatchmakerMatched.stream;
    case 'match.matchmaker_expired':
      return rt.onMatchmakerExpired.stream;
    case 'match.matchmaker_failed':
      return rt.onMatchmakerFailed.stream;
    case 'match.list':
      return rt.onMatchList.stream;
    case 'match.vote_start':
      return rt.onVoteStart.stream;
    case 'match.vote_tally':
      return rt.onVoteTally.stream;
    case 'match.vote_result':
      return rt.onVoteResult.stream;
    case 'match.vote_vetoed':
      return rt.onVoteVetoed.stream;
    case 'matchmaker.queued':
      return rt.onMatchmakerQueued.stream;
    case 'matchmaker.removed':
      return rt.onMatchmakerRemoved.stream;
    case 'chat.joined':
      return rt.onChatJoined.stream;
    case 'chat.left':
      return rt.onChatLeft.stream;
    case 'chat.message':
      return rt.onChatMessage.stream;
    case 'dm.sent':
      return rt.onDmSent.stream;
    case 'dm.message':
      return rt.onDmMessage.stream;
    case 'presence.updated':
      return rt.onPresenceChanged.stream;
    case 'notification.new':
      return rt.onNotification.stream;
    case 'vote.cast_ok':
      return rt.onVoteCastOk.stream;
    case 'vote.veto_ok':
      return rt.onVoteVetoOk.stream;
    case 'world.tick':
      return rt.onWorldTick.stream;
    case 'world.terrain':
      return rt.onWorldTerrain.stream;
    case 'world.list':
      return rt.onWorldList.stream;
    case 'world.joined':
      return rt.onWorldJoined.stream;
    case 'world.left':
      return rt.onWorldLeft.stream;
    case 'world.phase_changed':
      return rt.onWorldPhaseChanged.stream;
    case 'world.finished':
      return rt.onWorldFinished.stream;
  }
  throw StateError('No stream mapping for $type');
}

// rpc.ok and rpc.error are replies, not events: they correlate to a pending
// call by `cid` and never reach a stream. They have fixtures, so they are
// named here rather than left looking like an oversight; rpc_test.dart covers
// the correlation.
const correlatedTypes = <String>{'rpc.ok', 'rpc.error'};

const expectedTypes = <String>{
  'error',
  'game.error',
  'game.message',
  'module.error',
  'module.message',
  'match.matched',
  'session.connected',
  'session.heartbeat',
  'match.state',
  'match.joined',
  'match.left',
  'match.finished',
  'match.matchmaker_expired',
  'match.matchmaker_failed',
  'match.list',
  'match.vote_start',
  'match.vote_tally',
  'match.vote_result',
  'match.vote_vetoed',
  'matchmaker.queued',
  'matchmaker.removed',
  'chat.joined',
  'chat.left',
  'chat.message',
  'dm.sent',
  'dm.message',
  'presence.updated',
  'notification.new',
  'vote.cast_ok',
  'vote.veto_ok',
  'world.tick',
  'world.terrain',
  'world.list',
  'world.joined',
  'world.left',
  'world.phase_changed',
  'world.finished',
};

List<String> listFixtures() {
  final dir = Directory(fixtureDir);
  return dir
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.json'))
      .map((f) => f.uri.pathSegments.last)
      .toList()
    ..sort();
}

String typeFromFilename(String name) =>
    name.substring(0, name.length - '.json'.length);

void main() {
  final fixtures = listFixtures();
  final fixtureTypes = fixtures.map(typeFromFilename).toSet();

  test('every fixture has an EXPECTED entry', () {
    final missing =
        fixtureTypes.difference(expectedTypes).difference(correlatedTypes);
    expect(
      missing,
      isEmpty,
      reason: 'fixtures without dispatch mapping (add SDK callback): $missing',
    );
  });

  test('every EXPECTED entry has a fixture', () {
    final missing = expectedTypes.difference(fixtureTypes);
    expect(
      missing,
      isEmpty,
      reason:
          'EXPECTED types missing a fixture (stale or fixture missing): $missing',
    );
  });

  group('dispatches fixture to expected stream', () {
    for (final filename in fixtures) {
      final type = typeFromFilename(filename);
      if (correlatedTypes.contains(type)) continue;
      test(type, () async {
        final raw = File('$fixtureDir/$filename').readAsStringSync();
        // Sanity-check the fixture is valid JSON and has matching `type`.
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        expect(
          decoded['type'],
          type,
          reason: 'fixture filename ↔ type mismatch',
        );

        final client = AsobiClient('localhost');
        final fired = Completer<void>();
        final sub = streamFor(client.realtime, type).listen((_) {
          if (!fired.isCompleted) fired.complete();
        });

        client.realtime.debugHandleMessage(raw);

        await fired.future.timeout(
          const Duration(seconds: 1),
          onTimeout: () {
            fail('$type did not fire its expected stream');
          },
        );
        await sub.cancel();
      });
    }
  });

  group('generic passthrough', () {
    test('unenumerated match.* reaches onMatchEvent', () async {
      final client = AsobiClient('localhost');
      final got = client.realtime.onMatchEvent.stream.first;
      client.realtime.debugHandleMessage(
        '{"type":"match.custom","payload":{"foo":"bar"}}',
      );
      final payload = await got.timeout(const Duration(seconds: 1));
      expect(payload['foo'], 'bar');
    });

    test('match.matched reaches typed onMatchmakerMatched', () async {
      final client = AsobiClient('localhost');
      final got = client.realtime.onMatchmakerMatched.stream.first;
      client.realtime.debugHandleMessage(
        '{"type":"match.matched","payload":{"match_id":"m1","players":["p1","p2"]}}',
      );
      final match = await got.timeout(const Duration(seconds: 1));
      expect(match.matchId, 'm1');
      expect(match.players, ['p1', 'p2']);
    });

    test(
      'game.error fixture reaches typed onGameError with right fields',
      () async {
        final client = AsobiClient('localhost');
        final got = client.realtime.onGameError.stream.first;
        final raw = File('$fixtureDir/game.error.json').readAsStringSync();
        client.realtime.debugHandleMessage(raw);
        final err = await got.timeout(const Duration(seconds: 1));
        expect(err.callback, 'handle_input');
        expect(err.script, 'match.lua');
        expect(err.message, 'bad arithmetic + on nil, 1');
      },
    );

    test(
      'game.message fixture reaches typed onGameMessage with right value',
      () async {
        final client = AsobiClient('localhost');
        final got = client.realtime.onGameMessage.stream.first;
        final raw = File('$fixtureDir/game.message.json').readAsStringSync();
        client.realtime.debugHandleMessage(raw);
        final msg = await got.timeout(const Duration(seconds: 1));
        expect(msg.message, 'jij bent speler nummer 3');
      },
    );

    test(
      'game.message with non-string payload is not coerced or dropped',
      () async {
        final client = AsobiClient('localhost');
        final got = client.realtime.onGameMessage.stream.first;
        client.realtime.debugHandleMessage(
          '{"type":"game.message","payload":{"message":{"score":3,"lives":[1,2,3]}}}',
        );
        final msg = await got.timeout(const Duration(seconds: 1));
        expect(msg.message, {
          'score': 3,
          'lives': [1, 2, 3],
        });
      },
    );

    test(
      'game.message with a top-level array payload is not coerced or dropped',
      () async {
        final client = AsobiClient('localhost');
        final got = client.realtime.onGameMessage.stream.first;
        client.realtime.debugHandleMessage(
          '{"type":"game.message","payload":{"message":[1,2,3]}}',
        );
        final msg = await got.timeout(const Duration(seconds: 1));
        expect(msg.message, [1, 2, 3]);
      },
    );

    test(
      'game.message with a null payload still dispatches, not dropped',
      () async {
        final client = AsobiClient('localhost');
        final got = client.realtime.onGameMessage.stream.first;
        client.realtime.debugHandleMessage(
          '{"type":"game.message","payload":{"message":null}}',
        );
        final msg = await got.timeout(const Duration(seconds: 1));
        expect(msg.message, isNull);
      },
    );

    test(
      'game.message with a numeric payload is not coerced or dropped',
      () async {
        final client = AsobiClient('localhost');
        final got = client.realtime.onGameMessage.stream.first;
        client.realtime.debugHandleMessage(
          '{"type":"game.message","payload":{"message":42}}',
        );
        final msg = await got.timeout(const Duration(seconds: 1));
        expect(msg.message, 42);
      },
    );

    test('unenumerated world.* reaches onWorldEvent', () async {
      final client = AsobiClient('localhost');
      final got = client.realtime.onWorldEvent.stream.first;
      client.realtime.debugHandleMessage(
        '{"type":"world.custom","payload":{"world_id":"w1"}}',
      );
      final payload = await got.timeout(const Duration(seconds: 1));
      expect(payload['world_id'], 'w1');
    });
  });
}
