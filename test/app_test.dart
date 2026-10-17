import 'package:docscan/features/premium/providers/premium_providers.dart';
import 'package:docscan/features/ads/providers/ad_providers.dart';
import 'package:docscan/features/settings/providers/settings_providers.dart';

import 'helpers/ready_settings.dart';

import 'package:docscan/app.dart';
import 'package:docscan/core/routing/app_router.dart';
import 'package:docscan/features/documents/providers/document_providers.dart';
import 'package:docscan/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final locale in [
    const Locale('en'),
    const Locale('bn'),
    const Locale('fr'),
  ]) {
    testWidgets('Home follows ${locale.languageCode} device locale', (
      tester,
    ) async {
      tester.binding.platformDispatcher.localesTestValue = [locale];
      addTearDown(tester.binding.platformDispatcher.clearLocalesTestValue);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            premiumBootstrapProvider.overrideWithValue(false),
            adsEnabledProvider.overrideWithValue(false),
            settingsProvider.overrideWith(ReadySettings.new),
            documentsProvider.overrideWith((ref) async => []),
          ],
          child: const DocScanApp(),
        ),
      );
      await tester.pumpAndSettle();

      final strings = lookupAppLocalizations(
        locale.languageCode == 'fr' ? const Locale('en') : locale,
      );
      expect(find.text(strings.documentsTitle), findsOneWidget);
      expect(find.text(strings.emptyDocumentsTitle), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Unknown route recovers to home', (tester) async {
    final container = ProviderContainer(
      overrides: [
        premiumBootstrapProvider.overrideWithValue(false),
        adsEnabledProvider.overrideWithValue(false),
        settingsProvider.overrideWith(ReadySettings.new),
        documentsProvider.overrideWith((ref) async => []),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const DocScanApp(),
      ),
    );
    container.read(appRouterProvider).go('/missing');
    await tester.pumpAndSettle();
    final context = tester.element(find.byType(FilledButton));
    final strings = AppLocalizations.of(context);
    expect(find.text(strings.pageNotFound), findsOneWidget);
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
    expect(find.text(strings.documentsTitle), findsOneWidget);
  });

  testWidgets('System dark mode and large text render without overflow', (
    tester,
  ) async {
    tester.binding.platformDispatcher.platformBrightnessTestValue =
        Brightness.dark;
    tester.binding.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(
      tester.binding.platformDispatcher.clearPlatformBrightnessTestValue,
    );
    addTearDown(
      tester.binding.platformDispatcher.clearTextScaleFactorTestValue,
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          premiumBootstrapProvider.overrideWithValue(false),
          adsEnabledProvider.overrideWithValue(false),
          settingsProvider.overrideWith(ReadySettings.new),
          documentsProvider.overrideWith((ref) async => []),
        ],
        child: const DocScanApp(),
      ),
    );
    await tester.pumpAndSettle();
    final context = tester.element(find.byType(Scaffold));
    expect(Theme.of(context).brightness, Brightness.dark);
    expect(tester.takeException(), isNull);
  });
}
