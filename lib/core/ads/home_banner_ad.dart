import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../theme/ludo_global_tokens.dart';
import 'ad_ids.dart';
import 'ad_service.dart';

class HomeBannerAd extends StatefulWidget {
  const HomeBannerAd({super.key});

  @override
  State<HomeBannerAd> createState() => _HomeBannerAdState();
}

class _HomeBannerAdState extends State<HomeBannerAd> {
  BannerAd? _bannerAd;
  bool _loadRequested = false;
  int _availableWidth = 0;
  int _requestEpoch = 0;

  @override
  void initState() {
    super.initState();
    AdService.instance.addListener(_onConsentChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _availableWidth = (
      MediaQuery.sizeOf(context).width - (LudoGlobalSpacing.md * 2)
    ).floor();

    _tryLoadBanner();
  }

  void _onConsentChanged() {
    if (!AdService.instance.canShowAds) {
      _requestEpoch += 1;
      _loadRequested = false;
      _bannerAd?.dispose();
      _bannerAd = null;
    } else {
      _tryLoadBanner();
    }

    if (mounted) {
      setState(() {});
    }
  }

  void _tryLoadBanner() {
    if (_loadRequested ||
        _availableWidth <= 0 ||
        !AdService.instance.canShowAds) {
      return;
    }

    _loadRequested = true;
    final int epoch = _requestEpoch;
    unawaited(_loadBanner(_availableWidth, epoch));
  }

  Future<void> _loadBanner(int width, int epoch) async {
    try {
      final AdSize? size =
          await AdSize.getLargeAnchoredAdaptiveBannerAdSize(width);

      if (size == null ||
          !mounted ||
          epoch != _requestEpoch ||
          !AdService.instance.canShowAds) {
        return;
      }

      // Also check Google's UMP permission before each banner request.
      if (!await ConsentInformation.instance.canRequestAds() ||
          !mounted ||
          epoch != _requestEpoch ||
          !AdService.instance.canShowAds) {
        return;
      }

      final BannerAd ad = BannerAd(
        adUnitId: AdIds.banner,
        request: const AdRequest(),
        size: size,
        listener: BannerAdListener(
          onAdLoaded: (Ad loadedAd) {
            if (!mounted ||
                epoch != _requestEpoch ||
                !AdService.instance.canShowAds) {
              loadedAd.dispose();
              return;
            }

            setState(() {
              _bannerAd = loadedAd as BannerAd;
            });
          },
          onAdFailedToLoad: (Ad failedAd, LoadAdError error) {
            failedAd.dispose();
            _loadRequested = false;
          },
        ),
      );

      await ad.load();
    } catch (_) {
      // If the network or SDK is unavailable, gameplay still works.
      _loadRequested = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!AdService.instance.canShowAds) {
      return const SizedBox.shrink();
    }

    final BannerAd? ad = _bannerAd;

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 54),
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(LudoGlobalRadius.small),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      alignment: Alignment.center,
      child: ad == null
          ? const SizedBox(height: 50)
          : SizedBox(
              width: ad.size.width.toDouble(),
              height: ad.size.height.toDouble(),
              child: AdWidget(ad: ad),
            ),
    );
  }

  @override
  void dispose() {
    AdService.instance.removeListener(_onConsentChanged);
    _requestEpoch += 1;
    _bannerAd?.dispose();
    super.dispose();
  }
}
