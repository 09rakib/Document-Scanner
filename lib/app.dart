import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'l10n/generated/app_localizations.dart';
import 'features/settings/providers/settings_providers.dart';
import 'features/ads/presentation/ad_host.dart';
import 'features/premium/presentation/premium_host.dart';

class DocScanApp extends ConsumerWidget {
  const DocScanApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (context) => AppLocalizations.of(context).appName,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ref.watch(settingsProvider).value?.theme ?? ThemeMode.system,
      locale: ref.watch(settingsProvider).value?.locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) =>
          PremiumHost(child: AdHost(child: child ?? const SizedBox.shrink())),
      routerConfig: ref.watch(appRouterProvider),
    );
  }
}
