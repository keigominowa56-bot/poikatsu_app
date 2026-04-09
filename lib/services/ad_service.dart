import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// AdMob メディエーション対応広告サービス。
/// OS ごとの広告ユニットIDを切り替え、初期化・リワードプリロード・バナーを提供する。
/// デバッグビルド時は Google 公式のテスト広告IDを使用し、Test Ad が確実に表示される。
class AdService {
  AdService._();

  static final AdService instance = AdService._();

  // 本番用（Android / iOS）
  static const String _androidAppId = 'ca-app-pub-9929409261570259~1480285664';
  static const String _androidRewardId = 'ca-app-pub-9929409261570259/9820646390';
  static const String _androidBannerId = 'ca-app-pub-9929409261570259/9654289156';
  static const String _iosAppId = 'ca-app-pub-9929409261570259~6312500436';
  static const String _iosRewardId = 'ca-app-pub-9929409261570259/9470456328';
  static const String _iosBannerId = 'ca-app-pub-9929409261570259/9429618369';

  // Google 公式テスト用広告ユニットID（デバッグ時のみ使用）
  static const String _testAndroidBannerId = 'ca-app-pub-3940256099942544/6300978111';
  static const String _testAndroidRewardId = 'ca-app-pub-3940256099942544/5224354917';
  static const String _testIosBannerId = 'ca-app-pub-3940256099942544/2934735716';
  static const String _testIosRewardId = 'ca-app-pub-3940256099942544/1712485313';

  bool _initialized = false;
  RewardedAd? _rewardedAd;
  bool _isRewardedAdLoading = false;

  bool get isMobile => !kIsWeb && (Platform.isAndroid || Platform.isIOS);
  bool get _useTestAds => kDebugMode;

  String get rewardedAdUnitId {
    if (kIsWeb) return '';
    if (Platform.isIOS) return _useTestAds ? _testIosRewardId : _iosRewardId;
    return _useTestAds ? _testAndroidRewardId : _androidRewardId;
  }

  String get bannerAdUnitId {
    if (kIsWeb) return '';
    if (Platform.isIOS) return _useTestAds ? _testIosBannerId : _iosBannerId;
    return _useTestAds ? _testAndroidBannerId : _androidBannerId;
  }

  /// アプリ起動時に呼ぶ。Mobile Ads SDK の初期化とリワードのプリロードを行う。
  static Future<void> initialize() async {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) return;
    if (instance._initialized) return;
    await MobileAds.instance.initialize();
    instance._initialized = true;
    if (kDebugMode) {
      // ignore: avoid_print
      print('[AdMob] 初期化完了 (${instance._useTestAds ? "テスト広告ID使用" : "本番広告ID使用"})');
    }
    instance._loadRewardedAd();
  }

  void _loadRewardedAd() {
    if (!_initialized || rewardedAdUnitId.isEmpty || _isRewardedAdLoading) return;
    _isRewardedAdLoading = true;
    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          _rewardedAd = ad;
          _isRewardedAdLoading = false;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (Ad ad) {
              ad.dispose();
              _rewardedAd = null;
              _loadRewardedAd();
            },
            onAdFailedToShowFullScreenContent: (Ad ad, AdError error) {
              ad.dispose();
              _rewardedAd = null;
              _loadRewardedAd();
            },
          );
        },
        onAdFailedToLoad: (LoadAdError error) {
          _isRewardedAdLoading = false;
          if (kDebugMode) {
            // ignore: avoid_print
            print('[AdMob] リワード広告のロード失敗: ${error.message} (code: ${error.code})');
          }
        },
      ),
    );
  }

  /// リワード広告がプリロード済みで表示可能かどうか。
  static bool get isRewardAdReady => instance._rewardedAd != null;

  /// リワード広告を表示する。表示できた場合のみ onUserEarnedReward で [onComplete] を呼ぶ。
  /// 表示できない（未ロード・エラー）場合は [onFallback] を呼ぶ（プレースホルダ表示など）。
  /// 広告を閉じたが報酬未獲得の場合は [onDismissed] を呼ぶ。
  static Future<void> showRewardAd({
    required BuildContext context,
    required VoidCallback onComplete,
    required VoidCallback onFallback,
    VoidCallback? onDismissed,
  }) async {
    if (!instance.isMobile) {
      onFallback();
      return;
    }
    final ad = instance._rewardedAd;
    if (ad == null) {
      onFallback();
      return;
    }
    var earned = false;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (Ad ad) {
        if (!earned) onDismissed?.call();
        ad.dispose();
      },
      onAdFailedToShowFullScreenContent: (Ad ad, AdError error) {
        ad.dispose();
        instance._rewardedAd = null;
        instance._loadRewardedAd();
      },
    );
    ad.show(
      onUserEarnedReward: (ad, reward) {
        earned = true;
        onComplete();
      },
    );
    instance._rewardedAd = null;
    instance._loadRewardedAd();
  }

  /// バナー広告を表示する Widget。モバイル以外では [SizedBox.shrink] を返す。
  static Widget getBannerWidget() {
    if (!instance.isMobile || instance.bannerAdUnitId.isEmpty) {
      return const SizedBox.shrink();
    }
    return _BannerAdWidget(adUnitId: instance.bannerAdUnitId);
  }
}

/// バナー広告をロードして表示する StatefulWidget。
class _BannerAdWidget extends StatefulWidget {
  const _BannerAdWidget({required this.adUnitId});

  final String adUnitId;

  @override
  State<_BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<_BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _bannerAd = BannerAd(
      adUnitId: widget.adUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (Ad ad) {
          if (mounted) setState(() => _isLoaded = true);
        },
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          if (kDebugMode) {
            // ignore: avoid_print
            print('[AdMob] バナー広告のロード失敗: ${error.message} (code: ${error.code})');
          }
          ad.dispose();
          _bannerAd = null;
        },
      ),
    );
    _bannerAd!.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded || _bannerAd == null) {
      return const SizedBox.shrink();
    }
    return SizedBox(
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      child: AdWidget(ad: _bannerAd!),
    );
  }
}
