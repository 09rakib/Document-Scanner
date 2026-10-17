import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_bn.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('bn'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'DocScan'**
  String get appName;

  /// No description provided for @documentsTitle.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get documentsTitle;

  /// No description provided for @emptyDocumentsTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan your first document'**
  String get emptyDocumentsTitle;

  /// No description provided for @emptyDocumentsBody.
  ///
  /// In en, this message translates to:
  /// **'Your saved PDFs will appear here.'**
  String get emptyDocumentsBody;

  /// No description provided for @scan.
  ///
  /// In en, this message translates to:
  /// **'Scan'**
  String get scan;

  /// No description provided for @pageNotFound.
  ///
  /// In en, this message translates to:
  /// **'This page could not be found.'**
  String get pageNotFound;

  /// No description provided for @backToDocuments.
  ///
  /// In en, this message translates to:
  /// **'Back to documents'**
  String get backToDocuments;

  /// No description provided for @largePdfPreview.
  ///
  /// In en, this message translates to:
  /// **'PDF saved. Showing its scanned pages to keep memory use low.'**
  String get largePdfPreview;

  /// No description provided for @pageCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 page} other{{count} pages}}'**
  String pageCount(int count);

  /// No description provided for @documentTitle.
  ///
  /// In en, this message translates to:
  /// **'Document'**
  String get documentTitle;

  /// No description provided for @scanSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'The scan could not be saved. Check free storage and try again.'**
  String get scanSaveFailed;

  /// No description provided for @scanInProgress.
  ///
  /// In en, this message translates to:
  /// **'Scanning / saving…'**
  String get scanInProgress;

  /// No description provided for @previousPage.
  ///
  /// In en, this message translates to:
  /// **'Previous page'**
  String get previousPage;

  /// No description provided for @documentsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Saved documents could not be loaded.'**
  String get documentsLoadFailed;

  /// No description provided for @scanPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'The scanner could not access the camera or selected photos. Check its permissions in device settings, then try again.'**
  String get scanPermissionDenied;

  /// No description provided for @scanUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Document scanning is not supported on this device. It requires Android 7 or newer and at least 1.7 GB of device memory.'**
  String get scanUnsupported;

  /// No description provided for @scanServicesUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Enable or update Google Play services, then try scanning again.'**
  String get scanServicesUnavailable;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get loading;

  /// No description provided for @previewFailed.
  ///
  /// In en, this message translates to:
  /// **'The PDF could not be opened. It may be missing or damaged.'**
  String get previewFailed;

  /// No description provided for @scanCorruptOutput.
  ///
  /// In en, this message translates to:
  /// **'The scanner returned an incomplete or unreadable document. Please scan it again.'**
  String get scanCorruptOutput;

  /// No description provided for @defaultDocumentName.
  ///
  /// In en, this message translates to:
  /// **'Scan {date}'**
  String defaultDocumentName(String date);

  /// No description provided for @documentMissing.
  ///
  /// In en, this message translates to:
  /// **'This document could not be found.'**
  String get documentMissing;

  /// No description provided for @scanUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The scanner could not start. Update Google Play services and connect to the internet for its first-time setup, then try again.'**
  String get scanUnavailable;

  /// No description provided for @nextPage.
  ///
  /// In en, this message translates to:
  /// **'Next page'**
  String get nextPage;

  /// No description provided for @currentPage.
  ///
  /// In en, this message translates to:
  /// **'Page {page} of {total}'**
  String currentPage(int page, int total);

  /// No description provided for @scanNoSpace.
  ///
  /// In en, this message translates to:
  /// **'There is not enough free storage to save this scan. Free some space and scan again.'**
  String get scanNoSpace;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get retry;

  /// No description provided for @searchDocuments.
  ///
  /// In en, this message translates to:
  /// **'Search documents'**
  String get searchDocuments;

  /// No description provided for @clearSearch.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get clearSearch;

  /// No description provided for @sort.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get sort;

  /// No description provided for @sortNewest.
  ///
  /// In en, this message translates to:
  /// **'Newest first'**
  String get sortNewest;

  /// No description provided for @sortOldest.
  ///
  /// In en, this message translates to:
  /// **'Oldest first'**
  String get sortOldest;

  /// No description provided for @sortName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get sortName;

  /// No description provided for @noSearchResults.
  ///
  /// In en, this message translates to:
  /// **'No matching documents'**
  String get noSearchResults;

  /// No description provided for @selectAll.
  ///
  /// In en, this message translates to:
  /// **'Select all results'**
  String get selectAll;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @deleteDocuments.
  ///
  /// In en, this message translates to:
  /// **'Delete documents?'**
  String get deleteDocuments;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @rename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get rename;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @documentName.
  ///
  /// In en, this message translates to:
  /// **'Document name'**
  String get documentName;

  /// No description provided for @nameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a document name'**
  String get nameRequired;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @saveToDevice.
  ///
  /// In en, this message translates to:
  /// **'Save to device'**
  String get saveToDevice;

  /// No description provided for @documentSaved.
  ///
  /// In en, this message translates to:
  /// **'PDF saved to your selected location'**
  String get documentSaved;

  /// No description provided for @documentActionFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not complete this action. Check that the PDF is available and there is enough free storage, then try again.'**
  String get documentActionFailed;

  /// No description provided for @deleteCleanupPending.
  ///
  /// In en, this message translates to:
  /// **'Documents deleted. Remaining temporary files will be cleaned up when you reopen the app.'**
  String get deleteCleanupPending;

  /// No description provided for @sizeKilobytes.
  ///
  /// In en, this message translates to:
  /// **'{size} KB'**
  String sizeKilobytes(String size);

  /// No description provided for @sizeMegabytes.
  ///
  /// In en, this message translates to:
  /// **'{size} MB'**
  String sizeMegabytes(String size);

  /// No description provided for @selectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String selectedCount(int count);

  /// No description provided for @documentsDeleted.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Document deleted} other{{count} documents deleted}}'**
  String documentsDeleted(int count);

  /// No description provided for @deleteConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Permanently delete {count} selected document(s) and their scanned pages? This cannot be undone.'**
  String deleteConfirmation(int count);

  /// No description provided for @compressPdf.
  ///
  /// In en, this message translates to:
  /// **'Compress PDF'**
  String get compressPdf;

  /// No description provided for @compressionChoice.
  ///
  /// In en, this message translates to:
  /// **'Quality or target size'**
  String get compressionChoice;

  /// No description provided for @qualityHigh.
  ///
  /// In en, this message translates to:
  /// **'High quality'**
  String get qualityHigh;

  /// No description provided for @qualityMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium quality'**
  String get qualityMedium;

  /// No description provided for @qualityLow.
  ///
  /// In en, this message translates to:
  /// **'Low quality'**
  String get qualityLow;

  /// No description provided for @compressionStart.
  ///
  /// In en, this message translates to:
  /// **'Compress'**
  String get compressionStart;

  /// No description provided for @compressionWorking.
  ///
  /// In en, this message translates to:
  /// **'Compressing…'**
  String get compressionWorking;

  /// No description provided for @compressionSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving compressed copy…'**
  String get compressionSaving;

  /// No description provided for @compressionCancelling.
  ///
  /// In en, this message translates to:
  /// **'Cancelling…'**
  String get compressionCancelling;

  /// No description provided for @compressionOriginalKept.
  ///
  /// In en, this message translates to:
  /// **'Save a new copy. Your original document stays unchanged.'**
  String get compressionOriginalKept;

  /// No description provided for @compressionQualityWarning.
  ///
  /// In en, this message translates to:
  /// **'Smaller files can make fine print blurry. Check the preview before saving.'**
  String get compressionQualityWarning;

  /// No description provided for @compressionTargetNote.
  ///
  /// In en, this message translates to:
  /// **'Target sizes use 1 KB = 1,024 bytes. Some documents cannot fit a small target.'**
  String get compressionTargetNote;

  /// No description provided for @compressionBefore.
  ///
  /// In en, this message translates to:
  /// **'Original PDF'**
  String get compressionBefore;

  /// No description provided for @compressionAfter.
  ///
  /// In en, this message translates to:
  /// **'Compressed PDF'**
  String get compressionAfter;

  /// No description provided for @compressionTargetMissed.
  ///
  /// In en, this message translates to:
  /// **'The target could not be reached. This is the smallest result from the available quality levels. Check legibility before saving.'**
  String get compressionTargetMissed;

  /// No description provided for @compressionNotSmaller.
  ///
  /// In en, this message translates to:
  /// **'This result is not smaller than the original. Try a lower quality or a smaller target.'**
  String get compressionNotSmaller;

  /// No description provided for @saveCompressedCopy.
  ///
  /// In en, this message translates to:
  /// **'Save new copy'**
  String get saveCompressedCopy;

  /// No description provided for @compressedDocumentName.
  ///
  /// In en, this message translates to:
  /// **'{name} (compressed)'**
  String compressedDocumentName(String name);

  /// No description provided for @compressionMissingPages.
  ///
  /// In en, this message translates to:
  /// **'The original PDF or its scanned pages are missing. Please scan the document again.'**
  String get compressionMissingPages;

  /// No description provided for @compressionCorruptPage.
  ///
  /// In en, this message translates to:
  /// **'A scanned page cannot be read. Please scan the document again.'**
  String get compressionCorruptPage;

  /// No description provided for @compressionPageTooLarge.
  ///
  /// In en, this message translates to:
  /// **'A page needs more memory than is available. Scan it again at a smaller size.'**
  String get compressionPageTooLarge;

  /// No description provided for @compressionNoSpace.
  ///
  /// In en, this message translates to:
  /// **'Not enough free storage to compress or save. Free some space and try again.'**
  String get compressionNoSpace;

  /// No description provided for @compressionFailed.
  ///
  /// In en, this message translates to:
  /// **'Compression could not be completed. Your original document is safe. Please try again.'**
  String get compressionFailed;

  /// No description provided for @compressionPreview.
  ///
  /// In en, this message translates to:
  /// **'First page preview'**
  String get compressionPreview;

  /// No description provided for @compressionProgress.
  ///
  /// In en, this message translates to:
  /// **'Attempt {attempt} of {attempts} · Page {page} of {pages}'**
  String compressionProgress(int attempt, int attempts, int page, int pages);

  /// No description provided for @compressionReduction.
  ///
  /// In en, this message translates to:
  /// **'{percent}% smaller'**
  String compressionReduction(String percent);

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageBangla.
  ///
  /// In en, this message translates to:
  /// **'বাংলা'**
  String get languageBangla;

  /// No description provided for @followSystem.
  ///
  /// In en, this message translates to:
  /// **'Follow device'**
  String get followSystem;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @defaultCompression.
  ///
  /// In en, this message translates to:
  /// **'Default compression'**
  String get defaultCompression;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy information'**
  String get privacyPolicy;

  /// No description provided for @rateApp.
  ///
  /// In en, this message translates to:
  /// **'Rate app'**
  String get rateApp;

  /// No description provided for @appVersion.
  ///
  /// In en, this message translates to:
  /// **'App version'**
  String get appVersion;

  /// No description provided for @versionUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Version unavailable'**
  String get versionUnavailable;

  /// No description provided for @rateUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Rating will be available after DocScan is published on Google Play.'**
  String get rateUnavailable;

  /// No description provided for @settingsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Settings could not be loaded. Please try again.'**
  String get settingsLoadFailed;

  /// No description provided for @settingsSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'The change could not be saved. Check free storage and try again.'**
  String get settingsSaveFailed;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get getStarted;

  /// No description provided for @introScanTitle.
  ///
  /// In en, this message translates to:
  /// **'Paper to PDF'**
  String get introScanTitle;

  /// No description provided for @introScanBody.
  ///
  /// In en, this message translates to:
  /// **'Scan multiple pages or import photos. Crop and clean them in the scanner before saving.'**
  String get introScanBody;

  /// No description provided for @introCompressTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a smaller PDF'**
  String get introCompressTitle;

  /// No description provided for @introCompressBody.
  ///
  /// In en, this message translates to:
  /// **'Compress a saved scan for forms and uploads. Check its size and clarity before saving a new copy.'**
  String get introCompressBody;

  /// No description provided for @introPrivateTitle.
  ///
  /// In en, this message translates to:
  /// **'Your files stay on your phone'**
  String get introPrivateTitle;

  /// No description provided for @introPrivateBody.
  ///
  /// In en, this message translates to:
  /// **'No account is needed. Share or export only when you choose. The scanner may need internet for its first setup.'**
  String get introPrivateBody;

  /// No description provided for @privacyBody.
  ///
  /// In en, this message translates to:
  /// **'DocScan — current version\n\nYour scanned images, PDFs, document names and preferences are stored locally on this device. DocScan does not upload documents or require an account.\n\nScanning uses Google Play services and the ML Kit document scanner. Its initial component download or update may need internet and is managed by Google Play services. PDF preview and compression run on your device.\n\nSharing and Save to device send a copy only to the app or location you select. Those apps and storage providers have their own privacy practices.\n\nThis development version integrates Google Mobile Ads using Google test ad IDs. The advertising and consent SDKs may connect to Google and process device identifiers, IP address, app interactions and diagnostic information to serve ads, manage privacy choices and prevent fraud. No scanned images, PDFs, names or file paths are passed to the advertising SDK by DocScan. Ad requests are gated by Google UMP consent status. Where required, you can revisit Ad privacy choices in Settings. Ads need internet; scanning and saved files remain available without ads. Premium purchases use Google Play Billing. Google handles payment processing; DocScan does not receive your payment card details. A signed purchase receipt is stored privately on this device for offline ad-free access and checked with Google Play when available. Buying and restoring require Google Play connectivity. No document images, PDFs or names are sent to billing. There is no separate analytics SDK in this version.\n\nDelete documents from the Documents list. Uninstalling removes private app data; exported or shared copies remain in their destination. Android backup is disabled for private app data.\n\nThis offline information page is not a published Play Store privacy policy. A public policy URL and developer contact must be provided before release.'**
  String get privacyBody;

  /// No description provided for @advertisement.
  ///
  /// In en, this message translates to:
  /// **'Advertisement'**
  String get advertisement;

  /// No description provided for @adPrivacyChoices.
  ///
  /// In en, this message translates to:
  /// **'Ad privacy choices'**
  String get adPrivacyChoices;

  /// No description provided for @adPrivacyFailed.
  ///
  /// In en, this message translates to:
  /// **'Ad privacy choices could not be updated. Scanning is still available.'**
  String get adPrivacyFailed;

  /// No description provided for @adPrivacyRetry.
  ///
  /// In en, this message translates to:
  /// **'Tap to try again'**
  String get adPrivacyRetry;

  /// No description provided for @editPages.
  ///
  /// In en, this message translates to:
  /// **'Edit pages'**
  String get editPages;

  /// No description provided for @editOriginalKept.
  ///
  /// In en, this message translates to:
  /// **'Crop, rotate or filter pages and save a new PDF copy. The original document stays unchanged.'**
  String get editOriginalKept;

  /// No description provided for @cropHelp.
  ///
  /// In en, this message translates to:
  /// **'Drag each corner independently. Drag a middle handle to move that side, or drag inside to move all four corners. You can also tap a handle, then tap its new position.'**
  String get cropHelp;

  /// No description provided for @cropTool.
  ///
  /// In en, this message translates to:
  /// **'Crop'**
  String get cropTool;

  /// No description provided for @cropShortHelp.
  ///
  /// In en, this message translates to:
  /// **'Drag corners separately. Middle handles move one side.'**
  String get cropShortHelp;

  /// No description provided for @applyCrop.
  ///
  /// In en, this message translates to:
  /// **'Apply crop'**
  String get applyCrop;

  /// No description provided for @cropFullPage.
  ///
  /// In en, this message translates to:
  /// **'Full page'**
  String get cropFullPage;

  /// No description provided for @rotateLeft.
  ///
  /// In en, this message translates to:
  /// **'Left'**
  String get rotateLeft;

  /// No description provided for @rotateRight.
  ///
  /// In en, this message translates to:
  /// **'Right'**
  String get rotateRight;

  /// No description provided for @cropTopLeft.
  ///
  /// In en, this message translates to:
  /// **'Top-left corner'**
  String get cropTopLeft;

  /// No description provided for @cropTopRight.
  ///
  /// In en, this message translates to:
  /// **'Top-right corner'**
  String get cropTopRight;

  /// No description provided for @cropBottomRight.
  ///
  /// In en, this message translates to:
  /// **'Bottom-right corner'**
  String get cropBottomRight;

  /// No description provided for @cropBottomLeft.
  ///
  /// In en, this message translates to:
  /// **'Bottom-left corner'**
  String get cropBottomLeft;

  /// No description provided for @cropHorizontal.
  ///
  /// In en, this message translates to:
  /// **'Horizontal position'**
  String get cropHorizontal;

  /// No description provided for @cropVertical.
  ///
  /// In en, this message translates to:
  /// **'Vertical position'**
  String get cropVertical;

  /// No description provided for @cropCornerSelected.
  ///
  /// In en, this message translates to:
  /// **'Corner selected. Tap the image to place it.'**
  String get cropCornerSelected;

  /// No description provided for @preciseCrop.
  ///
  /// In en, this message translates to:
  /// **'Precise crop'**
  String get preciseCrop;

  /// No description provided for @cropLeft.
  ///
  /// In en, this message translates to:
  /// **'Left edge'**
  String get cropLeft;

  /// No description provided for @cropTop.
  ///
  /// In en, this message translates to:
  /// **'Top edge'**
  String get cropTop;

  /// No description provided for @cropRight.
  ///
  /// In en, this message translates to:
  /// **'Right edge'**
  String get cropRight;

  /// No description provided for @cropBottom.
  ///
  /// In en, this message translates to:
  /// **'Bottom edge'**
  String get cropBottom;

  /// No description provided for @pageFilter.
  ///
  /// In en, this message translates to:
  /// **'Page filter'**
  String get pageFilter;

  /// No description provided for @filterOriginal.
  ///
  /// In en, this message translates to:
  /// **'Original color'**
  String get filterOriginal;

  /// No description provided for @filterGrayscale.
  ///
  /// In en, this message translates to:
  /// **'Grayscale'**
  String get filterGrayscale;

  /// No description provided for @filterBlackWhite.
  ///
  /// In en, this message translates to:
  /// **'Black and white'**
  String get filterBlackWhite;

  /// No description provided for @rotatePage.
  ///
  /// In en, this message translates to:
  /// **'Rotate 90°'**
  String get rotatePage;

  /// No description provided for @resetPage.
  ///
  /// In en, this message translates to:
  /// **'Reset this page'**
  String get resetPage;

  /// No description provided for @movePageEarlier.
  ///
  /// In en, this message translates to:
  /// **'Move earlier'**
  String get movePageEarlier;

  /// No description provided for @movePageLater.
  ///
  /// In en, this message translates to:
  /// **'Move later'**
  String get movePageLater;

  /// No description provided for @removePage.
  ///
  /// In en, this message translates to:
  /// **'Remove page'**
  String get removePage;

  /// No description provided for @removePageBody.
  ///
  /// In en, this message translates to:
  /// **'Remove this page from the edited copy? The original document will keep it.'**
  String get removePageBody;

  /// No description provided for @discardEdits.
  ///
  /// In en, this message translates to:
  /// **'Discard edits'**
  String get discardEdits;

  /// No description provided for @discardEditsBody.
  ///
  /// In en, this message translates to:
  /// **'Leave without saving your changes?'**
  String get discardEditsBody;

  /// No description provided for @editMissingPages.
  ///
  /// In en, this message translates to:
  /// **'The saved page images are missing. This document cannot be edited.'**
  String get editMissingPages;

  /// No description provided for @editFailed.
  ///
  /// In en, this message translates to:
  /// **'The edited document could not be saved. Check free storage and try again.'**
  String get editFailed;

  /// No description provided for @editSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving edited PDF…'**
  String get editSaving;

  /// No description provided for @saveEditedCopy.
  ///
  /// In en, this message translates to:
  /// **'Save edited copy'**
  String get saveEditedCopy;

  /// No description provided for @editedDocumentName.
  ///
  /// In en, this message translates to:
  /// **'{name} (edited)'**
  String editedDocumentName(String name);

  /// No description provided for @premiumTitle.
  ///
  /// In en, this message translates to:
  /// **'DocScan Premium'**
  String get premiumTitle;

  /// No description provided for @premiumRemoveAds.
  ///
  /// In en, this message translates to:
  /// **'Remove ads'**
  String get premiumRemoveAds;

  /// No description provided for @premiumBody.
  ///
  /// In en, this message translates to:
  /// **'A one-time purchase removes banner, interstitial and rewarded ads in DocScan.'**
  String get premiumBody;

  /// No description provided for @premiumActive.
  ///
  /// In en, this message translates to:
  /// **'Premium is active'**
  String get premiumActive;

  /// No description provided for @premiumActiveBody.
  ///
  /// In en, this message translates to:
  /// **'Your ad-free upgrade is saved on this device.'**
  String get premiumActiveBody;

  /// No description provided for @premiumBuy.
  ///
  /// In en, this message translates to:
  /// **'Buy once · {price}'**
  String premiumBuy(String price);

  /// No description provided for @restorePurchases.
  ///
  /// In en, this message translates to:
  /// **'Restore purchases'**
  String get restorePurchases;

  /// No description provided for @premiumRestoreHint.
  ///
  /// In en, this message translates to:
  /// **'Use the Google Play account you purchased with. Buying and restoring need an internet connection. Confirmed premium access remains available offline.'**
  String get premiumRestoreHint;

  /// No description provided for @premiumNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Premium purchases are not available in this version yet.'**
  String get premiumNotConfigured;

  /// No description provided for @premiumUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Google Play purchases are unavailable. Check your connection and try again.'**
  String get premiumUnavailable;

  /// No description provided for @premiumPending.
  ///
  /// In en, this message translates to:
  /// **'Payment is pending. Premium will activate after Google Play confirms it.'**
  String get premiumPending;

  /// No description provided for @premiumCancelled.
  ///
  /// In en, this message translates to:
  /// **'Purchase cancelled. You can try again when ready.'**
  String get premiumCancelled;

  /// No description provided for @premiumPurchaseFailed.
  ///
  /// In en, this message translates to:
  /// **'The purchase could not be completed. Try Restore purchases before buying again.'**
  String get premiumPurchaseFailed;

  /// No description provided for @premiumVerificationFailed.
  ///
  /// In en, this message translates to:
  /// **'The purchase could not be verified. Check your connection and restore purchases.'**
  String get premiumVerificationFailed;

  /// No description provided for @premiumStorageFailed.
  ///
  /// In en, this message translates to:
  /// **'Premium access could not be saved or loaded. Free some storage and restore purchases.'**
  String get premiumStorageFailed;

  /// No description provided for @premiumAcknowledgementPending.
  ///
  /// In en, this message translates to:
  /// **'Premium is active. Google Play confirmation is still pending; reconnect and restore purchases to finish it.'**
  String get premiumAcknowledgementPending;

  /// No description provided for @premiumRestored.
  ///
  /// In en, this message translates to:
  /// **'Your premium purchase has been restored.'**
  String get premiumRestored;

  /// No description provided for @premiumNoneFound.
  ///
  /// In en, this message translates to:
  /// **'No premium purchase was found for the current Google Play account.'**
  String get premiumNoneFound;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['bn', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'bn':
      return AppLocalizationsBn();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
