class IAPResult {
  final String? productId;
  final String? transactionId;
  final String? orderId;
  final bool valid;

  IAPResult({this.productId, this.transactionId, this.orderId, required this.valid});

  factory IAPResult.fromJson(Map<String, dynamic> json) => IAPResult(
        productId: json['product_id'] as String?,
        transactionId: json['transaction_id'] as String? ?? json['order_id'] as String?,
        orderId: json['order_id'] as String?,
        valid: json['valid'] as bool? ?? false,
      );
}

class OAuthResponse {
  final String playerId;
  final String sessionToken;
  final String username;
  final bool created;

  OAuthResponse({
    required this.playerId,
    required this.sessionToken,
    required this.username,
    this.created = false,
  });

  factory OAuthResponse.fromJson(Map<String, dynamic> json) => OAuthResponse(
        playerId: json['player_id'] as String,
        sessionToken: json['session_token'] as String,
        username: json['username'] as String,
        created: json['created'] as bool? ?? false,
      );
}

class LinkResponse {
  final String provider;
  final String providerUid;
  final bool linked;

  LinkResponse({required this.provider, required this.providerUid, required this.linked});

  factory LinkResponse.fromJson(Map<String, dynamic> json) => LinkResponse(
        provider: json['provider'] as String,
        providerUid: json['provider_uid'] as String,
        linked: json['linked'] as bool? ?? false,
      );
}
