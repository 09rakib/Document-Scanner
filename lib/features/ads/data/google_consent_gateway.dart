import 'dart:async';

import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_contracts.dart';

class GoogleConsentGateway implements ConsentGateway {
  @override
  Future<void> update() {
    final done = Completer<void>();
    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () {
        if (!done.isCompleted) done.complete();
      },
      (error) {
        if (!done.isCompleted) done.completeError(error);
      },
    );
    return done.future.timeout(const Duration(seconds: 15));
  }

  @override
  Future<ConsentSnapshot> snapshot() async => ConsentSnapshot(
    canRequest: await ConsentInformation.instance.canRequestAds(),
    required:
        await ConsentInformation.instance.getConsentStatus() ==
        ConsentStatus.required,
    privacyOptionsRequired:
        await ConsentInformation.instance
            .getPrivacyOptionsRequirementStatus() ==
        PrivacyOptionsRequirementStatus.required,
  );
  @override
  Future<ConsentPrompt?> loadRequiredForm() async {
    if (!await ConsentInformation.instance.isConsentFormAvailable()) {
      return null;
    }
    final done = Completer<ConsentPrompt>();
    var expired = false;
    ConsentForm.loadConsentForm(
      (form) {
        if (expired) {
          unawaited(form.dispose().catchError((Object _) {}));
        } else {
          done.complete(_GoogleConsentPrompt(form));
        }
      },
      (error) {
        if (!expired) done.completeError(error);
      },
    );
    try {
      return await done.future.timeout(const Duration(seconds: 15));
    } finally {
      expired = true;
    }
  }

  @override
  Future<void> showPrivacyOptions() {
    final done = Completer<void>();
    void finish(Object? error) {
      if (done.isCompleted) return;
      if (error == null) {
        done.complete();
      } else {
        done.completeError(error);
      }
    }

    // Return the dismissal Future immediately so its error listener is attached
    // before the SDK can deliver a failed-form callback.
    unawaited(
      ConsentForm.showPrivacyOptionsForm(finish).catchError((Object error) {
        finish(error);
      }),
    );
    return done.future;
  }
}

class _GoogleConsentPrompt implements ConsentPrompt {
  _GoogleConsentPrompt(this.form);
  final ConsentForm form;
  @override
  Future<void> show() {
    final done = Completer<void>();
    form.show((error) {
      if (error == null) {
        done.complete();
      } else {
        done.completeError(error);
      }
    });
    return done.future;
  }

  @override
  void dispose() => unawaited(form.dispose().catchError((Object _) {}));
}
