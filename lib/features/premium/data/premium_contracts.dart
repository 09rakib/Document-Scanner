import 'dart:convert';

abstract final class PremiumConfig {
  /// Create this one-time, non-consumable product in Play Console.
  static const productId = 'docscan_remove_ads';

  /// Public licensing key (not a secret), supplied for the actual Play app.
  static const publicKey = String.fromEnvironment('DOCSCAN_PLAY_PUBLIC_KEY');
}

enum StorePurchaseState { pending, purchased, restored, cancelled, error }

enum PremiumMessage {
  unavailable,
  configuration,
  pending,
  cancelled,
  purchaseFailed,
  verificationFailed,
  storageFailed,
  acknowledgementPending,
  restored,
  noPurchases,
}

class SignedReceipt {
  const SignedReceipt(this.payload, this.signature);
  final String payload, signature;
  String get token {
    final json = jsonDecode(payload) as Map<String, dynamic>;
    return (json['purchaseToken'] ?? json['token']) as String;
  }
}

class StoreProduct {
  const StoreProduct(this.price, this.handle);
  final String price;
  final Object handle;
}

class StorePurchase {
  const StorePurchase({
    required this.productId,
    required this.state,
    this.receipt,
    this.token = '',
    this.needsCompletion = false,
    this.handle,
  });
  final String productId, token;
  final StorePurchaseState state;
  final SignedReceipt? receipt;
  final bool needsCompletion;
  final Object? handle;
}

abstract interface class BillingGateway {
  Stream<List<StorePurchase>> get updates;
  Future<bool> available();
  Future<StoreProduct?> product();
  Future<bool> buy(StoreProduct product);
  Future<List<StorePurchase>> owned();
  Future<void> complete(StorePurchase purchase);
}

abstract interface class ReceiptVerifier {
  bool get configured;
  Future<bool> verify(SignedReceipt receipt);
}

abstract interface class PremiumCache {
  Future<SignedReceipt?> load();
  Future<void> save(SignedReceipt receipt);
  Future<void> clear();
}
