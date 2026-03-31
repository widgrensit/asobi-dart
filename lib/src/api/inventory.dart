import '../asobi_client.dart';
import '../models/economy_models.dart';

class AsobiInventory {
  final AsobiClient _client;
  AsobiInventory(this._client);

  Future<List<PlayerItem>> list() async {
    final resp = await _client.http.get('/api/v1/inventory');
    final items = resp['items'] as List<dynamic>;
    return items.map((item) => PlayerItem.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<void> consume(String itemId, {int quantity = 1}) async {
    await _client.http.post('/api/v1/inventory/consume', body: {
      'item_id': itemId,
      'quantity': quantity,
    });
  }
}
