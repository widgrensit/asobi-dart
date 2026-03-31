import '../asobi_client.dart';
import '../models/storage_models.dart';

class AsobiStorage {
  final AsobiClient _client;
  AsobiStorage(this._client);

  Future<List<CloudSaveSummary>> listSaves() async {
    final resp = await _client.http.get('/api/v1/saves');
    final saves = resp['saves'] as List<dynamic>;
    return saves.map((save) => CloudSaveSummary.fromJson(save as Map<String, dynamic>)).toList();
  }

  Future<CloudSave> getSave(String slot) async {
    final resp = await _client.http.get('/api/v1/saves/$slot');
    return CloudSave.fromJson(resp);
  }

  Future<CloudSave> putSave(String slot, Map<String, dynamic> data, {int? version}) async {
    final body = <String, dynamic>{'data': data};
    if (version != null) body['version'] = version;
    final resp = await _client.http.put('/api/v1/saves/$slot', body: body);
    return CloudSave.fromJson(resp);
  }

  Future<List<StorageObject>> listStorage(String collection, {int limit = 50}) async {
    final resp = await _client.http.get(
      '/api/v1/storage/$collection',
      query: {'limit': limit.toString()},
    );
    final objects = resp['objects'] as List<dynamic>;
    return objects.map((object) => StorageObject.fromJson(object as Map<String, dynamic>)).toList();
  }

  Future<StorageObject> getStorage(String collection, String key) async {
    final resp = await _client.http.get('/api/v1/storage/$collection/$key');
    return StorageObject.fromJson(resp);
  }

  Future<StorageObject> putStorage(String collection, String key, Map<String, dynamic> value,
      {String readPerm = 'owner', String writePerm = 'owner'}) async {
    final resp = await _client.http.put('/api/v1/storage/$collection/$key', body: {
      'value': value,
      'read_perm': readPerm,
      'write_perm': writePerm,
    });
    return StorageObject.fromJson(resp);
  }

  Future<void> deleteStorage(String collection, String key) async {
    await _client.http.delete('/api/v1/storage/$collection/$key');
  }
}
