import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

import 'package:asobi/src/device.dart';
import 'package:asobi/src/device_io.dart';
import 'package:asobi/src/token_store.dart';
import 'package:asobi/src/asobi_client.dart';

/// Deterministic byte source: 0, 1, 2, ... so a test can assert an exact base64.
List<int> _rampBytes(int count) => List<int>.generate(count, (i) => i % 256);

void main() {
  group('AsobiDevice.generate', () {
    test('secret is standard base64 decoding to exactly 32 bytes', () {
      final creds = AsobiDevice.generate();
      final decoded = base64Decode(creds.deviceSecret);
      expect(decoded.length, 32);
      // Standard RFC 4648 alphabet (+/ with = padding), never url-safe (-_).
      expect(creds.deviceSecret, matches(r'^[A-Za-z0-9+/]+={0,2}$'));
      expect(creds.deviceSecret.contains('-'), isFalse);
      expect(creds.deviceSecret.contains('_'), isFalse);
    });

    test('deviceId is non-empty base64 of 16 bytes', () {
      final creds = AsobiDevice.generate();
      expect(creds.deviceId, isNotEmpty);
      expect(base64Decode(creds.deviceId).length, 16);
      expect(creds.deviceId.length, lessThanOrEqualTo(255));
    });

    test(
      'injected byte source yields deterministic, standard-base64 secret',
      () {
        final creds = AsobiDevice.generate(randomBytes: _rampBytes);
        final expected = base64Encode(List<int>.generate(32, (i) => i));
        expect(creds.deviceSecret, expected);
        expect(base64Decode(creds.deviceSecret).length, 32);
      },
    );

    test('explicit deviceId overrides the generated one', () {
      final creds = AsobiDevice.generate(deviceId: 'my-stable-id');
      expect(creds.deviceId, 'my-stable-id');
    });

    test('throws when the byte source under-delivers', () {
      expect(
        () => AsobiDevice.generate(randomBytes: (n) => List.filled(8, 0)),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('two generations differ (fresh entropy each call)', () {
      final a = AsobiDevice.generate();
      final b = AsobiDevice.generate();
      expect(a.deviceSecret, isNot(b.deviceSecret));
      expect(a.deviceId, isNot(b.deviceId));
    });
  });

  group('AsobiDevice.loadOrCreate', () {
    test('persists on first run and resumes the same pair after', () async {
      final store = InMemoryDeviceStore();
      final first = await AsobiDevice.loadOrCreate(store);
      final second = await AsobiDevice.loadOrCreate(store);
      expect(second.deviceId, first.deviceId);
      expect(second.deviceSecret, first.deviceSecret);
      final stored = await store.read();
      expect(stored!.deviceId, first.deviceId);
    });

    test('ignores an invalid stored pair and mints a fresh one', () async {
      final store = InMemoryDeviceStore();
      await store.write(const DeviceCredentials('', ''));
      final creds = await AsobiDevice.loadOrCreate(store);
      expect(creds.isValid, isTrue);
      expect((await store.read())!.deviceId, creds.deviceId);
    });

    test(
      'replaces a short-secret (< 32 byte) pair rather than resuming it',
      () async {
        final store = InMemoryDeviceStore();
        final weak = DeviceCredentials('id', base64Encode(List.filled(16, 0)));
        expect(weak.isValid, isFalse);
        await store.write(weak);
        final creds = await AsobiDevice.loadOrCreate(store);
        expect(creds.deviceSecret, isNot(weak.deviceSecret));
        expect(
          base64Decode(creds.deviceSecret).length,
          greaterThanOrEqualTo(32),
        );
        expect((await store.read())!.deviceSecret, creds.deviceSecret);
      },
    );

    test('replaces a corrupt (non-base64) stored secret', () async {
      final store = InMemoryDeviceStore();
      await store.write(const DeviceCredentials('id', 'not valid base64 !!!'));
      final creds = await AsobiDevice.loadOrCreate(store);
      expect(creds.isValid, isTrue);
      expect(base64Decode(creds.deviceSecret).length, greaterThanOrEqualTo(32));
    });
  });

  group('AsobiDevice.clear', () {
    test('erases the pair so the next load mints a new guest', () async {
      final store = InMemoryDeviceStore();
      final first = await AsobiDevice.loadOrCreate(store);
      await AsobiDevice.clear(store);
      expect(await store.read(), isNull);
      final second = await AsobiDevice.loadOrCreate(store);
      expect(second.deviceId, isNot(first.deviceId));
    });
  });

  group('FileDeviceStore', () {
    test('write / read / clear round-trips the pair on disk', () async {
      final dir = Directory.systemTemp.createTempSync('asobi_device_test');
      addTearDown(() => dir.deleteSync(recursive: true));
      final store = FileDeviceStore('${dir.path}/nested/guest_device.json');

      expect(await store.read(), isNull);
      final creds = await AsobiDevice.loadOrCreate(store);
      final reopened = await FileDeviceStore(
        '${dir.path}/nested/guest_device.json',
      ).read();
      expect(reopened!.deviceId, creds.deviceId);
      expect(reopened.deviceSecret, creds.deviceSecret);

      await store.clear();
      expect(await store.read(), isNull);
    });
  });

  group('AsobiAuth.guestDevice', () {
    test(
      'forwards the loaded keypair to guest() and returns the response',
      () async {
        Map<String, dynamic>? guestBody;
        final mock = MockClient((req) async {
          expect(req.url.path, '/api/v1/auth/guest');
          guestBody = jsonDecode(req.body) as Map<String, dynamic>;
          return http.Response(
            jsonEncode({
              'player_id': 'g1',
              'access_token': 'guest-access',
              'refresh_token': 'guest-refresh',
              'username': 'guest-1',
              'created': true,
              'guest': true,
            }),
            200,
          );
        });
        final client = AsobiClient.fromConfig(
          AsobiConfig('localhost'),
          httpClient: mock,
          tokenStore: InMemoryTokenStore(),
        );
        final store = InMemoryDeviceStore();

        final auth = await client.auth.guestDevice(
          store: store,
          randomBytes: _rampBytes,
        );

        final expected = AsobiDevice.generate(randomBytes: _rampBytes);
        expect(guestBody!['device_secret'], expected.deviceSecret);
        expect(base64Decode(guestBody!['device_secret'] as String).length, 32);
        expect(auth.playerId, 'g1');
        expect(auth.created, true);
        expect(client.accessToken, 'guest-access');
        expect(await client.refreshToken, 'guest-refresh');
      },
    );

    test('resumes the same guest keypair on a second call', () async {
      final seen = <String>[];
      final mock = MockClient((req) async {
        seen.add(jsonDecode(req.body)['device_id'] as String);
        return http.Response(
          jsonEncode({
            'player_id': 'g1',
            'access_token': 'a',
            'refresh_token': 'r',
            'username': 'guest-1',
            'guest': true,
          }),
          200,
        );
      });
      final client = AsobiClient.fromConfig(
        AsobiConfig('localhost'),
        httpClient: mock,
        tokenStore: InMemoryTokenStore(),
      );
      final store = InMemoryDeviceStore();

      await client.auth.guestDevice(store: store);
      await client.auth.guestDevice(store: store);

      expect(seen.length, 2);
      expect(seen[0], seen[1]);
    });
  });
}
