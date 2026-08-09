import 'dart:convert';
import 'package:http/http.dart' as http;

import 'token_store.dart';

class AsobiHttpClient {
  final String baseUrl;
  final http.Client _http;
  final TokenStore tokenStore;

  /// Access token used for the `Authorization: Bearer` header. Kept in
  /// memory only; the refresh token is persisted via [tokenStore].
  String? accessToken;

  /// Invoked after a 401 triggers a successful token refresh, with the new
  /// access token. Used by [AsobiClient] to re-authenticate the WebSocket.
  void Function(String accessToken)? onAccessTokenRefreshed;

  Future<bool>? _refreshInFlight;

  AsobiHttpClient(this.baseUrl, {http.Client? httpClient, TokenStore? tokenStore})
      : _http = httpClient ?? http.Client(),
        tokenStore = tokenStore ?? InMemoryTokenStore();

  Map<String, String> get headers => {
        'Content-Type': 'application/json',
        if (accessToken != null) 'Authorization': 'Bearer $accessToken',
      };

  Future<Map<String, dynamic>> get(String path, {Map<String, String>? query}) =>
      _request('GET', path, query: query);

  Future<Map<String, dynamic>> post(String path, {Map<String, dynamic>? body}) =>
      _request('POST', path, body: body);

  Future<Map<String, dynamic>> put(String path, {Map<String, dynamic>? body}) =>
      _request('PUT', path, body: body);

  Future<Map<String, dynamic>> delete(String path,
          {Map<String, dynamic>? body, Map<String, String>? query}) =>
      _request('DELETE', path, body: body, query: query);

  Future<Map<String, dynamic>> _request(String method, String path,
      {Map<String, dynamic>? body,
      Map<String, String>? query,
      bool isRetry = false}) async {
    final response = await _dispatch(method, path, body, query);

    if (response.statusCode == 401 && !isRetry && !_isAuthPath(path)) {
      final refreshed = await _refresh();
      if (!refreshed) {
        throw AsobiAuthExpiredException();
      }
      return _request(method, path, body: body, query: query, isRetry: true);
    }

    return handleResponse(response);
  }

  Future<http.Response> _dispatch(
      String method, String path, Map<String, dynamic>? body, Map<String, String>? query) {
    final uri = _buildUri(path, query);
    final encoded = body != null ? jsonEncode(body) : null;
    switch (method) {
      case 'GET':
        return _http.get(uri, headers: headers);
      case 'POST':
        return _http.post(uri, headers: headers, body: encoded);
      case 'PUT':
        return _http.put(uri, headers: headers, body: encoded);
      case 'DELETE':
        return _http.delete(uri, headers: headers, body: encoded);
      default:
        throw ArgumentError('Unsupported method: $method');
    }
  }

  bool _isAuthPath(String path) => path.contains('/auth/');

  /// Exchanges the stored refresh token for a fresh token pair. Guarded so
  /// concurrent 401s trigger a single refresh (single-use rotation would
  /// otherwise burn tokens and trip reuse detection).
  Future<bool> _refresh() =>
      _refreshInFlight ??= _doRefresh().whenComplete(() => _refreshInFlight = null);

  Future<bool> _doRefresh() async {
    final refreshToken = await tokenStore.read();
    if (refreshToken == null) return false;
    try {
      final response = await _http.post(
        _buildUri('/api/v1/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh_token': refreshToken}),
      );
      if (response.statusCode >= 400) return false;
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final newAccess = body['access_token'] as String;
      final newRefresh = body['refresh_token'] as String;
      accessToken = newAccess;
      await tokenStore.write(newRefresh);
      onAccessTokenRefreshed?.call(newAccess);
      return true;
    } catch (_) {
      return false;
    }
  }

  Uri _buildUri(String path, [Map<String, String>? query]) {
    final uri = Uri.parse('$baseUrl$path');
    if (query != null && query.isNotEmpty) {
      return uri.replace(queryParameters: query);
    }
    return uri;
  }

  Map<String, dynamic> handleResponse(http.Response response) {
    final body = response.body.isNotEmpty
        ? jsonDecode(response.body) as Map<String, dynamic>
        : <String, dynamic>{};

    if (response.statusCode >= 400) {
      throw _exception(response.statusCode, body['error']);
    }

    return body;
  }

  /// asobi answers every failure with a shared error object,
  /// `{"error": {"code": ..., "message": ..., "details": {...}}}`. This used to
  /// cast `error` straight to `String?`, so against any current server the cast
  /// itself threw a `_TypeError` out of the SDK and no caller ever saw an
  /// `AsobiException` at all - a wrong password, a 404, a rate limit, all of
  /// them. The bare-string form is still accepted: a few routes kept a flat
  /// legacy body, and an older deployment may send one.
  AsobiException _exception(int status, dynamic error) {
    if (error is Map<String, dynamic>) {
      final code = error['code'];
      final message = error['message'];
      return AsobiException(
        status,
        message is String ? message : 'HTTP $status',
        code: code is String ? code : null,
      );
    }
    if (error is String) return AsobiException(status, error);
    return AsobiException(status, 'HTTP $status');
  }

  void close() => _http.close();
}

class AsobiException implements Exception {
  final int statusCode;
  final String message;

  /// The machine-readable half of asobi's error object, e.g.
  /// `player.confirmation_failed`. Branch on this, never on [message], which is
  /// prose for a human and may be reworded at any time. Null when the server
  /// sent a legacy flat body or no error object at all.
  final String? code;

  AsobiException(this.statusCode, this.message, {this.code});

  @override
  String toString() => code == null
      ? 'AsobiException($statusCode): $message'
      : 'AsobiException($statusCode $code): $message';
}

/// Thrown when an extension's RPC handler answers `rpc.error`.
///
/// [code] is the machine-readable half and is what you branch on; [message]
/// is prose for a human and may change without notice.
class AsobiRpcException implements Exception {
  final String code;
  final String message;
  final Map<String, dynamic> details;

  AsobiRpcException(this.code, this.message, [this.details = const {}]);

  @override
  String toString() => 'AsobiRpcException($code): $message';
}

/// Thrown when an authenticated request receives a 401 and the token
/// refresh also fails. The app should force a re-login.
class AsobiAuthExpiredException implements Exception {
  final String message;

  AsobiAuthExpiredException([this.message = 'Authentication expired; re-login required']);

  @override
  String toString() => 'AsobiAuthExpiredException: $message';
}
