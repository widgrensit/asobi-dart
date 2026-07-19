import '../asobi_client.dart';
import '../models/match_models.dart';

class AsobiMatches {
  final AsobiClient _client;
  AsobiMatches(this._client);

  Future<List<MatchRecord>> list({String? mode, String? status, int? limit}) async {
    final query = <String, String>{};
    if (mode != null) query['mode'] = mode;
    if (status != null) query['status'] = status;
    if (limit != null) query['limit'] = limit.toString();
    final resp = await _client.http.get('/api/v1/matches', query: query.isNotEmpty ? query : null);
    final matches = resp['matches'] as List<dynamic>;
    return matches.map((match) => MatchRecord.fromJson(match as Map<String, dynamic>)).toList();
  }

  /// Live, joinable matches. [list] reads finished-match history; this
  /// enumerates the matches currently running.
  Future<List<LiveMatch>> live({String? mode, bool? hasCapacity}) async {
    final query = <String, String>{};
    if (mode != null) query['mode'] = mode;
    if (hasCapacity == true) query['has_capacity'] = 'true';
    final resp = await _client.http
        .get('/api/v1/matches/live', query: query.isNotEmpty ? query : null);
    final matches = (resp['matches'] as List<dynamic>?) ?? [];
    return matches
        .map((match) => LiveMatch.fromJson(match as Map<String, dynamic>))
        .toList();
  }

  Future<MatchRecord> get(String matchId) async {
    final resp = await _client.http.get('/api/v1/matches/$matchId');
    return MatchRecord.fromJson(resp);
  }
}
