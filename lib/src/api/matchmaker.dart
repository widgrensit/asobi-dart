import '../asobi_client.dart';
import '../models/match_models.dart';

class AsobiMatchmaker {
  final AsobiClient _client;
  AsobiMatchmaker(this._client);

  /// Queues this player for matchmaking. [mode] defaults to `'default'` if
  /// omitted - pass the mode you configured on the backend to queue for it
  /// instead.
  Future<MatchmakerTicket> add({
    String mode = 'default',
    Map<String, dynamic>? properties,
    List<String>? party,
  }) async {
    final body = <String, dynamic>{'mode': mode};
    if (properties != null) body['properties'] = properties;
    if (party != null) body['party'] = party;
    final resp = await _client.http.post('/api/v1/matchmaker', body: body);
    return MatchmakerTicket.fromJson(resp);
  }

  Future<MatchmakerTicket> status(String ticketId) async {
    final resp = await _client.http.get('/api/v1/matchmaker/$ticketId');
    return MatchmakerTicket.fromJson(resp);
  }

  Future<void> cancel(String ticketId) async {
    await _client.http.delete('/api/v1/matchmaker/$ticketId');
  }
}
