import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../documents/providers/document_providers.dart';
import '../data/app_settings.dart';
import '../data/settings_repository.dart';

final settingsRepositoryProvider = Provider(
  (ref) => SettingsRepository(ref.watch(appDatabaseProvider)),
);
final settingsProvider = AsyncNotifierProvider<SettingsController, AppSettings>(
  SettingsController.new,
);

class SettingsController extends AsyncNotifier<AppSettings> {
  bool _saving = false;
  @override
  Future<AppSettings> build() => ref
      .watch(settingsRepositoryProvider)
      .load()
      .timeout(const Duration(seconds: 15));
  // Publish only after durable storage succeeds. The UI handles failures and
  // keeps the previous language/theme instead of claiming an unsaved change.
  Future<bool> persist(AppSettings next) async {
    if (_saving || !state.hasValue) return false;
    _saving = true;
    try {
      await ref.read(settingsRepositoryProvider).save(next);
      if (ref.mounted) state = AsyncData(next);
      return true;
    } catch (_) {
      return false;
    } finally {
      _saving = false;
    }
  }
}
