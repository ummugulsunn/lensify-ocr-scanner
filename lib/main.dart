import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'text_editor_screen.dart';
import 'utils/image_processor.dart';
import 'utils/ocr_engine_manager.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lensify OCR Scanner',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        fontFamily: 'SF Pro Display',
      ),
      home: const OCRHomePage(),
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
  List<File> _selectedImages = []; // Batch scanning için
  String _statusMessage = '';
  String _extractedText = '';
  bool _isProcessing = false;
  bool _isPickingImage = false;
  bool _isBatchMode = false; // Batch mod kontrolü
  bool _isHandwritingMode = false; // El yazısı tanıma modu
  ImageEnhancementLevel _enhancementLevel = ImageEnhancementLevel.auto; // Enhancement seviyesi
  OCRQuality _ocrQuality = OCRQuality.balanced; // OCR kalite seviyesi
  final List<OCRResult> _ocrHistory = []; // OCR geçmişi

  // Color constants for better maintainability
  static const _gradientColors = [
    Color(0xFF667eea),
    Color(0xFF764ba2),
    Color(0xFFf093fb),
    Color(0xFFf5576c),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _gradientColors,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                _buildHeader(),
                const SizedBox(height: 20),
                _buildModeSelector(), // Yeni: Mod seçici
                const SizedBox(height: 20),
                _isBatchMode ? _buildBatchImageSection() : _buildImageSection(),
                const SizedBox(height: 30),
                _buildImagePickerButtons(),
                const SizedBox(height: 20),
                if ((_selectedImage != null && !_isBatchMode) || 
                    (_selectedImages.isNotEmpty && _isBatchMode)) ...[
                  _buildEnhancementSelector(),
                  const SizedBox(height: 15),
                  _buildOCRQualitySelector(),
                  const SizedBox(height: 15),
                  _buildHandwritingModeSelector(),
                  const SizedBox(height: 15),
                  _buildOCRButton(),
                ],
                const SizedBox(height: 20),
                if (_statusMessage.isNotEmpty) _buildStatusCard(),
                if (_extractedText.isNotEmpty) _buildResultCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return _buildGlassCard(
      child: const Column(
        children: [
          Icon(Icons.document_scanner_outlined, size: 50, color: Colors.white),
          SizedBox(height: 10),
          Text(
            'Lensify',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1.2,
            ),
          ),
          Text(
            'OCR Scanner & PDF',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white70,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildModeButton(
              label: 'Tek Resim',
              isSelected: !_isBatchMode,
              onTap: () => _switchMode(false),
            ),
          ),
          Expanded(
            child: _buildModeButton(
              label: 'Çoklu Resim',
              isSelected: _isBatchMode,
              onTap: () => _switchMode(true),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Container(
      height: 45,
      decoration: BoxDecoration(
        color: isSelected 
          ? Colors.white.withValues(alpha: 0.3) 
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
                color: isSelected ? Colors.white : Colors.white60,
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
                child: const Text(
                  'Temizle',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedImages.length,
              itemBuilder: (context, index) {
                return Container(
                  width: 140,
                  margin: const EdgeInsets.only(right: 10),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Image.file(
                          _selectedImages[index],
                          width: 140,
                          height: 200,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 5,
                        right: 5,
                        child: Container(
                          width: 25,
                          height: 25,
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            onPressed: () => _removeImageFromBatch(index),
                            icon: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 5,
                        left: 5,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
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
    return SizedBox(
      height: 250,
      child: const Center(
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
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25),
              image: DecorationImage(
                image: FileImage(_selectedImage!),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Positioned(
            top: 10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_photo_alternate_outlined,
            size: 60,
            color: Colors.white60,
          ),
          SizedBox(height: 15),
          Text(
            'Resim Seçin',
            style: TextStyle(
              fontSize: 18,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 5),
          Text(
            'Kamera veya galeri kullanarak\nmetin içeren bir resim seçin',
            textAlign: TextAlign.center,
            style: TextStyle(
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
                label: _isPickingImage ? 'Bekleyiniz...' : 'Kamera',
                onTap: () => _isBatchMode ? _pickBatchImages(ImageSource.camera) : _pickImage(ImageSource.camera),
                isEnabled: !_isProcessing && !_isPickingImage,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: _buildActionButton(
                icon: Icons.photo_library_outlined,
                label: _isPickingImage ? 'Bekleyiniz...' : 'Galeri',
                onTap: () => _isBatchMode ? _pickBatchImages(ImageSource.gallery) : _pickImage(ImageSource.gallery),
                isEnabled: !_isProcessing && !_isPickingImage,
              ),
            ),
          ],
        ),
      ],
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
                  label: 'Temel',
                  level: ImageEnhancementLevel.basic,
                  icon: Icons.auto_fix_normal_outlined,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildEnhancementButton(
                  label: 'Gelişmiş',
                  level: ImageEnhancementLevel.advanced,
                  icon: Icons.auto_fix_high_outlined,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildEnhancementButton(
                  label: 'Otomatik',
                  level: ImageEnhancementLevel.auto,
                  icon: Icons.auto_awesome_outlined,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildEnhancementButton(
                  label: 'Belge',
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
        return 'Temel';
      case ImageEnhancementLevel.advanced:
        return 'Gelişmiş';
      case ImageEnhancementLevel.auto:
        return 'Otomatik';
      case ImageEnhancementLevel.document:
        return 'Belge';
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
              const Text(
                'OCR Kalitesi',
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
                  label: 'Hızlı',
                  subtitle: 'ML Kit',
                  quality: OCRQuality.fast,
                  icon: Icons.flash_on_outlined,
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildOCRQualityButton(
                  label: 'Dengeli',
                  subtitle: '2 Motor',
                  quality: OCRQuality.balanced,
                  icon: Icons.balance_outlined,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildOCRQualityButton(
                  label: 'Doğru',
                  subtitle: 'Tüm Motor',
                  quality: OCRQuality.accurate,
                  icon: Icons.verified_outlined,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildOCRQualityButton(
                  label: 'Premium',
                  subtitle: 'Cloud',
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
        return 'Hızlı';
      case OCRQuality.balanced:
        return 'Dengeli';
      case OCRQuality.accurate:
        return 'Doğru';
      case OCRQuality.premium:
        return 'Premium';
    }
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

  Widget _buildHandwritingModeSelector() {
    return _buildGlassCard(
      child: Row(
        children: [
          const Icon(Icons.edit_outlined, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'El Yazısı Tanıma',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Not fotoğraflarından el yazısını metne dönüştür',
                  style: TextStyle(
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
                ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Metin Çıkarılıyor...',
                        style: TextStyle(
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
                        _isBatchMode ? 'Toplu Metin Çıkar' : 'Metin Çıkar',
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
                _isBatchMode ? 'Toplu Çıkarılan Metin' : 'Çıkarılan Metin',
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
                  label: 'Düzenle',
                  color: Colors.green,
                  onTap: _openTextEditor,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildResultButton(
                  icon: Icons.copy_outlined,
                  label: 'Kopyala',
                  color: Colors.blue,
                  onTap: _copyToClipboard,
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

  Widget _buildGlassCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: child,
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_isPickingImage) return;

    _updateStatus(
      isPickingImage: true,
      message: source == ImageSource.gallery
          ? 'Galeri açılıyor... (Lütfen bekleyiniz)'
          : 'Kamera açılıyor...',
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
          ? 'Galeri açılıyor... (Çoklu mod)'
          : 'Kamera açılıyor... (Çoklu mod)',
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
      _showPermissionDialog('Kamera izni gerekli');
      return false;
    }
    return true;
  }

  void _handleImagePickerError(dynamic e) {
    _updateStatus(
      isPickingImage: false,
      message: 'Galeri hatası! Tekrar deneyin.',
    );
    _clearStatusAfterDelay(3);

    if (e.toString().contains('zaman aşımı')) {
      _showErrorDialog('Galeri açılırken sorun oluştu. Lütfen tekrar deneyin.');
    }
  }

  Future<void> _performOCR() async {
    if (_selectedImage == null && _selectedImages.isEmpty) return;

    _updateStatus(isProcessing: true, message: 'Görüntü iyileştiriliyor...');

    try {
      if (_selectedImage != null) {
        // Tek resim OCR (Enhancement + OCR)
        await _performSingleImageOCR(_selectedImage!);
      } else if (_selectedImages.isNotEmpty) {
        // Batch OCR
        await _performBatchOCR();
      }
    } catch (e) {
      _updateStatus(
        isProcessing: false,
        message: 'OCR işlemi sırasında hata oluştu',
        extractedText: 'OCR işlemi sırasında hata oluştu',
      );
      _showErrorDialog('Metin çıkarma sırasında hata oluştu');
    }
  }

  Future<void> _performSingleImageOCR(File imageFile) async {
    try {
      // 1. Görüntü iyileştirme
      _updateStatus(isProcessing: true, message: 'Görüntü optimize ediliyor...');
      
      final optimizedFile = await ImageProcessor.optimizeForOCR(
        imageFile,
        level: _enhancementLevel,
      );

      // 2. OCR işlemi - Çoklu motor desteği
      _updateStatus(
        isProcessing: true, 
        message: _getOCRProcessingMessage(_ocrQuality),
      );
      
      final ocrResult = await OCREngineManager.performOCR(
        optimizedFile,
        quality: _ocrQuality,
        language: 'tur',
        isHandwritingMode: _isHandwritingMode,
      );

      // OCR geçmişine ekle
      _ocrHistory.add(ocrResult);
      
      _updateStatus(
        isProcessing: false,
        message: _buildOCRResultMessage(ocrResult),
        extractedText: ocrResult.text.isEmpty ? 'Metin bulunamadı' : ocrResult.text,
      );

      // 3. Optimize edilmiş dosyayı temizle (orijinal değilse)
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
        return 'Metin çıkarılıyor (Hızlı)...';
      case OCRQuality.balanced:
        return 'Metin çıkarılıyor (2 motor)...';
      case OCRQuality.accurate:
        return 'Metin çıkarılıyor (Yüksek doğruluk)...';
      case OCRQuality.premium:
        return 'Metin çıkarılıyor (Premium)...';
    }
  }

  String _buildOCRResultMessage(OCRResult result) {
    if (!result.isSuccess) {
      return 'OCR işlemi başarısız: ${result.errorMessage ?? "Bilinmeyen hata"}';
    }
    
    if (result.text.isEmpty) {
      return 'Metin bulunamadı (${result.engine.displayName})';
    }
    
    final processingTime = result.processingTime.inMilliseconds;
    final confidence = (result.confidence * 100).toStringAsFixed(0);
    
    return 'Metin başarıyla çıkarıldı! ✨\n'
           '${result.engine.displayName} • ${processingTime}ms • %$confidence güven';
  }

  Future<void> _performBatchOCR() async {
    final List<String> allExtractedTexts = [];
    final List<File> optimizedFiles = [];
    final List<OCRResult> batchResults = [];
    
    for (int i = 0; i < _selectedImages.length; i++) {
      try {
        // 1. Görüntü iyileştirme
        _updateStatus(
          isProcessing: true,
          message: 'Resim ${i + 1}/${_selectedImages.length} optimize ediliyor...',
        );
        
        final optimizedFile = await ImageProcessor.optimizeForOCR(
          _selectedImages[i],
          level: _enhancementLevel,
        );
        optimizedFiles.add(optimizedFile);

        // 2. OCR işlemi - Çoklu motor desteği
        _updateStatus(
          isProcessing: true,
          message: 'Resim ${i + 1}/${_selectedImages.length} ${_getOCRProcessingMessage(_ocrQuality).toLowerCase()}',
        );
        
        final ocrResult = await OCREngineManager.performOCR(
          optimizedFile,
          quality: _ocrQuality,
          language: 'tur',
          isHandwritingMode: _isHandwritingMode,
        );
        
        batchResults.add(ocrResult);
        _ocrHistory.add(ocrResult);
        
        // Sonuç formatla
        if (ocrResult.isSuccess && ocrResult.text.isNotEmpty) {
          final confidence = (ocrResult.confidence * 100).toStringAsFixed(0);
          final engine = ocrResult.engine.displayName;
          allExtractedTexts.add(
            '--- Sayfa ${i + 1} ---\n'
            '[$engine • %$confidence güven]\n\n'
            '${ocrResult.text}'
          );
        } else {
          allExtractedTexts.add(
            '--- Sayfa ${i + 1} ---\n'
            '[${ocrResult.isSuccess ? "Metin bulunamadı" : "Hata: ${ocrResult.errorMessage}"}]'
          );
        }
        
        // Kısa bekleme
        await Future.delayed(const Duration(milliseconds: 300));
      } catch (e) {
        allExtractedTexts.add('--- Sayfa ${i + 1} ---\n\n[Hata: Metin çıkarılamadı]');
      }
    }
    
    // 3. Optimize edilmiş dosyaları temizle
    for (final optimizedFile in optimizedFiles) {
      if (!_selectedImages.any((original) => original.path == optimizedFile.path)) {
        try {
          await optimizedFile.delete();
        } catch (e) {
          // Silme hatası önemli değil
        }
      }
    }
    
    final combinedText = allExtractedTexts.join('\n\n');
    
    // Batch performans özeti
    final successfulResults = batchResults.where((r) => r.isSuccess && r.text.isNotEmpty).length;
    final avgTime = batchResults.map((r) => r.processingTime.inMilliseconds).reduce((a, b) => a + b) / batchResults.length;
    
    _updateStatus(
      isProcessing: false,
      message: 'Toplu OCR tamamlandı! ✨\n'
               '$successfulResults/${_selectedImages.length} başarılı • ${avgTime.toStringAsFixed(0)}ms ort.',
      extractedText: combinedText.isEmpty ? 'Hiçbir resimde metin bulunamadı' : combinedText,
    );
  }

  void _switchMode(bool isBatchMode) {
    setState(() {
      _isBatchMode = isBatchMode;
      _selectedImage = null; // Clear single image if switching to batch
      _selectedImages = []; // Clear batch images if switching to single
      _extractedText = ''; // Clear extracted text
      _statusMessage = '';
    });
  }



  void _clearBatchImages() {
    setState(() {
      _selectedImages = [];
      _statusMessage = 'Çoklu resimler temizlendi.';
      _clearStatusAfterDelay(2);
    });
  }

  void _removeImageFromBatch(int index) {
    setState(() {
      _selectedImages.removeAt(index);
      _statusMessage = '${_selectedImages.length} resim seçildi.';
      _clearStatusAfterDelay(2);
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

  void _clearStatusAfterDelay(int seconds) {
    Future.delayed(Duration(seconds: seconds), () {
      if (mounted) {
        setState(() {
          _statusMessage = '';
        });
      }
    });
  }

  void _openTextEditor() {
    if (_extractedText.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TextEditorScreen(initialText: _extractedText),
        ),
      );
    }
  }

  void _copyToClipboard() {
    if (_extractedText.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: _extractedText));
      _showSnackBar('Metin panoya kopyalandı', Colors.green);
    }
  }

  void _showSnackBar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _showPermissionDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('İzin Gerekli'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Ayarlara Git'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hata'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }
}
