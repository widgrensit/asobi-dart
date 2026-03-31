import '../asobi_client.dart';
import '../models/economy_models.dart';

class AsobiEconomy {
  final AsobiClient _client;
  AsobiEconomy(this._client);

  Future<List<Wallet>> getWallets() async {
    final resp = await _client.http.get('/api/v1/wallets');
    final wallets = resp['wallets'] as List<dynamic>;
    return wallets.map((wallet) => Wallet.fromJson(wallet as Map<String, dynamic>)).toList();
  }

  Future<List<Transaction>> getHistory(String currency, {int limit = 50}) async {
    final resp = await _client.http.get(
      '/api/v1/wallets/$currency/history',
      query: {'limit': limit.toString()},
    );
    final txns = resp['transactions'] as List<dynamic>;
    return txns.map((transaction) => Transaction.fromJson(transaction as Map<String, dynamic>)).toList();
  }

  Future<List<StoreListing>> getStore({String? currency}) async {
    final query = currency != null ? {'currency': currency} : null;
    final resp = await _client.http.get('/api/v1/store', query: query);
    final listings = resp['listings'] as List<dynamic>;
    return listings.map((listing) => StoreListing.fromJson(listing as Map<String, dynamic>)).toList();
  }

  Future<PurchaseResponse> purchase(String listingId) async {
    final resp = await _client.http.post('/api/v1/store/purchase', body: {
      'listing_id': listingId,
    });
    return PurchaseResponse.fromJson(resp);
  }
}
