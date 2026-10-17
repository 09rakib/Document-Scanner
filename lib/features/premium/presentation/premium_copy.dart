import '../../../l10n/generated/app_localizations.dart';
import '../data/premium_contracts.dart';

String premiumMessage(AppLocalizations s, PremiumMessage message) =>
    switch (message) {
      PremiumMessage.configuration => s.premiumNotConfigured,
      PremiumMessage.pending => s.premiumPending,
      PremiumMessage.cancelled => s.premiumCancelled,
      PremiumMessage.purchaseFailed => s.premiumPurchaseFailed,
      PremiumMessage.verificationFailed => s.premiumVerificationFailed,
      PremiumMessage.storageFailed => s.premiumStorageFailed,
      PremiumMessage.acknowledgementPending => s.premiumAcknowledgementPending,
      PremiumMessage.restored => s.premiumRestored,
      PremiumMessage.noPurchases => s.premiumNoneFound,
      PremiumMessage.unavailable => s.premiumUnavailable,
    };
