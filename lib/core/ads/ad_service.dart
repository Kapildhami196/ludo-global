import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ad_ids.dart';

enum RewardedAdOutcome {
  earned,
  unavailable,
  dismissedWithoutReward,
}

class AdService extends ChangeNotifier {
  AdService._();

  static final AdService instance = AdService._();

  static const String _adFreeMatchesKey = 'ad_free_matches';

  SharedPreferences? _preferences;
  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;

  bool _initialized = false;
  bool _initializing = false;
  bool _canRequestAds = false;
  bool _privacyOptionsRequired = false;
  bool _interstitialLoading = false;
  bool _rewardedLoading = false;
  int _adFreeMatches = 0;

  bool get isInitialized => _initialized;
  bool get canShowAds => _initialized && _canRequestAds;
  bool get privacyOptionsRequired => _privacyOptionsRequired;
  int get adFreeMatches => _adFreeMatches;

  Future<void> initialize() async {
    if (_initializing || _initialized) {
      return;
    }

    _initializing = true;

    try {
      _preferences = await SharedPreferences.getInstance();
      _adFreeMatches = _preferences?.getInt(_adFreeMatchesKey) ?? 0;

      // Google recommends updating UMP consent information on each launch.
      final bool updated = await _requestConsentInfoUpdate();
      if (updated) {
        await _showConsentFormIfRequired();
      }

      // On network errors, UMP can still allow ads from saved consent.
      await _refreshConsentState();

      if (_canRequestAds) {
        await _startAds();
      }
    } catch (_) {
      // The game remains playable without advertising.
      await _refreshConsentState();
      if (_canRequestAds) {
        await _startAds();
      }
    } finally {
      _initializing = false;
    }
  }

  Future<bool> _requestConsentInfoUpdate() async {
    final Completer<bool> result = Completer<bool>();

    try {
      ConsentInformation.instance.requestConsentInfoUpdate(
        ConsentRequestParameters(),
        () {
          if (!result.isCompleted) {
            result.complete(true);
          }
        },
        (FormError error) {
          if (!result.isCompleted) {
            result.complete(false);
          }
        },
      );

      return await result.future;
    } catch (_) {
      return false;
    }
  }

  Future<void> _showConsentFormIfRequired() async {
    final Completer<void> dismissed = Completer<void>();

    try {
      await ConsentForm.loadAndShowConsentFormIfRequired(
        (FormError? error) {
          if (!dismissed.isCompleted) {
            dismissed.complete();
          }
        },
      );
      await dismissed.future;
    } catch (_) {
      // If the form fails, canRequestAds() decides whether ads are allowed.
    }
  }

  Future<void> _refreshConsentState() async {
    bool allowed = false;
    bool optionsRequired = false;

    try {
      allowed = await ConsentInformation.instance.canRequestAds();
      optionsRequired =
          await ConsentInformation.instance
              .getPrivacyOptionsRequirementStatus() ==
          PrivacyOptionsRequirementStatus.required;
    } catch (_) {
      // Fail closed when the SDK cannot confirm permission.
      allowed = false;
    }

    _canRequestAds = allowed;
    _privacyOptionsRequired = optionsRequired;

    if (!allowed) {
      final InterstitialAd? interstitial = _interstitialAd;
      final RewardedAd? rewarded = _rewardedAd;

      _interstitialAd = null;
      _rewardedAd = null;

      if (interstitial != null) {
        unawaited(interstitial.dispose());
      }
      if (rewarded != null) {
        unawaited(rewarded.dispose());
      }
    }

    notifyListeners();
  }

  Future<void> _startAds() async {
    if (!_canRequestAds) {
      return;
    }

    if (!_initialized) {
      try {
        await MobileAds.instance.initialize();
        _initialized = true;
      } catch (_) {
        return;
      }
    }

    notifyListeners();
    unawaited(_loadInterstitial());
    unawaited(_loadRewarded());
  }

  Future<bool> showPrivacyOptionsForm() async {
    if (!_privacyOptionsRequired) {
      return false;
    }

    final Completer<FormError?> dismissed = Completer<FormError?>();

    try {
      await ConsentForm.showPrivacyOptionsForm((FormError? error) {
        if (!dismissed.isCompleted) {
          dismissed.complete(error);
        }
      });

      final FormError? error = await dismissed.future;
      await _refreshConsentState();

      if (_canRequestAds) {
        await _startAds();
      }

      return error == null;
    } catch (_) {
      await _refreshConsentState();
      return false;
    }
  }

  Future<bool> _mayRequestAds() async {
    if (!canShowAds) {
      return false;
    }

    try {
      return await ConsentInformation.instance.canRequestAds();
    } catch (_) {
      return false;
    }
  }

  Future<RewardedAdOutcome> showRewardedForAdFreeMatch() async {
    if (!await _mayRequestAds()) {
      return RewardedAdOutcome.unavailable;
    }

    final RewardedAd? ad = _rewardedAd;
    if (ad == null) {
      unawaited(_loadRewarded());
      return RewardedAdOutcome.unavailable;
    }

    _rewardedAd = null;

    final Completer<RewardedAdOutcome> completer =
        Completer<RewardedAdOutcome>();
    bool rewardEarned = false;

    void complete(RewardedAdOutcome outcome) {
      if (!completer.isCompleted) {
        completer.complete(outcome);
      }
    }

    ad.fullScreenContentCallback =
        FullScreenContentCallback<RewardedAd>(
      onAdDismissedFullScreenContent: (RewardedAd dismissedAd) {
        dismissedAd.dispose();
        unawaited(_loadRewarded());
        complete(
          rewardEarned
              ? RewardedAdOutcome.earned
              : RewardedAdOutcome.dismissedWithoutReward,
        );
      },
      onAdFailedToShowFullScreenContent: (
        RewardedAd failedAd,
        AdError error,
      ) {
        failedAd.dispose();
        unawaited(_loadRewarded());
        complete(RewardedAdOutcome.unavailable);
      },
    );

    unawaited(
      ad.show(
        onUserEarnedReward: (
          AdWithoutView ad,
          RewardItem reward,
        ) {
          if (rewardEarned) {
            return;
          }

          rewardEarned = true;
          unawaited(_grantAdFreeMatch());
        },
      ),
    );

    return completer.future;
  }

  Future<void> showMatchFinishInterstitialIfNeeded() async {
    if (!await _mayRequestAds()) {
      // Do not spend an ad-free match when no ads may be shown.
      return;
    }

    if (_adFreeMatches > 0) {
      await _consumeAdFreeMatch();
      return;
    }

    final InterstitialAd? ad = _interstitialAd;
    if (ad == null) {
      unawaited(_loadInterstitial());
      return;
    }

    _interstitialAd = null;

    final Completer<void> completer = Completer<void>();

    void complete() {
      if (!completer.isCompleted) {
        completer.complete();
      }
    }

    ad.fullScreenContentCallback =
        FullScreenContentCallback<InterstitialAd>(
      onAdDismissedFullScreenContent: (
        InterstitialAd dismissedAd,
      ) {
        dismissedAd.dispose();
        unawaited(_loadInterstitial());
        complete();
      },
      onAdFailedToShowFullScreenContent: (
        InterstitialAd failedAd,
        AdError error,
      ) {
        failedAd.dispose();
        unawaited(_loadInterstitial());
        complete();
      },
    );

    unawaited(ad.show());
    await completer.future;
  }

  Future<void> _loadInterstitial() async {
    if (!await _mayRequestAds()) {
      return;
    }

    if (_interstitialLoading || _interstitialAd != null || !canShowAds) {
      return;
    }

    _interstitialLoading = true;

    try {
      await InterstitialAd.load(
        adUnitId: AdIds.interstitial,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (InterstitialAd ad) {
            _interstitialLoading = false;
            if (!canShowAds) {
              ad.dispose();
              return;
            }
            _interstitialAd = ad;
          },
          onAdFailedToLoad: (LoadAdError error) {
            _interstitialLoading = false;
            _interstitialAd = null;
          },
        ),
      );
    } catch (_) {
      _interstitialLoading = false;
    }
  }

  Future<void> _loadRewarded() async {
    if (!await _mayRequestAds()) {
      return;
    }

    if (_rewardedLoading || _rewardedAd != null || !canShowAds) {
      return;
    }

    _rewardedLoading = true;

    try {
      await RewardedAd.load(
        adUnitId: AdIds.rewarded,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (RewardedAd ad) {
            _rewardedLoading = false;
            if (!canShowAds) {
              ad.dispose();
              return;
            }
            _rewardedAd = ad;
          },
          onAdFailedToLoad: (LoadAdError error) {
            _rewardedLoading = false;
            _rewardedAd = null;
          },
        ),
      );
    } catch (_) {
      _rewardedLoading = false;
    }
  }

  Future<void> _grantAdFreeMatch() async {
    _adFreeMatches += 1;
    await _preferences?.setInt(_adFreeMatchesKey, _adFreeMatches);
  }

  Future<void> _consumeAdFreeMatch() async {
    if (_adFreeMatches <= 0) {
      return;
    }

    _adFreeMatches -= 1;
    await _preferences?.setInt(_adFreeMatchesKey, _adFreeMatches);
  }
}
