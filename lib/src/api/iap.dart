import '../asobi_client.dart';
import '../models/iap_models.dart';

class AsobiIAP {
  final AsobiClient _client;
  AsobiIAP(this._client);

  Future<IAPResult> verifyApple(String signedTransaction) async {
    final resp = await _client.http.post('/api/v1/iap/apple', body: {
      'signed_transaction': signedTransaction,
    });
    return IAPResult.fromJson(resp);
  }

  Future<IAPResult> verifyGoogle(String productId, String purchaseToken) async {
    final resp = await _client.http.post('/api/v1/iap/google', body: {
      'product_id': productId,
      'purchase_token': purchaseToken,
    });
    return IAPResult.fromJson(resp);
  }
}
