import 'package:intl/intl.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../data/compression_models.dart';

String compressionChoiceLabel(AppLocalizations s, CompressionChoice choice) =>
    switch (choice) {
      CompressionChoice.high => s.qualityHigh,
      CompressionChoice.medium => s.qualityMedium,
      CompressionChoice.low => s.qualityLow,
      CompressionChoice.kb100 => s.sizeKilobytes(
        NumberFormat.decimalPattern(s.localeName).format(100),
      ),
      CompressionChoice.kb200 => s.sizeKilobytes(
        NumberFormat.decimalPattern(s.localeName).format(200),
      ),
      CompressionChoice.kb500 => s.sizeKilobytes(
        NumberFormat.decimalPattern(s.localeName).format(500),
      ),
      CompressionChoice.mb1 => s.sizeMegabytes(
        NumberFormat.decimalPattern(s.localeName).format(1),
      ),
    };

String compressionFailureMessage(
  AppLocalizations s,
  CompressionFailure failure,
) => switch (failure) {
  CompressionFailure.missingPages => s.compressionMissingPages,
  CompressionFailure.corruptPage => s.compressionCorruptPage,
  CompressionFailure.pageTooLarge => s.compressionPageTooLarge,
  CompressionFailure.noSpace => s.compressionNoSpace,
  _ => s.compressionFailed,
};

String compressionFileSize(AppLocalizations s, int bytes) {
  final number = NumberFormat('0.##', s.localeName);
  return bytes < 1024 * 1024
      ? s.sizeKilobytes(number.format(bytes / 1024))
      : s.sizeMegabytes(number.format(bytes / (1024 * 1024)));
}
