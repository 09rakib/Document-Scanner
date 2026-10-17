import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(s.privacyPolicy)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: SelectableText(s.privacyBody),
        ),
      ),
    );
  }
}
