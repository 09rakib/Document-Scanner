import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../compression/data/compression_models.dart';
import '../../compression/presentation/compression_copy.dart';
import '../data/app_info.dart';
import '../data/app_settings.dart';
import '../providers/settings_providers.dart';
import '../../ads/presentation/ad_privacy_options.dart';
import '../../premium/providers/premium_providers.dart';

final appInfoProvider = Provider((ref) => AppInfo());
final appVersionProvider = FutureProvider(
  (ref) => ref.watch(appInfoProvider).version(),
);

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});
  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _saving = false;
  Future<void> _save(AppSettings value) async {
    setState(() => _saving = true);
    final success = await ref.read(settingsProvider.notifier).persist(value);
    if (!mounted) return;
    setState(() => _saving = false);
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).settingsSaveFailed),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final settings = ref.watch(settingsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(s.settings)),
      body: SafeArea(
        child: settings.when(
          loading: () => Center(
            child: CircularProgressIndicator(semanticsLabel: s.loading),
          ),
          error: (_, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(s.settingsLoadFailed),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => ref.invalidate(settingsProvider),
                    child: Text(s.retry),
                  ),
                ],
              ),
            ),
          ),
          data: (value) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (_saving) LinearProgressIndicator(semanticsLabel: s.loading),
              DropdownButtonFormField<String>(
                key: ValueKey('language-${value.language}'),
                initialValue: value.language,
                isExpanded: true,
                decoration: InputDecoration(labelText: s.language),
                items: [
                  DropdownMenuItem(
                    value: 'system',
                    child: Text(s.followSystem),
                  ),
                  DropdownMenuItem(value: 'en', child: Text(s.languageEnglish)),
                  DropdownMenuItem(value: 'bn', child: Text(s.languageBangla)),
                ],
                onChanged: _saving
                    ? null
                    : (v) {
                        if (v != null) _save(value.copyWith(language: v));
                      },
              ),
              const SizedBox(height: 24),
              DropdownButtonFormField<ThemeMode>(
                key: ValueKey('theme-${value.theme.name}'),
                initialValue: value.theme,
                isExpanded: true,
                decoration: InputDecoration(labelText: s.theme),
                items: [
                  DropdownMenuItem(
                    value: ThemeMode.system,
                    child: Text(s.followSystem),
                  ),
                  DropdownMenuItem(
                    value: ThemeMode.light,
                    child: Text(s.themeLight),
                  ),
                  DropdownMenuItem(
                    value: ThemeMode.dark,
                    child: Text(s.themeDark),
                  ),
                ],
                onChanged: _saving
                    ? null
                    : (v) {
                        if (v != null) _save(value.copyWith(theme: v));
                      },
              ),
              const SizedBox(height: 24),
              DropdownButtonFormField<CompressionChoice>(
                key: ValueKey('compression-${value.compression.name}'),
                initialValue: value.compression,
                isExpanded: true,
                decoration: InputDecoration(labelText: s.defaultCompression),
                items: [
                  for (final c in CompressionChoice.values)
                    DropdownMenuItem(
                      value: c,
                      child: Text(compressionChoiceLabel(s, c)),
                    ),
                ],
                onChanged: _saving
                    ? null
                    : (v) {
                        if (v != null) _save(value.copyWith(compression: v));
                      },
              ),
              const SizedBox(height: 24),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.privacy_tip_outlined),
                title: Text(s.privacyPolicy),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/settings/privacy'),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.workspace_premium_outlined),
                title: Text(s.premiumTitle),
                subtitle: Text(
                  ref.watch(isPremiumProvider)
                      ? s.premiumActive
                      : s.premiumRemoveAds,
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/premium'),
              ),
              const AdPrivacyOptions(),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.star_outline),
                title: Text(s.rateApp),
                onTap: () async {
                  try {
                    await ref.read(appInfoProvider).rate();
                  } catch (_) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(s.rateUnavailable)),
                      );
                    }
                  }
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(s.appVersion),
                subtitle: ref
                    .watch(appVersionProvider)
                    .when(
                      loading: () => Text(s.loading),
                      data: (v) => Text(v.isEmpty ? s.versionUnavailable : v),
                      error: (_, _) => Text(s.versionUnavailable),
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
