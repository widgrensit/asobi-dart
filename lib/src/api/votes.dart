import '../asobi_client.dart';

class AsobiVotes {
  final AsobiClient _client;
  AsobiVotes(this._client);

  Future<Map<String, dynamic>> listForMatch(String matchId) async {
    return await _client.http.get('/api/v1/matches/$matchId/votes');
  }

  Future<Map<String, dynamic>> get(String voteId) async {
    return await _client.http.get('/api/v1/votes/$voteId');
  }
}
