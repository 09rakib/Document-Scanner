import 'package:docscan/features/ads/data/google_consent_gateway.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('plugins.flutter.io/google_mobile_ads/ump');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  tearDown(() => messenger.setMockMethodCallHandler(channel, null));
  test('native privacy form success resolves its dismissal future', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'UserMessagingPlatform#showPrivacyOptionsForm');
      return null;
    });
    await GoogleConsentGateway().showPrivacyOptions();
  });
  test('native privacy form failure reaches the caller without unhandled async error', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      throw PlatformException(code: '3', message: 'offline');
    });
    await expectLater(
      GoogleConsentGateway().showPrivacyOptions(),
      throwsA(isA<FormError>().having((error) => error.errorCode, 'code', 3)),
    );
  });
}
