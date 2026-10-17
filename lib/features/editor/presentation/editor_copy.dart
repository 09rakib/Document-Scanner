import '../../../l10n/generated/app_localizations.dart';
import '../data/page_edit.dart';

String editFailureMessage(AppLocalizations s, Object? error) {
  final failure = error is EditException ? error.failure : error;
  return switch (failure) {
    EditFailure.missingPages => s.editMissingPages,
    EditFailure.corrupt => s.scanCorruptOutput,
    EditFailure.tooLarge => s.compressionPageTooLarge,
    EditFailure.noSpace => s.scanNoSpace,
    _ => s.editFailed,
  };
}
