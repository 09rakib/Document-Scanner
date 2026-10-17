import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../documents/data/scanned_document.dart';
import '../../documents/providers/document_providers.dart';
import '../data/compression_models.dart';
import '../providers/compression_providers.dart';
import 'compression_copy.dart';
import '../../settings/providers/settings_providers.dart';
import 'compression_progress_indicator.dart';
import 'compression_result_card.dart';

class CompressionForm extends ConsumerStatefulWidget {
  const CompressionForm({super.key, required this.document});
  final ScannedDocument document;
  @override
  ConsumerState<CompressionForm> createState() => _CompressionFormState();
}

class _CompressionFormState extends ConsumerState<CompressionForm> {
  CompressionChoice _choice = CompressionChoice.medium;
  @override
  void initState() {
    super.initState();
    _choice =
        ref.read(settingsProvider).value?.compression ??
        CompressionChoice.medium;
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final state = ref.watch(compressionControllerProvider);
    final controller = ref.read(compressionControllerProvider.notifier);
    final globallyBusy = ref.watch(documentBusyProvider);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          widget.document.name,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        Text(s.compressionOriginalKept),
        const SizedBox(height: 16),
        DropdownButtonFormField<CompressionChoice>(
          initialValue: _choice,
          isExpanded: true,
          decoration: InputDecoration(labelText: s.compressionChoice),
          items: [
            for (final choice in CompressionChoice.values)
              DropdownMenuItem(
                value: choice,
                child: Text(compressionChoiceLabel(s, choice)),
              ),
          ],
          onChanged: state.busy
              ? null
              : (value) {
                  if (value != null) {
                    unawaited(controller.discard());
                    setState(() => _choice = value);
                  }
                },
        ),
        const SizedBox(height: 12),
        Text(s.compressionQualityWarning),
        const SizedBox(height: 8),
        Text(s.compressionTargetNote),
        const SizedBox(height: 16),
        if (state.busy)
          CompressionProgressIndicator(
            state: state,
            onCancel: controller.cancel,
          )
        else
          FilledButton.icon(
            onPressed: globallyBusy
                ? null
                : () => controller.generate(widget.document, _choice),
            icon: const Icon(Icons.compress),
            label: Text(s.compressionStart),
          ),
        if (state.failure != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              compressionFailureMessage(s, state.failure!),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        if (state.result != null && state.session != null) ...[
          CompressionResultCard(
            result: state.result!,
            originalBytes: state.session!.originalBytes,
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed:
                state.busy ||
                    globallyBusy ||
                    state.result!.fileSizeBytes >= state.session!.originalBytes
                ? null
                : () async {
                    final result = await controller.save(
                      s.compressedDocumentName(widget.document.name),
                    );
                    if (result != null && context.mounted) {
                      context.go('/documents/${result.id}');
                    }
                  },
            icon: const Icon(Icons.save_alt),
            label: Text(s.saveCompressedCopy),
          ),
        ],
      ],
    );
  }
}
