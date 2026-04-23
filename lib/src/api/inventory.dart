import '../asobi_client.dart';
import '../models/economy_models.dart' show PlayerItem, ConsumeResponse;

class AsobiInventory {
  final AsobiClient _client;
  AsobiInventory(this._client);

  Future<List<PlayerItem>> list({int? limit}) async {
    final query = <String, String>{};
    if (limit != null) query['limit'] = limit.toString();
    final resp = await _client.http.get('/api/v1/inventory', query: query.isNotEmpty ? query : null);
    final items = resp['items'] as List<dynamic>;
    return items.map((item) => PlayerItem.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<ConsumeResponse> consume(String itemId, {int quantity = 1}) async {
    final resp = await _client.http.post('/api/v1/inventory/consume', body: {
      'item_id': itemId,
      'quantity': quantity,
    });
    return ConsumeResponse.fromJson(resp);
  }
}
