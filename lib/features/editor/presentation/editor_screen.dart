import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../documents/providers/document_providers.dart';
import 'editor_form.dart';

class EditorScreen extends ConsumerWidget {
  const EditorScreen({
    super.key,
    required this.documentId,
    this.initialPage = 0,
  });
  final int documentId, initialPage;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(s.editPages)),
      body: SafeArea(
        child: ref
            .watch(documentProvider(documentId))
            .when(
              loading: () => Center(
                child: CircularProgressIndicator(semanticsLabel: s.loading),
              ),
              error: (_, _) => Center(
                child: FilledButton(
                  onPressed: () => ref.invalidate(documentProvider(documentId)),
                  child: Text(s.retry),
                ),
              ),
              data: (document) => document == null
                  ? Center(child: Text(s.documentMissing))
                  : EditorForm(document: document, initialPage: initialPage),
            ),
      ),
    );
  }
}
