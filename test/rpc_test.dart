// The RPC seam: an extension's method, called over the same socket and
// correlated by cid. Pure unit test - no network.

import 'dart:convert';
import 'dart:io';

import 'package:asobi/asobi.dart';
import 'package:test/test.dart';

const fixtureDir = 'test/fixtures';

String fixture(String name) => File('$fixtureDir/$name').readAsStringSync();

void main() {
  test('builds the versioned rpc.call envelope', () {
    expect(
      AsobiRealtime.debugRpcPayload('quests.claim', {'quest_key': 'daily'}),
      {
        'protocol': 1,
        'method': 'quests.claim',
        'params': {'quest_key': 'daily'},
      },
    );
  });

  test('an empty params map is still an object', () {
    expect(
      AsobiRealtime.debugRpcPayload('quests.list', const {})['params'],
      isEmpty,
    );
  });

  test('rpc.ok resolves the pending call with its result', () async {
    final rt = AsobiClient('localhost').realtime;
    final pending = rt.debugAwaitReply('c-1');
    rt.debugHandleMessage(
      jsonEncode({
        'type': 'rpc.ok',
        'cid': 'c-1',
        'payload': {
          'result': {'reward': 100},
        },
      }),
    );
    expect(await pending, {
      'result': {'reward': 100},
    });
  });

  test('rpc.error throws with the code, not just a message', () async {
    final rt = AsobiClient('localhost').realtime;
    final pending = rt.debugAwaitReply('c-2');
    rt.debugHandleMessage(
      jsonEncode({
        'type': 'rpc.error',
        'cid': 'c-2',
        'payload': {
          'error': {
            'code': 'quests.already_claimed',
            'message': "This quest's reward has already been claimed.",
            'details': {'quest_key': 'daily'},
          },
        },
      }),
    );

    await expectLater(
      pending,
      throwsA(
        isA<AsobiRpcException>()
            .having((e) => e.code, 'code', 'quests.already_claimed')
            .having((e) => e.details, 'details', {'quest_key': 'daily'}),
      ),
    );
  });

  test('an error object with nothing in it still carries a code', () async {
    final rt = AsobiClient('localhost').realtime;
    final pending = rt.debugAwaitReply('c-3');
    rt.debugHandleMessage(
      jsonEncode({'type': 'rpc.error', 'cid': 'c-3', 'payload': {}}),
    );
    await expectLater(
      pending,
      throwsA(
        isA<AsobiRpcException>().having((e) => e.code, 'code', 'internal'),
      ),
    );
  });

  test('the canonical fixtures correlate', () async {
    final ok = jsonDecode(fixture('rpc.ok.json')) as Map<String, dynamic>;
    final err = jsonDecode(fixture('rpc.error.json')) as Map<String, dynamic>;

    final a = AsobiClient('localhost').realtime;
    final first = a.debugAwaitReply(ok['cid'] as String);
    a.debugHandleMessage(fixture('rpc.ok.json'));
    expect(await first, ok['payload']);

    final b = AsobiClient('localhost').realtime;
    final second = b.debugAwaitReply(err['cid'] as String);
    b.debugHandleMessage(fixture('rpc.error.json'));
    await expectLater(
      second,
      throwsA(
        isA<AsobiRpcException>().having(
          (e) => e.code,
          'code',
          (err['payload'] as Map<String, dynamic>)['error']['code'],
        ),
      ),
    );
  });

  test('concurrent calls correlate by cid, out of order', () async {
    final rt = AsobiClient('localhost').realtime;
    final first = rt.debugAwaitReply('c-1');
    final second = rt.debugAwaitReply('c-2');

    rt.debugHandleMessage(
      jsonEncode({
        'type': 'rpc.ok',
        'cid': 'c-2',
        'payload': {
          'result': {'ok': 2},
        },
      }),
    );
    rt.debugHandleMessage(
      jsonEncode({
        'type': 'rpc.ok',
        'cid': 'c-1',
        'payload': {
          'result': {'ok': 1},
        },
      }),
    );

    expect((await second)['result'], {'ok': 2});
    expect((await first)['result'], {'ok': 1});
  });
}
