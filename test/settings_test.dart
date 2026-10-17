import 'package:docscan/features/premium/providers/premium_providers.dart';
import 'package:docscan/features/ads/providers/ad_providers.dart';

import 'dart:io';

import 'package:docscan/app.dart';
import 'package:docscan/core/data/app_database.dart';
import 'package:docscan/core/routing/app_router.dart';
import 'package:docscan/features/compression/data/compression_models.dart';
import 'package:docscan/features/documents/providers/document_providers.dart';
import 'package:docscan/features/documents/data/scanned_document.dart';
import 'package:docscan/features/settings/data/app_settings.dart';
import 'package:docscan/features/settings/presentation/settings_screen.dart';
import 'package:docscan/features/settings/data/settings_repository.dart';
import 'package:docscan/features/settings/providers/settings_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class MemorySettings extends SettingsRepository {
  MemorySettings(this.saved) : super(AppDatabase(factory: databaseFactoryFfi));
  AppSettings saved;
  bool fail = false;
  @override
  Future<AppSettings> load() async => saved;
  @override
  Future<void> save(AppSettings value) async {
    if (fail) throw const FileSystemException('disk full');
    saved = value;
  }
}

void main() {
  sqfliteFfiInit();
  test(
    'v1 migration preserves document data and settings survive reopen',
    () async {
      final root = await Directory.systemTemp.createTemp('settings_test_');
      final path = '${root.path}/app.db';
      final old = await databaseFactoryFfi.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: (db, _) async {
            await db.execute(
              'CREATE TABLE documents (id INTEGER PRIMARY KEY, name TEXT)',
            );
            await db.insert('documents', {'id': 1, 'name': 'Keep me'});
          },
        ),
      );
      await old.close();
      var owner = AppDatabase(factory: databaseFactoryFfi, path: path);
      try {
        var repository = SettingsRepository(owner);
        expect((await repository.load()).onboarded, false);
        expect(
          (await (await owner.database).query('documents')).single['name'],
          'Keep me',
        );
        await repository.save(
          const AppSettings(
            language: 'bn',
            theme: ThemeMode.dark,
            compression: CompressionChoice.kb200,
            onboarded: true,
          ),
        );
        await owner.close();
        owner = AppDatabase(factory: databaseFactoryFfi, path: path);
        repository = SettingsRepository(owner);
        final restored = await repository.load();
        expect(restored.language, 'bn');
        expect(restored.theme, ThemeMode.dark);
        expect(restored.compression, CompressionChoice.kb200);
        expect(restored.onboarded, true);
      } finally {
        await owner.close();
        await root.delete(recursive: true);
      }
    },
  );
  test('unknown preference values safely follow device defaults', () {
    final settings = AppSettings.fromMap({
      'language': 'xx',
      'theme': 'new',
      'compression': 'new',
    });
    expect(settings.locale, isNull);
    expect(settings.theme, ThemeMode.system);
    expect(settings.compression, CompressionChoice.medium);
  });
  testWidgets('onboarding next/back/skip is durable and absent on restart', (
    tester,
  ) async {
    final repository = MemorySettings(const AppSettings());
    Future<void> mount() async {
      await tester.pumpWidget(
        ProviderScope(
          key: UniqueKey(),
          overrides: [
            premiumBootstrapProvider.overrideWithValue(false),
            adsEnabledProvider.overrideWithValue(false),
            appVersionProvider.overrideWith((ref) async => '0.1.0 (1)'),
            settingsRepositoryProvider.overrideWithValue(repository),
            documentsProvider.overrideWith((ref) async => []),
          ],
          child: const DocScanApp(),
        ),
      );
      await tester.pumpAndSettle();
    }

    await mount();
    expect(find.text('Paper to PDF'), findsOneWidget);
    await tester.tap(find.text('Next page'));
    await tester.pumpAndSettle();
    expect(find.text('Choose a smaller PDF'), findsOneWidget);
    await tester.tap(find.text('Previous page'));
    await tester.pumpAndSettle();
    expect(find.text('Paper to PDF'), findsOneWidget);
    repository.fail = true;
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
    expect(repository.saved.onboarded, false);
    expect(find.text('Paper to PDF'), findsOneWidget);
    repository.fail = false;
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
    expect(repository.saved.onboarded, true);
    expect(find.text('Documents'), findsOneWidget);
    await mount();
    expect(find.text('Documents'), findsOneWidget);
    expect(find.text('Skip'), findsNothing);
  });
  testWidgets(
    'live language and theme keep settings route and failed save keeps old value',
    (tester) async {
      final repository = MemorySettings(const AppSettings(onboarded: true));
      final container = ProviderContainer(
        overrides: [
          premiumBootstrapProvider.overrideWithValue(false),
          adsEnabledProvider.overrideWithValue(false),
          appVersionProvider.overrideWith((ref) async => '0.1.0 (1)'),
          settingsRepositoryProvider.overrideWithValue(repository),
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
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Settings'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('language-system')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('বাংলা').last);
      await tester.pumpAndSettle();
      expect(find.text('সেটিংস'), findsOneWidget);
      expect(find.byType(SettingsScreen), findsOneWidget);
      await container
          .read(settingsProvider.notifier)
          .persist(repository.saved.copyWith(theme: ThemeMode.dark));
      await tester.pumpAndSettle();
      expect(
        Theme.of(tester.element(find.byType(Scaffold))).brightness,
        Brightness.dark,
      );
      repository.fail = true;
      final success = await container
          .read(settingsProvider.notifier)
          .persist(repository.saved.copyWith(language: 'en'));
      expect(success, false);
      await tester.pumpAndSettle();
      expect(find.text('সেটিংস'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('new compression screen uses saved default target', (
    tester,
  ) async {
    final repository = MemorySettings(
      const AppSettings(onboarded: true, compression: CompressionChoice.kb200),
    );
    final date = DateTime.utc(2026);
    final document = ScannedDocument(
      id: 1,
      name: 'Example',
      pdfPath: '/test/document.pdf',
      thumbnailPath: '/test/thumbnail.jpg',
      pageCount: 2,
      fileSizeBytes: 1000000,
      createdAt: date,
      updatedAt: date,
    );
    final database = AppDatabase(
      factory: databaseFactoryFfi,
      path: inMemoryDatabasePath,
    );
    addTearDown(database.close);
    final container = ProviderContainer(
      overrides: [
        premiumBootstrapProvider.overrideWithValue(false),
        adsEnabledProvider.overrideWithValue(false),
        appDatabaseProvider.overrideWithValue(database),
        appVersionProvider.overrideWith((ref) async => '0.1.0 (1)'),
        settingsRepositoryProvider.overrideWithValue(repository),
        documentsProvider.overrideWith((ref) async => []),
        documentProvider(1).overrideWith((ref) async => document),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const DocScanApp(),
      ),
    );
    await tester.pumpAndSettle();
    container.read(appRouterProvider).go('/documents/1/compress');
    await tester.pumpAndSettle();
    final field = tester.widget<DropdownButtonFormField<CompressionChoice>>(
      find.byType(DropdownButtonFormField<CompressionChoice>),
    );
    expect(field.initialValue, CompressionChoice.kb200);
    expect(tester.takeException(), isNull);
  });
  for (final language in ['en', 'bn']) {
    testWidgets(
      'onboarding and settings at 200% text in $language fit narrow screen',
      (tester) async {
        tester.view.physicalSize = const Size(360, 640);
        tester.view.devicePixelRatio = 1;
        tester.binding.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(
          tester.binding.platformDispatcher.clearTextScaleFactorTestValue,
        );
        final repository = MemorySettings(AppSettings(language: language));
        final container = ProviderContainer(
          overrides: [
            premiumBootstrapProvider.overrideWithValue(false),
            adsEnabledProvider.overrideWithValue(false),
            appVersionProvider.overrideWith((ref) async => '0.1.0 (1)'),
            settingsRepositoryProvider.overrideWithValue(repository),
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
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await container
            .read(settingsProvider.notifier)
            .persist(repository.saved.copyWith(onboarded: true));
        container.read(appRouterProvider).go('/settings');
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );
  }
}
