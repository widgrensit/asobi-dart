import '../asobi_client.dart';
import '../models/auth_models.dart';

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
    _client.sessionToken = auth.sessionToken;
    _client.playerId = auth.playerId;
    return auth;
  }

  Future<AuthResponse> login(String username, String password) async {
    final resp = await _client.http.post('/api/v1/auth/login', body: {
      'username': username,
      'password': password,
    });
    final auth = AuthResponse.fromJson(resp);
    _client.sessionToken = auth.sessionToken;
    _client.playerId = auth.playerId;
    return auth;
  }

  Future<RefreshResponse> refresh() async {
    final resp = await _client.http.post('/api/v1/auth/refresh', body: {
      'session_token': _client.sessionToken,
    });
    final result = RefreshResponse.fromJson(resp);
    _client.sessionToken = result.sessionToken;
    return result;
  }

  void logout() {
    _client.sessionToken = null;
    _client.playerId = null;
  }
}
