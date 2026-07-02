/// Pluggable persistence for the refresh token.
///
/// The access token lives only in memory; the refresh token is long-lived
/// and should survive app restarts. Apps that need secure persistence
/// (e.g. `flutter_secure_storage`) implement this interface and inject it
/// via [AsobiClient]. The default [InMemoryTokenStore] keeps it in memory.
abstract class TokenStore {
  Future<String?> read();
  Future<void> write(String? token);
  Future<void> clear();
}

class InMemoryTokenStore implements TokenStore {
  String? _token;

  @override
  Future<String?> read() async => _token;

  @override
  Future<void> write(String? token) async => _token = token;

  @override
  Future<void> clear() async => _token = null;
}
