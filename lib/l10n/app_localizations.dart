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

  // OCR Quality Subtitles
  String get mlKit => _localizedStrings[locale.languageCode]!['ml_kit']!;
  String get dualEngine => _localizedStrings[locale.languageCode]!['dual_engine']!;
  String get allEngines => _localizedStrings[locale.languageCode]!['all_engines']!;
  String get cloud => _localizedStrings[locale.languageCode]!['cloud']!;

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
  String get getPdf => _localizedStrings[locale.languageCode]!['get_pdf']!;
  String get exportWord => _localizedStrings[locale.languageCode]!['export_word']!;
  String get save => _localizedStrings[locale.languageCode]!['save']!;
  String get textCopied => _localizedStrings[locale.languageCode]!['text_copied']!;
  String get ocrScanResult => _localizedStrings[locale.languageCode]!['ocr_scan_result']!;

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
  String get settingsSubtitle => _localizedStrings[locale.languageCode]!['settings_subtitle']!;
  String get lightThemeSubtitle => _localizedStrings[locale.languageCode]!['light_theme_subtitle']!;
  String get darkThemeSubtitle => _localizedStrings[locale.languageCode]!['dark_theme_subtitle']!;
  String get systemThemeSubtitle => _localizedStrings[locale.languageCode]!['system_theme_subtitle']!;
  String get ocrHistoryTitle => _localizedStrings[locale.languageCode]!['ocr_history_title']!;
  String get viewOcrHistory => _localizedStrings[locale.languageCode]!['view_ocr_history']!;
  String get viewOcrHistorySubtitle => _localizedStrings[locale.languageCode]!['view_ocr_history_subtitle']!;
  String get totalOperationsLabel => _localizedStrings[locale.languageCode]!['total_operations_label']!;
  String get successRateLabel => _localizedStrings[locale.languageCode]!['success_rate_label']!;
  String get averageTimeLabel => _localizedStrings[locale.languageCode]!['average_time_label']!;
  String get detailedReportButton => _localizedStrings[locale.languageCode]!['detailed_report_button']!;
  String get enginePerformanceValue => _localizedStrings[locale.languageCode]!['engine_performance_value']!;
  String get buy50Credits => _localizedStrings[locale.languageCode]!['buy_50_credits']!;
  String get buy100Credits => _localizedStrings[locale.languageCode]!['buy_100_credits']!;
  String get buy250Credits => _localizedStrings[locale.languageCode]!['buy_250_credits']!;
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
  String get pdfCreationError => _localizedStrings[locale.languageCode]!['pdf_creation_error']!;
  String get performanceDataWarning => _localizedStrings[locale.languageCode]!['performance_data_warning']!;
  String get selectCreditPackage => _localizedStrings[locale.languageCode]!['select_credit_package']!;
  String get creditsAddedSuccess => _localizedStrings[locale.languageCode]!['credits_added_success']!;

  // New translations for OCR History Screen
  String get deleteConfirmation => _localizedStrings[locale.languageCode]!['delete_confirmation']!;
  String get deleteConfirmationMessage => _localizedStrings[locale.languageCode]!['delete_confirmation_message']!;
  String get delete => _localizedStrings[locale.languageCode]!['delete']!;
  String get ocrHistory => _localizedStrings[locale.languageCode]!['ocr_history']!;
  String get sortByDateDesc => _localizedStrings[locale.languageCode]!['sort_by_date_desc']!;
  String get sortByDateAsc => _localizedStrings[locale.languageCode]!['sort_by_date_asc']!;
  String get sortByConfidenceDesc => _localizedStrings[locale.languageCode]!['sort_by_confidence_desc']!;
  String get sortByConfidenceAsc => _localizedStrings[locale.languageCode]!['sort_by_confidence_asc']!;
  String get edit => _localizedStrings[locale.languageCode]!['edit']!;
  String get items => _localizedStrings[locale.languageCode]!['items']!;
  String get search => _localizedStrings[locale.languageCode]!['search']!;
  String get apply => _localizedStrings[locale.languageCode]!['apply']!;
  String get filter => _localizedStrings[locale.languageCode]!['filter']!;
  String get all => _localizedStrings[locale.languageCode]!['all']!;
  String get favoritesOnly => _localizedStrings[locale.languageCode]!['favorites_only']!;
  String get archivedOnly => _localizedStrings[locale.languageCode]!['archived_only']!;

  // New translations for Text Editor Screen
  String get pdfSettings => _localizedStrings[locale.languageCode]!['pdf_settings']!;
  String get fontSize => _localizedStrings[locale.languageCode]!['font_size']!;
  String get dateHeader => _localizedStrings[locale.languageCode]!['date_header']!;
  String get pageNumbers => _localizedStrings[locale.languageCode]!['page_numbers']!;
  String get createPdf => _localizedStrings[locale.languageCode]!['create_pdf']!;
  String get documentTitle => _localizedStrings[locale.languageCode]!['document_title']!;
  String get pageFormat => _localizedStrings[locale.languageCode]!['page_format']!;
  String get a4 => _localizedStrings[locale.languageCode]!['a4']!;
  String get a5 => _localizedStrings[locale.languageCode]!['a5']!;
  String get letter => _localizedStrings[locale.languageCode]!['letter']!;

  // New Translations for Error Handler
  String get connectionTips => _localizedStrings[locale.languageCode]!['connection_tips']!;
  String get checkWifi => _localizedStrings[locale.languageCode]!['check_wifi']!;
  String get enableMobileData => _localizedStrings[locale.languageCode]!['enable_mobile_data']!;
  String get disableAirplaneMode => _localizedStrings[locale.languageCode]!['disable_airplane_mode']!;
  String get restartRouter => _localizedStrings[locale.languageCode]!['restart_router']!;
  String get storageTips => _localizedStrings[locale.languageCode]!['storage_tips']!;
  String get deleteUnnecessaryPhotos => _localizedStrings[locale.languageCode]!['delete_unnecessary_photos']!;
  String get clearCache => _localizedStrings[locale.languageCode]!['clear_cache']!;
  String get uninstallUnusedApps => _localizedStrings[locale.languageCode]!['uninstall_unused_apps']!;
  String get moveFilesToCloud => _localizedStrings[locale.languageCode]!['move_files_to_cloud']!;
  String get support => _localizedStrings[locale.languageCode]!['support']!;
  String get ifProblemPersists => _localizedStrings[locale.languageCode]!['if_problem_persists']!;
  String get restartApp => _localizedStrings[locale.languageCode]!['restart_app']!;
  String get restartDevice => _localizedStrings[locale.languageCode]!['restart_device']!;
  String get checkAppUpdates => _localizedStrings[locale.languageCode]!['check_app_updates']!;
  String get contactDeveloper => _localizedStrings[locale.languageCode]!['contact_developer']!;

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
  String get searchHint => _localizedStrings[locale.languageCode]!['search_hint']!;
  String get category => _localizedStrings[locale.languageCode]!['category']!;
  String get minutesAgo => _localizedStrings[locale.languageCode]!['minutes_ago']!;
  String get yesterday => _localizedStrings[locale.languageCode]!['yesterday']!;
  String get daysAgo => _localizedStrings[locale.languageCode]!['days_ago']!;
  String get recordDeleted => _localizedStrings[locale.languageCode]!['record_deleted']!;
  String get recordDeletionFailed => _localizedStrings[locale.languageCode]!['record_deletion_failed']!;
  String get history => _localizedStrings[locale.languageCode]!['history']!;
  String get categories => _localizedStrings[locale.languageCode]!['categories']!;
  String get statistics => _localizedStrings[locale.languageCode]!['statistics']!;
  String get searchNoResults => _localizedStrings[locale.languageCode]!['search_no_results']!;
  String get noHistory => _localizedStrings[locale.languageCode]!['no_history']!;
  String get searchNoResultsForQuery => _localizedStrings[locale.languageCode]!['search_no_results_for_query']!;
  String get uncategorized => _localizedStrings[locale.languageCode]!['uncategorized']!;
  String get images => _localizedStrings[locale.languageCode]!['images']!;
  String get generalStatistics => _localizedStrings[locale.languageCode]!['general_statistics']!;
  String get totalRecords => _localizedStrings[locale.languageCode]!['total_records']!;
  String get favorites => _localizedStrings[locale.languageCode]!['favorites']!;
  String get archived => _localizedStrings[locale.languageCode]!['archived']!;
  String get averageConfidence => _localizedStrings[locale.languageCode]!['average_confidence']!;
  String get averageProcessingTime => _localizedStrings[locale.languageCode]!['average_processing_time']!;
  String get engineUsage => _localizedStrings[locale.languageCode]!['engine_usage']!;
  String get languageDistribution => _localizedStrings[locale.languageCode]!['language_distribution']!;

  // AdMob & Pro Upgrade
  String get removeAds => _localizedStrings[locale.languageCode]!['remove_ads']!;
  String get adFree => _localizedStrings[locale.languageCode]!['ad_free']!;
  String get upgradeToPro => _localizedStrings[locale.languageCode]!['upgrade_to_pro']!;

  // Çeviriler
  static final Map<String, Map<String, String>> _localizedStrings = {
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
      'settings_subtitle': 'Uygulamayı kişiselleştirin',
      'theme': 'Tema',
      'light_theme': 'Açık Tema',
      'light_theme_subtitle': 'Aydınlık görünüm',
      'dark_theme': 'Koyu Tema',
      'dark_theme_subtitle': 'Karanlık görünüm',
      'system_theme': 'Sistem',
      'system_theme_subtitle': 'Sistem ayarını takip et',
      'language': 'Dil',
      'turkish': 'Türkçe',
      'english': 'İngilizce',
      'ocr_history_title': 'OCR Geçmişi',
      'view_ocr_history': 'Geçmiş OCR İşlemlerini Görüntüle',
      'view_ocr_history_subtitle': 'Tüm tarama geçmişinizi ve sonuçlarını görün',
      'total_operations_label': 'Toplam İşlem',
      'success_rate_label': 'Başarı Oranı',
      'average_time_label': 'Ortalama Süre',
      'detailed_report_button': 'Detaylı Rapor',
      'engine_performance_value': '{count} işlem ({rate}%)',
      'buy_50_credits': '50 kredi - ₺9.99',
      'buy_100_credits': '100 kredi - ₺19.99',
      'buy_250_credits': '250 kredi - ₺39.99',
      
      // OCR Quality Subtitles
      'ml_kit': 'ML Kit',
      'dual_engine': '2 Motor',
      'all_engines': 'Tüm Motor',
      'cloud': 'Cloud',
      
      // Document Title
      'ocr_scan_result': 'OCR Tarama Sonucu',
      
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
      'get_pdf': 'PDF Al',
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
      'pdf_creation_error': 'PDF oluşturma hatası',
      'performance_data_warning': 'Tüm performans verileri silinecek. Bu işlem geri alınamaz.',
      'select_credit_package': 'Kredi paketlerini seçin',
      'credits_added_success': 'kredi başarıyla eklendi!',
      
      // OCR History
      'delete_confirmation': 'Silme Onayı',
      'delete_confirmation_message': 'Bu OCR kaydını silmek istediğinizden emin misiniz?',
      'delete': 'Sil',
      'ocr_history': 'OCR Geçmişi',
      'sort_by_date_desc': 'En Yeni',
      'sort_by_date_asc': 'En Eski',
      'sort_by_confidence_desc': 'Yüksek Güven',
      'sort_by_confidence_asc': 'Düşük Güven',
      'edit': 'Düzenle',
      'items': 'öğe',
      'search': 'Arama',
      'apply': 'Uygula',
      'filter': 'Filtrele',
      'all': 'Tümü',
      'favorites_only': 'Sadece Favoriler',
      'archived_only': 'Sadece Arşivlenenler',

      // Text Editor
      'pdf_settings': 'PDF Ayarları',
      'font_size': 'Yazı Boyutu',
      'date_header': 'Tarih Başlığı',
      'page_numbers': 'Sayfa Numaraları',
      'create_pdf': 'PDF Oluştur',
      'document_title': 'Belge Başlığı',
      'page_format': 'Sayfa Formatı',
      'a4': 'A4',
      'a5': 'A5',
      'letter': 'Letter',
      'record_deleted': 'Kayıt silindi',
      'record_deletion_failed': 'Kayıt silinemedi',
      'history': 'Geçmiş',
      'categories': 'Kategoriler',
      'statistics': 'İstatistikler',
      'search_no_results': 'Arama sonucu bulunamadı',
      'no_history': 'Henüz OCR geçmişi yok',
      'search_no_results_for_query': 'için sonuç bulunamadı',
      'uncategorized': 'Kategorisiz',
      'images': 'resim',
      'general_statistics': 'Genel İstatistikler',
      'total_records': 'Toplam Kayıt',
      'favorites': 'Favoriler',
      'archived': 'Arşivlenenler',
      'average_confidence': 'Ortalama Güven',
      'average_processing_time': 'Ortalama Süre',
      'engine_usage': 'Motor Kullanımı',
      'language_distribution': 'Dil Dağılımı',
      'search_hint': 'Metin içinde ara...',
      'category': 'Kategori',
      'yesterday': 'Dün',
      'days_ago': 'gün önce',
      'minutes_ago': 'dakika önce',


      // Error Handler
      'connection_tips': 'Bağlantı İpuçları',
      'check_wifi': '• Wi-Fi bağlantınızı kontrol edin',
      'enable_mobile_data': '• Mobil verilerinizi açın',
      'disable_airplane_mode': '• Uçak modunu kapatın',
      'restart_router': '• Router\'ınızı yeniden başlatın',
      'storage_tips': 'Depolama İpuçları',
      'delete_unnecessary_photos': '• Gereksiz fotoğrafları silin',
      'clear_cache': '• Önbelleği temizleyin',
      'uninstall_unused_apps': '• Kullanmadığınız uygulamaları kaldırın',
      'move_files_to_cloud': '• Dosyaları bulut depolamaya taşıyın',
      'support': 'Destek',
      'if_problem_persists': 'Sorun devam ederse:',
      'restart_app': '• Uygulamayı yeniden başlatın',
      'restart_device': '• Cihazınızı yeniden başlatın',
      'check_app_updates': '• Uygulama güncellemelerini kontrol edin',
      'contact_developer': '• Geliştirici ile iletişime geçin',
      
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
      
      // AdMob & Pro Upgrade
      'remove_ads': 'Reklamları Kaldır',
      'ad_free': 'Reklamsız',
      'upgrade_to_pro': 'Pro\'ya Yükselt',
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
      'settings_subtitle': 'Customize the application',
      'theme': 'Theme',
      'light_theme': 'Light Theme',
      'light_theme_subtitle': 'Light appearance',
      'dark_theme': 'Dark Theme',
      'dark_theme_subtitle': 'Dark appearance',
      'system_theme': 'System',
      'system_theme_subtitle': 'Follow system setting',
      'language': 'Language',
      'turkish': 'Turkish',
      'english': 'English',
      'ocr_history_title': 'OCR History',
      'view_ocr_history': 'View Past OCR Operations',
      'view_ocr_history_subtitle': 'See all your scan history and results',
      'total_operations_label': 'Total Operations',
      'success_rate_label': 'Success Rate',
      'average_time_label': 'Average Time',
      'detailed_report_button': 'Detailed Report',
      'engine_performance_value': '{count} operations ({rate}%)',
      'buy_50_credits': '50 credits - \$0.99',
      'buy_100_credits': '100 credits - \$1.99',
      'buy_250_credits': '250 credits - \$3.99',
      
      // OCR Quality Subtitles
      'ml_kit': 'ML Kit',
      'dual_engine': 'Dual Engine',
      'all_engines': 'All Engines',
      'cloud': 'Cloud',
      
      // Document Title
      'ocr_scan_result': 'OCR Scan Result',
      
      // OCR History
      'delete_confirmation': 'Delete Confirmation',
      'delete_confirmation_message': 'Are you sure you want to delete this OCR record?',
      'delete': 'Delete',
      'ocr_history': 'OCR History',
      'sort_by_date_desc': 'Newest',
      'sort_by_date_asc': 'Oldest',
      'sort_by_confidence_desc': 'High Confidence',
      'sort_by_confidence_asc': 'Low Confidence',
      'edit': 'Edit',
      'items': 'items',
      'search': 'Search',
      'apply': 'Apply',
      'filter': 'Filter',
      'all': 'All',
      'favorites_only': 'Favorites Only',
      'archived_only': 'Archived Only',

      // Text Editor
      'pdf_settings': 'PDF Settings',
      'font_size': 'Font Size',
      'date_header': 'Date Header',
      'page_numbers': 'Page Numbers',
      'create_pdf': 'Create PDF',
      'document_title': 'Document Title',
      'page_format': 'Page Format',
      'a4': 'A4',
      'a5': 'A5',
      'letter': 'Letter',
      'record_deleted': 'Record deleted',
      'record_deletion_failed': 'Failed to delete record',
      'history': 'History',
      'categories': 'Categories',
      'statistics': 'Statistics',
      'search_no_results': 'No search results found',
      'no_history': 'No OCR history yet',
      'search_no_results_for_query': 'No results found for',
      'uncategorized': 'Uncategorized',
      'images': 'images',
      'general_statistics': 'General Statistics',
      'total_records': 'Total Records',
      'favorites': 'Favorites',
      'archived': 'Archived',
      'average_confidence': 'Average Confidence',
      'average_processing_time': 'Average Processing Time',
      'engine_usage': 'Engine Usage',
      'language_distribution': 'Language Distribution',
      'search_hint': 'Search within text...',
      'category': 'Category',
      'yesterday': 'Yesterday',
      'days_ago': 'days ago',
      'minutes_ago': 'minutes ago',

      // Error Handler
      'connection_tips': 'Connection Tips',
      'check_wifi': '• Check your Wi-Fi connection',
      'enable_mobile_data': '• Turn on your mobile data',
      'disable_airplane_mode': '• Turn off airplane mode',
      'restart_router': '• Restart your router',
      'storage_tips': 'Storage Tips',
      'delete_unnecessary_photos': '• Delete unnecessary photos',
      'clear_cache': '• Clear the cache',
      'uninstall_unused_apps': '• Uninstall unused apps',
      'move_files_to_cloud': '• Move files to cloud storage',
      'support': 'Support',
      'if_problem_persists': 'If the problem persists:',
      'restart_app': '• Restart the app',
      'restart_device': '• Restart your device',
      'check_app_updates': '• Check for app updates',
      'contact_developer': '• Contact the developer',
      
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
      'get_pdf': 'Get PDF',
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
      'pdf_creation_error': 'PDF creation error',
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
      
      // AdMob & Pro Upgrade
      'remove_ads': 'Remove Ads',
      'ad_free': 'Ad-Free',
      'upgrade_to_pro': 'Upgrade to Pro',
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
