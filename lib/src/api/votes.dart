import '../asobi_client.dart';
import '../models/vote_models.dart';

class AsobiVotes {
  final AsobiClient _client;
  AsobiVotes(this._client);

  Future<List<Vote>> listForMatch(String matchId) async {
    final resp = await _client.http.get('/api/v1/matches/$matchId/votes');
    final votes = resp['votes'] as List<dynamic>;
    return votes.map((v) => Vote.fromJson(v as Map<String, dynamic>)).toList();
  }

  Future<Vote> get(String voteId) async {
    final resp = await _client.http.get('/api/v1/votes/$voteId');
    return Vote.fromJson(resp);
  }
}
