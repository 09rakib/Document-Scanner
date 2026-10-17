import 'package:docscan/features/settings/data/app_settings.dart';
import 'package:docscan/features/settings/providers/settings_providers.dart';

class ReadySettings extends SettingsController {
  @override
  Future<AppSettings> build() async => const AppSettings(onboarded: true);
}
