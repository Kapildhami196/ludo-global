import 'dart:async';

import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ad_ids.dart';

enum RewardedAdOutcome {
  earned,
  unavailable,
  dismissedWithoutReward,
}

class AdService {
  AdService._();

  static final AdService instance = AdService._();

  static const String _adFreeMatchesKey = 'ad_free_matches';

  SharedPreferences? _preferences;
  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;

  bool _initialized = false;
  bool _interstitialLoading = false;
  bool _rewardedLoading = false;
  int _adFreeMatches = 0;

  bool get isInitialized => _initialized;
  int get adFreeMatches => _adFreeMatches;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    _preferences = await SharedPreferences.getInstance();
    _adFreeMatches =
        _preferences?.getInt(_adFreeMatchesKey) ?? 0;

    try {
      await MobileAds.instance.initialize();
    } catch (_) {
      return;
    }

    _initialized = true;
    _loadInterstitial();
    _loadRewarded();
  }

  Future<RewardedAdOutcome> showRewardedForAdFreeMatch() async {
    if (!_initialized) {
      return RewardedAdOutcome.unavailable;
    }

    final RewardedAd? ad = _rewardedAd;
    if (ad == null) {
      _loadRewarded();
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
        _loadRewarded();
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
        _loadRewarded();
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
    if (_adFreeMatches > 0) {
      await _consumeAdFreeMatch();
      return;
    }

    if (!_initialized) {
      return;
    }

    final InterstitialAd? ad = _interstitialAd;
    if (ad == null) {
      _loadInterstitial();
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
        _loadInterstitial();
        complete();
      },
      onAdFailedToShowFullScreenContent: (
        InterstitialAd failedAd,
        AdError error,
      ) {
        failedAd.dispose();
        _loadInterstitial();
        complete();
      },
    );

    unawaited(ad.show());
    await completer.future;
  }

  void _loadInterstitial() {
    if (!_initialized ||
        _interstitialLoading ||
        _interstitialAd != null) {
      return;
    }

    _interstitialLoading = true;

    InterstitialAd.load(
      adUnitId: AdIds.interstitial,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          _interstitialLoading = false;
          _interstitialAd = ad;
        },
        onAdFailedToLoad: (LoadAdError error) {
          _interstitialLoading = false;
          _interstitialAd = null;
        },
      ),
    );
  }

  void _loadRewarded() {
    if (!_initialized ||
        _rewardedLoading ||
        _rewardedAd != null) {
      return;
    }

    _rewardedLoading = true;

    RewardedAd.load(
      adUnitId: AdIds.rewarded,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          _rewardedLoading = false;
          _rewardedAd = ad;
        },
        onAdFailedToLoad: (LoadAdError error) {
          _rewardedLoading = false;
          _rewardedAd = null;
        },
      ),
    );
  }

  Future<void> _grantAdFreeMatch() async {
    _adFreeMatches += 1;
    await _preferences?.setInt(
      _adFreeMatchesKey,
      _adFreeMatches,
    );
  }

  Future<void> _consumeAdFreeMatch() async {
    if (_adFreeMatches <= 0) {
      return;
    }

    _adFreeMatches -= 1;
    await _preferences?.setInt(
      _adFreeMatchesKey,
      _adFreeMatches,
    );
  }
}
