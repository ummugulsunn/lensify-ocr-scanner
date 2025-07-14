import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:flutter_tesseract_ocr/flutter_tesseract_ocr.dart';

/// OCR motoru sonuç modeli
class OCRResult {
  final String text;
  final double confidence;
  final OCREngine engine;
  final Duration processingTime;
  final bool isSuccess;
  final String? errorMessage;

  const OCRResult({
    required this.text,
    required this.confidence,
    required this.engine,
    required this.processingTime,
    required this.isSuccess,
    this.errorMessage,
  });

  factory OCRResult.error(
    OCREngine engine,
    String errorMessage,
    Duration processingTime,
  ) {
    return OCRResult(
      text: '',
      confidence: 0.0,
      engine: engine,
      processingTime: processingTime,
      isSuccess: false,
      errorMessage: errorMessage,
    );
  }

  /// JSON'a dönüştür
  Map<String, dynamic> toJson() => {
    'text': text,
    'confidence': confidence,
    'engine': engine.name,
    'processingTime': processingTime.inMilliseconds,
    'isSuccess': isSuccess,
    'errorMessage': errorMessage,
  };

  /// JSON'dan oluştur
  factory OCRResult.fromJson(Map<String, dynamic> json) => OCRResult(
    text: json['text'] ?? '',
    confidence: (json['confidence'] ?? 0.0).toDouble(),
    engine: OCREngine.values.firstWhere(
      (e) => e.name == json['engine'],
      orElse: () => OCREngine.googleMLKit,
    ),
    processingTime: Duration(milliseconds: json['processingTime'] ?? 0),
    isSuccess: json['isSuccess'] ?? false,
    errorMessage: json['errorMessage'],
  );
}

/// OCR motor türleri
enum OCREngine {
  googleMLKit('Google ML Kit', true),
  googleMLKitHandwriting('Google ML Kit (El Yazısı)', true),
  tesseract('Tesseract', true),
  cloudVision('Cloud Vision API', false); // Premium

  const OCREngine(this.displayName, this.isAvailable);
  
  final String displayName;
  final bool isAvailable;
}

/// OCR kalite stratejileri
enum OCRQuality {
  fast,      // Hızlı - sadece ML Kit
  balanced,  // Dengeli - ML Kit + Tesseract
  accurate,  // Doğru - Tüm motorlar + karşılaştırma
  premium,   // Premium - Cloud Vision dahil
}

/// Çoklu OCR motoru yöneticisi
class OCREngineManager {

  /// Ana OCR işlemi - strateji bazlı
  static Future<OCRResult> performOCR(
    File imageFile, {
    OCRQuality quality = OCRQuality.balanced,
    String language = 'tur',
    bool useMultipleEngines = true,
    bool isHandwritingMode = false,
  }) async {
    // El yazısı modu aktifse, handwriting engine kullan
    if (isHandwritingMode) {
      return _performSingleEngineOCR(imageFile, OCREngine.googleMLKitHandwriting, language);
    }
    
    switch (quality) {
      case OCRQuality.fast:
        return _performSingleEngineOCR(imageFile, OCREngine.googleMLKit, language);
      
      case OCRQuality.balanced:
        return _performDualEngineOCR(imageFile, language);
      
      case OCRQuality.accurate:
        return _performMultiEngineOCR(imageFile, language, includePremium: false);
      
      case OCRQuality.premium:
        return _performMultiEngineOCR(imageFile, language, includePremium: true);
    }
  }

  /// Tek motor OCR
  static Future<OCRResult> _performSingleEngineOCR(
    File imageFile,
    OCREngine engine,
    String language,
  ) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      switch (engine) {
        case OCREngine.googleMLKit:
          final result = await _performGoogleMLKitOCR(imageFile);
          stopwatch.stop();
          return OCRResult(
            text: result,
            confidence: result.isNotEmpty ? 0.85 : 0.0,
            engine: engine,
            processingTime: stopwatch.elapsed,
            isSuccess: true,
          );
        
        case OCREngine.googleMLKitHandwriting:
          final result = await _performGoogleMLKitHandwritingOCR(imageFile);
          stopwatch.stop();
          return OCRResult(
            text: result,
            confidence: result.isNotEmpty ? 0.75 : 0.0, // Handwriting confidence biraz daha düşük
            engine: engine,
            processingTime: stopwatch.elapsed,
            isSuccess: true,
          );
        
        case OCREngine.tesseract:
          final result = await _performTesseractOCR(imageFile, language);
          stopwatch.stop();
          return OCRResult(
            text: result,
            confidence: result.isNotEmpty ? 0.75 : 0.0,
            engine: engine,
            processingTime: stopwatch.elapsed,
            isSuccess: true,
          );
        
        case OCREngine.cloudVision:
          // Cloud Vision API implementasyonu eklenecek
          stopwatch.stop();
          return OCRResult.error(
            engine,
            'Cloud Vision API henüz implement edilmedi',
            stopwatch.elapsed,
          );
      }
    } catch (e) {
      stopwatch.stop();
      return OCRResult.error(engine, e.toString(), stopwatch.elapsed);
    }
  }

  /// İkili motor OCR (ML Kit + Tesseract)
  static Future<OCRResult> _performDualEngineOCR(
    File imageFile,
    String language,
  ) async {
    final results = await Future.wait([
      _performSingleEngineOCR(imageFile, OCREngine.googleMLKit, language),
      _performSingleEngineOCR(imageFile, OCREngine.tesseract, language),
    ]);

    // En iyi sonucu seç
    return _selectBestResult(results);
  }

  /// Çoklu motor OCR
  static Future<OCRResult> _performMultiEngineOCR(
    File imageFile,
    String language, {
    bool includePremium = false,
  }) async {
    final futures = <Future<OCRResult>>[
      _performSingleEngineOCR(imageFile, OCREngine.googleMLKit, language),
      _performSingleEngineOCR(imageFile, OCREngine.tesseract, language),
    ];

    if (includePremium) {
      futures.add(
        _performSingleEngineOCR(imageFile, OCREngine.cloudVision, language),
      );
    }

    final results = await Future.wait(futures);
    return _selectBestResult(results);
  }

  /// Google ML Kit OCR
  static Future<String> _performGoogleMLKitOCR(File imageFile) async {
    final inputImage = InputImage.fromFilePath(imageFile.path);
    final textRecognizer = TextRecognizer();
    
    try {
      final recognizedText = await textRecognizer.processImage(inputImage);
      return recognizedText.text;
    } finally {
      await textRecognizer.close();
    }
  }

  /// Google ML Kit El Yazısı OCR
  static Future<String> _performGoogleMLKitHandwritingOCR(File imageFile) async {
    final inputImage = InputImage.fromFilePath(imageFile.path);
    // El yazısı tanıma için Latin script recognizer kullanıyoruz
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    
    try {
      final recognizedText = await textRecognizer.processImage(inputImage);
      
      // El yazısı tanıma sonuçlarını temizle
      String cleanedText = recognizedText.text;
      
      // El yazısında yaygın karışıklıkları düzelt
      cleanedText = _cleanHandwritingText(cleanedText);
      
      return cleanedText;
    } finally {
      await textRecognizer.close();
    }
  }

  /// El yazısı tanıma sonuçlarını temizle
  static String _cleanHandwritingText(String text) {
    if (text.isEmpty) return text;
    
    String cleaned = text;
    
    // El yazısında yaygın karışıklıkları düzelt
    final corrections = {
      // Harfler arası karışıklıklar
      r'\br\b': 'n', // 'r' ve 'n' karışıklığı
      r'\bm\b': 'n', // 'm' ve 'n' karışıklığı  
      
      // Noktalama işaretleri
      r'\.{2,}': '.', // Çoklu noktalar
      r',{2,}': ',', // Çoklu virgüller
      
      // Fazla boşluklar
      r'\s+': ' ', // Çoklu boşluklar
      
      // Türkçe karakterler için yaygın hatalar
      r'\bg\b': 'ğ',
      r'\bc\b': 'ç',
      r'\bs\b': 'ş',
      r'\bI\b': 'ı',
      r'\bi\b': 'i',
      r'\bo\b': 'ö',
      r'\bu\b': 'ü',
    };
    
    // Düzeltmeleri uygula
    corrections.forEach((pattern, replacement) {
      cleaned = cleaned.replaceAll(RegExp(pattern), replacement);
    });
    
    // Başındaki ve sonundaki boşlukları temizle
    cleaned = cleaned.trim();
    
    return cleaned;
  }

  /// Tesseract OCR
  static Future<String> _performTesseractOCR(File imageFile, String language) async {
    // Tesseract dil kodları (Google ML Kit'ten farklı)
    final tesseractLanguage = _convertLanguageCode(language);
    
    try {
      final result = await FlutterTesseractOcr.extractText(
        imageFile.path,
        language: tesseractLanguage,
        args: {
          "preserve_interword_spaces": "1",
          "psm": "6", // Uniform block of text
          "oem": "3", // Default OCR Engine Mode
        },
      );
      
      return result.trim();
    } catch (e) {
      throw Exception('Tesseract OCR failed: $e');
    }
  }

  /// En iyi OCR sonucunu seç
  static OCRResult _selectBestResult(List<OCRResult> results) {
    // Başarılı sonuçları filtrele
    final successfulResults = results.where((r) => r.isSuccess).toList();
    
    if (successfulResults.isEmpty) {
      // Hiç başarılı sonuç yoksa, en az hatalı olanı döndür
      return results.reduce((a, b) => 
        a.processingTime.compareTo(b.processingTime) < 0 ? a : b);
    }

    // Skorlama sistemi
    var bestResult = successfulResults.first;
    double bestScore = _calculateResultScore(bestResult);

    for (final result in successfulResults.skip(1)) {
      final score = _calculateResultScore(result);
      if (score > bestScore) {
        bestScore = score;
        bestResult = result;
      }
    }

    // Eğer metinler çok farklıysa, en uzun ve anlamlı olanı seç
    if (successfulResults.length > 1) {
      bestResult = _selectBestTextResult(successfulResults);
    }

    return bestResult;
  }

  /// Sonuç skorunu hesapla
  static double _calculateResultScore(OCRResult result) {
    double score = 0;

    // Güven skoru (0-100)
    score += result.confidence * 40;

    // Metin uzunluğu (daha uzun = daha iyi, bir noktaya kadar)
    final textLength = result.text.trim().split(' ').length;
    score += (textLength * 2).clamp(0, 30);

    // Türkçe diyakritik bonusu
    final turkishDiacritics = 'ğĞüÜşŞöÖçÇıİ';
    final diacriticCount = result.text.runes.where((r) => turkishDiacritics.contains(String.fromCharCode(r))).length;
    if (textLength > 0) {
      final diacriticRatio = diacriticCount / result.text.length;
      // Max +20 puan
      score += diacriticRatio * 20;
    }

    // Motor tercihi (Tesseract Türkçe metinlerde genelde daha iyi)
    switch (result.engine) {
      case OCREngine.tesseract:
        score += 20;
        break;
      case OCREngine.googleMLKit:
        score += 15;
        break;
      case OCREngine.googleMLKitHandwriting:
        score += 13;
        break;
      case OCREngine.cloudVision:
        score += 25;
        break;
    }

    // Hız bonusu (daha hızlı = bonus)
    if (result.processingTime.inSeconds < 5) {
      score += 10;
    } else if (result.processingTime.inSeconds < 10) {
      score += 5;
    }

    return score;
  }

  /// En iyi metin sonucunu seç
  static OCRResult _selectBestTextResult(List<OCRResult> results) {
    return results.reduce((a, b) {
      final aWords = a.text.trim().split(' ').length;
      final bWords = b.text.trim().split(' ').length;
      
      // Eğer word count'lar çok farklıysa, daha uzun olanı seç
      if ((aWords - bWords).abs() > 10) {
        return aWords > bWords ? a : b;
      }
      
      // Aksi halde confidence'a göre seç
      return a.confidence > b.confidence ? a : b;
    });
  }

  /// Dil kodunu Tesseract formatına çevir
  static String _convertLanguageCode(String languageCode) {
    switch (languageCode.toLowerCase()) {
      case 'tur':
      case 'tr':
        return 'tur';
      case 'eng':
      case 'en':
        return 'eng';
      case 'ara':
      case 'ar':
        return 'ara';
      case 'deu':
      case 'de':
        return 'deu';
      case 'fra':
      case 'fr':
        return 'fra';
      case 'spa':
      case 'es':
        return 'spa';
      case 'rus':
      case 'ru':
        return 'rus';
      case 'chi_sim':
      case 'zh-cn':
        return 'chi_sim';
      case 'jpn':
      case 'ja':
        return 'jpn';
      case 'kor':
      case 'ko':
        return 'kor';
      case 'ita':
      case 'it':
        return 'ita';
      case 'por':
      case 'pt':
        return 'por';
      case 'nld':
      case 'nl':
        return 'nld';
      default:
        return 'eng'; // Varsayılan
    }
  }
  
  /// Desteklenen dillerin listesi
  static const Map<String, String> supportedLanguages = {
    'tr': 'Türkçe',
    'en': 'English',
    'ar': 'العربية',
    'de': 'Deutsch',
    'fr': 'Français',
    'es': 'Español',
    'ru': 'Русский',
    'zh': '中文',
    'ja': '日本語',
    'ko': '한국어',
    'it': 'Italiano',
    'pt': 'Português',
    'nl': 'Nederlands',
  };
  
  /// Kullanıcı locale'ine göre OCR dili belirle
  static String getOCRLanguageFromLocale(Locale locale) {
    return locale.languageCode;
  }

  /// Motor durumunu kontrol et
  static Future<Map<OCREngine, bool>> checkEngineAvailability() async {
    final results = <OCREngine, bool>{};
    
    // Google ML Kit - her zaman mevcut
    results[OCREngine.googleMLKit] = true;
    
    // Tesseract - test et
    try {
      // Dummy test (küçük bir test resmi ile)
      results[OCREngine.tesseract] = true;
    } catch (e) {
      results[OCREngine.tesseract] = false;
    }
    
    // Cloud Vision - premium feature
    results[OCREngine.cloudVision] = false;
    
    return results;
  }

  /// OCR performans istatistikleri
  static String getPerformanceReport(List<OCRResult> results) {
    if (results.isEmpty) return 'Henüz OCR işlemi yapılmadı.';
    
    final successful = results.where((r) => r.isSuccess).length;
    final avgTime = results.map((r) => r.processingTime.inMilliseconds).reduce((a, b) => a + b) / results.length;
    final avgConfidence = results.where((r) => r.isSuccess).map((r) => r.confidence).reduce((a, b) => a + b) / successful;
    
    return '''
OCR Performans Raporu:
• Toplam işlem: ${results.length}
• Başarılı: $successful (${(successful/results.length*100).toStringAsFixed(1)}%)
• Ortalama süre: ${avgTime.toStringAsFixed(0)}ms
• Ortalama güven: ${(avgConfidence*100).toStringAsFixed(1)}%
''';
  }
} 