// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'DocScan';

  @override
  String get documentsTitle => 'Documents';

  @override
  String get emptyDocumentsTitle => 'Scan your first document';

  @override
  String get emptyDocumentsBody => 'Your saved PDFs will appear here.';

  @override
  String get scan => 'Scan';

  @override
  String get pageNotFound => 'This page could not be found.';

  @override
  String get backToDocuments => 'Back to documents';

  @override
  String get largePdfPreview =>
      'PDF saved. Showing its scanned pages to keep memory use low.';

  @override
  String pageCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pages',
      one: '1 page',
    );
    return '$_temp0';
  }

  @override
  String get documentTitle => 'Document';

  @override
  String get scanSaveFailed =>
      'The scan could not be saved. Check free storage and try again.';

  @override
  String get scanInProgress => 'Scanning / saving…';

  @override
  String get previousPage => 'Previous page';

  @override
  String get documentsLoadFailed => 'Saved documents could not be loaded.';

  @override
  String get scanPermissionDenied =>
      'The scanner could not access the camera or selected photos. Check its permissions in device settings, then try again.';

  @override
  String get scanUnsupported =>
      'Document scanning is not supported on this device. It requires Android 7 or newer and at least 1.7 GB of device memory.';

  @override
  String get scanServicesUnavailable =>
      'Enable or update Google Play services, then try scanning again.';

  @override
  String get loading => 'Loading';

  @override
  String get previewFailed =>
      'The PDF could not be opened. It may be missing or damaged.';

  @override
  String get scanCorruptOutput =>
      'The scanner returned an incomplete or unreadable document. Please scan it again.';

  @override
  String defaultDocumentName(String date) {
    return 'Scan $date';
  }

  @override
  String get documentMissing => 'This document could not be found.';

  @override
  String get scanUnavailable =>
      'The scanner could not start. Update Google Play services and connect to the internet for its first-time setup, then try again.';

  @override
  String get nextPage => 'Next page';

  @override
  String currentPage(int page, int total) {
    return 'Page $page of $total';
  }

  @override
  String get scanNoSpace =>
      'There is not enough free storage to save this scan. Free some space and scan again.';

  @override
  String get retry => 'Try again';

  @override
  String get searchDocuments => 'Search documents';

  @override
  String get clearSearch => 'Clear search';

  @override
  String get sort => 'Sort';

  @override
  String get sortNewest => 'Newest first';

  @override
  String get sortOldest => 'Oldest first';

  @override
  String get sortName => 'Name';

  @override
  String get noSearchResults => 'No matching documents';

  @override
  String get selectAll => 'Select all results';

  @override
  String get delete => 'Delete';

  @override
  String get deleteDocuments => 'Delete documents?';

  @override
  String get cancel => 'Cancel';

  @override
  String get rename => 'Rename';

  @override
  String get save => 'Save';

  @override
  String get documentName => 'Document name';

  @override
  String get nameRequired => 'Enter a document name';

  @override
  String get share => 'Share';

  @override
  String get saveToDevice => 'Save to device';

  @override
  String get documentSaved => 'PDF saved to your selected location';

  @override
  String get documentActionFailed =>
      'Could not complete this action. Check that the PDF is available and there is enough free storage, then try again.';

  @override
  String get deleteCleanupPending =>
      'Documents deleted. Remaining temporary files will be cleaned up when you reopen the app.';

  @override
  String sizeKilobytes(String size) {
    return '$size KB';
  }

  @override
  String sizeMegabytes(String size) {
    return '$size MB';
  }

  @override
  String selectedCount(int count) {
    return '$count selected';
  }

  @override
  String documentsDeleted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count documents deleted',
      one: 'Document deleted',
    );
    return '$_temp0';
  }

  @override
  String deleteConfirmation(int count) {
    return 'Permanently delete $count selected document(s) and their scanned pages? This cannot be undone.';
  }

  @override
  String get compressPdf => 'Compress PDF';

  @override
  String get compressionChoice => 'Quality or target size';

  @override
  String get qualityHigh => 'High quality';

  @override
  String get qualityMedium => 'Medium quality';

  @override
  String get qualityLow => 'Low quality';

  @override
  String get compressionStart => 'Compress';

  @override
  String get compressionWorking => 'Compressing…';

  @override
  String get compressionSaving => 'Saving compressed copy…';

  @override
  String get compressionCancelling => 'Cancelling…';

  @override
  String get compressionOriginalKept =>
      'Save a new copy. Your original document stays unchanged.';

  @override
  String get compressionQualityWarning =>
      'Smaller files can make fine print blurry. Check the preview before saving.';

  @override
  String get compressionTargetNote =>
      'Target sizes use 1 KB = 1,024 bytes. Some documents cannot fit a small target.';

  @override
  String get compressionBefore => 'Original PDF';

  @override
  String get compressionAfter => 'Compressed PDF';

  @override
  String get compressionTargetMissed =>
      'The target could not be reached. This is the smallest result from the available quality levels. Check legibility before saving.';

  @override
  String get compressionNotSmaller =>
      'This result is not smaller than the original. Try a lower quality or a smaller target.';

  @override
  String get saveCompressedCopy => 'Save new copy';

  @override
  String compressedDocumentName(String name) {
    return '$name (compressed)';
  }

  @override
  String get compressionMissingPages =>
      'The original PDF or its scanned pages are missing. Please scan the document again.';

  @override
  String get compressionCorruptPage =>
      'A scanned page cannot be read. Please scan the document again.';

  @override
  String get compressionPageTooLarge =>
      'A page needs more memory than is available. Scan it again at a smaller size.';

  @override
  String get compressionNoSpace =>
      'Not enough free storage to compress or save. Free some space and try again.';

  @override
  String get compressionFailed =>
      'Compression could not be completed. Your original document is safe. Please try again.';

  @override
  String get compressionPreview => 'First page preview';

  @override
  String compressionProgress(int attempt, int attempts, int page, int pages) {
    return 'Attempt $attempt of $attempts · Page $page of $pages';
  }

  @override
  String compressionReduction(String percent) {
    return '$percent% smaller';
  }

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageBangla => 'বাংলা';

  @override
  String get followSystem => 'Follow device';

  @override
  String get theme => 'Theme';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get defaultCompression => 'Default compression';

  @override
  String get privacyPolicy => 'Privacy information';

  @override
  String get rateApp => 'Rate app';

  @override
  String get appVersion => 'App version';

  @override
  String get versionUnavailable => 'Version unavailable';

  @override
  String get rateUnavailable =>
      'Rating will be available after DocScan is published on Google Play.';

  @override
  String get settingsLoadFailed =>
      'Settings could not be loaded. Please try again.';

  @override
  String get settingsSaveFailed =>
      'The change could not be saved. Check free storage and try again.';

  @override
  String get skip => 'Skip';

  @override
  String get getStarted => 'Get started';

  @override
  String get introScanTitle => 'Paper to PDF';

  @override
  String get introScanBody =>
      'Scan multiple pages or import photos. Crop and clean them in the scanner before saving.';

  @override
  String get introCompressTitle => 'Choose a smaller PDF';

  @override
  String get introCompressBody =>
      'Compress a saved scan for forms and uploads. Check its size and clarity before saving a new copy.';

  @override
  String get introPrivateTitle => 'Your files stay on your phone';

  @override
  String get introPrivateBody =>
      'No account is needed. Share or export only when you choose. The scanner may need internet for its first setup.';

  @override
  String get privacyBody =>
      'DocScan — current version\n\nYour scanned images, PDFs, document names and preferences are stored locally on this device. DocScan does not upload documents or require an account.\n\nScanning uses Google Play services and the ML Kit document scanner. Its initial component download or update may need internet and is managed by Google Play services. PDF preview and compression run on your device.\n\nSharing and Save to device send a copy only to the app or location you select. Those apps and storage providers have their own privacy practices.\n\nThis development version integrates Google Mobile Ads using Google test ad IDs. The advertising and consent SDKs may connect to Google and process device identifiers, IP address, app interactions and diagnostic information to serve ads, manage privacy choices and prevent fraud. No scanned images, PDFs, names or file paths are passed to the advertising SDK by DocScan. Ad requests are gated by Google UMP consent status. Where required, you can revisit Ad privacy choices in Settings. Ads need internet; scanning and saved files remain available without ads. Premium purchases use Google Play Billing. Google handles payment processing; DocScan does not receive your payment card details. A signed purchase receipt is stored privately on this device for offline ad-free access and checked with Google Play when available. Buying and restoring require Google Play connectivity. No document images, PDFs or names are sent to billing. There is no separate analytics SDK in this version.\n\nDelete documents from the Documents list. Uninstalling removes private app data; exported or shared copies remain in their destination. Android backup is disabled for private app data.\n\nThis offline information page is not a published Play Store privacy policy. A public policy URL and developer contact must be provided before release.';

  @override
  String get advertisement => 'Advertisement';

  @override
  String get adPrivacyChoices => 'Ad privacy choices';

  @override
  String get adPrivacyFailed =>
      'Ad privacy choices could not be updated. Scanning is still available.';

  @override
  String get adPrivacyRetry => 'Tap to try again';

  @override
  String get editPages => 'Edit pages';

  @override
  String get editOriginalKept =>
      'Crop, rotate or filter pages and save a new PDF copy. The original document stays unchanged.';

  @override
  String get cropHelp =>
      'Drag each corner independently. Drag a middle handle to move that side, or drag inside to move all four corners. You can also tap a handle, then tap its new position.';

  @override
  String get cropTool => 'Crop';

  @override
  String get cropShortHelp =>
      'Drag corners separately. Middle handles move one side.';

  @override
  String get applyCrop => 'Apply crop';

  @override
  String get cropFullPage => 'Full page';

  @override
  String get rotateLeft => 'Left';

  @override
  String get rotateRight => 'Right';

  @override
  String get cropTopLeft => 'Top-left corner';

  @override
  String get cropTopRight => 'Top-right corner';

  @override
  String get cropBottomRight => 'Bottom-right corner';

  @override
  String get cropBottomLeft => 'Bottom-left corner';

  @override
  String get cropHorizontal => 'Horizontal position';

  @override
  String get cropVertical => 'Vertical position';

  @override
  String get cropCornerSelected =>
      'Corner selected. Tap the image to place it.';

  @override
  String get preciseCrop => 'Precise crop';

  @override
  String get cropLeft => 'Left edge';

  @override
  String get cropTop => 'Top edge';

  @override
  String get cropRight => 'Right edge';

  @override
  String get cropBottom => 'Bottom edge';

  @override
  String get pageFilter => 'Page filter';

  @override
  String get filterOriginal => 'Original color';

  @override
  String get filterGrayscale => 'Grayscale';

  @override
  String get filterBlackWhite => 'Black and white';

  @override
  String get rotatePage => 'Rotate 90°';

  @override
  String get resetPage => 'Reset this page';

  @override
  String get movePageEarlier => 'Move earlier';

  @override
  String get movePageLater => 'Move later';

  @override
  String get removePage => 'Remove page';

  @override
  String get removePageBody =>
      'Remove this page from the edited copy? The original document will keep it.';

  @override
  String get discardEdits => 'Discard edits';

  @override
  String get discardEditsBody => 'Leave without saving your changes?';

  @override
  String get editMissingPages =>
      'The saved page images are missing. This document cannot be edited.';

  @override
  String get editFailed =>
      'The edited document could not be saved. Check free storage and try again.';

  @override
  String get editSaving => 'Saving edited PDF…';

  @override
  String get saveEditedCopy => 'Save edited copy';

  @override
  String editedDocumentName(String name) {
    return '$name (edited)';
  }

  @override
  String get premiumTitle => 'DocScan Premium';

  @override
  String get premiumRemoveAds => 'Remove ads';

  @override
  String get premiumBody =>
      'A one-time purchase removes banner, interstitial and rewarded ads in DocScan.';

  @override
  String get premiumActive => 'Premium is active';

  @override
  String get premiumActiveBody =>
      'Your ad-free upgrade is saved on this device.';

  @override
  String premiumBuy(String price) {
    return 'Buy once · $price';
  }

  @override
  String get restorePurchases => 'Restore purchases';

  @override
  String get premiumRestoreHint =>
      'Use the Google Play account you purchased with. Buying and restoring need an internet connection. Confirmed premium access remains available offline.';

  @override
  String get premiumNotConfigured =>
      'Premium purchases are not available in this version yet.';

  @override
  String get premiumUnavailable =>
      'Google Play purchases are unavailable. Check your connection and try again.';

  @override
  String get premiumPending =>
      'Payment is pending. Premium will activate after Google Play confirms it.';

  @override
  String get premiumCancelled =>
      'Purchase cancelled. You can try again when ready.';

  @override
  String get premiumPurchaseFailed =>
      'The purchase could not be completed. Try Restore purchases before buying again.';

  @override
  String get premiumVerificationFailed =>
      'The purchase could not be verified. Check your connection and restore purchases.';

  @override
  String get premiumStorageFailed =>
      'Premium access could not be saved or loaded. Free some storage and restore purchases.';

  @override
  String get premiumAcknowledgementPending =>
      'Premium is active. Google Play confirmation is still pending; reconnect and restore purchases to finish it.';

  @override
  String get premiumRestored => 'Your premium purchase has been restored.';

  @override
  String get premiumNoneFound =>
      'No premium purchase was found for the current Google Play account.';
}
