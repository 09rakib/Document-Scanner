import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../documents/presentation/home_screen.dart';
import '../providers/settings_providers.dart';
import 'onboarding_screen.dart';

class StartupGate extends ConsumerWidget {
  const StartupGate({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = AppLocalizations.of(context);
    return ref
        .watch(settingsProvider)
        .when(
          loading: () => Scaffold(
            body: Center(
              child: CircularProgressIndicator(semanticsLabel: s.loading),
            ),
          ),
          error: (_, _) => Scaffold(
            body: Center(
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
          ),
          data: (settings) => settings.onboarded
              ? const HomeScreen()
              : const OnboardingScreen(),
        );
  }
}
