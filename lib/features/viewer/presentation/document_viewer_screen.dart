import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../documents/providers/document_providers.dart';
import 'document_preview.dart';
import 'page_thumbnails.dart';
import 'viewer_actions.dart';

class DocumentViewerScreen extends ConsumerStatefulWidget {
  const DocumentViewerScreen({super.key, required this.documentId});
  final int documentId;
  @override
  ConsumerState<DocumentViewerScreen> createState() =>
      _DocumentViewerScreenState();
}

class _DocumentViewerScreenState extends ConsumerState<DocumentViewerScreen> {
  int _page = 0;
  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final document = ref.watch(documentProvider(widget.documentId));
    return Scaffold(
      appBar: AppBar(title: Text(document.value?.name ?? s.documentTitle)),
      body: SafeArea(
        child: document.when(
          loading: () => Center(
            child: CircularProgressIndicator(semanticsLabel: s.loading),
          ),
          error: (_, _) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(s.documentsLoadFailed),
                FilledButton(
                  onPressed: () =>
                      ref.invalidate(documentProvider(widget.documentId)),
                  child: Text(s.retry),
                ),
              ],
            ),
          ),
          data: (saved) {
            if (saved == null) return Center(child: Text(s.documentMissing));
            return Column(
              children: [
                Expanded(
                  child: DocumentPreview(
                    documentId: widget.documentId,
                    page: _page,
                  ),
                ),
                PageThumbnails(
                  document: saved,
                  page: _page,
                  onSelected: (page) => setState(() => _page = page),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      tooltip: s.previousPage,
                      onPressed: _page > 0
                          ? () => setState(() => _page--)
                          : null,
                      icon: const Icon(Icons.chevron_left),
                    ),
                    Flexible(
                      child: Text(s.currentPage(_page + 1, saved.pageCount)),
                    ),
                    IconButton(
                      tooltip: s.nextPage,
                      onPressed: _page + 1 < saved.pageCount
                          ? () => setState(() => _page++)
                          : null,
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
                ViewerActions(document: saved, page: _page),
              ],
            );
          },
        ),
      ),
    );
  }
}
