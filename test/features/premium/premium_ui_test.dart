import 'package:docscan/features/ads/providers/ad_providers.dart';
import 'package:docscan/app.dart';
import 'package:docscan/features/ads/data/ad_service.dart';
import 'package:docscan/features/documents/providers/document_providers.dart';
import 'package:docscan/features/settings/providers/settings_providers.dart';
import 'package:docscan/features/premium/data/premium_service.dart';
import 'package:docscan/features/premium/presentation/premium_screen.dart';
import 'package:docscan/features/premium/providers/premium_providers.dart';
import 'package:docscan/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'premium_fakes.dart';
import '../../helpers/ready_settings.dart';
import '../ads/ad_fakes.dart';

void main() {
  testWidgets(
    'billing completion releases consent gate; purchase removes live banner',
    (tester) async {
      final billing = FakeBilling();
      final premium = PremiumService(
        billing,
        FakeVerifier(),
        FakeCache(billing.order),
      );
      final ads = FakeAds();
      final adService = AdService(ads, FakeConsent(), FakeFrequency());
      final container = ProviderContainer(
        overrides: [
          premiumServiceProvider.overrideWith((ref) => premium),
          adServiceProvider.overrideWith((ref) {
            adService.setEnabled(ref.read(adsEnabledProvider));
            ref.listen(
              adsEnabledProvider,
              (_, next) => adService.setEnabled(next),
            );
            return adService;
          }),
          settingsProvider.overrideWith(ReadySettings.new),
          documentsProvider.overrideWith((ref) async => []),
        ],
      );
      addTearDown(container.dispose);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const DocScanApp(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('SDK test banner'), findsOneWidget);
      billing.events.add([purchase()]);
      await tester.pumpAndSettle();
      expect(find.text('SDK test banner'), findsNothing);
      expect(adService.bannerAllowed, false);
      expect(ads.banners.single.disposals, 1);
      expect(tester.takeException(), isNull);
    },
  );
  test('entitlement providers suppress ads before cache and react to purchase and restore', () async {
    final billing = FakeBilling();
    final service = PremiumService(
      billing,
      FakeVerifier(),
      FakeCache(billing.order),
    );
    final container = ProviderContainer(
      overrides: [premiumServiceProvider.overrideWith((ref) => service)],
    );
    addTearDown(container.dispose);
    expect(container.read(adsEnabledProvider), false);
    await service.start();
    expect(container.read(adsEnabledProvider), true);
    billing.events.add([purchase()]);
    await settlePremium();
    expect(container.read(isPremiumProvider), true);
    expect(container.read(adsEnabledProvider), false);
    await service.refresh(userRequested: true);
    expect(container.read(isPremiumProvider), false);
    expect(container.read(adsEnabledProvider), true);
  });

  for (final language in ['en', 'bn']) {
    testWidgets(
      '$language purchase price, restore and active UI at 200% text',
      (tester) async {
        tester.view.physicalSize = const Size(360, 640);
        tester.view.devicePixelRatio = 1;
        tester.binding.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(
          tester.binding.platformDispatcher.clearTextScaleFactorTestValue,
        );
        final billing = FakeBilling();
        final service = PremiumService(
          billing,
          FakeVerifier(),
          FakeCache(billing.order),
        );
        await service.start();
        final container = ProviderContainer(
          overrides: [premiumServiceProvider.overrideWith((ref) => service)],
        );
        addTearDown(container.dispose);
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              locale: Locale(language),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: const PremiumScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(find.byType(FilledButton), 180);
        expect(find.textContaining('৳99.00'), findsOneWidget);
        final restore = find.byType(OutlinedButton);
        await tester.ensureVisible(restore);
        await tester.pumpAndSettle();
        await tester.tap(restore);
        await tester.pumpAndSettle();
        expect(billing.queries, 2);
        billing.events.add([purchase()]);
        await tester.pumpAndSettle();
        expect(find.byType(FilledButton), findsNothing);
        expect(service.isPremium, true);
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets(
    'unconfigured app disables buy and restore without invented price',
    (tester) async {
      final billing = FakeBilling();
      final service = PremiumService(
        billing,
        FakeVerifier()..configured = false,
        FakeCache(billing.order),
      );
      await service.start();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [premiumServiceProvider.overrideWith((ref) => service)],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: PremiumScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      expect(
        tester.widget<OutlinedButton>(find.byType(OutlinedButton)).onPressed,
        isNull,
      );
      expect(find.textContaining('৳99.00'), findsNothing);
      expect(billing.availableCalls, 0);
      expect(tester.takeException(), isNull);
    },
  );
}
