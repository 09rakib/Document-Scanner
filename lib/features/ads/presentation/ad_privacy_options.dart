import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../providers/ad_providers.dart';

class AdPrivacyOptions extends ConsumerWidget {
  const AdPrivacyOptions({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.watch(adServiceProvider);
    final s = AppLocalizations.of(context);
    if (!service.privacyOptionsRequired && !service.consentError) {
      return const SizedBox.shrink();
    }
    return Column(
      children: [
        if (service.privacyOptionsRequired)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.tune),
            title: Text(s.adPrivacyChoices),
            onTap: service.modalBusy
                ? null
                : () async {
                    final success = await service.showPrivacyOptions();
                    if (!success && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(s.adPrivacyFailed)),
                      );
                    }
                  },
          ),
        if (service.consentError)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(s.adPrivacyFailed),
            subtitle: Text(s.adPrivacyRetry),
            onTap: service.modalBusy ? null : service.refreshConsent,
          ),
      ],
    );
  }
}
