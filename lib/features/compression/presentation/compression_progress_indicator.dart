import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../providers/compression_providers.dart';

class CompressionProgressIndicator extends StatelessWidget {
  const CompressionProgressIndicator({
    super.key,
    required this.state,
    required this.onCancel,
  });
  final CompressionState state;
  final VoidCallback onCancel;
  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final progress = state.progress;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LinearProgressIndicator(
          value: state.saving || state.cancelling ? null : progress?.fraction,
          semanticsLabel: s.compressionWorking,
        ),
        const SizedBox(height: 8),
        Text(
          state.saving
              ? s.compressionSaving
              : state.cancelling
              ? s.compressionCancelling
              : s.compressionWorking,
        ),
        if (progress != null && !state.saving)
          Text(
            s.compressionProgress(
              progress.attempt,
              progress.attempts,
              (progress.page + 1).clamp(1, progress.pages),
              progress.pages,
            ),
          ),
        if (!state.saving)
          TextButton(
            onPressed: state.cancelling ? null : onCancel,
            child: Text(s.cancel),
          ),
      ],
    );
  }
}
