import '../asobi_client.dart';
import '../models/tournament_models.dart';

class AsobiTournaments {
  final AsobiClient _client;
  AsobiTournaments(this._client);

  Future<List<Tournament>> list({String? status, int? limit}) async {
    final query = <String, String>{};
    if (status != null) query['status'] = status;
    if (limit != null) query['limit'] = limit.toString();
    final resp = await _client.http.get('/api/v1/tournaments', query: query.isNotEmpty ? query : null);
    final tournaments = resp['tournaments'] as List<dynamic>;
    return tournaments.map((tournament) => Tournament.fromJson(tournament as Map<String, dynamic>)).toList();
  }

  Future<Tournament> get(String tournamentId) async {
    final resp = await _client.http.get('/api/v1/tournaments/$tournamentId');
    return Tournament.fromJson(resp);
  }

  Future<void> join(String tournamentId) async {
    await _client.http.post('/api/v1/tournaments/$tournamentId/join');
  }
}
