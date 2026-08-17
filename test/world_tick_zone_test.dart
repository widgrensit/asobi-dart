// Unit tests for the zone-aware fields asobi v0.89.0 added to world.tick, and
// the resync request that repairs a gap.
//
// Pure model tests: they do not read the fixture corpus, because the vendored
// copy still predates the server change and the sync PR that updates it is
// separate. Once it lands, dispatch_test exercises the same fields end to end.

import 'package:test/test.dart';
import 'package:asobi/asobi.dart';

void main() {
  group('WorldTick zone fields', () {
    test('reads zone, frame_seq and kf', () {
      final t = WorldTick.fromJson({
        'zone': [3, -1],
        'frame_seq': 17,
        'kf': true,
        'tick': 42,
        'updates': <dynamic>[],
      });
      expect(t.zone, [3, -1]);
      expect(t.frameSeq, 17);
      expect(t.kf, isTrue);
      expect(t.tick, 42);
    });

    // A server predating v0.89.0, and match.state, send none of the three. They
    // must read as absent rather than as zero, because zero is a real frame_seq
    // and a real zone coordinate.
    test('absent fields are null, not zero', () {
      final t = WorldTick.fromJson({'tick': 1, 'updates': <dynamic>[]});
      expect(t.zone, isNull);
      expect(t.frameSeq, isNull);
      expect(t.kf, isFalse);
    });

    test('zone 0,0 is a real zone and does not read as absent', () {
      final t = WorldTick.fromJson({
        'zone': [0, 0],
        'frame_seq': 0,
        'tick': 0,
        'updates': <dynamic>[],
      });
      expect(t.zone, [0, 0]);
      expect(t.frameSeq, 0);
    });

    // A malformed zone must read as absent rather than throw. This is decoded
    // inside a stream handler, where a raise takes the subscription down with
    // it and the game stops receiving ticks entirely.
    test('a malformed zone reads as absent instead of throwing', () {
      for (final bad in <dynamic>[
        'not a list',
        <dynamic>[],
        <dynamic>[1],
        <dynamic>['x', 'y'],
        <dynamic>[null, null],
        42,
      ]) {
        final t = WorldTick.fromJson({
          'zone': bad,
          'tick': 1,
          'updates': <dynamic>[],
        });
        expect(t.zone, isNull, reason: 'zone $bad should decode as null');
      }
    });

    test('kf is only true for a real true, not any truthy value', () {
      expect(WorldTick.fromJson({'kf': 'true', 'updates': <dynamic>[]}).kf, isFalse);
      expect(WorldTick.fromJson({'kf': 1, 'updates': <dynamic>[]}).kf, isFalse);
      expect(WorldTick.fromJson({'kf': true, 'updates': <dynamic>[]}).kf, isTrue);
    });

    // Coordinates arrive as JSON numbers, which Dart may hand back as double
    // depending on the decoder. They index a zone grid, so they must be ints.
    test('float coordinates are coerced to int', () {
      final t = WorldTick.fromJson({
        'zone': [2.0, 3.0],
        'tick': 1,
        'updates': <dynamic>[],
      });
      expect(t.zone, [2, 3]);
      expect(t.zone!.first, isA<int>());
    });

    test('updates still decode alongside the new fields', () {
      final t = WorldTick.fromJson({
        'zone': [1, 1],
        'frame_seq': 5,
        'tick': 9,
        'updates': <dynamic>[
          {'op': 'a', 'id': 'e1', 'x': 10, 'y': 20},
        ],
      });
      expect(t.updates, hasLength(1));
      expect(t.updates.first.op, 'a');
      expect(t.updates.first.id, 'e1');
      expect(t.updates.first.x, 10);
    });
  });
}
