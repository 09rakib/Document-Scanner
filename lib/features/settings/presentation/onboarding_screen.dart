import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../providers/settings_providers.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});
  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  int _page = 0;
  bool _saving = false;
  Future<void> _finish() async {
    setState(() => _saving = true);
    final settings = ref.read(settingsProvider).requireValue;
    final saved = await ref
        .read(settingsProvider.notifier)
        .persist(settings.copyWith(onboarded: true));
    if (!mounted) return;
    setState(() => _saving = false);
    if (!saved) {
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
    final titles = [
      s.introScanTitle,
      s.introCompressTitle,
      s.introPrivateTitle,
    ];
    final bodies = [s.introScanBody, s.introCompressBody, s.introPrivateBody];
    final icons = [
      Icons.document_scanner_outlined,
      Icons.compress,
      Icons.folder_outlined,
    ];
    return Scaffold(
      appBar: AppBar(
        title: Text(s.appName),
        actions: [
          TextButton(onPressed: _saving ? null : _finish, child: Text(s.skip)),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ExcludeSemantics(
                        child: Icon(
                          icons[_page],
                          size: 88,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Semantics(
                        header: true,
                        liveRegion: true,
                        child: Text(
                          titles[_page],
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(bodies[_page], textAlign: TextAlign.center),
                      const SizedBox(height: 24),
                      Text(s.currentPage(_page + 1, 3)),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 16,
                runSpacing: 8,
                children: [
                  if (_page > 0)
                    TextButton(
                      onPressed: _saving ? null : () => setState(() => _page--),
                      child: Text(s.previousPage),
                    ),
                  FilledButton(
                    onPressed: _saving
                        ? null
                        : () {
                            if (_page < 2) {
                              setState(() => _page++);
                            } else {
                              _finish();
                            }
                          },
                    child: Text(
                      _saving
                          ? s.loading
                          : _page == 2
                          ? s.getStarted
                          : s.nextPage,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
