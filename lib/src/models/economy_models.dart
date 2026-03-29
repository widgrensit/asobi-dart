class Wallet {
  final String currency;
  final int balance;

  Wallet({required this.currency, required this.balance});

  factory Wallet.fromJson(Map<String, dynamic> json) => Wallet(
        currency: json['currency'] as String,
        balance: json['balance'] as int,
      );
}

class Transaction {
  final String id;
  final String walletId;
  final int amount;
  final int balanceAfter;
  final String reason;
  final String? referenceType;
  final String? referenceId;
  final String insertedAt;

  Transaction({
    required this.id,
    required this.walletId,
    required this.amount,
    required this.balanceAfter,
    required this.reason,
    this.referenceType,
    this.referenceId,
    required this.insertedAt,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
        id: json['id'] as String,
        walletId: json['wallet_id'] as String,
        amount: json['amount'] as int,
        balanceAfter: json['balance_after'] as int,
        reason: json['reason'] as String,
        referenceType: json['reference_type'] as String?,
        referenceId: json['reference_id'] as String?,
        insertedAt: json['inserted_at'] as String,
      );
}

class StoreListing {
  final String id;
  final String itemDefId;
  final String currency;
  final int price;
  final bool active;
  final String? validFrom;
  final String? validUntil;

  StoreListing({
    required this.id,
    required this.itemDefId,
    required this.currency,
    required this.price,
    required this.active,
    this.validFrom,
    this.validUntil,
  });

  factory StoreListing.fromJson(Map<String, dynamic> json) => StoreListing(
        id: json['id'] as String,
        itemDefId: json['item_def_id'] as String,
        currency: json['currency'] as String,
        price: json['price'] as int,
        active: json['active'] as bool,
        validFrom: json['valid_from'] as String?,
        validUntil: json['valid_until'] as String?,
      );
}

class PlayerItem {
  final String id;
  final String itemDefId;
  final String playerId;
  final int quantity;
  final String acquiredAt;
  final String updatedAt;

  PlayerItem({
    required this.id,
    required this.itemDefId,
    required this.playerId,
    required this.quantity,
    required this.acquiredAt,
    required this.updatedAt,
  });

  factory PlayerItem.fromJson(Map<String, dynamic> json) => PlayerItem(
        id: json['id'] as String,
        itemDefId: json['item_def_id'] as String,
        playerId: json['player_id'] as String,
        quantity: json['quantity'] as int,
        acquiredAt: json['acquired_at'] as String,
        updatedAt: json['updated_at'] as String,
      );
}

class PurchaseResponse {
  final bool success;
  final PlayerItem item;

  PurchaseResponse({required this.success, required this.item});

  factory PurchaseResponse.fromJson(Map<String, dynamic> json) => PurchaseResponse(
        success: json['success'] as bool,
        item: PlayerItem.fromJson(json['item'] as Map<String, dynamic>),
      );
}
