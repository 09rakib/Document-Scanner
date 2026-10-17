import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../providers/premium_providers.dart';
import 'premium_copy.dart';

class PremiumScreen extends ConsumerWidget {
  const PremiumScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = AppLocalizations.of(context);
    final service = ref.watch(premiumServiceProvider);
    return Scaffold(
      appBar: AppBar(title: Text(s.premiumTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            ExcludeSemantics(
              child: Icon(
                Icons.workspace_premium_outlined,
                size: 72,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Semantics(
              header: true,
              child: Text(
                service.isPremium ? s.premiumActive : s.premiumRemoveAds,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            const SizedBox(height: 12),
            Text(service.isPremium ? s.premiumActiveBody : s.premiumBody),
            const SizedBox(height: 24),
            if (!service.cacheReady || service.storeBusy)
              LinearProgressIndicator(semanticsLabel: s.loading),
            if (service.message case final message?)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Semantics(
                  liveRegion: true,
                  child: Text(premiumMessage(s, message)),
                ),
              ),
            if (!service.isPremium)
              FilledButton.icon(
                onPressed: service.canBuy ? service.buy : null,
                icon: const Icon(Icons.shopping_bag_outlined),
                label: Text(
                  service.price == null
                      ? s.premiumRemoveAds
                      : s.premiumBuy(service.price!),
                ),
              ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: service.canRestore
                  ? () => service.refresh(userRequested: true)
                  : null,
              child: Text(s.restorePurchases),
            ),
            TextButton(
              onPressed: service.storeBusy ? null : () => service.refresh(),
              child: Text(s.retry),
            ),
            const SizedBox(height: 16),
            Text(s.premiumRestoreHint),
          ],
        ),
      ),
    );
  }
}
