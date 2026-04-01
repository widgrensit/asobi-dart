import '../asobi_client.dart';

/// Votes API for listing and retrieving vote sessions within matches.
class AsobiVotes {
  final AsobiClient _client;
  AsobiVotes(this._client);

  /// Lists all vote sessions for a given [matchId].
  Future<Map<String, dynamic>> listForMatch(String matchId) async {
    return await _client.http.get('/api/v1/matches/$matchId/votes');
  }

  /// Fetches a single vote session by [voteId].
  Future<Map<String, dynamic>> get(String voteId) async {
    return await _client.http.get('/api/v1/votes/$voteId');
  }
}
