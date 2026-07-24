import 'dart:convert';
import 'dart:math';

/// Supplies [count] random bytes. Override [AsobiDevice.generate]'s default to
/// plug in a specific entropy source (a hardware RNG, or a fixed sequence in a
/// test). The default is [Random.secure].
typedef RandomBytes = List<int> Function(int count);

List<int> _secureRandomBytes(int count) {
  final rng = Random.secure();
  return List<int>.generate(count, (_) => rng.nextInt(256));
}

/// A persisted guest keypair. The same pair re-presented on every launch
/// resumes the same player; a fresh pair creates a new guest.
///
/// [deviceSecret] is standard base64 (RFC 4648, `+/` alphabet with `=`
/// padding) of 32 random bytes, so the server accepts it - anything decoding
/// to fewer than 32 bytes is rejected as `weak_device_secret`.
class DeviceCredentials {
  final String deviceId;
  final String deviceSecret;

  const DeviceCredentials(this.deviceId, this.deviceSecret);

  /// True only when the pair is usable: a non-empty id and a [deviceSecret]
  /// that decodes as standard base64 to >= 32 bytes. A corrupt or legacy pair
  /// (empty, malformed, or too-short secret) is rejected here so [loadOrCreate]
  /// mints a fresh one rather than re-presenting it and tripping the server's
  /// `weak_device_secret` rejection.
  bool get isValid {
    if (deviceId.isEmpty || deviceSecret.isEmpty) return false;
    try {
      return base64Decode(deviceSecret).length >= 32;
    } on FormatException {
      return false;
    }
  }

  Map<String, dynamic> toJson() => {
    'device_id': deviceId,
    'device_secret': deviceSecret,
  };

  factory DeviceCredentials.fromJson(Map<String, dynamic> json) =>
      DeviceCredentials(
        json['device_id'] as String? ?? '',
        json['device_secret'] as String? ?? '',
      );
}

/// Pluggable persistence for the guest keypair, mirroring [TokenStore]. Flutter
/// apps inject a store backed by `shared_preferences` or `flutter_secure_storage`;
/// standalone Dart can use `FileDeviceStore` (native only); tests use
/// [InMemoryDeviceStore].
abstract class DeviceStore {
  Future<DeviceCredentials?> read();
  Future<void> write(DeviceCredentials credentials);
  Future<void> clear();
}

class InMemoryDeviceStore implements DeviceStore {
  DeviceCredentials? _credentials;

  @override
  Future<DeviceCredentials?> read() async => _credentials;

  @override
  Future<void> write(DeviceCredentials credentials) async =>
      _credentials = credentials;

  @override
  Future<void> clear() async => _credentials = null;
}

/// Opt-in guest device-credential helper.
///
/// Guest sign-in needs a stable [DeviceCredentials] the game generates once,
/// persists, and re-presents on every launch. This does that dance so a game
/// doesn't hand-roll base64 + persistence + the >= 32-byte rule. Entirely
/// optional: pass your own values to [AsobiAuth.guest] for your own storage.
class AsobiDevice {
  AsobiDevice._();

  /// Generate a fresh keypair. [randomBytes] may supply bytes from a specific
  /// source; [deviceId] fixes the id explicitly (any stable non-empty string
  /// <= 255 bytes).
  static DeviceCredentials generate({
    RandomBytes? randomBytes,
    String? deviceId,
  }) {
    final rand = randomBytes ?? _secureRandomBytes;
    // Fail loud here rather than as an opaque server `weak_device_secret` 400
    // if a custom source under-delivers: the secret must decode to >= 32 bytes.
    final secretBytes = rand(32);
    if (secretBytes.length < 32) {
      throw ArgumentError('randomBytes(32) must return at least 32 bytes');
    }
    final secret = base64Encode(secretBytes.sublist(0, 32));
    final id = deviceId ?? base64Encode(rand(16));
    return DeviceCredentials(id, secret);
  }

  /// Load the persisted keypair, or generate + persist one on first run. A
  /// stored pair that fails [DeviceCredentials.isValid] (empty, corrupt, or a
  /// secret decoding to < 32 bytes) is discarded and replaced with a fresh one.
  static Future<DeviceCredentials> loadOrCreate(
    DeviceStore store, {
    RandomBytes? randomBytes,
    String? deviceId,
  }) async {
    final existing = await store.read();
    if (existing != null && existing.isValid) return existing;
    final credentials = generate(randomBytes: randomBytes, deviceId: deviceId);
    await store.write(credentials);
    return credentials;
  }

  /// Erase the stored keypair so the next [loadOrCreate] / [AsobiAuth.guestDevice]
  /// mints a brand-new guest (`created == true`). Local-only: it does not delete
  /// the server account - pair it with [AsobiAuth.logout] to end the session, or
  /// [AsobiAuth.upgradeGuest] first if the player wants to keep it.
  static Future<void> clear(DeviceStore store) => store.clear();
}
