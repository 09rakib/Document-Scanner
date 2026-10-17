import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../providers/document_providers.dart';
import '../../scan/providers/scan_providers.dart';

Future<bool> runDocumentOperation(
  BuildContext context,
  WidgetRef ref,
  Future<String?> Function() operation,
) async {
  if (ref.read(documentBusyProvider) ||
      ref.read(scanControllerProvider).isLoading) {
    return false;
  }
  final busy = ref.read(documentBusyProvider.notifier);
  busy.set(true);
  try {
    final message = await operation();
    if (context.mounted && message != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
    return true;
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).documentActionFailed),
        ),
      );
    }
    return false;
  } finally {
    busy.set(false);
  }
}

void refreshDocuments(ProviderContainer ref, Iterable<int> ids) {
  ref.invalidate(documentsProvider);
  for (final id in ids) {
    ref.invalidate(documentProvider(id));
  }
}
