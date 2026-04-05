import '../http_client.dart';
import '../models/world_models.dart';

class AsobiWorlds {
  final AsobiHttpClient _http;

  AsobiWorlds(this._http);

  Future<List<WorldInfo>> list({String? mode, bool? hasCapacity}) async {
    final params = <String, String>{};
    if (mode != null) params['mode'] = mode;
    if (hasCapacity == true) params['has_capacity'] = 'true';
    final qs = params.entries.map((e) => '${e.key}=${e.value}').join('&');
    final path = qs.isEmpty ? '/api/v1/worlds' : '/api/v1/worlds?$qs';
    final response = await _http.get(path);
    final worlds = (response['worlds'] as List<dynamic>?) ?? [];
    return worlds
        .map((w) => WorldInfo.fromJson(w as Map<String, dynamic>))
        .toList();
  }

  Future<WorldInfo> get(String worldId) async {
    final response = await _http.get('/api/v1/worlds/$worldId');
    return WorldInfo.fromJson(response);
  }

  Future<WorldInfo> create({required String mode}) async {
    final response = await _http.post('/api/v1/worlds', body: {'mode': mode});
    return WorldInfo.fromJson(response);
  }
}
