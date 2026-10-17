import 'dart:io';

import 'package:docscan/core/data/app_database.dart';
import 'package:docscan/features/premium/data/premium_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'premium_fakes.dart';

void main() {
  sqfliteFfiInit();
  test('v3 upgrade preserves existing rows; signed receipt survives reopen and clears', () async {
    final root = await Directory.systemTemp.createTemp('premium_db_');
    final path = '${root.path}/app.db';
    final old = await databaseFactoryFfi.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 3,
        onCreate: (db, _) async {
          for (final table in ['documents', 'settings', 'ad_frequency']) {
            await db.execute(
              'CREATE TABLE $table (id INTEGER PRIMARY KEY, value TEXT)',
            );
            await db.insert(table, {'id': 1, 'value': 'preserved-$table'});
          }
        },
      ),
    );
    await old.close();
    var owner = AppDatabase(factory: databaseFactoryFfi, path: path);
    try {
      var repository = PremiumRepository(() => owner);
      expect(await repository.load(), isNull);
      for (final table in ['documents', 'settings', 'ad_frequency']) {
        expect(
          (await (await owner.database).query(table)).single['value'],
          'preserved-$table',
        );
      }
      await repository.save(receipt('first'));
      await repository.save(receipt('replacement'));
      expect((await (await owner.database).query('premium_receipt')).length, 1);
      await owner.close();
      owner = AppDatabase(factory: databaseFactoryFfi, path: path);
      repository = PremiumRepository(() => owner);
      final saved = await repository.load();
      expect(saved!.token, 'replacement');
      expect(saved.signature, 'signature');
      await repository.clear();
      expect(await repository.load(), isNull);
    } finally {
      await owner.close();
      await root.delete(recursive: true);
    }
  });
}
