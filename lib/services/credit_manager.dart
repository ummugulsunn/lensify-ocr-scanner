import 'dart:convert';
import 'dart:developer' as developer;
import 'package:shared_preferences/shared_preferences.dart';

/// OCR kredi sistemi yöneticisi
class CreditManager {
  static const String _creditsKey = 'user_credits';
  static const String _lastResetKey = 'last_credit_reset';
  static const String _monthlyResetKey = 'last_monthly_reset';
  static const String _totalUsedKey = 'total_credits_used';
  static const String _subscriptionKey = 'user_subscription';

  // Kredi limitleri
  static const int dailyFreeCredits = 10;
  static const int monthlyFreeCredits = 100;
  static const int proMonthlyCredits = 1000;
  static const int premiumMonthlyCredits = 5000;

  // OCR işlem maliyetleri
  static const int basicOCRCost = 1;
  static const int handwritingOCRCost = 2;
  static const int batchOCRCost = 1; // Her resim için
  static const int premiumOCRCost = 3;

  late SharedPreferences _prefs;
  
  /// Credit manager'ı başlat
  Future<void> initialize() async {
    try {
      developer.log('CreditManager: Starting initialization...');
      _prefs = await SharedPreferences.getInstance();
      developer.log('CreditManager: SharedPreferences initialized');
      await _checkAndResetCredits();
      developer.log('CreditManager: Credits checked and reset');
      developer.log('CreditManager: Initialization completed successfully');
    } catch (e) {
      developer.log('CreditManager: Initialization error: $e');
      rethrow;
    }
  }

  /// Günlük ve aylık kredi sıfırlama kontrolü
  Future<void> _checkAndResetCredits() async {
    final now = DateTime.now();
    
    // Günlük sıfırlama kontrolü
    final lastReset = _getLastResetDate();
    if (lastReset == null || !_isSameDay(lastReset, now)) {
      await _resetDailyCredits();
    }
    
    // Aylık sıfırlama kontrolü
    final lastMonthlyReset = _getLastMonthlyResetDate();
    if (lastMonthlyReset == null || !_isSameMonth(lastMonthlyReset, now)) {
      await _resetMonthlyCredits();
    }
  }

  /// Günlük kredileri sıfırla
  Future<void> _resetDailyCredits() async {
    final subscription = await getSubscriptionType();
    int newCredits = dailyFreeCredits;
    
    // Pro kullanıcılar için günlük bonus
    if (subscription == SubscriptionType.pro) {
      newCredits += 20;
    } else if (subscription == SubscriptionType.premium) {
      newCredits += 50;
    }
    
    await _prefs.setInt(_creditsKey, newCredits);
    await _prefs.setString(_lastResetKey, DateTime.now().toIso8601String());
    
    developer.log('Daily credits reset to $newCredits', name: 'CreditManager');
  }

  /// Aylık kredileri sıfırla
  Future<void> _resetMonthlyCredits() async {
    final subscription = await getSubscriptionType();
    int monthlyCredits = monthlyFreeCredits;
    
    switch (subscription) {
      case SubscriptionType.pro:
        monthlyCredits = proMonthlyCredits;
        break;
      case SubscriptionType.premium:
        monthlyCredits = premiumMonthlyCredits;
        break;
      case SubscriptionType.free:
        monthlyCredits = monthlyFreeCredits;
        break;
    }
    
    // Aylık kredileri mevcut günlük kredilere ekle (döngüyü kırmak için direkt SharedPreferences'tan al)
    final currentCredits = _prefs.getInt(_creditsKey) ?? dailyFreeCredits;
    await _prefs.setInt(_creditsKey, currentCredits + monthlyCredits);
    await _prefs.setString(_monthlyResetKey, DateTime.now().toIso8601String());
    
    developer.log('Monthly credits added: $monthlyCredits', name: 'CreditManager');
  }

  /// Mevcut kredi sayısını al
  Future<int> getCurrentCredits() async {
    await _checkAndResetCredits();
    return _prefs.getInt(_creditsKey) ?? dailyFreeCredits;
  }

  /// Kredi kullan
  Future<bool> useCredits(int amount, {String? operation}) async {
    await _checkAndResetCredits();
    
    // Döngüyü kırmak için direkt SharedPreferences'tan al
    final currentCredits = _prefs.getInt(_creditsKey) ?? dailyFreeCredits;
    if (currentCredits >= amount) {
      final newCredits = currentCredits - amount;
      await _prefs.setInt(_creditsKey, newCredits);
      
      // Toplam kullanılan kredileri güncelle
      final totalUsed = _prefs.getInt(_totalUsedKey) ?? 0;
      await _prefs.setInt(_totalUsedKey, totalUsed + amount);
      
      developer.log('Used $amount credits for $operation. Remaining: $newCredits', 
                   name: 'CreditManager');
      return true;
    }
    
    developer.log('Insufficient credits. Required: $amount, Available: $currentCredits', 
                 name: 'CreditManager');
    return false;
  }

  /// OCR işlemi için kredi kontrolü ve kullanımı
  Future<bool> useOCRCredits({
    required OCRType type,
    int imageCount = 1,
    bool isHandwriting = false,
    bool isPremiumQuality = false,
  }) async {
    int cost = _calculateOCRCost(
      type: type,
      imageCount: imageCount,
      isHandwriting: isHandwriting,
      isPremiumQuality: isPremiumQuality,
    );
    
    return await useCredits(cost, operation: 'OCR ${type.name}');
  }

  /// OCR maliyetini hesapla
  int _calculateOCRCost({
    required OCRType type,
    int imageCount = 1,
    bool isHandwriting = false,
    bool isPremiumQuality = false,
  }) {
    int baseCost = basicOCRCost;
    
    if (isHandwriting) {
      baseCost = handwritingOCRCost;
    } else if (isPremiumQuality) {
      baseCost = premiumOCRCost;
    }
    
    switch (type) {
      case OCRType.single:
        return baseCost;
      case OCRType.batch:
        return baseCost * imageCount;
    }
  }

  /// Kredi ekle (satın alma sonrası)
  Future<void> addCredits(int amount, {String? reason}) async {
    // Döngüyü kırmak için direkt SharedPreferences'tan al
    final currentCredits = _prefs.getInt(_creditsKey) ?? dailyFreeCredits;
    final newCredits = currentCredits + amount;
    await _prefs.setInt(_creditsKey, newCredits);
    
    developer.log('Added $amount credits ($reason). Total: $newCredits', 
                 name: 'CreditManager');
  }

  /// Abonelik tipini al
  Future<SubscriptionType> getSubscriptionType() async {
    final subscriptionData = _prefs.getString(_subscriptionKey);
    if (subscriptionData != null) {
      final data = json.decode(subscriptionData);
      final typeString = data['type'] as String;
      final expiryString = data['expiry'] as String?;
      
      if (expiryString != null) {
        final expiry = DateTime.parse(expiryString);
        if (DateTime.now().isAfter(expiry)) {
          // Abonelik süresi dolmuş, free'ye düşür
          await setSubscriptionType(SubscriptionType.free);
          return SubscriptionType.free;
        }
      }
      
      return SubscriptionType.values.firstWhere(
        (type) => type.name == typeString,
        orElse: () => SubscriptionType.free,
      );
    }
    
    return SubscriptionType.free;
  }

  /// Abonelik tipini ayarla
  Future<void> setSubscriptionType(SubscriptionType type, {DateTime? expiry}) async {
    final data = {
      'type': type.name,
      'expiry': expiry?.toIso8601String(),
      'purchaseDate': DateTime.now().toIso8601String(),
    };
    
    await _prefs.setString(_subscriptionKey, json.encode(data));
    developer.log('Subscription set to ${type.name}', name: 'CreditManager');
  }

  /// Kredi geçmişini al
  Future<CreditStats> getCreditStats() async {
    // Önce reset kontrolü yap
    await _checkAndResetCredits();
    
    // Döngüyü kırmak için direkt SharedPreferences'tan al
    final currentCredits = _prefs.getInt(_creditsKey) ?? dailyFreeCredits;
    final totalUsed = _prefs.getInt(_totalUsedKey) ?? 0;
    final subscription = await getSubscriptionType();
    final lastReset = _getLastResetDate();
    final lastMonthlyReset = _getLastMonthlyResetDate();
    
    return CreditStats(
      currentCredits: currentCredits,
      totalUsed: totalUsed,
      subscription: subscription,
      lastDailyReset: lastReset,
      lastMonthlyReset: lastMonthlyReset,
      dailyLimit: _getDailyLimit(subscription),
      monthlyLimit: _getMonthlyLimit(subscription),
    );
  }

  /// Günlük limit al
  int _getDailyLimit(SubscriptionType subscription) {
    switch (subscription) {
      case SubscriptionType.free:
        return dailyFreeCredits;
      case SubscriptionType.pro:
        return dailyFreeCredits + 20;
      case SubscriptionType.premium:
        return dailyFreeCredits + 50;
    }
  }

  /// Aylık limit al
  int _getMonthlyLimit(SubscriptionType subscription) {
    switch (subscription) {
      case SubscriptionType.free:
        return monthlyFreeCredits;
      case SubscriptionType.pro:
        return proMonthlyCredits;
      case SubscriptionType.premium:
        return premiumMonthlyCredits;
    }
  }

  /// Son sıfırlama tarihini al
  DateTime? _getLastResetDate() {
    final dateString = _prefs.getString(_lastResetKey);
    return dateString != null ? DateTime.parse(dateString) : null;
  }

  /// Son aylık sıfırlama tarihini al
  DateTime? _getLastMonthlyResetDate() {
    final dateString = _prefs.getString(_monthlyResetKey);
    return dateString != null ? DateTime.parse(dateString) : null;
  }

  /// Aynı gün mü kontrol et
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  /// Aynı ay mı kontrol et
  bool _isSameMonth(DateTime date1, DateTime date2) {
    return date1.year == date2.year && date1.month == date2.month;
  }

  /// Kredi satın alma seçeneklerini al
  List<CreditPackage> getCreditPackages() {
    return [
      CreditPackage(
        id: 'credits_50',
        name: '50 Kredi',
        credits: 50,
        price: 2.99,
        description: 'Küçük projeler için ideal',
      ),
      CreditPackage(
        id: 'credits_150',
        name: '150 Kredi',
        credits: 150,
        price: 7.99,
        description: '25% bonus kredi',
        bonus: 30,
      ),
      CreditPackage(
        id: 'credits_500',
        name: '500 Kredi',
        credits: 500,
        price: 19.99,
        description: '50% bonus kredi',
        bonus: 250,
      ),
      CreditPackage(
        id: 'credits_1000',
        name: '1000 Kredi',
        credits: 1000,
        price: 34.99,
        description: '75% bonus kredi',
        bonus: 750,
      ),
    ];
  }

  /// Abonelik paketlerini al
  List<SubscriptionPackage> getSubscriptionPackages() {
    return [
      SubscriptionPackage(
        id: 'pro_monthly',
        name: 'Pro Aylık',
        type: SubscriptionType.pro,
        price: 9.99,
        duration: const Duration(days: 30),
        features: [
          'Aylık 1000 kredi',
          'Günlük +20 bonus kredi',
          'Öncelikli destek',
          'Gelişmiş OCR kalitesi',
        ],
      ),
      SubscriptionPackage(
        id: 'pro_yearly',
        name: 'Pro Yıllık',
        type: SubscriptionType.pro,
        price: 99.99,
        duration: const Duration(days: 365),
        features: [
          'Aylık 1000 kredi',
          'Günlük +20 bonus kredi',
          'Öncelikli destek',
          'Gelişmiş OCR kalitesi',
          '2 ay ücretsiz!',
        ],
      ),
      SubscriptionPackage(
        id: 'premium_monthly',
        name: 'Premium Aylık',
        type: SubscriptionType.premium,
        price: 19.99,
        duration: const Duration(days: 30),
        features: [
          'Aylık 5000 kredi',
          'Günlük +50 bonus kredi',
          'Öncelikli destek',
          'Premium OCR kalitesi',
          'Reklamsız deneyim',
          'Toplu işleme',
        ],
      ),
      SubscriptionPackage(
        id: 'premium_yearly',
        name: 'Premium Yıllık',
        type: SubscriptionType.premium,
        price: 199.99,
        duration: const Duration(days: 365),
        features: [
          'Aylık 5000 kredi',
          'Günlük +50 bonus kredi',
          'Öncelikli destek',
          'Premium OCR kalitesi',
          'Reklamsız deneyim',
          'Toplu işleme',
          '2 ay ücretsiz!',
        ],
      ),
    ];
  }
}

/// OCR işlem tipleri
enum OCRType {
  single,
  batch,
}

/// Abonelik tipleri
enum SubscriptionType {
  free,
  pro,
  premium,
}

/// Kredi istatistikleri
class CreditStats {
  final int currentCredits;
  final int totalUsed;
  final SubscriptionType subscription;
  final DateTime? lastDailyReset;
  final DateTime? lastMonthlyReset;
  final int dailyLimit;
  final int monthlyLimit;

  CreditStats({
    required this.currentCredits,
    required this.totalUsed,
    required this.subscription,
    this.lastDailyReset,
    this.lastMonthlyReset,
    required this.dailyLimit,
    required this.monthlyLimit,
  });
}

/// Kredi paketi
class CreditPackage {
  final String id;
  final String name;
  final int credits;
  final double price;
  final String description;
  final int bonus;

  CreditPackage({
    required this.id,
    required this.name,
    required this.credits,
    required this.price,
    required this.description,
    this.bonus = 0,
  });

  int get totalCredits => credits + bonus;
}

/// Abonelik paketi
class SubscriptionPackage {
  final String id;
  final String name;
  final SubscriptionType type;
  final double price;
  final Duration duration;
  final List<String> features;

  SubscriptionPackage({
    required this.id,
    required this.name,
    required this.type,
    required this.price,
    required this.duration,
    required this.features,
  });
} 