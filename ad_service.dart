import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  static final AdService instance = AdService._internal();
  AdService._internal();

  InterstitialAd? _interstitialAd;
  bool _isInterstitialAdReady = false;

  // Google AdMob Test Ad Unit IDs (Safe for testing - never get banned)
  static const String testBannerId = 'ca-app-pub-3940256099942544/6300978111';
  static const String testInterstitialId = 'ca-app-pub-3940256099942544/1033173712';

  // REPLACE THESE WITH YOUR REAL ADMOB IDS BEFORE PLAY STORE RELEASE:
  static const String productionBannerId = 'ca-app-pub-3940256099942544/6300978111';
  static const String productionInterstitialId = 'ca-app-pub-3940256099942544/1033173712';

  static String get bannerAdUnitId =>
      kReleaseMode ? productionBannerId : testBannerId;

  static String get interstitialAdUnitId =>
      kReleaseMode ? productionInterstitialId : testInterstitialId;

  Future<void> initialize() async {
    await MobileAds.instance.initialize();
    loadInterstitialAd();
  }

  void loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialAdReady = true;
          _interstitialAd!.fullScreenContentCallback =
              FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              loadInterstitialAd(); // Preload next ad
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              loadInterstitialAd();
            },
          );
        },
        onAdFailedToLoad: (error) {
          _isInterstitialAdReady = false;
          debugPrint('Interstitial Ad failed to load: $error');
        },
      ),
    );
  }

  void showInterstitialAd({VoidCallback? onComplete}) {
    if (_isInterstitialAdReady && _interstitialAd != null) {
      _interstitialAd!.show();
      _interstitialAd = null;
      _isInterstitialAdReady = false;
    }
    if (onComplete != null) {
      onComplete();
    }
  }
}
