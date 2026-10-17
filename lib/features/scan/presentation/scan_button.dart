import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../documents/providers/document_providers.dart';
import '../providers/scan_providers.dart';
import 'scan_error_message.dart';
import '../../ads/providers/ad_providers.dart';
import '../../../core/routing/app_router.dart';

class ScanButton extends ConsumerWidget {
  const ScanButton({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = AppLocalizations.of(context);
    final scan = ref.watch(scanControllerProvider);
    final disabled =
        ref.watch(adServiceProvider).modalBusy ||
        scan.isLoading ||
        ref.watch(documentBusyProvider) ||
        ref.watch(documentsProvider).isLoading;
    return FloatingActionButton.extended(
      onPressed: disabled
          ? null
          : () async {
              if (ref.read(adServiceProvider).modalBusy) return;
              final saved = await ref
                  .read(scanControllerProvider.notifier)
                  .scan(
                    (date) => s.defaultDocumentName(
                      DateFormat.yMd(s.localeName)
                          .add_Hm()
                          .format(date.toLocal()),
                    ),
                  );
              if (!context.mounted) return;
              if (saved != null) {
                await ref
                    .read(adServiceProvider)
                    .afterSavedScan(
                      stillAtTransition: () =>
                          context.mounted &&
                          ref.read(appRouterProvider).state.uri.path == '/',
                    );
                if (!context.mounted ||
                    ref.read(appRouterProvider).state.uri.path != '/') {
                  return;
                }
                context.push('/documents/${saved.id}');
              } else {
                final error = ref.read(scanControllerProvider).error;
                if (error != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(scanErrorMessage(s, error))),
                  );
                }
              }
            },
      icon: scan.isLoading
          ? SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                semanticsLabel: s.scanInProgress,
              ),
            )
          : const Icon(Icons.document_scanner_outlined),
      label: Text(scan.isLoading ? s.scanInProgress : s.scan),
    );
  }
}
