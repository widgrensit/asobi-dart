import '../asobi_client.dart';
import '../device.dart';
import '../device_stub.dart' if (dart.library.io) '../device_io.dart';
import '../models/auth_models.dart';
import '../models/iap_models.dart';

class AsobiAuth {
  final AsobiClient _client;
  AsobiAuth(this._client);

  Future<AuthResponse> register(String username, String password, {String? displayName}) async {
    final resp = await _client.http.post('/api/v1/auth/register', body: {
      'username': username,
      'password': password,
      'display_name': displayName ?? username,
    });
    final auth = AuthResponse.fromJson(resp);
    _client.accessToken = auth.accessToken;
    await _client.saveRefreshToken(auth.refreshToken);
    _client.playerId = auth.playerId;
    return auth;
  }

  Future<AuthResponse> login(String username, String password) async {
    final resp = await _client.http.post('/api/v1/auth/login', body: {
      'username': username,
      'password': password,
    });
    final auth = AuthResponse.fromJson(resp);
    _client.accessToken = auth.accessToken;
    await _client.saveRefreshToken(auth.refreshToken);
    _client.playerId = auth.playerId;
    return auth;
  }

  Future<OAuthResponse> oauth(String provider, String token) async {
    final resp = await _client.http.post('/api/v1/auth/oauth', body: {
      'provider': provider,
      'token': token,
    });
    final auth = OAuthResponse.fromJson(resp);
    _client.accessToken = auth.accessToken;
    await _client.saveRefreshToken(auth.refreshToken);
    _client.playerId = auth.playerId;
    return auth;
  }

  Future<AuthResponse> guest(String deviceId, String deviceSecret) async {
    final resp = await _client.http.post('/api/v1/auth/guest', body: {
      'device_id': deviceId,
      'device_secret': deviceSecret,
    });
    final auth = AuthResponse.fromJson(resp);
    _client.accessToken = auth.accessToken;
    await _client.saveRefreshToken(auth.refreshToken);
    _client.playerId = auth.playerId;
    return auth;
  }

  /// Opt-in convenience: load (or generate + persist) a device keypair and
  /// sign in as a guest in one call. Equivalent to calling [guest] with a
  /// keypair you manage yourself.
  ///
  /// [store] persists the keypair across launches. It defaults to the platform
  /// store ([defaultDeviceStore]): a file under the OS app-support directory on
  /// native, and unsupported on web - inject a `store:` there (a
  /// `shared_preferences`-backed one) or in tests (an [InMemoryDeviceStore]).
  /// [randomBytes] and [deviceId] are forwarded to [AsobiDevice.generate] on
  /// first run.
  Future<AuthResponse> guestDevice({
    DeviceStore? store,
    RandomBytes? randomBytes,
    String? deviceId,
  }) async {
    final credentials = await AsobiDevice.loadOrCreate(
      store ?? defaultDeviceStore(),
      randomBytes: randomBytes,
      deviceId: deviceId,
    );
    return guest(credentials.deviceId, credentials.deviceSecret);
  }

  Future<AuthResponse> upgradeGuest(String username, String password) async {
    final resp = await _client.http.post('/api/v1/auth/guest/upgrade', body: {
      'username': username,
      'password': password,
    });
    final auth = AuthResponse.fromJson(resp);
    _client.accessToken = auth.accessToken;
    await _client.saveRefreshToken(auth.refreshToken);
    _client.playerId = auth.playerId;
    _client.notifyAccessTokenRotated(auth.accessToken);
    return auth;
  }

  Future<LinkResponse> linkProvider(String provider, String token) async {
    final resp = await _client.http.post('/api/v1/auth/link', body: {
      'provider': provider,
      'token': token,
    });
    return LinkResponse.fromJson(resp);
  }

  Future<void> unlinkProvider(String provider) async {
    await _client.http.delete('/api/v1/auth/unlink', query: {
      'provider': provider,
    });
  }

  Future<RefreshResponse> refresh() async {
    final refreshToken = await _client.refreshToken;
    final resp = await _client.http.post('/api/v1/auth/refresh', body: {
      'refresh_token': refreshToken,
    });
    final result = RefreshResponse.fromJson(resp);
    _client.accessToken = result.accessToken;
    await _client.saveRefreshToken(result.refreshToken);
    _client.notifyAccessTokenRotated(result.accessToken);
    return result;
  }

  Future<void> logout() async {
    final refreshToken = await _client.refreshToken;
    try {
      await _client.http.post('/api/v1/auth/logout', body: {
        if (refreshToken != null) 'refresh_token': refreshToken,
      });
    } finally {
      _client.accessToken = null;
      await _client.saveRefreshToken(null);
      _client.playerId = null;
    }
  }
}
