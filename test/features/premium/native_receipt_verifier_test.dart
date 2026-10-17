import 'package:docscan/features/premium/data/native_receipt_verifier.dart';
import 'package:docscan/features/premium/data/premium_contracts.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'premium_fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(NativeReceiptVerifier.channel, null),
  );
  test('missing key fails closed without invoking Android', () async {
    var calls = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(NativeReceiptVerifier.channel, (_) async {
          calls++;
          return true;
        });
    expect(await NativeReceiptVerifier(publicKey: '').verify(receipt()), false);
    expect(calls, 0);
  });
  test('passes signed proof and exact product to native verifier; null fails closed', () async {
    MethodCall? call;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(NativeReceiptVerifier.channel, (value) async {
          call = value;
          return null;
        });
    expect(
      await NativeReceiptVerifier(publicKey: 'test-key').verify(receipt()),
      false,
    );
    expect(call!.method, 'verify');
    expect(call!.arguments, {
      'payload': receipt().payload,
      'signature': 'signature',
      'publicKey': 'test-key',
      'productId': PremiumConfig.productId,
    });
  });
}
