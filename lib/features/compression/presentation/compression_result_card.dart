import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../data/compression_models.dart';
import 'compression_copy.dart';

class CompressionResultCard extends StatelessWidget {
  const CompressionResultCard({
    super.key,
    required this.result,
    required this.originalBytes,
  });
  final CompressionResult result;
  final int originalBytes;
  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final smaller = result.fileSizeBytes < originalBytes;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${s.compressionBefore}: ${compressionFileSize(s, originalBytes)}',
            ),
            Text(
              '${s.compressionAfter}: ${compressionFileSize(s, result.fileSizeBytes)}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (smaller)
              Text(
                s.compressionReduction(
                  NumberFormat(
                    '0.#',
                    s.localeName,
                  ).format((1 - result.fileSizeBytes / originalBytes) * 100),
                ),
              ),
            if (!result.targetMet)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(s.compressionTargetMissed),
              ),
            if (!smaller)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(s.compressionNotSmaller),
              ),
            const SizedBox(height: 12),
            Text(s.compressionPreview),
            SizedBox(
              height: 220,
              child: InteractiveViewer(
                minScale: 1,
                maxScale: 5,
                child: Center(
                  child: Image.file(
                    File(result.pages.first),
                    cacheWidth: 1200,
                    fit: BoxFit.contain,
                    semanticLabel: s.compressionPreview,
                    errorBuilder: (_, _, _) => Text(s.previewFailed),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
