// Unit tests for the binary `world.tick` decoder (asobi ADR 0013).
//
// Driven entirely by asobi's own committed fixture corpus in test/fixtures/wire:
// real bytes from the real encoder, with a manifest saying what each one decodes
// to. Nothing here is hand-rolled test data, which is the point - a decoder
// checked only against a fixture the same author invented proves the two agree
// with each other and nothing about whether either matches the server.

import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:asobi/asobi.dart';

const fixtureDir = 'test/fixtures/wire';

const opShort = {'add': 'a', 'update': 'u', 'remove': 'r'};

List<int> readBytes(String name) =>
    File('$fixtureDir/$name.bin').readAsBytesSync();

void main() {
  final manifest = jsonDecode(File('$fixtureDir/manifest.json').readAsStringSync())
      as List<dynamic>;

  test('the corpus is present', () => expect(manifest, isNotEmpty));

  for (final entry in manifest) {
    final e = entry as Map<String, dynamic>;
    final name = e['name'] as String;
    final expected = e['frame'] as Map<String, dynamic>;

    test('$name decodes to the payload the manifest describes', () {
      final bytes = readBytes(name);
      expect(bytes.length, e['bytes']);

      // A fresh decoder per fixture: the corpus cases are independent frames,
      // not a stream, so sharing slot tables between them would be the test
      // lying to itself.
      final got = AsobiWire().decode(bytes);
      expect(got, isNotNull, reason: 'decoded to nothing');

      final zone = (expected['zone'] as List).cast<num>();
      expect(got!['zone'], [zone[0].toInt(), zone[1].toInt()]);
      expect(got['tick'], (expected['tick'] as num).toInt());

      // An ungated frame holds no position in the zone's stream and says so by
      // carrying no frame_seq at all. Reporting sequence 0 instead would have the
      // gap detector discard the one frame that clears a leaving zone's ghosts.
      if (expected['kind'] == 'sequenced') {
        expect(got['frame_seq'], (expected['frame_seq'] as num).toInt());
        expect(got['kf'], expected['kf']);
      } else {
        expect(got.containsKey('frame_seq'), isFalse);
      }

      final records = (expected['records'] as List).cast<Map<String, dynamic>>();
      final updates = (got['updates'] as List).cast<Map<String, dynamic>>();
      expect(updates.length, records.length);

      for (var i = 0; i < records.length; i++) {
        expect(updates[i]['op'], opShort[records[i]['op']]);
        if (records[i].containsKey('id')) {
          expect(updates[i]['id'], records[i]['id']);
        }
        // The generation. A decoder that skipped the byte shifts every later
        // offset and fails loudly; one that read it from the wrong place would
        // not, so pin the value.
        expect(updates[i]['gen'], records[i]['gen']);
        final fields = (records[i]['fields'] as Map<String, dynamic>?) ?? {};
        fields.forEach((key, want) {
          final have = updates[i][key];
          if (want is num && have is num) {
            // float32 on the wire against a float64 in the manifest, so compare
            // with a tolerance: 12.5 survives exactly, 1.5 * 7 does not.
            expect(have.toDouble(), closeTo(want.toDouble(), 0.0001),
                reason: key);
          } else {
            expect(have, want, reason: key);
          }
        });
      }
    });
  }

  // The reason the slot table lives in the decoder: an update carries the slot
  // alone, and the caller must still see the entity id it saw on the add.
  test('slot bindings are scoped per zone', () {
    final decoder = AsobiWire();
    final kf = decoder.decode(readBytes('keyframe_all_adds'))!;
    final ids = (kf['updates'] as List)
        .cast<Map<String, dynamic>>()
        .map((u) => u['id'] as String)
        .toSet();
    expect(ids, isNotEmpty);

    // The keyframe is zone [-1, -1]. A frame for a DIFFERENT zone must not
    // resolve against its table: slot 1 in one zone has nothing to do with slot 1
    // in another, and aliasing them is the corruption per-zone tables prevent.
    final other = decoder.decode(readBytes('removes_only'))!;
    for (final u in (other['updates'] as List).cast<Map<String, dynamic>>()) {
      expect(ids.contains(u['id']), isFalse);
    }
  });

  // Bindings belong to one connection's stream of adds. Kept across a reconnect
  // they would attach stale ids to slots the server has since reassigned.
  test('reset forgets every binding', () {
    final decoder = AsobiWire();
    decoder.decode(readBytes('keyframe_all_adds'));
    decoder.reset();
    final after = decoder.decode(readBytes('removes_only'))!;
    for (final u in (after['updates'] as List).cast<Map<String, dynamic>>()) {
      expect(u.containsKey('id'), isFalse);
    }
  });

  // These bytes come off the network and this runs inside a stream handler, where
  // an uncaught throw takes the whole subscription down with it.
  test('malformed frames return null rather than throwing', () {
    final good = readBytes('steady_state_40_updates');
    final cases = <String, List<int>>{
      'empty': [],
      'one byte': [1],
      'truncated envelope': good.sublist(0, 10),
      'truncated mid-record': good.sublist(0, good.length - 2),
      'trailing junk': [...good, 0, 0, 0],
      'unknown kind byte': [9, ...good.sublist(1)],
    };
    cases.forEach((label, bytes) {
      expect(AsobiWire().decode(bytes), isNull, reason: label);
    });
  });

  // The whole "nothing downstream changes" claim: a decoded payload has to build
  // the same WorldTick a JSON frame does.
  test('a decoded payload builds a WorldTick', () {
    final payload = AsobiWire().decode(readBytes('keyframe_all_adds'))!;
    final tick = WorldTick.fromJson(payload);
    expect(tick.zone, [-1, -1]);
    expect(tick.kf, isTrue);
    expect(tick.updates, hasLength(5));
    expect(tick.updates.every((u) => u.op == 'a' && u.id.isNotEmpty), isTrue);
    expect(tick.updates.first.data['x'], isA<num>());
  });
}
