import '../asobi_client.dart';
import '../models/player_models.dart';

class AsobiPlayers {
  final AsobiClient _client;
  AsobiPlayers(this._client);

  Future<Player> get(String playerId) async {
    final resp = await _client.http.get('/api/v1/players/$playerId');
    return Player.fromJson(resp);
  }

  Future<Player> update(String playerId, {String? displayName, String? avatarUrl}) async {
    final body = <String, dynamic>{};
    if (displayName != null) body['display_name'] = displayName;
    if (avatarUrl != null) body['avatar_url'] = avatarUrl;
    final resp = await _client.http.put('/api/v1/players/$playerId', body: body);
    return Player.fromJson(resp);
  }

  Future<Player> getSelf() => get(_client.playerId!);
}
