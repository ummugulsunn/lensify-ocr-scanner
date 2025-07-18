import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'text_editor_screen.dart';
import 'utils/image_processor.dart';
import 'utils/ocr_engine_manager.dart';
import 'utils/async_ocr_processor.dart';
import 'theme/theme_provider.dart';
import 'services/credit_manager.dart';
import 'settings_dialog.dart';
import 'animations/animations.dart';
import 'l10n/app_localizations.dart';
import 'utils/error_handler.dart';
import 'utils/ocr_cache_manager.dart';
import 'utils/performance_monitor.dart';
import 'utils/memory_manager.dart';
import 'database/ocr_history_database.dart';
import 'services/admob_service.dart';
import 'services/subscription_manager.dart';
import 'widgets/banner_ad_widget.dart';

import 'dart:developer' as developer;
import 'package:crypto/crypto.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize services
  final themeProvider = ThemeProvider();
  final creditManager = CreditManager();
  
  await themeProvider.initialize();
  await creditManager.initialize();
  await OCRCacheManager.instance.initialize();
  await PerformanceMonitor.instance.initialize();
  
  // Initialize AdMob
  await AdMobService.initialize();
  await AdMobService.instance.checkProStatus();
  
  // Initialize Subscription Manager
  await SubscriptionManager.instance.initialize();
  await SubscriptionManager.instance.loadSubscriptionStatus();
  
  // Initialize OCR History Database
  try {
    await OCRHistoryDatabase.instance.database;
  } catch (e, s) {
    developer.log('Database initialization error', error: e, stackTrace: s);
    // Continue app startup even if database fails
  }
  
  runApp(MyApp(
    themeProvider: themeProvider,
    creditManager: creditManager,
  ));
}

class MyApp extends StatelessWidget {
  final ThemeProvider themeProvider;
  final CreditManager creditManager;
  
  const MyApp({
    super.key,
    required this.themeProvider,
    required this.creditManager,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeProvider),
        Provider.value(value: creditManager),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
    return MaterialApp(
      title: 'Lensify OCR Scanner',
      debugShowCheckedModeBanner: false,
            theme: themeProvider.getTheme(context),
            themeMode: themeProvider.themeMode.toMaterialThemeMode(),
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            locale: themeProvider.locale,
      home: const OCRHomePage(),
          );
        },
      ),
    );
  }
}

class OCRHomePage extends StatefulWidget {
  const OCRHomePage({super.key});

  @override
  State<OCRHomePage> createState() => _OCRHomePageState();
}

class _OCRHomePageState extends State<OCRHomePage> {
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  final List<File> _selectedImages = []; // Batch scanning için
  String _statusMessage = '';
  String _extractedText = '';
  bool _isProcessing = false;
  bool _isPickingImage = false;
  bool _isBatchMode = false; // Batch mod kontrolü
  bool _isHandwritingMode = false; // El yazısı tanıma modu
  ImageEnhancementLevel _enhancementLevel = ImageEnhancementLevel.auto; // Enhancement seviyesi
  OCRQuality _ocrQuality = OCRQuality.balanced; // OCR kalite seviyesi
  final List<OCRResult> _ocrHistory = []; // OCR geçmişi

  // Kredi sistemi için
  int _currentCredits = 0;


  
  @override
  void initState() {
    super.initState();
    _loadCreditInfo();
  }
  
  @override
  void dispose() {
    // Cleanup memory resources
    MemoryManager.dispose();
    super.dispose();
  }
  
  Future<void> _loadCreditInfo() async {
    final creditManager = Provider.of<CreditManager>(context, listen: false);
    final credits = await creditManager.getCurrentCredits();
    
    setState(() {
      _currentCredits = credits;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final theme = Theme.of(context);
        final isDark = themeProvider.isDarkMode(context);
        
        // Theme-aware gradient colors
        final gradientColors = isDark 
          ? [
              const Color(0xFF1E293B),
              const Color(0xFF334155),
              const Color(0xFF475569),
              const Color(0xFF64748B),
            ]
          : [
              const Color(0xFF667eea),
              const Color(0xFF764ba2),
              const Color(0xFFf093fb),
              const Color(0xFFf5576c),
            ];
        
    return Scaffold(
          backgroundColor: theme.colorScheme.surface,
      body: Container(
            decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
                colors: gradientColors,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                    AppAnimations.fadeIn(
                      child: _buildHeader(),
                      duration: AppAnimations.medium,
                    ),
                const SizedBox(height: 20),
                    AppAnimations.slideInFromRight(
                      child: _buildModeSelector(),
                      duration: AppAnimations.medium,
                    ),
                const SizedBox(height: 20),
                    AppAnimations.scaleIn(
                      child: _isBatchMode ? _buildBatchImageSection() : _buildImageSection(),
                      duration: AppAnimations.medium,
                    ),
                const SizedBox(height: 30),
                    AppAnimations.bounceInAnimation(
                      child: _buildImagePickerButtons(),
                      duration: AppAnimations.medium,
                    ),
                const SizedBox(height: 20),
                if ((_selectedImage != null && !_isBatchMode) || 
                        (_selectedImages.isNotEmpty && _isBatchMode))
                      _buildOcrOptions(),
                const SizedBox(height: 20),
                    if (_statusMessage.isNotEmpty) 
                      AppAnimations.fadeIn(
                        child: _buildStatusCard(),
                        duration: AppAnimations.fast,
                      ),
                    if (_extractedText.isNotEmpty) 
                      AppAnimations.slideInFromBottom(
                        child: _buildResultCard(),
                        duration: AppAnimations.medium,
                      ),
                    // Banner reklam alanı
                    const SizedBox(height: 20),
                    BannerAdWidget(
                      onUpgradePressed: () => _showInsufficientCreditsDialog(),
                    ),
              ],
            ),
          ),
        ),
          ),
        );
      },
    );
  }

  Widget _buildOcrOptions() {
    return AppAnimations.fadeIn(
      child: Column(
        children: [
          AppAnimations.slideInFromBottom(
            child: _buildEnhancementSelector(),
          ),
          const SizedBox(height: 15),
          AppAnimations.slideInFromBottom(
            child: _buildOCRQualitySelector(),
          ),
          const SizedBox(height: 15),
          AppAnimations.slideInFromBottom(
            child: _buildHandwritingModeSelector(),
          ),
          const SizedBox(height: 15),
          AppAnimations.scaleIn(
            child: _buildOCRButton(),
            curve: AppAnimations.elasticOut,
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final isDark = themeProvider.isDarkMode(context);
        
    return _buildGlassCard(
          isDark: isDark,
          child: Column(
        children: [
              // Top row with settings and credits
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Settings button - daha görünür hale getir
                  Container(
                    decoration: BoxDecoration(
                      color: isDark 
                        ? Colors.white.withValues(alpha: 0.1) 
                        : Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      onPressed: _showSettingsDialog,
                      icon: Icon(
                        Icons.settings, 
                        color: isDark ? Colors.white : Colors.white, 
                        size: 24
                      ),
                      tooltip: 'Ayarlar',
                    ),
                  ),
                  // Credits info
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                                      color: isDark 
                  ? Colors.white.withValues(alpha: 0.1) 
                  : Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.credit_card, 
                          size: 16, 
                          color: isDark ? Colors.white : Colors.white
                        ),
                        const SizedBox(width: 4),
          Text(
                          '$_currentCredits ${context.l10n.credits}',
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Logo and title
              AppAnimations.scaleIn(
                child: Icon(
                  Icons.document_scanner_outlined, 
                  size: 50, 
                  color: isDark ? Colors.white : Colors.white
                ),
              ),
              const SizedBox(height: 10),
          Text(
            context.l10n.appTitle,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.white,
              letterSpacing: 1.2,
            ),
          ),
          Text(
            context.l10n.appSubtitle,
            style: TextStyle(
              fontSize: 16,
                  color: isDark ? Colors.white70 : Colors.white70,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
        );
      },
    );
  }

  Widget _buildModeSelector() {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final isDark = themeProvider.isDarkMode(context);
        
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
            color: isDark 
              ? Colors.white.withValues(alpha: 0.1) 
              : Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark 
                ? Colors.white.withValues(alpha: 0.2) 
                : Colors.white.withValues(alpha: 0.3)
            ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildModeButton(
              label: context.l10n.singleImage,
              isSelected: !_isBatchMode,
              onTap: () => _switchMode(false),
                  isDark: isDark,
            ),
          ),
          Expanded(
            child: _buildModeButton(
              label: context.l10n.multipleImages,
              isSelected: _isBatchMode,
              onTap: () => _switchMode(true),
                  isDark: isDark,
            ),
          ),
        ],
      ),
        );
      },
    );
  }

  Widget _buildModeButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Container(
      height: 45,
      decoration: BoxDecoration(
        color: isSelected 
          ? (isDark ? Colors.white.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.3))
          : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected 
                  ? (isDark ? Colors.white : Colors.white) 
                  : (isDark ? Colors.white60 : Colors.white60),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Container(
      height: 250,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: _selectedImage != null
          ? _buildSelectedImageView()
          : _buildImagePlaceholder(),
    );
  }

  Widget _buildBatchImageSection() {
    return Container(
      constraints: const BoxConstraints(minHeight: 250),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: _selectedImages.isNotEmpty
          ? _buildBatchImageList()
          : _buildBatchImagePlaceholder(),
    );
  }

  Widget _buildBatchImageList() {
    return Padding(
      padding: const EdgeInsets.all(15),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_selectedImages.length} Resim Seçildi',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextButton(
                onPressed: _clearBatchImages,
                child: Text(
                  context.l10n.clear,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 180,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedImages.length,
              itemBuilder: (context, index) {
                return Container(
                  width: 120,
                  margin: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                  ),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Image.file(
                          _selectedImages[index],
                          fit: BoxFit.cover,
                          width: 120,
                          height: 180,
                        ),
                      ),
                      Positioned(
                        top: 5,
                        right: 5,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.close, color: Colors.white, size: 16),
                            onPressed: () => _removeBatchImage(index),
                            padding: const EdgeInsets.all(4),
                            constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 5,
                        left: 5,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBatchImagePlaceholder() {
    return const SizedBox(
      height: 250,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.photo_library_outlined,
              size: 60,
              color: Colors.white60,
            ),
            SizedBox(height: 15),
            Text(
              'Birden Fazla Resim Seçin',
              style: TextStyle(
                fontSize: 18,
                color: Colors.white70,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 5),
            Text(
              'Sırasıyla taranacak resimleri seçin\nAltalta birleştirilecek',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedImageView() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(25),
      child: Image.file(
        _selectedImage!,
                fit: BoxFit.cover,
        width: double.infinity,
        height: 250,
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.add_photo_alternate_outlined,
            size: 60,
            color: Colors.white60,
          ),
          const SizedBox(height: 15),
          Text(
            context.l10n.selectImage,
            style: const TextStyle(
              fontSize: 18,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            context.l10n.selectImageInstruction,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePickerButtons() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                icon: Icons.camera_alt_outlined,
                label: _isPickingImage ? context.l10n.pleaseWait : context.l10n.camera,
                onTap: () => _isBatchMode ? _pickBatchImages(ImageSource.camera) : _pickImage(ImageSource.camera),
                isEnabled: !_isProcessing && !_isPickingImage,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: _buildActionButton(
                icon: Icons.photo_library_outlined,
                label: _isPickingImage ? context.l10n.pleaseWait : context.l10n.gallery,
                onTap: () => _isBatchMode ? _pickBatchImages(ImageSource.gallery) : _pickImage(ImageSource.gallery),
                isEnabled: !_isProcessing && !_isPickingImage,
              ),
            ),
          ],
        ),

      ],
    );
  }

  Widget _buildGlassCard({required Widget child, bool isDark = false}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark 
          ? Colors.white.withValues(alpha: 0.1) 
          : Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark 
            ? Colors.white.withValues(alpha: 0.2) 
            : Colors.white.withValues(alpha: 0.3)
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isEnabled,
  }) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: isEnabled ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: isEnabled ? onTap : null,
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: isEnabled ? Colors.white : Colors.white38,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: isEnabled ? Colors.white : Colors.white38,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancementSelector() {
    return _buildGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.tune_outlined, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Görüntü İyileştirme',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _getEnhancementLevelName(_enhancementLevel),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: _buildEnhancementButton(
                  label: context.l10n.basic,
                  level: ImageEnhancementLevel.basic,
                  icon: Icons.auto_fix_normal_outlined,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildEnhancementButton(
                  label: context.l10n.advanced,
                  level: ImageEnhancementLevel.advanced,
                  icon: Icons.auto_fix_high_outlined,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildEnhancementButton(
                  label: context.l10n.automatic,
                  level: ImageEnhancementLevel.auto,
                  icon: Icons.auto_awesome_outlined,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildEnhancementButton(
                  label: context.l10n.document,
                  level: ImageEnhancementLevel.document,
                  icon: Icons.description_outlined,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancementButton({
    required String label,
    required ImageEnhancementLevel level,
    required IconData icon,
  }) {
    final isSelected = _enhancementLevel == level;
    
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: isSelected 
          ? Colors.white.withValues(alpha: 0.3) 
          : Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected 
            ? Colors.white.withValues(alpha: 0.5) 
            : Colors.white.withValues(alpha: 0.2),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
                     onTap: () => setState(() {
             _enhancementLevel = level;
             // Enhancement değiştiğinde önceki sonuçları temizle
             if (_extractedText.isNotEmpty) {
               _extractedText = '';
               _statusMessage = 'Enhancement seviyesi değiştirildi. Yeniden tarayın.';
               _clearStatusAfterDelay(3);
             }
           }),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : Colors.white70,
                size: 20,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getEnhancementLevelName(ImageEnhancementLevel level) {
    switch (level) {
      case ImageEnhancementLevel.basic:
        return context.l10n.basic;
      case ImageEnhancementLevel.advanced:
        return context.l10n.advanced;
      case ImageEnhancementLevel.auto:
        return context.l10n.automatic;
      case ImageEnhancementLevel.document:
        return context.l10n.document;
    }
  }

  Widget _buildOCRQualitySelector() {
    return _buildGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.speed_outlined, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                context.l10n.ocrQuality,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _getOCRQualityName(_ocrQuality),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: _buildOCRQualityButton(
                  label: context.l10n.fast,
                  subtitle: context.l10n.mlKit,
                  quality: OCRQuality.fast,
                  icon: Icons.flash_on_outlined,
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildOCRQualityButton(
                  label: context.l10n.balanced,
                  subtitle: context.l10n.dualEngine,
                  quality: OCRQuality.balanced,
                  icon: Icons.balance_outlined,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildOCRQualityButton(
                  label: context.l10n.accurate,
                  subtitle: context.l10n.allEngines,
                  quality: OCRQuality.accurate,
                  icon: Icons.verified_outlined,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildOCRQualityButton(
                  label: context.l10n.premium,
                  subtitle: context.l10n.cloud,
                  quality: OCRQuality.premium,
                  icon: Icons.cloud_outlined,
                  color: Colors.purple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOCRQualityButton({
    required String label,
    required String subtitle,
    required OCRQuality quality,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _ocrQuality == quality;
    
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: isSelected 
          ? color.withValues(alpha: 0.3) 
          : Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected 
            ? color.withValues(alpha: 0.7) 
            : Colors.white.withValues(alpha: 0.2),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => setState(() {
            _ocrQuality = quality;
            // Quality değiştiğinde önceki sonuçları temizle
            if (_extractedText.isNotEmpty) {
              _extractedText = '';
              _statusMessage = 'OCR kalitesi değiştirildi. Yeniden tarayın.';
              _clearStatusAfterDelay(3);
            }
          }),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : Colors.white70,
                size: 20,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  color: isSelected ? Colors.white70 : Colors.white54,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getOCRQualityName(OCRQuality quality) {
    switch (quality) {
      case OCRQuality.fast:
        return context.l10n.fast;
      case OCRQuality.balanced:
        return context.l10n.balanced;
      case OCRQuality.accurate:
        return context.l10n.accurate;
      case OCRQuality.premium:
        return context.l10n.premium;
    }
  }

  Widget _buildHandwritingModeSelector() {
    return _buildGlassCard(
      child: Row(
        children: [
          const Icon(Icons.edit_outlined, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.handwritingRecognition,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  context.l10n.handwritingMode,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Switch(
            value: _isHandwritingMode,
            onChanged: (value) {
              setState(() {
                _isHandwritingMode = value;
              });
            },
            activeColor: Colors.white,
            activeTrackColor: Colors.white.withValues(alpha: 0.3),
            inactiveThumbColor: Colors.white70,
            inactiveTrackColor: Colors.white.withValues(alpha: 0.1),
          ),
        ],
      ),
    );
  }

  Widget _buildOCRButton() {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: _isProcessing ? null : _performOCR,
          child: Center(
            child: _isProcessing
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AppAnimations.loadingDots(
                        color: Colors.white,
                        size: 6.0,
                      ),
                      const SizedBox(width: 15),
                      Text(
                        context.l10n.extractingText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _isBatchMode ? Icons.library_books_outlined : Icons.text_fields_outlined,
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isBatchMode ? context.l10n.batchMode : context.l10n.extractText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return _buildGlassCard(
      child: Text(
        _statusMessage,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildResultCard() {
    return _buildGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _isBatchMode ? Icons.library_books_outlined : Icons.text_snippet_outlined, 
                color: Colors.white, 
                size: 24
              ),
              const SizedBox(width: 10),
              Text(
                _isBatchMode ? context.l10n.batchMode : context.l10n.extractedTextTitle,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: Text(
              _extractedText,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildResultButton(
                  icon: Icons.edit_outlined,
                  label: context.l10n.edit,
                  color: Colors.green,
                  onTap: _openTextEditor,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildResultButton(
                  icon: Icons.copy_outlined,
                  label: context.l10n.copyText,
                  color: Colors.blue,
                  onTap: _copyToClipboard,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildResultButton(
                  icon: Icons.picture_as_pdf_outlined,
                  label: context.l10n.getPdf,
                  color: Colors.red,
                  onTap: _generatePDF,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResultButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: onTap,
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Fonksiyonlar ---



  Future<void> _copyToClipboard() async {
    if (_extractedText.isNotEmpty) {
      await Clipboard.setData(ClipboardData(text: _extractedText));
      if (!mounted) return;
      _showSnackbar(context.l10n.textCopiedToClipboard);
    }
  }

  Future<void> _generatePDF() async {
    if (_extractedText.isEmpty) return;
    
    try {
      // Text Editor ekranını PDF oluşturma modunda aç
      Navigator.push(
        context,
        AppAnimations.createRoute(
          page: TextEditorScreen(
            initialText: _extractedText, 
            l10n: context.l10n,
            autoGeneratePDF: true, // PDF modunda aç
          ),
          duration: AppAnimations.medium,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ErrorHandler.handleError(
        context,
        e,
        customMessage: context.l10n.pdfCreationError,
      );
    }
  }

  void _showSnackbar(String message) {
    // Enhanced success message kullan
    ErrorHandler.showSuccess(context, message);
  }

  void _switchMode(bool isBatchMode) {
    setState(() {
      _isBatchMode = isBatchMode;
      _selectedImage = null;
      _selectedImages.clear();
      _extractedText = '';
      _statusMessage = '';
    });
  }

  void _clearBatchImages() {
    setState(() {
      _selectedImages.clear();
      _extractedText = '';
      _statusMessage = '';
    });
  }

  void _removeBatchImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
      if (_selectedImages.isEmpty) {
        _extractedText = '';
        _statusMessage = '';
      }
    });
  }

  void _clearStatusAfterDelay(int seconds) {
    Future.delayed(Duration(seconds: seconds), () {
      if (mounted) {
        setState(() {
          _statusMessage = '';
        });
      }
    });
  }

  void _updateStatus({
    bool? isProcessing,
    bool? isPickingImage,
    String? message,
    File? selectedImage,
    String? extractedText,
  }) {
    setState(() {
      if (isProcessing != null) _isProcessing = isProcessing;
      if (isPickingImage != null) _isPickingImage = isPickingImage;
      if (message != null) _statusMessage = message;
      if (selectedImage != null) _selectedImage = selectedImage;
      if (extractedText != null) _extractedText = extractedText;
    });
  }

  void _openTextEditor() {
    Navigator.push(
      context,
      AppAnimations.createRoute(
        page: TextEditorScreen(initialText: _extractedText, l10n: context.l10n),
        duration: AppAnimations.medium,
      ),
    );
  }
  
  void _showSettingsDialog() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, animation, secondaryAnimation) {
        return SettingsDialog(
          onCreditsChanged: _loadCreditInfo,
        );
      },
    );
  }
  
  void _showInsufficientCreditsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            const SizedBox(width: 8),
            Expanded(child: Text(context.l10n.insufficientCredits)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.l10n.insufficientCreditsMessage),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withAlpha((255 * 0.1).toInt()),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.blue, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        '🚀 Pro Abonelik',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Sınırsız OCR işlemi\n• Reklamsız deneyim\n• Öncelikli destek',
                    style: TextStyle(fontSize: 13, color: Colors.blue[700]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sadece ₺29.99/ay',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[800],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(context.l10n.cancel),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              _showSettingsDialog();
            },
            icon: Icon(Icons.star, size: 16),
            label: Text('Pro Ol'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // Mock functions - bunları gerçek implementasyonlarla değiştirin
  Future<void> _pickImage(ImageSource source) async {
    if (_isPickingImage) return;

    _updateStatus(
      isPickingImage: true,
      message: source == ImageSource.gallery
                  ? context.l10n.galleryOpening
        : context.l10n.cameraOpening,
    );

    await Future.delayed(const Duration(milliseconds: 100));

    try {
      if (source == ImageSource.camera && !await _requestCameraPermission()) {
        _updateStatus(isPickingImage: false, message: '');
        return;
      }

      final XFile? image = await _picker
          .pickImage(
            source: source,
            imageQuality: 85,
            maxWidth: 1920,
            maxHeight: 1080,
            preferredCameraDevice: CameraDevice.rear,
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () => throw Exception('Galeri açılırken zaman aşımı'),
          );

      if (image != null) {
        _updateStatus(
          isPickingImage: false,
          message: 'Resim başarıyla yüklendi! 📸',
          selectedImage: File(image.path),
          extractedText: '',
        );
        _clearStatusAfterDelay(2);
      } else {
        _updateStatus(
          isPickingImage: false,
          message: 'Resim seçimi iptal edildi',
        );
        _clearStatusAfterDelay(1);
      }
    } catch (e) {
      _handleImagePickerError(e);
    }
  }

  Future<void> _pickBatchImages(ImageSource source) async {
    if (_isPickingImage) return;

    _updateStatus(
      isPickingImage: true,
      message: source == ImageSource.gallery
                  ? context.l10n.galleryOpeningMulti
        : context.l10n.cameraOpeningMulti,
    );

    await Future.delayed(const Duration(milliseconds: 100));

    try {
      if (source == ImageSource.camera && !await _requestCameraPermission()) {
        _updateStatus(isPickingImage: false, message: '');
        return;
      }

      // Tek resim seçimi (hem kamera hem galeri için)
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1080,
        preferredCameraDevice: CameraDevice.rear,
      );

      if (image != null) {
        setState(() {
          _selectedImages.add(File(image.path));
        });
        
        _updateStatus(
          isPickingImage: false,
          message: 'Resim eklendi! Toplam: ${_selectedImages.length}',
          extractedText: '',
        );
        _clearStatusAfterDelay(2);
      } else {
        _updateStatus(
          isPickingImage: false,
          message: 'Resim seçimi iptal edildi',
        );
        _clearStatusAfterDelay(1);
      }
    } catch (e) {
      _handleImagePickerError(e);
    }
  }

  Future<bool> _requestCameraPermission() async {
    final cameraPermission = await Permission.camera.request();
    if (!cameraPermission.isGranted) {
      if (!mounted) return false;
      _showPermissionDialog(context.l10n.cameraPermissionRequired);
      return false;
    }
    return true;
  }

  void _handleImagePickerError(dynamic e) {
    _updateStatus(
      isPickingImage: false,
              message: context.l10n.galleryError,
    );
    _clearStatusAfterDelay(3);

    // Enhanced error handling kullan
    ErrorHandler.handleError(
      context,
      e,
              customMessage: context.l10n.galleryErrorRetry,
      onRetry: () {
        // Galeri açmayı tekrar dene
        _pickImage(ImageSource.gallery);
      },
    );
  }

  Future<void> _performOCR() async {
    if (_selectedImage == null && _selectedImages.isEmpty) return;

    // Kredi kontrolü
    final creditManager = Provider.of<CreditManager>(context, listen: false);
    final imageCount = _selectedImage != null ? 1 : _selectedImages.length;
    final ocrType = _selectedImage != null ? OCRType.single : OCRType.batch;
    
    final canUseCredits = await creditManager.useOCRCredits(
      type: ocrType,
      imageCount: imageCount,
      isHandwriting: _isHandwritingMode,
      isPremiumQuality: _ocrQuality == OCRQuality.premium,
    );
    
    if (!context.mounted) return;
    if (!canUseCredits) {
      _showInsufficientCreditsDialog();
      return;
    }

    if (!mounted) return;
    
    // Memory check before processing
    if (_selectedImage != null) {
      final isAcceptable = await MemoryManager.isImageSizeAcceptable(_selectedImage!);
      if (!isAcceptable) {
        if (!mounted) return;
        ErrorHandler.handleError(context, 'Image too large', customMessage: 'Resim çok büyük. Daha küçük bir resim seçin.');
        return;
      }
    }
    
    if (!mounted) return;
    _updateStatus(isProcessing: true, message: context.l10n.optimizingImage);

    try {
      // Check memory before processing
      await MemoryManager.checkMemoryUsage();
      
      if (_selectedImage != null) {
        // Tek resim OCR (Enhancement + OCR)
        await _performSingleImageOCR(_selectedImage!);
      } else if (_selectedImages.isNotEmpty) {
        // Batch OCR
        await _performBatchOCR();
      }
      
      // Kredi bilgilerini güncelle
      await _loadCreditInfo();
      
      // Memory cleanup after processing
      await MemoryManager.checkMemoryUsage();
    } catch (e) {
      if (!mounted) return;
      _updateStatus(
        isProcessing: false,
        message: 'OCR işlemi sırasında hata oluştu',
        extractedText: 'OCR işlemi sırasında hata oluştu',
      );
      
      // Enhanced error handling kullan
      ErrorHandler.handleError(
        context,
        e,
        customMessage: context.l10n.extractionError,
        onRetry: () {
          // OCR işlemini tekrar dene
          _performOCR();
        },
      );
    }
  }

  Future<void> _performSingleImageOCR(File imageFile) async {
    try {
      // Provider'ı async işlemlerden önce al
      final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
      final ocrLanguage = OCREngineManager.getOCRLanguageFromLocale(themeProvider.locale);
      final l10n = context.l10n;
      
      // Cache konfigürasyonu oluştur
      final cacheConfig = OCRCacheConfig(
        quality: _ocrQuality,
        language: ocrLanguage,
        isHandwriting: _isHandwritingMode,
        enhancementLevel: _enhancementLevel,
      );

      // 1. Önce cache'den kontrol et
      final cachedResult = await OCRCacheManager.instance.getCachedResult(
        imageFile,
        cacheConfig,
      );

      if (cachedResult != null) {
        // Cache hit - sonucu direkt kullan
        _ocrHistory.add(cachedResult);
        
        if (!mounted) return;
        _updateStatus(
          isProcessing: false,
          message: '${_buildOCRResultMessage(cachedResult, l10n)} (Önbellekten)',
          extractedText: cachedResult.text.isEmpty ? context.l10n.noTextFound : cachedResult.text,
        );
        
        if (mounted) {
          ErrorHandler.showInfo(context, 'Sonuç önbellekten getirildi');
        }
        return;
      }

      // 2. Cache miss - normal OCR işlemi
      _updateStatus(isProcessing: true, message: l10n.imageOptimizing);
      
      final optimizedFile = await ImageProcessor.optimizeForOCR(
        imageFile,
        level: _enhancementLevel,
      );

      // 3. OCR işlemi - Performance monitoring ile
      _updateStatus(
        isProcessing: true, 
        message: _getOCRProcessingMessage(_ocrQuality),
      );
      
      // Performance monitoring context oluştur
      final imageSize = await imageFile.length();
      
      final operationContext = OCROperationContext(
        quality: _ocrQuality,
        language: ocrLanguage,
        isHandwritingMode: _isHandwritingMode,
        isBatchMode: false,
        imageCount: 1,
        imageSize: imageSize,
      );
      
      // OCR işlemini performance monitoring ile wrap et - Optimized version
      final ocrResult = await PerformanceMonitor.instance.trackOCROperation(
        () => OptimizedOCRManager.performOptimizedOCR(
        optimizedFile,
        quality: _ocrQuality,
          language: ocrLanguage,
        isHandwritingMode: _isHandwritingMode,
        ),
        operationContext,
      );

      // 4. Sonucu cache'e kaydet
      await OCRCacheManager.instance.cacheResult(
        imageFile,
        ocrResult,
        cacheConfig,
      );

      // OCR geçmişine ekle
      _ocrHistory.add(ocrResult);
      
      // Database'e kaydet
      try {
        final historyEntry = OCRHistoryEntry.fromOCRResult(
          ocrResult,
          language: ocrLanguage,
          quality: _ocrQuality.name,
          isHandwriting: _isHandwritingMode,
          isBatch: false,
          imageCount: 1,
          imageSize: await imageFile.length(),
          imagePath: imageFile.path,
          imageHash: await _calculateImageHash(imageFile),
        );
        await OCRHistoryDatabase.instance.saveOCRResult(historyEntry);
      } catch (e) {
        developer.log('Error saving to history database: $e');
      }
      
      if (!mounted) return;
      _updateStatus(
        isProcessing: false,
        message: _buildOCRResultMessage(ocrResult, l10n),
        extractedText: ocrResult.text.isEmpty ? context.l10n.noTextFound : ocrResult.text,
      );

      // 5. Optimize edilmiş dosyayı temizle (orijinal değilse)
      if (optimizedFile.path != imageFile.path) {
        try {
          await optimizedFile.delete();
        } catch (e) {
          // Silme hatası önemli değil
        }
      }
    } catch (e) {
      rethrow; // Ana catch bloğu yakalayacak
    }
  }

  String _getOCRProcessingMessage(OCRQuality quality) {
    switch (quality) {
      case OCRQuality.fast:
        return context.l10n.extractingFast;
      case OCRQuality.balanced:
        return context.l10n.extractingDualEngine;
      case OCRQuality.accurate:
        return context.l10n.extractingHighAccuracy;
      case OCRQuality.premium:
        return context.l10n.extractingPremium;
    }
  }

  String _buildOCRResultMessage(OCRResult result, [AppLocalizations? l10n]) {
    final localizations = l10n ?? context.l10n;
    
    if (!result.isSuccess) {
      return '${localizations.error}: ${result.errorMessage}';
    }
    
    if (result.text.isEmpty) {
      return localizations.noTextFound;
    }
    
    final confidence = (result.confidence * 100).toStringAsFixed(0);
    final time = result.processingTime.inMilliseconds;
    return '${localizations.ocrCompleted} (${result.engine.displayName} • %$confidence • ${time}ms)';
  }

  Future<void> _performBatchOCR() async {
    // Provider ve localization'ı async işlemlerden önce al
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final ocrLanguage = OCREngineManager.getOCRLanguageFromLocale(themeProvider.locale);
    final l10n = context.l10n;
    
        _updateStatus(
          isProcessing: true,
        message: '${l10n.optimizingImage} (${_selectedImages.length} resim)...',
      );
    
    try {
      // Determine optimal concurrent processing count based on device capabilities
      final maxConcurrent = _calculateOptimalConcurrency();
      
      // Optimized parallel batch processing
      final batchResults = await OptimizedOCRManager.performOptimizedBatchOCR(
        _selectedImages,
          quality: _ocrQuality,
        language: ocrLanguage,
          isHandwritingMode: _isHandwritingMode,
        maxConcurrent: maxConcurrent,
      );
      
      // Update progress during processing
      var processedCount = 0;
      final List<String> allExtractedTexts = [];
      
      for (int i = 0; i < batchResults.length; i++) {
        final ocrResult = batchResults[i];
        processedCount++;
        
        // Update progress every few items
        if (processedCount % 2 == 0 || processedCount == batchResults.length) {
          if (!mounted) return;
                     _updateStatus(
             isProcessing: processedCount < batchResults.length,
             message: 'İşleniyor $processedCount/${_selectedImages.length}...',
           );
        }
        
        // Add to history
        _ocrHistory.add(ocrResult);
        
        // Format result
        if (ocrResult.isSuccess && ocrResult.text.isNotEmpty) {
          final confidence = (ocrResult.confidence * 100).toStringAsFixed(0);
          final engine = ocrResult.engine.displayName;
          allExtractedTexts.add(
             '--- ${l10n.pageNumber} ${i + 1} ---\n'
            '[$engine • %$confidence güven]\n\n'
            '${ocrResult.text}'
          );
        } else {
          final noTextMessage = ocrResult.isSuccess ? l10n.noTextFound : "${l10n.error}: ${ocrResult.errorMessage}";
          allExtractedTexts.add(
            '--- ${l10n.pageNumber} ${i + 1} ---\n'
            '[$noTextMessage]'
          );
      }
    }
    
    final combinedText = allExtractedTexts.join('\n\n');
    
    // Batch performans özeti
    final successfulResults = batchResults.where((r) => r.isSuccess && r.text.isNotEmpty).length;
      
      String message;
      if (successfulResults > 0) {
    final avgTime = batchResults.map((r) => r.processingTime.inMilliseconds).reduce((a, b) => a + b) / batchResults.length;
        message = '${l10n.batchOcrComplete}\n'
                  '$successfulResults/${_selectedImages.length} ${l10n.success} • ${avgTime.toStringAsFixed(0)}ms ${l10n.average}';
      } else {
        message = l10n.noTextFound;
      }
    
      if (!mounted) return;
    _updateStatus(
      isProcessing: false,
        message: message,
        extractedText: combinedText.isEmpty ? l10n.noTextFound : combinedText,
      );
        
      // Success animasyonu göster
      if (successfulResults > 0) {
        if (!mounted) return;
        _showSnackbar(l10n.ocrCompletedSuccess);
      }
    } catch (e) {
      if (!mounted) return;
      _updateStatus(
        isProcessing: false,
        message: l10n.extractionError,
        extractedText: l10n.extractionError,
      );
      
      ErrorHandler.handleError(
        context,
        e,
        customMessage: l10n.extractionError,
        onRetry: () => _performBatchOCR(),
      );
    }
  }
  
  /// Calculate optimal concurrency based on device capabilities
  int _calculateOptimalConcurrency() {
    // Conservative approach: limit based on image count and memory
    final imageCount = _selectedImages.length;
    
    if (imageCount <= 3) {
      return imageCount; // Process all at once for small batches
    } else if (imageCount <= 10) {
      return 3; // Moderate concurrency
    } else {
      return 2; // Conservative for large batches to prevent memory issues
    }
  }

  void _showPermissionDialog(String message) {
    // Enhanced error handling kullan
    ErrorHandler.handleError(
        context,
      'permission: $message',
      customMessage: message,
      showSnackBar: false, // Dialog göstereceğimiz için snackbar'ı kapatıyoruz
    );
  }

  /// Calculate SHA256 hash of image file for caching and deduplication
  Future<String> _calculateImageHash(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final digest = sha256.convert(bytes);
      return digest.toString();
    } catch (e) {
      return DateTime.now().millisecondsSinceEpoch.toString();
    }
  }


}
