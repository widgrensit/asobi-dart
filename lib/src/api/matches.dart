import '../asobi_client.dart';
import '../models/match_models.dart';

class AsobiMatches {
  final AsobiClient _client;
  AsobiMatches(this._client);

  Future<List<MatchRecord>> list() async {
    final resp = await _client.http.get('/api/v1/matches');
    final matches = resp['matches'] as List<dynamic>;
    return matches.map((m) => MatchRecord.fromJson(m as Map<String, dynamic>)).toList();
  }

  Future<MatchRecord> get(String matchId) async {
    final resp = await _client.http.get('/api/v1/matches/$matchId');
    return MatchRecord.fromJson(resp);
  }
}
