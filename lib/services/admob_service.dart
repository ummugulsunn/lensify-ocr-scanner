import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;

/// AdMob servisini yöneten sınıf
/// Pro subscription kontrolü ile birlikte banner reklamları yönetir
class AdMobService {
  static final AdMobService _instance = AdMobService._internal();
  factory AdMobService() => _instance;
  AdMobService._internal();

  static AdMobService get instance => _instance;

  BannerAd? _bannerAd;
  bool _isAdLoaded = false;
  bool _isProUser = false;

  // Real Banner Ad Unit IDs
  static const String _androidBannerAdUnitId = 'ca-app-pub-2163842474515875/1324454214';
  static const String _iosBannerAdUnitId = 'ca-app-pub-2163842474515875/8548338110';

  /// AdMob SDK'yı başlatır
  static Future<void> initialize() async {
    try {
      await MobileAds.instance.initialize();
      developer.log('AdMob SDK initialized successfully');
    } catch (e) {
      developer.log('AdMob initialization failed: $e');
    }
  }

  /// Platform'a uygun Banner Ad Unit ID'sini döndürür
  String get _bannerAdUnitId {
    if (Platform.isAndroid) {
      return _androidBannerAdUnitId;
    } else if (Platform.isIOS) {
      return _iosBannerAdUnitId;
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }

  /// Pro kullanıcı durumunu kontrol eder
  Future<void> checkProStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isProUser = prefs.getBool('is_pro_user') ?? false;
      developer.log('Pro user status: $_isProUser');
    } catch (e) {
      developer.log('Error checking pro status: $e');
      _isProUser = false;
    }
  }

  /// Pro kullanıcı durumunu günceller
  Future<void> updateProStatus(bool isPro) async {
    try {
      _isProUser = isPro;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_pro_user', isPro);
      
      if (isPro) {
        // Pro kullanıcı olduysa reklamları kapat
        disposeBannerAd();
      }
      
      developer.log('Pro status updated to: $isPro');
    } catch (e) {
      developer.log('Error updating pro status: $e');
    }
  }

  /// Banner reklam yükler
  Future<void> loadBannerAd() async {
    // Pro kullanıcıysa reklam yükleme
    if (_isProUser) {
      developer.log('Pro user detected, skipping ad load');
      return;
    }

    // Debug mode check disabled for testing real ads
    // if (kDebugMode) {
    //   developer.log('Debug mode detected, skipping ad load');
    //   return;
    // }

    try {
      // Önceki reklamı temizle
      disposeBannerAd();

      _bannerAd = BannerAd(
        adUnitId: _bannerAdUnitId,
        size: AdSize.banner,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            _isAdLoaded = true;
            developer.log('Banner ad loaded successfully');
          },
          onAdFailedToLoad: (ad, error) {
            _isAdLoaded = false;
            ad.dispose();
            developer.log('Banner ad failed to load: ${error.message}');
          },
          onAdOpened: (ad) {
            developer.log('Banner ad opened');
          },
          onAdClosed: (ad) {
            developer.log('Banner ad closed');
          },
        ),
      );

      await _bannerAd!.load();
    } catch (e) {
      developer.log('Error loading banner ad: $e');
      _isAdLoaded = false;
    }
  }

  /// Banner reklamın yüklenip yüklenmediğini kontrol eder
  bool get isBannerAdLoaded => _isAdLoaded && _bannerAd != null && !_isProUser;

  /// Banner reklam widget'ını döndürür
  Widget? getBannerAdWidget() {
    if (!isBannerAdLoaded || _isProUser) {
      return null;
    }

    return Container(
      alignment: Alignment.center,
      height: _bannerAd!.size.height.toDouble(),
      width: _bannerAd!.size.width.toDouble(),
      child: AdWidget(ad: _bannerAd!),
    );
  }

  /// Banner reklamı kaldırır
  void disposeBannerAd() {
    try {
      _bannerAd?.dispose();
      _bannerAd = null;
      _isAdLoaded = false;
      developer.log('Banner ad disposed');
    } catch (e) {
      developer.log('Error disposing banner ad: $e');
    }
  }

  /// Pro kullanıcı mı kontrol eder
  bool get isProUser => _isProUser;

  /// Reklamların gösterilip gösterilmeyeceğini kontrol eder
  bool get shouldShowAds => !_isProUser; // Removed debug mode check for production testing

  /// Servis kapanırken temizlik yapar
  void dispose() {
    disposeBannerAd();
  }
} 