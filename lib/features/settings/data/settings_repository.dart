import 'package:sqflite/sqflite.dart';

import '../../../core/data/app_database.dart';
import 'app_settings.dart';

class SettingsRepository {
  SettingsRepository(this.database);
  final AppDatabase database;
  Future<AppSettings> load() async {
    final rows = await (await database.database).query('settings', limit: 1);
    return rows.isEmpty
        ? const AppSettings()
        : AppSettings.fromMap(rows.single);
  }

  Future<void> save(AppSettings settings) async {
    await (await database.database).insert(
      'settings',
      settings.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
