import '../asobi_client.dart';
import '../models/leaderboard_models.dart';

class AsobiLeaderboards {
  final AsobiClient _client;
  AsobiLeaderboards(this._client);

  Future<List<LeaderboardEntry>> getTop(String leaderboardId, {int limit = 100}) async {
    final resp = await _client.http.get(
      '/api/v1/leaderboards/$leaderboardId',
      query: {'limit': limit.toString()},
    );
    final entries = resp['entries'] as List<dynamic>;
    return entries.map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<LeaderboardEntry>> getAroundPlayer(
      String leaderboardId, String playerId, {int range = 5}) async {
    final resp = await _client.http.get(
      '/api/v1/leaderboards/$leaderboardId/around/$playerId',
      query: {'range': range.toString()},
    );
    final entries = resp['entries'] as List<dynamic>;
    return entries.map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<LeaderboardEntry>> getAroundSelf(String leaderboardId, {int range = 5}) {
    return getAroundPlayer(leaderboardId, _client.playerId!, range: range);
  }

  Future<LeaderboardEntry> submitScore(String leaderboardId, int score, {int subScore = 0}) async {
    final resp = await _client.http.post('/api/v1/leaderboards/$leaderboardId', body: {
      'score': score,
      'sub_score': subScore,
    });
    return LeaderboardEntry.fromJson(resp);
  }
}
