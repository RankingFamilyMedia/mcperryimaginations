import 'dart:async';

import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdsConsentService {
  static bool _canRequestAds = false;
  static bool get canRequestAds => _canRequestAds;

  static Future<void> initialize() async {
    final update = Completer<void>();
    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () => unawaited(_finishConsent(update, showForm: true)),
      (_) => unawaited(_finishConsent(update, showForm: false)),
    );
    try {
      await update.future.timeout(const Duration(seconds: 15));
    } catch (_) {
      _canRequestAds = await ConsentInformation.instance.canRequestAds();
    }
    if (_canRequestAds) await MobileAds.instance.initialize();
  }

  static Future<void> _finishConsent(Completer<void> update,
      {required bool showForm}) async {
    try {
      if (showForm) {
        final form = Completer<void>();
        ConsentForm.loadAndShowConsentFormIfRequired((_) {
          if (!form.isCompleted) form.complete();
        });
        await form.future.timeout(const Duration(seconds: 15));
      }
      _canRequestAds = await ConsentInformation.instance.canRequestAds();
    } catch (_) {
      _canRequestAds = false;
    } finally {
      if (!update.isCompleted) update.complete();
    }
  }

  static Future<bool> privacyOptionsRequired() async =>
      await ConsentInformation.instance.getPrivacyOptionsRequirementStatus() ==
      PrivacyOptionsRequirementStatus.required;

  static Future<void> showPrivacyOptions() async {
    final form = Completer<FormError?>();
    ConsentForm.showPrivacyOptionsForm(form.complete);
    final error = await form.future;
    if (error != null) throw StateError(error.message);
    _canRequestAds = await ConsentInformation.instance.canRequestAds();
  }
}
