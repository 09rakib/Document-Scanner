import 'package:docscan/features/premium/providers/premium_providers.dart';

import 'dart:async';

import 'package:docscan/app.dart';
import 'package:docscan/core/routing/app_router.dart';
import 'package:docscan/features/ads/data/ad_contracts.dart';
import 'package:docscan/features/ads/data/ad_service.dart';
import 'package:docscan/features/ads/providers/ad_providers.dart';
import 'package:docscan/features/documents/providers/document_providers.dart';
import 'package:docscan/features/settings/providers/settings_providers.dart';
import 'package:docscan/features/settings/presentation/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/ready_settings.dart';
import 'ad_fakes.dart';

void main() {
  testWidgets(
    'adaptive banner is separated from Scan and removed off home and when disabled',
    (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      tester.binding.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(
        tester.binding.platformDispatcher.clearTextScaleFactorTestValue,
      );
      final ads = FakeAds();
      final service = AdService(ads, FakeConsent(), FakeFrequency());
      final container = ProviderContainer(
        overrides: [
          premiumBootstrapProvider.overrideWithValue(false),
          adServiceProvider.overrideWith((ref) => service),
          settingsProvider.overrideWith(ReadySettings.new),
          documentsProvider.overrideWith((ref) async => []),
          appVersionProvider.overrideWith((ref) async => '0.1.0 (1)'),
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
      expect(find.text('Advertisement'), findsOneWidget);
      expect(ads.bannerLoads, 1);
      final banner = tester.getRect(find.text('SDK test banner'));
      final scan = tester.getRect(find.byType(FloatingActionButton));
      expect(scan.bottom < banner.top, true);
      await tester.tap(find.byTooltip('Settings'));
      await tester.pumpAndSettle();
      expect(find.text('SDK test banner'), findsNothing);
      expect(ads.banners.first.disposals, 1);
      container.read(appRouterProvider).go('/');
      await tester.pumpAndSettle();
      expect(find.text('SDK test banner'), findsOneWidget);
      service.setEnabled(false);
      await tester.pumpAndSettle();
      expect(find.text('Advertisement'), findsNothing);
      expect(ads.banners.last.disposals, 1);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'late banner after widget disposal is released without setState error',
    (tester) async {
      final ads = FakeAds()..pendingBanner = Completer<BannerHandle>();
      final service = AdService(ads, FakeConsent(), FakeFrequency());
      final container = ProviderContainer(
        overrides: [
          premiumBootstrapProvider.overrideWithValue(false),
          adServiceProvider.overrideWith((ref) => service),
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
      expect(ads.bannerLoads, 1);
      await tester.pumpWidget(const SizedBox.shrink());
      final banner = FakeBanner(320);
      ads.pendingBanner!.complete(banner);
      await tester.pumpAndSettle();
      expect(banner.disposals, 1);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('consent waits outside home/settings and resumes on return', (
    tester,
  ) async {
    final consent = FakeConsent()..updating = Completer<void>();
    consent.status = const ConsentSnapshot(
      canRequest: false,
      required: true,
      privacyOptionsRequired: true,
    );
    final prompt = FakePrompt();
    consent.prompt = prompt;
    final ads = FakeAds();
    final service = AdService(ads, consent, FakeFrequency());
    final container = ProviderContainer(
      overrides: [
        premiumBootstrapProvider.overrideWithValue(false),
        adServiceProvider.overrideWith((ref) => service),
        settingsProvider.overrideWith(ReadySettings.new),
        documentsProvider.overrideWith((ref) async => []),
        documentProvider(1).overrideWith((ref) async => null),
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
    container.read(appRouterProvider).go('/documents/1');
    await tester.pumpAndSettle();
    consent.updating!.complete();
    await tester.pumpAndSettle();
    expect(prompt.shows, 0);
    expect(ads.initializations, 0);
    container.read(appRouterProvider).go('/');
    await tester.pumpAndSettle();
    expect(prompt.shows, 1);
    expect(service.modalBusy, true);
    consent.status = const ConsentSnapshot(
      canRequest: true,
      required: false,
      privacyOptionsRequired: true,
    );
    prompt.done.complete();
    await tester.pumpAndSettle();
    expect(service.modalBusy, false);
    expect(ads.initializations, 1);
    expect(tester.takeException(), isNull);
  });
}
