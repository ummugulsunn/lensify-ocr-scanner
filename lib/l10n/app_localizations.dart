import 'package:flutter/material.dart';

/// Lensify OCR Scanner için lokalizasyon sistemi
class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  static const List<Locale> supportedLocales = [
    Locale('tr', 'TR'), // Türkçe
    Locale('en', 'US'), // İngilizce
  ];

  // App Title & Branding
  String get appTitle => _localizedStrings[locale.languageCode]!['app_title']!;
  String get appSubtitle => _localizedStrings[locale.languageCode]!['app_subtitle']!;

  // Main Screen
  String get selectImage => _localizedStrings[locale.languageCode]!['select_image']!;
  String get camera => _localizedStrings[locale.languageCode]!['camera']!;
  String get gallery => _localizedStrings[locale.languageCode]!['gallery']!;
  String get extractText => _localizedStrings[locale.languageCode]!['extract_text']!;
  String get extractingText => _localizedStrings[locale.languageCode]!['extracting_text']!;
  String get textExtracted => _localizedStrings[locale.languageCode]!['text_extracted']!;
  String get noTextFound => _localizedStrings[locale.languageCode]!['no_text_found']!;
  String get credits => _localizedStrings[locale.languageCode]!['credits']!;

  // Mode Selection
  String get singleImage => _localizedStrings[locale.languageCode]!['single_image']!;
  String get multipleImages => _localizedStrings[locale.languageCode]!['multiple_images']!;
  String get batchMode => _localizedStrings[locale.languageCode]!['batch_mode']!;

  // Image Enhancement
  String get imageEnhancement => _localizedStrings[locale.languageCode]!['image_enhancement']!;
  String get basic => _localizedStrings[locale.languageCode]!['basic']!;
  String get advanced => _localizedStrings[locale.languageCode]!['advanced']!;
  String get automatic => _localizedStrings[locale.languageCode]!['automatic']!;
  String get document => _localizedStrings[locale.languageCode]!['document']!;

  // OCR Quality
  String get ocrQuality => _localizedStrings[locale.languageCode]!['ocr_quality']!;
  String get fast => _localizedStrings[locale.languageCode]!['fast']!;
  String get balanced => _localizedStrings[locale.languageCode]!['balanced']!;
  String get accurate => _localizedStrings[locale.languageCode]!['accurate']!;
  String get premium => _localizedStrings[locale.languageCode]!['premium']!;

  // Handwriting Mode
  String get handwritingMode => _localizedStrings[locale.languageCode]!['handwriting_mode']!;
  String get handwritingRecognition => _localizedStrings[locale.languageCode]!['handwriting_recognition']!;

  // Settings
  String get settings => _localizedStrings[locale.languageCode]!['settings']!;
  String get theme => _localizedStrings[locale.languageCode]!['theme']!;
  String get lightTheme => _localizedStrings[locale.languageCode]!['light_theme']!;
  String get darkTheme => _localizedStrings[locale.languageCode]!['dark_theme']!;
  String get systemTheme => _localizedStrings[locale.languageCode]!['system_theme']!;
  String get language => _localizedStrings[locale.languageCode]!['language']!;
  String get turkish => _localizedStrings[locale.languageCode]!['turkish']!;
  String get english => _localizedStrings[locale.languageCode]!['english']!;

  // Credits
  String get creditInfo => _localizedStrings[locale.languageCode]!['credit_info']!;
  String get currentCredits => _localizedStrings[locale.languageCode]!['current_credits']!;
  String get totalUsed => _localizedStrings[locale.languageCode]!['total_used']!;
  String get subscription => _localizedStrings[locale.languageCode]!['subscription']!;
  String get buyCredits => _localizedStrings[locale.languageCode]!['buy_credits']!;
  String get insufficientCredits => _localizedStrings[locale.languageCode]!['insufficient_credits']!;
  String get insufficientCreditsMessage => _localizedStrings[locale.languageCode]!['insufficient_credits_message']!;

  // Subscription Types
  String get freeSubscription => _localizedStrings[locale.languageCode]!['free_subscription']!;
  String get proSubscription => _localizedStrings[locale.languageCode]!['pro_subscription']!;
  String get premiumSubscription => _localizedStrings[locale.languageCode]!['premium_subscription']!;

  // Text Editor
  String get textEditor => _localizedStrings[locale.languageCode]!['text_editor']!;
  String get editText => _localizedStrings[locale.languageCode]!['edit_text']!;
  String get copyText => _localizedStrings[locale.languageCode]!['copy_text']!;
  String get shareText => _localizedStrings[locale.languageCode]!['share_text']!;
  String get exportPdf => _localizedStrings[locale.languageCode]!['export_pdf']!;
  String get exportWord => _localizedStrings[locale.languageCode]!['export_word']!;
  String get save => _localizedStrings[locale.languageCode]!['save']!;
  String get textCopied => _localizedStrings[locale.languageCode]!['text_copied']!;

  // Messages & Errors
  String get success => _localizedStrings[locale.languageCode]!['success']!;
  String get error => _localizedStrings[locale.languageCode]!['error']!;
  String get warning => _localizedStrings[locale.languageCode]!['warning']!;
  String get info => _localizedStrings[locale.languageCode]!['info']!;
  String get ok => _localizedStrings[locale.languageCode]!['ok']!;
  String get cancel => _localizedStrings[locale.languageCode]!['cancel']!;
  String get yes => _localizedStrings[locale.languageCode]!['yes']!;
  String get no => _localizedStrings[locale.languageCode]!['no']!;
  String get close => _localizedStrings[locale.languageCode]!['close']!;

  // Permissions
  String get permissionRequired => _localizedStrings[locale.languageCode]!['permission_required']!;
  String get cameraPermission => _localizedStrings[locale.languageCode]!['camera_permission']!;
  String get storagePermission => _localizedStrings[locale.languageCode]!['storage_permission']!;
  String get goToSettings => _localizedStrings[locale.languageCode]!['go_to_settings']!;

  // OCR Status Messages
  String get ocrCompleted => _localizedStrings[locale.languageCode]!['ocr_completed']!;
  String get batchOcrCompleted => _localizedStrings[locale.languageCode]!['batch_ocr_completed']!;
  String get processingImage => _localizedStrings[locale.languageCode]!['processing_image']!;
  String get optimizingImage => _localizedStrings[locale.languageCode]!['optimizing_image']!;

  // Batch Operations
  String get addMoreImages => _localizedStrings[locale.languageCode]!['add_more_images']!;
  String get clearAll => _localizedStrings[locale.languageCode]!['clear_all']!;
  String get imagesSelected => _localizedStrings[locale.languageCode]!['images_selected']!;
  String get removeImage => _localizedStrings[locale.languageCode]!['remove_image']!;

  // Test & Development
  String get testCredits => _localizedStrings[locale.languageCode]!['test_credits']!;
  String get addTestCredits => _localizedStrings[locale.languageCode]!['add_test_credits']!;
  String get testCreditsAdded => _localizedStrings[locale.languageCode]!['test_credits_added']!;

  // Additional UI Components
  String get back => _localizedStrings[locale.languageCode]!['back']!;
  String get pleaseWait => _localizedStrings[locale.languageCode]!['please_wait']!;
  String get cameraOpening => _localizedStrings[locale.languageCode]!['camera_opening']!;
  String get galleryOpening => _localizedStrings[locale.languageCode]!['gallery_opening']!;
  String get galleryOpeningMulti => _localizedStrings[locale.languageCode]!['gallery_opening_multi']!;
  String get cameraOpeningMulti => _localizedStrings[locale.languageCode]!['camera_opening_multi']!;
  String get textCopiedToClipboard => _localizedStrings[locale.languageCode]!['text_copied_to_clipboard']!;
  String get ocrCompletedSuccess => _localizedStrings[locale.languageCode]!['ocr_completed_success']!;
  String get selectImageInstruction => _localizedStrings[locale.languageCode]!['select_image_instruction']!;
  String get galleryError => _localizedStrings[locale.languageCode]!['gallery_error']!;
  String get galleryErrorRetry => _localizedStrings[locale.languageCode]!['gallery_error_retry']!;
  String get cameraPermissionRequired => _localizedStrings[locale.languageCode]!['camera_permission_required']!;
  String get extractedTextTitle => _localizedStrings[locale.languageCode]!['extracted_text_title']!;
  String get extractingFast => _localizedStrings[locale.languageCode]!['extracting_fast']!;
  String get extractingDualEngine => _localizedStrings[locale.languageCode]!['extracting_dual_engine']!;
  String get extractingHighAccuracy => _localizedStrings[locale.languageCode]!['extracting_high_accuracy']!;
  String get extractingPremium => _localizedStrings[locale.languageCode]!['extracting_premium']!;
  String get batchOcrComplete => _localizedStrings[locale.languageCode]!['batch_ocr_complete']!;
  String get pageNumber => _localizedStrings[locale.languageCode]!['page_number']!;
  String get extractionError => _localizedStrings[locale.languageCode]!['extraction_error']!;
  String get wordExportUnavailable => _localizedStrings[locale.languageCode]!['word_export_unavailable']!;
  String get performanceDataWarning => _localizedStrings[locale.languageCode]!['performance_data_warning']!;
  String get selectCreditPackage => _localizedStrings[locale.languageCode]!['select_credit_package']!;
  String get creditsAddedSuccess => _localizedStrings[locale.languageCode]!['credits_added_success']!;

  // Performance & Statistics
  String get performanceStatistics => _localizedStrings[locale.languageCode]!['performance_statistics']!;
  String get clearData => _localizedStrings[locale.languageCode]!['clear_data']!;
  String get detailedReport => _localizedStrings[locale.languageCode]!['detailed_report']!;
  String get totalOperations => _localizedStrings[locale.languageCode]!['total_operations']!;
  String get successRate => _localizedStrings[locale.languageCode]!['success_rate']!;
  String get averageTime => _localizedStrings[locale.languageCode]!['average_time']!;
  String get fastest => _localizedStrings[locale.languageCode]!['fastest']!;
  String get slowest => _localizedStrings[locale.languageCode]!['slowest']!;
  String get characters => _localizedStrings[locale.languageCode]!['characters']!;
  String get enginePerformance => _localizedStrings[locale.languageCode]!['engine_performance']!;
  String get clearPerformanceData => _localizedStrings[locale.languageCode]!['clear_performance_data']!;
  String get clear => _localizedStrings[locale.languageCode]!['clear']!;
  String get imageOptimizing => _localizedStrings[locale.languageCode]!['image_optimizing']!;
  String get average => _localizedStrings[locale.languageCode]!['average']!;

  // Çeviriler
  static const Map<String, Map<String, String>> _localizedStrings = {
    'tr': {
      // App Title & Branding
      'app_title': 'Lensify',
      'app_subtitle': 'OCR Scanner & PDF',
      
      // Main Screen
      'select_image': 'Resim Seçin',
      'camera': 'Kamera',
      'gallery': 'Galeri',
      'extract_text': 'Metin Çıkar',
      'extracting_text': 'Metin Çıkarılıyor...',
      'text_extracted': 'Metin Çıkarıldı',
      'no_text_found': 'Metin bulunamadı',
      'credits': 'kredi',
      
      // Mode Selection
      'single_image': 'Tek Resim',
      'multiple_images': 'Çoklu Resim',
      'batch_mode': 'Toplu İşlem',
      
      // Image Enhancement
      'image_enhancement': 'Görüntü İyileştirme',
      'basic': 'Temel',
      'advanced': 'Gelişmiş',
      'automatic': 'Otomatik',
      'document': 'Belge',
      
      // OCR Quality
      'ocr_quality': 'OCR Kalitesi',
      'fast': 'Hızlı',
      'balanced': 'Dengeli',
      'accurate': 'Doğru',
      'premium': 'Premium',
      
      // Handwriting Mode
      'handwriting_mode': 'El Yazısı Modu',
      'handwriting_recognition': 'El Yazısı Tanıma',
      
      // Settings
      'settings': 'Ayarlar',
      'theme': 'Tema',
      'light_theme': 'Açık Tema',
      'dark_theme': 'Koyu Tema',
      'system_theme': 'Sistem',
      'language': 'Dil',
      'turkish': 'Türkçe',
      'english': 'İngilizce',
      
      // Credits
      'credit_info': 'Kredi Bilgileri',
      'current_credits': 'Mevcut Kredi',
      'total_used': 'Toplam Kullanılan',
      'subscription': 'Abonelik',
      'buy_credits': 'Kredi Satın Al',
      'insufficient_credits': 'Yetersiz Kredi',
      'insufficient_credits_message': 'Bu işlem için yeterli krediniz bulunmuyor. Kredi satın alarak devam edebilirsiniz.',
      
      // Subscription Types
      'free_subscription': 'Ücretsiz',
      'pro_subscription': 'Pro',
      'premium_subscription': 'Premium',
      
      // Text Editor
      'text_editor': 'Metin Düzenleyici',
      'edit_text': 'Metni Düzenle',
      'copy_text': 'Metni Kopyala',
      'share_text': 'Metni Paylaş',
      'export_pdf': 'PDF Olarak Kaydet',
      'export_word': 'Word Olarak Kaydet',
      'save': 'Kaydet',
      'text_copied': 'Metin kopyalandı',
      
      // Messages & Errors
      'success': 'Başarılı',
      'error': 'Hata',
      'warning': 'Uyarı',
      'info': 'Bilgi',
      'ok': 'Tamam',
      'cancel': 'İptal',
      'yes': 'Evet',
      'no': 'Hayır',
      'close': 'Kapat',
      
      // Permissions
      'permission_required': 'İzin Gerekli',
      'camera_permission': 'Kamera kullanımı için izin gerekli',
      'storage_permission': 'Dosya kaydetmek için depolama izni gerekli',
      'go_to_settings': 'Ayarlara Git',
      
      // OCR Status Messages
      'ocr_completed': 'OCR işlemi başarıyla tamamlandı! 🎉',
      'batch_ocr_completed': 'Toplu OCR tamamlandı! ✨',
      'processing_image': 'Görüntü işleniyor...',
      'optimizing_image': 'Görüntü optimize ediliyor...',
      
      // Batch Operations
      'add_more_images': 'Daha Fazla Resim Ekle',
      'clear_all': 'Tümünü Temizle',
      'images_selected': 'resim seçildi',
      'remove_image': 'Resmi Kaldır',
      
      // Test & Development
      'test_credits': 'Test Kredisi',
      'add_test_credits': 'Test Kredisi Ekle',
      'test_credits_added': '100 kredi hesabınıza eklendi!',
      
      // Additional UI Components
      'back': 'Geri',
      'please_wait': 'Bekleyiniz...',
      'camera_opening': 'Kamera açılıyor...',
      'gallery_opening': 'Galeri açılıyor... (Lütfen bekleyiniz)',
      'gallery_opening_multi': 'Galeri açılıyor... (Çoklu mod)',
      'camera_opening_multi': 'Kamera açılıyor... (Çoklu mod)',
      'text_copied_to_clipboard': 'Metin panoya kopyalandı!',
      'ocr_completed_success': 'OCR tamamlandı',
      'select_image_instruction': 'Kamera veya galeri kullanarak\nmetin içeren bir resim seçin',
      'gallery_error': 'Galeri hatası! Tekrar deneyin.',
      'gallery_error_retry': 'Galeri açılırken sorun oluştu. Lütfen tekrar deneyin.',
      'camera_permission_required': 'Kamera izni gerekli',
      'extracted_text_title': 'Çıkarılan Metin',
      'extracting_fast': 'Metin çıkarılıyor (Hızlı)...',
      'extracting_dual_engine': 'Metin çıkarılıyor (2 motor)...',
      'extracting_high_accuracy': 'Metin çıkarılıyor (Yüksek doğruluk)...',
      'extracting_premium': 'Metin çıkarılıyor (Premium)...',
      'batch_ocr_complete': 'Toplu OCR tamamlandı',
      'page_number': 'Sayfa',
      'extraction_error': 'Hata: Metin çıkarılamadı',
      'word_export_unavailable': 'Word export henüz mevcut değil.',
      'performance_data_warning': 'Tüm performans verileri silinecek. Bu işlem geri alınamaz.',
      'select_credit_package': 'Kredi paketlerini seçin',
      'credits_added_success': 'kredi başarıyla eklendi!',
      
      // Performance & Statistics
      'performance_statistics': 'Performans İstatistikleri',
      'clear_data': 'Verileri Temizle', 
      'detailed_report': 'Detaylı Performans Raporu',
      'total_operations': 'Toplam İşlem',
      'success_rate': 'Başarı Oranı',
      'average_time': 'Ortalama Süre',
      'fastest': 'En Hızlı',
      'slowest': 'En Yavaş',
      'characters': 'karakter',
      'engine_performance': 'Engine Performansı',
      'clear_performance_data': 'Performans Verilerini Temizle',
      'clear': 'Temizle',
      'image_optimizing': 'Görüntü iyileştiriliyor...',
      'average': 'ort.',
    },
    'en': {
      // App Title & Branding
      'app_title': 'Lensify',
      'app_subtitle': 'OCR Scanner & PDF',
      
      // Main Screen
      'select_image': 'Select Image',
      'camera': 'Camera',
      'gallery': 'Gallery',
      'extract_text': 'Extract Text',
      'extracting_text': 'Extracting Text...',
      'text_extracted': 'Text Extracted',
      'no_text_found': 'No text found',
      'credits': 'credits',
      
      // Mode Selection
      'single_image': 'Single Image',
      'multiple_images': 'Multiple Images',
      'batch_mode': 'Batch Mode',
      
      // Image Enhancement
      'image_enhancement': 'Image Enhancement',
      'basic': 'Basic',
      'advanced': 'Advanced',
      'automatic': 'Automatic',
      'document': 'Document',
      
      // OCR Quality
      'ocr_quality': 'OCR Quality',
      'fast': 'Fast',
      'balanced': 'Balanced',
      'accurate': 'Accurate',
      'premium': 'Premium',
      
      // Handwriting Mode
      'handwriting_mode': 'Handwriting Mode',
      'handwriting_recognition': 'Handwriting Recognition',
      
      // Settings
      'settings': 'Settings',
      'theme': 'Theme',
      'light_theme': 'Light Theme',
      'dark_theme': 'Dark Theme',
      'system_theme': 'System',
      'language': 'Language',
      'turkish': 'Turkish',
      'english': 'English',
      
      // Credits
      'credit_info': 'Credit Information',
      'current_credits': 'Current Credits',
      'total_used': 'Total Used',
      'subscription': 'Subscription',
      'buy_credits': 'Buy Credits',
      'insufficient_credits': 'Insufficient Credits',
      'insufficient_credits_message': 'You don\'t have enough credits for this operation. You can continue by purchasing credits.',
      
      // Subscription Types
      'free_subscription': 'Free',
      'pro_subscription': 'Pro',
      'premium_subscription': 'Premium',
      
      // Text Editor
      'text_editor': 'Text Editor',
      'edit_text': 'Edit Text',
      'copy_text': 'Copy Text',
      'share_text': 'Share Text',
      'export_pdf': 'Export as PDF',
      'export_word': 'Export as Word',
      'save': 'Save',
      'text_copied': 'Text copied',
      
      // Messages & Errors
      'success': 'Success',
      'error': 'Error',
      'warning': 'Warning',
      'info': 'Info',
      'ok': 'OK',
      'cancel': 'Cancel',
      'yes': 'Yes',
      'no': 'No',
      'close': 'Close',
      
      // Permissions
      'permission_required': 'Permission Required',
      'camera_permission': 'Camera permission is required',
      'storage_permission': 'Storage permission is required to save files',
      'go_to_settings': 'Go to Settings',
      
      // OCR Status Messages
      'ocr_completed': 'OCR operation completed successfully! 🎉',
      'batch_ocr_completed': 'Batch OCR completed! ✨',
      'processing_image': 'Processing image...',
      'optimizing_image': 'Optimizing image...',
      
      // Batch Operations
      'add_more_images': 'Add More Images',
      'clear_all': 'Clear All',
      'images_selected': 'images selected',
      'remove_image': 'Remove Image',
      
      // Test & Development
      'test_credits': 'Test Credits',
      'add_test_credits': 'Add Test Credits',
      'test_credits_added': '100 credits added to your account!',
      
      // Additional UI Components
      'back': 'Back',
      'please_wait': 'Please wait...',
      'camera_opening': 'Opening camera...',
      'gallery_opening': 'Opening gallery... (Please wait)',
      'gallery_opening_multi': 'Opening gallery... (Multi mode)',
      'camera_opening_multi': 'Opening camera... (Multi mode)',
      'text_copied_to_clipboard': 'Text copied to clipboard!',
      'ocr_completed_success': 'OCR completed',
      'select_image_instruction': 'Use camera or gallery to\nselect an image with text',
      'gallery_error': 'Gallery error! Please try again.',
      'gallery_error_retry': 'Problem opening gallery. Please try again.',
      'camera_permission_required': 'Camera permission required',
      'extracted_text_title': 'Extracted Text',
      'extracting_fast': 'Extracting text (Fast)...',
      'extracting_dual_engine': 'Extracting text (Dual engine)...',
      'extracting_high_accuracy': 'Extracting text (High accuracy)...',
      'extracting_premium': 'Extracting text (Premium)...',
      'batch_ocr_complete': 'Batch OCR completed',
      'page_number': 'Page',
      'extraction_error': 'Error: Text extraction failed',
      'word_export_unavailable': 'Word export is not available yet.',
      'performance_data_warning': 'All performance data will be deleted. This action cannot be undone.',
      'select_credit_package': 'Select credit packages',
      'credits_added_success': 'credits successfully added!',
      
      // Performance & Statistics
      'performance_statistics': 'Performance Statistics',
      'clear_data': 'Clear Data',
      'detailed_report': 'Detailed Performance Report', 
      'total_operations': 'Total Operations',
      'success_rate': 'Success Rate',
      'average_time': 'Average Time',
      'fastest': 'Fastest',
      'slowest': 'Slowest',
      'characters': 'characters',
      'engine_performance': 'Engine Performance',
      'clear_performance_data': 'Clear Performance Data',
      'clear': 'Clear',
      'image_optimizing': 'Optimizing image...',
      'average': 'avg.',
    },
  };
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['tr', 'en'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(LocalizationsDelegate<AppLocalizations> old) => false;
}

/// Kolay erişim için extension
extension AppLocalizationsExtension on BuildContext {
  AppLocalizations get l10n {
    final localizations = AppLocalizations.of(this);
    if (localizations == null) {
      // Fallback to Turkish if localization is not available
      return AppLocalizations(const Locale('tr', 'TR'));
    }
    return localizations;
  }
} 