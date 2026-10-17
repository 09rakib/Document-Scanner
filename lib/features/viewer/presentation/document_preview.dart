import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../providers/viewer_providers.dart';

class DocumentPreview extends ConsumerWidget {
  const DocumentPreview({
    super.key,
    required this.documentId,
    required this.page,
  });
  final int documentId;
  final int page;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = AppLocalizations.of(context);
    final loading = Center(
      child: CircularProgressIndicator(semanticsLabel: s.loading),
    );
    final failure = Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(s.previewFailed, textAlign: TextAlign.center),
          ),
          FilledButton(
            onPressed: () {
              ref.invalidate(viewerPdfProvider(documentId));
              ref.invalidate(
                largePdfPageProvider((documentId: documentId, page: page)),
              );
            },
            child: Text(s.retry),
          ),
        ],
      ),
    );
    return ref
        .watch(viewerPdfProvider(documentId))
        .when(
          loading: () => loading,
          error: (_, _) => failure,
          data: (bytes) => bytes == null
              ? ref
                    .watch(
                      largePdfPageProvider((
                        documentId: documentId,
                        page: page,
                      )),
                    )
                    .when(
                      loading: () => loading,
                      error: (_, _) => failure,
                      data: (image) => InteractiveViewer(
                        child: Center(
                          child: Image.memory(image, gaplessPlayback: false),
                        ),
                      ),
                    )
              : PdfPreview(
                  key: ValueKey((documentId, page)),
                  build: (_) async => bytes,
                  pages: [page],
                  dynamicLayout: false,
                  useActions: false,
                  allowPrinting: false,
                  allowSharing: false,
                  canDebug: false,
                  canChangePageFormat: false,
                  canChangeOrientation: false,
                  dpi: 100,
                  loadingWidget: loading,
                  onError: (_, _) => failure,
                ),
        );
  }
}
