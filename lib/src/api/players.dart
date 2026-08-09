import '../asobi_client.dart';
import '../models/player_models.dart';

class AsobiPlayers {
  final AsobiClient _client;
  AsobiPlayers(this._client);

  Future<Player> get(String playerId) async {
    final resp = await _client.http.get('/api/v1/players/$playerId');
    return Player.fromJson(resp);
  }

  Future<Player> update(
    String playerId, {
    String? displayName,
    String? avatarUrl,
    Map<String, dynamic>? metadata,
  }) async {
    final body = <String, dynamic>{};
    if (displayName != null) body['display_name'] = displayName;
    if (avatarUrl != null) body['avatar_url'] = avatarUrl;
    if (metadata != null) body['metadata'] = metadata;
    final resp = await _client.http.put('/api/v1/players/$playerId', body: body);
    return Player.fromJson(resp);
  }

  Future<Player> getSelf() => get(_client.playerId!);

  /// Erases the signed-in account and everything the server holds for it -
  /// saves, storage, inventory, wallets, leaderboard entries, identities.
  /// Irreversible.
  ///
  /// Pass [password] only for an account that has one. A guest or a
  /// provider-only account has no credential the client can re-present, so its
  /// session is the whole confirmation.
  ///
  /// Clears the local session on success only, deliberately not in a `finally`
  /// the way `AsobiAuth.logout` does: a refused confirmation (403) or a
  /// credential change mid-flight (409) leaves a live account whose session
  /// must survive. On success the server deleted the token pair inside the
  /// erase transaction, so keeping it would only buy a doomed refresh.
  Future<void> eraseSelf({String? password}) async {
    await _client.http.post('/api/v1/players/me/erase', body: {
      if (password != null) 'password': password,
    });
    _client.accessToken = null;
    await _client.saveRefreshToken(null);
    _client.playerId = null;
  }
}
