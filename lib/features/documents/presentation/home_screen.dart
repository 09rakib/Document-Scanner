import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../scan/presentation/scan_button.dart';
import '../../scan/providers/scan_providers.dart';
import '../providers/document_list_providers.dart';
import '../providers/document_providers.dart';
import 'document_dialogs.dart';
import 'document_operations.dart';
import 'widgets/document_search.dart';
import 'widgets/document_tile.dart';
import 'widgets/empty_documents.dart';
import '../../ads/presentation/home_ad_banner.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _selected = <int>{};
  void _toggle(int id) => setState(() {
    if (!_selected.add(id)) _selected.remove(id);
  });
  Future<void> _delete() async {
    final ids = Set<int>.of(_selected);
    if (!await confirmDelete(context, ids.length) || !mounted) return;
    final s = AppLocalizations.of(context);
    final container = ProviderScope.containerOf(context);
    final success = await runDocumentOperation(context, ref, () async {
      final outcome = await ref.read(documentActionsProvider).delete(ids);
      refreshDocuments(container, ids);
      return outcome.cleanupPending
          ? s.deleteCleanupPending
          : s.documentsDeleted(outcome.count);
    });
    if (success && mounted) setState(_selected.clear);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final documents = ref.watch(visibleDocumentsProvider);
    final busy =
        ref.watch(documentBusyProvider) ||
        ref.watch(scanControllerProvider).isLoading;
    final selecting = _selected.isNotEmpty;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          selecting ? s.selectedCount(_selected.length) : s.documentsTitle,
        ),
        leading: selecting
            ? IconButton(
                tooltip: s.cancel,
                onPressed: busy ? null : () => setState(_selected.clear),
                icon: const Icon(Icons.close),
              )
            : null,
        actions: selecting
            ? [
                IconButton(
                  tooltip: s.selectAll,
                  onPressed: busy
                      ? null
                      : () => setState(() {
                          _selected.addAll(
                            documents.value?.map((row) => row.id!) ?? <int>[],
                          );
                        }),
                  icon: const Icon(Icons.select_all),
                ),
                IconButton(
                  tooltip: s.delete,
                  onPressed: busy ? null : _delete,
                  icon: const Icon(Icons.delete_outline),
                ),
              ]
            : [
                IconButton(
                  tooltip: s.settings,
                  onPressed: busy ? null : () => context.push('/settings'),
                  icon: const Icon(Icons.settings_outlined),
                ),
              ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            DocumentSearch(enabled: !selecting && !busy),
            if (busy) LinearProgressIndicator(semanticsLabel: s.loading),
            Expanded(
              child: documents.when(
                loading: () => Center(
                  child: CircularProgressIndicator(semanticsLabel: s.loading),
                ),
                error: (_, _) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(s.documentsLoadFailed),
                      FilledButton(
                        onPressed: () => ref.invalidate(documentsProvider),
                        child: Text(s.retry),
                      ),
                    ],
                  ),
                ),
                data: (items) => items.isEmpty
                    ? (ref.watch(searchProvider).trim().isEmpty
                          ? const EmptyDocuments()
                          : Center(child: Text(s.noSearchResults)))
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 96),
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return DocumentTile(
                            document: item,
                            selected: _selected.contains(item.id),
                            selecting: selecting,
                            onTap: busy
                                ? null
                                : () {
                                    if (selecting) {
                                      _toggle(item.id!);
                                    } else {
                                      context.push('/documents/${item.id}');
                                    }
                                  },
                            onLongPress: busy ? null : () => _toggle(item.id!),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: selecting ? null : const HomeAdBanner(),
      floatingActionButton: selecting ? null : const ScanButton(),
    );
  }
}
