import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/generated/app_localizations.dart';

class RouteErrorScreen extends StatelessWidget {
  const RouteErrorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(strings.appName)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(strings.pageNotFound),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => context.go('/'),
                child: Text(strings.backToDocuments),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
