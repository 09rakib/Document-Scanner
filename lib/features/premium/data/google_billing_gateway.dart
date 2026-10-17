import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';

import 'premium_contracts.dart';

class GoogleBillingGateway implements BillingGateway {
  InAppPurchase get _store => InAppPurchase.instance;
  InAppPurchaseAndroidPlatformAddition get _android =>
      _store.getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();
  @override
  Stream<List<StorePurchase>> get updates =>
      _store.purchaseStream.map((rows) => rows.map(_convert).toList());
  @override
  Future<bool> available() =>
      _store.isAvailable().timeout(const Duration(seconds: 15));
  @override
  Future<StoreProduct?> product() async {
    final result = await _store
        .queryProductDetails({PremiumConfig.productId})
        .timeout(const Duration(seconds: 15));
    if (result.error != null) throw StateError('Product lookup failed');
    final row = result.productDetails
        .where((p) => p.id == PremiumConfig.productId)
        .firstOrNull;
    return row == null ? null : StoreProduct(row.price, row);
  }

  @override
  Future<bool> buy(StoreProduct product) => _store.buyNonConsumable(
    purchaseParam: PurchaseParam(
      productDetails: product.handle as ProductDetails,
    ),
  );
  @override
  Future<List<StorePurchase>> owned() async {
    final result = await _android.queryPastPurchases().timeout(
      const Duration(seconds: 15),
    );
    if (result.error != null) throw StateError('Purchase query failed');
    return result.pastPurchases.map(_convert).toList();
  }

  @override
  Future<void> complete(StorePurchase purchase) async {
    final details = purchase.handle as GooglePlayPurchaseDetails;
    await _store.completePurchase(details).timeout(const Duration(seconds: 15));
    // The generic plugin discards Android's BillingResult. Confirm actual
    // acknowledgement from a fresh query instead of assuming Future<void> = OK.
    final result = await _android.queryPastPurchases().timeout(
      const Duration(seconds: 15),
    );
    if (result.error != null ||
        !result.pastPurchases.any(
          (p) =>
              p.productID == PremiumConfig.productId &&
              p.billingClientPurchase.purchaseToken == purchase.token &&
              p.billingClientPurchase.isAcknowledged,
        )) {
      throw StateError('Acknowledgement not confirmed');
    }
  }

  StorePurchase _convert(PurchaseDetails p) => StorePurchase(
    productId: p.productID,
    state: switch (p.status) {
      PurchaseStatus.pending => StorePurchaseState.pending,
      PurchaseStatus.purchased => StorePurchaseState.purchased,
      PurchaseStatus.restored => StorePurchaseState.restored,
      PurchaseStatus.canceled => StorePurchaseState.cancelled,
      PurchaseStatus.error => StorePurchaseState.error,
    },
    receipt: p is GooglePlayPurchaseDetails
        ? SignedReceipt(
            p.billingClientPurchase.originalJson,
            p.billingClientPurchase.signature,
          )
        : null,
    token: p.verificationData.serverVerificationData,
    needsCompletion: p.pendingCompletePurchase,
    handle: p,
  );
}
