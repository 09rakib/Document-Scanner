import 'package:flutter/services.dart';

import 'premium_contracts.dart';

class NativeReceiptVerifier implements ReceiptVerifier {
  NativeReceiptVerifier({this.publicKey = PremiumConfig.publicKey});
  final String publicKey;
  static const channel = MethodChannel('com.example.docscan/purchases');
  @override
  bool get configured => publicKey.trim().isNotEmpty;
  @override
  Future<bool> verify(SignedReceipt receipt) async {
    if (!configured) return false;
    return await channel
            .invokeMethod<bool>('verify', {
              'payload': receipt.payload,
              'signature': receipt.signature,
              'publicKey': publicKey,
              'productId': PremiumConfig.productId,
            })
            .timeout(const Duration(seconds: 10)) ??
        false;
  }
}
