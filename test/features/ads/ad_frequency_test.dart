import 'dart:io';

import 'package:docscan/core/data/app_database.dart';
import 'package:docscan/features/ads/data/ad_frequency_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  test('v2 upgrade preserves settings/documents and caps survive reopen and clock reversal', () async {
    final root = await Directory.systemTemp.createTemp('ad_caps_');
    final path = '${root.path}/app.db';
    final old = await databaseFactoryFfi.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 2,
        onCreate: (db, _) async {
          await db.execute(
            'CREATE TABLE documents (id INTEGER PRIMARY KEY, name TEXT)',
          );
          await db.insert('documents', {'id': 1, 'name': 'Keep'});
          await db.execute(
            'CREATE TABLE settings (id INTEGER PRIMARY KEY, language TEXT)',
          );
          await db.insert('settings', {'id': 1, 'language': 'bn'});
        },
      ),
    );
    await old.close();
    var owner = AppDatabase(factory: databaseFactoryFfi, path: path);
    var repository = AdFrequencyRepository(() => owner);
    var now = DateTime.utc(2026);
    try {
      expect(
        (await (await owner.database).query('documents')).single['name'],
        'Keep',
      );
      expect(
        (await (await owner.database).query('settings')).single['language'],
        'bn',
      );
      for (var i = 0; i < 2; i++) {
        await repository.recordScan();
        expect(await repository.reserve(now), false);
      }
      await repository.recordScan();
      expect(await repository.reserve(now), true);
      await owner.close();
      owner = AppDatabase(factory: databaseFactoryFfi, path: path);
      repository = AdFrequencyRepository(() => owner);
      for (var i = 0; i < 3; i++) {
        await repository.recordScan();
      }
      expect(
        await repository.reserve(
          now.add(const Duration(minutes: 2, seconds: 59)),
        ),
        false,
      );
      expect(
        await repository.reserve(now.subtract(const Duration(days: 1))),
        false,
      );
      now = now.add(const Duration(minutes: 3));
      final concurrent = await Future.wait([
        repository.reserve(now),
        repository.reserve(now),
      ]);
      expect(concurrent.where((v) => v).length, 1);
      await repository.extendCooldown(now.add(const Duration(minutes: 1)));
      for (var i = 0; i < 3; i++) {
        await repository.recordScan();
      }
      expect(
        await repository.reserve(now.add(const Duration(minutes: 3))),
        false,
      );
      expect(
        await repository.reserve(now.add(const Duration(minutes: 4))),
        true,
      );
    } finally {
      await owner.close();
      await root.delete(recursive: true);
    }
  });
}
