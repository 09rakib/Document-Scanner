// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Bengali Bangla (`bn`).
class AppLocalizationsBn extends AppLocalizations {
  AppLocalizationsBn([String locale = 'bn']) : super(locale);

  @override
  String get appName => 'ডকস্ক্যান';

  @override
  String get documentsTitle => 'নথি';

  @override
  String get emptyDocumentsTitle => 'আপনার প্রথম নথি স্ক্যান করুন';

  @override
  String get emptyDocumentsBody => 'আপনার সংরক্ষিত পিডিএফগুলো এখানে দেখা যাবে।';

  @override
  String get scan => 'স্ক্যান';

  @override
  String get pageNotFound => 'এই পৃষ্ঠাটি খুঁজে পাওয়া যায়নি।';

  @override
  String get backToDocuments => 'নথিতে ফিরে যান';

  @override
  String get largePdfPreview =>
      'পিডিএফ সংরক্ষিত আছে। মেমোরির ব্যবহার কম রাখতে স্ক্যান করা পৃষ্ঠাগুলো দেখানো হচ্ছে।';

  @override
  String pageCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count পৃষ্ঠা',
      one: '১ পৃষ্ঠা',
    );
    return '$_temp0';
  }

  @override
  String get documentTitle => 'নথি';

  @override
  String get scanSaveFailed =>
      'স্ক্যান সংরক্ষণ করা যায়নি। খালি জায়গা পরীক্ষা করে আবার চেষ্টা করুন।';

  @override
  String get scanInProgress => 'স্ক্যান / সংরক্ষণ হচ্ছে…';

  @override
  String get previousPage => 'আগের পৃষ্ঠা';

  @override
  String get documentsLoadFailed => 'সংরক্ষিত নথি লোড করা যায়নি।';

  @override
  String get scanPermissionDenied =>
      'স্ক্যানার ক্যামেরা বা নির্বাচিত ছবিতে প্রবেশ করতে পারেনি। ডিভাইসের সেটিংসে অনুমতি পরীক্ষা করে আবার চেষ্টা করুন।';

  @override
  String get scanUnsupported =>
      'এই ডিভাইসে নথি স্ক্যান করা সম্ভব নয়। অ্যান্ড্রয়েড ৭ বা পরবর্তী সংস্করণ এবং অন্তত ১.৭ জিবি মেমোরি প্রয়োজন।';

  @override
  String get scanServicesUnavailable =>
      'গুগল প্লে সার্ভিস চালু বা আপডেট করে আবার স্ক্যান করুন।';

  @override
  String get loading => 'লোড হচ্ছে';

  @override
  String get previewFailed =>
      'পিডিএফ খোলা যায়নি। এটি অনুপস্থিত বা ক্ষতিগ্রস্ত হতে পারে।';

  @override
  String get scanCorruptOutput =>
      'স্ক্যানার অসম্পূর্ণ বা পড়ার অযোগ্য নথি দিয়েছে। আবার স্ক্যান করুন।';

  @override
  String defaultDocumentName(String date) {
    return 'স্ক্যান $date';
  }

  @override
  String get documentMissing => 'এই নথিটি খুঁজে পাওয়া যায়নি।';

  @override
  String get scanUnavailable =>
      'স্ক্যানার চালু করা যায়নি। গুগল প্লে সার্ভিস আপডেট করুন এবং প্রথমবার সেটআপের জন্য ইন্টারনেটে যুক্ত হয়ে আবার চেষ্টা করুন।';

  @override
  String get nextPage => 'পরের পৃষ্ঠা';

  @override
  String currentPage(int page, int total) {
    return '$total পৃষ্ঠার মধ্যে $page নম্বর পৃষ্ঠা';
  }

  @override
  String get scanNoSpace =>
      'এই স্ক্যান সংরক্ষণের জন্য পর্যাপ্ত জায়গা নেই। কিছু জায়গা খালি করে আবার স্ক্যান করুন।';

  @override
  String get retry => 'আবার চেষ্টা করুন';

  @override
  String get searchDocuments => 'নথি খুঁজুন';

  @override
  String get clearSearch => 'অনুসন্ধান মুছুন';

  @override
  String get sort => 'সাজান';

  @override
  String get sortNewest => 'নতুন আগে';

  @override
  String get sortOldest => 'পুরোনো আগে';

  @override
  String get sortName => 'নাম';

  @override
  String get noSearchResults => 'কোনো নথি পাওয়া যায়নি';

  @override
  String get selectAll => 'সব ফলাফল নির্বাচন করুন';

  @override
  String get delete => 'মুছুন';

  @override
  String get deleteDocuments => 'নথি মুছবেন?';

  @override
  String get cancel => 'বাতিল';

  @override
  String get rename => 'নাম পরিবর্তন';

  @override
  String get save => 'সংরক্ষণ';

  @override
  String get documentName => 'নথির নাম';

  @override
  String get nameRequired => 'নথির নাম লিখুন';

  @override
  String get share => 'শেয়ার';

  @override
  String get saveToDevice => 'ডিভাইসে সংরক্ষণ';

  @override
  String get documentSaved => 'আপনার নির্বাচিত স্থানে PDF সংরক্ষিত হয়েছে';

  @override
  String get documentActionFailed =>
      'কাজটি সম্পন্ন হয়নি। PDF আছে এবং পর্যাপ্ত খালি জায়গা আছে কি না দেখে আবার চেষ্টা করুন।';

  @override
  String get deleteCleanupPending =>
      'নথি মুছে ফেলা হয়েছে। অ্যাপ আবার খুললে বাকি অস্থায়ী ফাইল পরিষ্কার হবে।';

  @override
  String sizeKilobytes(String size) {
    return '$size কেবি';
  }

  @override
  String sizeMegabytes(String size) {
    return '$size এমবি';
  }

  @override
  String selectedCount(int count) {
    return '$countটি নির্বাচিত';
  }

  @override
  String documentsDeleted(int count) {
    return '$countটি নথি মুছে ফেলা হয়েছে';
  }

  @override
  String deleteConfirmation(int count) {
    return 'নির্বাচিত $countটি নথি ও স্ক্যান করা পৃষ্ঠাগুলো স্থায়ীভাবে মুছবেন? এগুলো আর ফেরত আনা যাবে না।';
  }

  @override
  String get compressPdf => 'PDF ছোট করুন';

  @override
  String get compressionChoice => 'মান অথবা লক্ষ্য সাইজ';

  @override
  String get qualityHigh => 'উচ্চ মান';

  @override
  String get qualityMedium => 'মাঝারি মান';

  @override
  String get qualityLow => 'কম মান';

  @override
  String get compressionStart => 'ছোট করুন';

  @override
  String get compressionWorking => 'ছোট করা হচ্ছে…';

  @override
  String get compressionSaving => 'ছোট করা কপি সংরক্ষণ হচ্ছে…';

  @override
  String get compressionCancelling => 'বাতিল হচ্ছে…';

  @override
  String get compressionOriginalKept =>
      'নতুন কপি সংরক্ষণ হবে। মূল নথি অপরিবর্তিত থাকবে।';

  @override
  String get compressionQualityWarning =>
      'ফাইল ছোট করলে ছোট লেখা ঝাপসা হতে পারে। সংরক্ষণের আগে প্রিভিউ দেখে নিন।';

  @override
  String get compressionTargetNote =>
      '১ কেবি = ১,০২৪ বাইট হিসাবে লক্ষ্য সাইজ নির্ধারিত হয়। কিছু নথি ছোট লক্ষ্য সাইজে আনা সম্ভব নয়।';

  @override
  String get compressionBefore => 'মূল PDF';

  @override
  String get compressionAfter => 'ছোট করা PDF';

  @override
  String get compressionTargetMissed =>
      'লক্ষ্য সাইজ অর্জিত হয়নি। উপলব্ধ মানগুলোর মধ্যে এটি সবচেয়ে ছোট ফলাফল। সংরক্ষণের আগে লেখা পড়া যাচ্ছে কি না দেখুন।';

  @override
  String get compressionNotSmaller =>
      'এই ফলাফল মূল ফাইলের চেয়ে ছোট হয়নি। কম মান বা ছোট লক্ষ্য সাইজ বেছে নিন।';

  @override
  String get saveCompressedCopy => 'নতুন কপি সংরক্ষণ';

  @override
  String compressedDocumentName(String name) {
    return '$name (ছোট কপি)';
  }

  @override
  String get compressionMissingPages =>
      'মূল PDF বা স্ক্যান করা পৃষ্ঠা পাওয়া যাচ্ছে না। নথিটি আবার স্ক্যান করুন।';

  @override
  String get compressionCorruptPage =>
      'স্ক্যান করা একটি পৃষ্ঠা পড়া যাচ্ছে না। নথিটি আবার স্ক্যান করুন।';

  @override
  String get compressionPageTooLarge =>
      'একটি পৃষ্ঠা প্রক্রিয়া করার জন্য যথেষ্ট মেমোরি নেই। কম সাইজে আবার স্ক্যান করুন।';

  @override
  String get compressionNoSpace =>
      'ফাইল ছোট করা বা সংরক্ষণের জন্য যথেষ্ট খালি জায়গা নেই। কিছু জায়গা খালি করে আবার চেষ্টা করুন।';

  @override
  String get compressionFailed =>
      'ফাইল ছোট করা সম্পন্ন হয়নি। মূল নথি নিরাপদ আছে। আবার চেষ্টা করুন।';

  @override
  String get compressionPreview => 'প্রথম পৃষ্ঠার প্রিভিউ';

  @override
  String compressionProgress(int attempt, int attempts, int page, int pages) {
    return 'চেষ্টা $attempt/$attempts · পৃষ্ঠা $page/$pages';
  }

  @override
  String compressionReduction(String percent) {
    return '$percent% ছোট';
  }

  @override
  String get settings => 'সেটিংস';

  @override
  String get language => 'ভাষা';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageBangla => 'বাংলা';

  @override
  String get followSystem => 'ডিভাইস অনুযায়ী';

  @override
  String get theme => 'থিম';

  @override
  String get themeLight => 'হালকা';

  @override
  String get themeDark => 'গাঢ়';

  @override
  String get defaultCompression => 'ডিফল্ট কম্প্রেশন';

  @override
  String get privacyPolicy => 'গোপনীয়তার তথ্য';

  @override
  String get rateApp => 'অ্যাপের রেটিং দিন';

  @override
  String get appVersion => 'অ্যাপের সংস্করণ';

  @override
  String get versionUnavailable => 'সংস্করণ জানা যাচ্ছে না';

  @override
  String get rateUnavailable =>
      'Google Play-এ DocScan প্রকাশের পর রেটিং দেওয়া যাবে।';

  @override
  String get settingsLoadFailed => 'সেটিংস লোড করা যায়নি। আবার চেষ্টা করুন।';

  @override
  String get settingsSaveFailed =>
      'পরিবর্তন সংরক্ষণ করা যায়নি। খালি জায়গা দেখে আবার চেষ্টা করুন।';

  @override
  String get skip => 'এড়িয়ে যান';

  @override
  String get getStarted => 'শুরু করুন';

  @override
  String get introScanTitle => 'কাগজ থেকে PDF';

  @override
  String get introScanBody =>
      'একাধিক পৃষ্ঠা স্ক্যান করুন বা ছবি আনুন। সংরক্ষণের আগে স্ক্যানারে ক্রপ ও পরিষ্কার করুন।';

  @override
  String get introCompressTitle => 'ছোট PDF তৈরি করুন';

  @override
  String get introCompressBody =>
      'ফর্মে আপলোডের জন্য স্ক্যান কম্প্রেস করুন। নতুন কপি সংরক্ষণের আগে আকার ও স্পষ্টতা দেখুন।';

  @override
  String get introPrivateTitle => 'আপনার ফাইল ফোনেই থাকে';

  @override
  String get introPrivateBody =>
      'অ্যাকাউন্ট লাগবে না। আপনার ইচ্ছায় শেয়ার বা এক্সপোর্ট করুন। স্ক্যানারের প্রথম সেটআপে ইন্টারনেট লাগতে পারে।';

  @override
  String get privacyBody =>
      'DocScan — বর্তমান সংস্করণ\n\nস্ক্যানের ছবি, PDF, নথির নাম ও পছন্দ এই ডিভাইসেই সংরক্ষিত থাকে। DocScan নথি আপলোড করে না এবং অ্যাকাউন্ট লাগে না।\n\nস্ক্যানের জন্য Google Play services ও ML Kit document scanner ব্যবহৃত হয়। প্রথমবারের কম্পোনেন্ট ডাউনলোড বা আপডেটে ইন্টারনেট লাগতে পারে; এটি Google Play services পরিচালনা করে। PDF দেখা ও কম্প্রেশন ফোনেই হয়।\n\nশেয়ার ও ডিভাইসে সংরক্ষণ করলে কেবল আপনার নির্বাচিত অ্যাপ বা স্থানে কপি পাঠানো হয়। সেসব অ্যাপ ও স্টোরেজ সেবার নিজস্ব গোপনীয়তা নীতি আছে।\n\nএই উন্নয়ন সংস্করণে Google-এর test ad ID দিয়ে Google Mobile Ads যুক্ত আছে। বিজ্ঞাপন দেখানো, গোপনীয়তার পছন্দ পরিচালনা ও প্রতারণা ঠেকাতে বিজ্ঞাপন এবং consent SDK Google-এর সঙ্গে সংযোগ করে ডিভাইসের শনাক্তকারী, IP address, অ্যাপ ব্যবহারের তথ্য ও diagnostic তথ্য প্রক্রিয়া করতে পারে। DocScan স্ক্যানের ছবি, PDF, নথির নাম বা ফাইলের পথ বিজ্ঞাপনের SDK-তে পাঠায় না। Google UMP-এর consent অবস্থা অনুযায়ী ad request করা হয়। প্রয়োজন হলে Settings থেকে বিজ্ঞাপনের গোপনীয়তা পছন্দ আবার বদলাতে পারবেন। বিজ্ঞাপনে ইন্টারনেট লাগে; বিজ্ঞাপন ছাড়াও স্ক্যান ও সংরক্ষিত ফাইল ব্যবহার করা যাবে। প্রিমিয়াম কেনাকাটায় Google Play Billing ব্যবহার করা হয়। Google পেমেন্ট পরিচালনা করে; DocScan আপনার পেমেন্ট কার্ডের তথ্য পায় না। অফলাইনে বিজ্ঞাপনমুক্ত সুবিধার জন্য signed purchase receipt এই ডিভাইসে ব্যক্তিগতভাবে সংরক্ষিত থাকে এবং সংযোগ থাকলে Google Play-এর সঙ্গে কেনাকাটা যাচাই করা হয়। কেনা ও ফিরিয়ে আনতে Google Play সংযোগ প্রয়োজন। নথির ছবি, PDF বা নাম billing-এ পাঠানো হয় না। এই সংস্করণে আলাদা analytics SDK নেই।\n\nনথির তালিকা থেকে নথি মুছুন। আনইনস্টল করলে অ্যাপের ব্যক্তিগত ডেটা মুছে যায়; এক্সপোর্ট বা শেয়ার করা কপি গন্তব্যে থেকে যায়। ব্যক্তিগত অ্যাপ ডেটার Android backup বন্ধ আছে।\n\nএটি offline তথ্য পেজ, প্রকাশিত Play Store privacy policy নয়। প্রকাশের আগে public policy URL ও ডেভেলপারের যোগাযোগের তথ্য দিতে হবে।';

  @override
  String get advertisement => 'বিজ্ঞাপন';

  @override
  String get adPrivacyChoices => 'বিজ্ঞাপনের গোপনীয়তা পছন্দ';

  @override
  String get adPrivacyFailed =>
      'বিজ্ঞাপনের গোপনীয়তা পছন্দ আপডেট করা যায়নি। স্ক্যান করা যাবে।';

  @override
  String get adPrivacyRetry => 'আবার চেষ্টা করতে চাপুন';

  @override
  String get editPages => 'পৃষ্ঠা এডিট';

  @override
  String get editOriginalKept =>
      'ক্রপ, ঘোরানো বা ফিল্টার দিয়ে নতুন PDF কপি সংরক্ষণ করুন। আগের নথি অক্ষত থাকবে।';

  @override
  String get cropHelp =>
      'প্রতিটি কোণা আলাদাভাবে টানুন। মাঝের হ্যান্ডেল টানলে সেই পাশ, আর ভেতরে টানলে চার কোণা একসঙ্গে সরবে। হ্যান্ডেলে ট্যাপ করে তারপর নতুন জায়গায় ট্যাপ করেও সরাতে পারবেন।';

  @override
  String get cropTool => 'ক্রপ';

  @override
  String get cropShortHelp =>
      'কোণা আলাদাভাবে টানুন। মাঝের হ্যান্ডেল টানলে সেই পাশ সরবে।';

  @override
  String get applyCrop => 'ক্রপ প্রয়োগ করুন';

  @override
  String get cropFullPage => 'পুরো পৃষ্ঠা';

  @override
  String get rotateLeft => 'বামে';

  @override
  String get rotateRight => 'ডানে';

  @override
  String get cropTopLeft => 'ওপরের বাঁ কোণা';

  @override
  String get cropTopRight => 'ওপরের ডান কোণা';

  @override
  String get cropBottomRight => 'নিচের ডান কোণা';

  @override
  String get cropBottomLeft => 'নিচের বাঁ কোণা';

  @override
  String get cropHorizontal => 'অনুভূমিক অবস্থান';

  @override
  String get cropVertical => 'উল্লম্ব অবস্থান';

  @override
  String get cropCornerSelected =>
      'কোণা নির্বাচন করা হয়েছে। বসানোর জন্য ছবিতে ট্যাপ করুন।';

  @override
  String get preciseCrop => 'সূক্ষ্ম ক্রপ';

  @override
  String get cropLeft => 'বাম প্রান্ত';

  @override
  String get cropTop => 'উপরের প্রান্ত';

  @override
  String get cropRight => 'ডান প্রান্ত';

  @override
  String get cropBottom => 'নিচের প্রান্ত';

  @override
  String get pageFilter => 'পৃষ্ঠার ফিল্টার';

  @override
  String get filterOriginal => 'আসল রং';

  @override
  String get filterGrayscale => 'ধূসর';

  @override
  String get filterBlackWhite => 'সাদা-কালো';

  @override
  String get rotatePage => '৯০° ঘোরান';

  @override
  String get resetPage => 'এই পৃষ্ঠা রিসেট';

  @override
  String get movePageEarlier => 'আগে সরান';

  @override
  String get movePageLater => 'পরে সরান';

  @override
  String get removePage => 'পৃষ্ঠা বাদ দিন';

  @override
  String get removePageBody =>
      'এডিট করা কপি থেকে এই পৃষ্ঠা বাদ দেবেন? আগের নথিতে এটি থাকবে।';

  @override
  String get discardEdits => 'এডিট বাতিল';

  @override
  String get discardEditsBody => 'পরিবর্তন সংরক্ষণ না করে বের হবেন?';

  @override
  String get editMissingPages =>
      'সংরক্ষিত পৃষ্ঠার ছবি পাওয়া যাচ্ছে না। এই নথি এডিট করা যাচ্ছে না।';

  @override
  String get editFailed =>
      'এডিট করা নথি সংরক্ষণ করা যায়নি। খালি জায়গা দেখে আবার চেষ্টা করুন।';

  @override
  String get editSaving => 'এডিট করা PDF সংরক্ষণ হচ্ছে…';

  @override
  String get saveEditedCopy => 'এডিট করা কপি সংরক্ষণ';

  @override
  String editedDocumentName(String name) {
    return '$name (এডিট করা)';
  }

  @override
  String get premiumTitle => 'DocScan প্রিমিয়াম';

  @override
  String get premiumRemoveAds => 'বিজ্ঞাপন সরান';

  @override
  String get premiumBody =>
      'একবার কিনলে DocScan-এর ব্যানার, পূর্ণপর্দা ও rewarded বিজ্ঞাপন বন্ধ থাকবে।';

  @override
  String get premiumActive => 'প্রিমিয়াম চালু আছে';

  @override
  String get premiumActiveBody =>
      'আপনার বিজ্ঞাপনমুক্ত আপগ্রেড এই ডিভাইসে সংরক্ষিত আছে।';

  @override
  String premiumBuy(String price) {
    return 'একবার কিনুন · $price';
  }

  @override
  String get restorePurchases => 'আগের কেনাকাটা ফিরিয়ে আনুন';

  @override
  String get premiumRestoreHint =>
      'যে Google Play অ্যাকাউন্ট দিয়ে কিনেছেন সেটি ব্যবহার করুন। কেনা ও ফিরিয়ে আনতে ইন্টারনেট লাগবে। নিশ্চিত প্রিমিয়াম সুবিধা অফলাইনেও থাকবে।';

  @override
  String get premiumNotConfigured =>
      'এই সংস্করণে প্রিমিয়াম কেনা এখনো চালু হয়নি।';

  @override
  String get premiumUnavailable =>
      'Google Play কেনাকাটা পাওয়া যাচ্ছে না। সংযোগ দেখে আবার চেষ্টা করুন।';

  @override
  String get premiumPending =>
      'পেমেন্ট অপেক্ষায় আছে। Google Play নিশ্চিত করলে প্রিমিয়াম চালু হবে।';

  @override
  String get premiumCancelled =>
      'কেনাকাটা বাতিল হয়েছে। প্রস্তুত হলে আবার চেষ্টা করতে পারবেন।';

  @override
  String get premiumPurchaseFailed =>
      'কেনাকাটা শেষ করা যায়নি। আবার কেনার আগে আগের কেনাকাটা ফিরিয়ে আনার চেষ্টা করুন।';

  @override
  String get premiumVerificationFailed =>
      'কেনাকাটা যাচাই করা যায়নি। সংযোগ দেখে আগের কেনাকাটা ফিরিয়ে আনুন।';

  @override
  String get premiumStorageFailed =>
      'প্রিমিয়াম সুবিধা সংরক্ষণ বা লোড করা যায়নি। কিছু জায়গা খালি করে আগের কেনাকাটা ফিরিয়ে আনুন।';

  @override
  String get premiumAcknowledgementPending =>
      'প্রিমিয়াম চালু আছে। Google Play-এ নিশ্চিতকরণ বাকি; সংযোগ দিয়ে আগের কেনাকাটা ফিরিয়ে এনে এটি শেষ করুন।';

  @override
  String get premiumRestored => 'আপনার প্রিমিয়াম কেনাকাটা ফিরে এসেছে।';

  @override
  String get premiumNoneFound =>
      'বর্তমান Google Play অ্যাকাউন্টে কোনো প্রিমিয়াম কেনাকাটা পাওয়া যায়নি।';
}
