import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../documents/providers/document_providers.dart';
import '../providers/compression_providers.dart';
import 'compression_form.dart';

class CompressionScreen extends ConsumerStatefulWidget {
  const CompressionScreen({super.key, required this.documentId});
  final int documentId;
  @override
  ConsumerState<CompressionScreen> createState() => _CompressionScreenState();
}

class _CompressionScreenState extends ConsumerState<CompressionScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(ref.read(compressionControllerProvider.notifier).discard());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final document = ref.watch(documentProvider(widget.documentId));
    final busy = ref.watch(
      compressionControllerProvider.select((value) => value.busy),
    );
    final controller = ref.read(compressionControllerProvider.notifier);
    return PopScope(
      canPop: !busy,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          unawaited(controller.discard());
        } else {
          unawaited(controller.cancel());
        }
      },
      child: Scaffold(
        appBar: AppBar(title: Text(s.compressPdf)),
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
            data: (saved) => saved == null
                ? Center(child: Text(s.documentMissing))
                : CompressionForm(document: saved),
          ),
        ),
      ),
    );
  }
}
