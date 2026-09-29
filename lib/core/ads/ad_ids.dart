import 'package:flutter/foundation.dart';

class AdIds {
  AdIds._();

  static const String androidAppId =
      'ca-app-pub-8260098990370186~3638405754';

  static const String _productionBanner =
      'ca-app-pub-8260098990370186/3539915984';
  static const String _productionInterstitial =
      'ca-app-pub-8260098990370186/3232794226';
  static const String _productionRewarded =
      'ca-app-pub-8260098990370186/2083364081';

  static const String _testBanner =
      'ca-app-pub-3940256099942544/9214589741';
  static const String _testInterstitial =
      'ca-app-pub-3940256099942544/1033173712';
  static const String _testRewarded =
      'ca-app-pub-3940256099942544/5224354917';

  static String get banner =>
      kReleaseMode ? _productionBanner : _testBanner;

  static String get interstitial =>
      kReleaseMode ? _productionInterstitial : _testInterstitial;

  static String get rewarded =>
      kReleaseMode ? _productionRewarded : _testRewarded;
}
