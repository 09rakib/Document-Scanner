import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../documents/data/scanned_document.dart';
import '../../documents/providers/document_providers.dart';
import '../../documents/presentation/document_dialogs.dart';
import '../../documents/presentation/document_operations.dart';
import '../../scan/providers/scan_providers.dart';

enum ViewerAction { edit, share, rename, delete, save, compress }

class ViewerActions extends ConsumerWidget {
  const ViewerActions({super.key, required this.document, this.page = 0});
  final ScannedDocument document;
  final int page;

  Future<void> _act(
    BuildContext context,
    WidgetRef ref,
    ViewerAction action,
  ) async {
    final s = AppLocalizations.of(context);
    final container = ProviderScope.containerOf(context);
    final actions = ref.read(documentActionsProvider);
    final transfer = ref.read(documentTransferProvider);
    switch (action) {
      case ViewerAction.edit:
        context.push('/documents/${document.id}/edit?page=$page');
      case ViewerAction.compress:
        context.push('/documents/${document.id}/compress');
      case ViewerAction.rename:
        final name = await requestDocumentName(context, document.name);
        if (name == null || !context.mounted) return;
        await runDocumentOperation(context, ref, () async {
          await actions.rename(document.id!, name);
          refreshDocuments(container, [document.id!]);
          return null;
        });
      case ViewerAction.delete:
        if (!await confirmDelete(context, 1) || !context.mounted) return;
        final success = await runDocumentOperation(context, ref, () async {
          final outcome = await actions.delete({document.id!});
          refreshDocuments(container, [document.id!]);
          return outcome.cleanupPending
              ? s.deleteCleanupPending
              : s.documentsDeleted(outcome.count);
        });
        if (success && context.mounted) context.go('/');
      case ViewerAction.share:
        await runDocumentOperation(context, ref, () async {
          await transfer.share(document);
          return null;
        });
      case ViewerAction.save:
        await runDocumentOperation(
          context,
          ref,
          () async =>
              await transfer.saveToDevice(document) ? s.documentSaved : null,
        );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = AppLocalizations.of(context);
    final busy =
        ref.watch(documentBusyProvider) ||
        ref.watch(scanControllerProvider).isLoading;
    final labels = {
      ViewerAction.edit: s.editPages,
      ViewerAction.share: s.share,
      ViewerAction.rename: s.rename,
      ViewerAction.delete: s.delete,
      ViewerAction.save: s.saveToDevice,
      ViewerAction.compress: s.compressPdf,
    };
    final icons = {
      ViewerAction.edit: Icons.crop_rotate,
      ViewerAction.share: Icons.share_outlined,
      ViewerAction.rename: Icons.drive_file_rename_outline,
      ViewerAction.delete: Icons.delete_outline,
      ViewerAction.save: Icons.save_alt,
      ViewerAction.compress: Icons.compress,
    };
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (busy) LinearProgressIndicator(semanticsLabel: s.loading),
        Wrap(
          alignment: WrapAlignment.center,
          children: [
            for (final action in ViewerAction.values)
              TextButton.icon(
                onPressed: busy ? null : () => _act(context, ref, action),
                icon: Icon(icons[action]),
                label: Text(labels[action]!),
              ),
          ],
        ),
      ],
    );
  }
}
