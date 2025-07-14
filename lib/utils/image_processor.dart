import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

class ImageProcessor {
  static const int _maxImageSize = 1920; // Max width/height for processing
  static const int _jpegQuality = 85; // Balanced quality vs size
  
  /// Görüntüyü OCR için optimize eder - Memory optimized version
  static Future<File> optimizeForOCR(File originalFile, {
    ImageEnhancementLevel level = ImageEnhancementLevel.auto,
  }) async {
    try {
      // Check file size first to prevent memory issues
      final fileSize = await originalFile.length();
      if (fileSize > 50 * 1024 * 1024) { // 50MB limit
        throw Exception('Görüntü çok büyük (>50MB). Daha küçük bir görüntü seçin.');
      }
      
      // Use compute() for heavy image processing to avoid blocking UI
      final optimizedBytes = await compute(_processImageInIsolate, ImageProcessingRequest(
        filePath: originalFile.path,
        level: level,
        maxSize: _maxImageSize,
        quality: _jpegQuality,
      ));
      
      if (optimizedBytes != null) {
        final optimizedFile = await _saveOptimizedImage(optimizedBytes, originalFile.path);
        return optimizedFile;
      } else {
        // Fallback to original file if processing fails
        return originalFile;
      }
    } catch (e) {
      // Hata durumunda orijinal dosyayı geri döndür
      return originalFile;
    }
  }

  /// Process image in isolate to prevent UI blocking
  static Uint8List? _processImageInIsolate(ImageProcessingRequest request) {
    try {
      // Read and decode image
      final bytes = File(request.filePath).readAsBytesSync();
      img.Image? image = img.decodeImage(bytes);
      
      if (image == null) return null;

      // Resize if too large (memory optimization)
      if (image.width > request.maxSize || image.height > request.maxSize) {
        final ratio = request.maxSize / (image.width > image.height ? image.width : image.height);
        image = img.copyResize(
          image,
          width: (image.width * ratio).round(),
          height: (image.height * ratio).round(),
          interpolation: img.Interpolation.linear, // Fast interpolation
        );
      }

      // Apply enhancement based on level
      switch (request.level) {
        case ImageEnhancementLevel.basic:
          image = _applyBasicEnhancement(image);
          break;
        case ImageEnhancementLevel.advanced:
          image = _applyAdvancedEnhancement(image);
          break;
        case ImageEnhancementLevel.auto:
          image = _applyAutoEnhancement(image);
          break;
        case ImageEnhancementLevel.document:
          image = _applyDocumentEnhancement(image);
          break;
      }

      // Encode with optimized quality
      return img.encodeJpg(image, quality: request.quality);
    } catch (e) {
      return null;
    }
  }

  /// Temel iyileştirmeler
  static img.Image _applyBasicEnhancement(img.Image image) {
    // Kontrast ve parlaklık ayarlama
    image = img.adjustColor(image, contrast: 1.2, brightness: 1.1);
    
    // Keskinlik artırma
    image = _applySharpenFilter(image);
    
    return image;
  }

  /// Gelişmiş iyileştirmeler
  static img.Image _applyAdvancedEnhancement(img.Image image) {
    // Temel iyileştirmeler
    image = _applyBasicEnhancement(image);
    
    // Gamma düzeltme
    image = img.adjustColor(image, gamma: 1.2);
    
    // Gürültü giderme
    image = img.gaussianBlur(image, radius: 1);
    image = _applySharpenFilter(image);
    
    return image;
  }

  /// Otomatik iyileştirme
  static img.Image _applyAutoEnhancement(img.Image image) {
    // Histogram analizi ile otomatik iyileştirme
    final stats = _analyzeImage(image);
    
    // Kontrast ve parlaklık otomatik ayarlama
    double brightness = 1.0;
    double contrast = 1.0;
    
    if (stats.averageBrightness < 100) {
      brightness = 1.2;
    } else if (stats.averageBrightness > 180) {
      brightness = 0.9;
    }
    
    if (stats.contrast < 50) {
      contrast = 1.3;
    }
    
    image = img.adjustColor(image, contrast: contrast, brightness: brightness);
    
    // Keskinlik artırma
    image = _applySharpenFilter(image);
    
    return image;
  }

  /// Belge için özelleştirilmiş iyileştirme
  static img.Image _applyDocumentEnhancement(img.Image image) {
    // Griye çevir
    image = img.grayscale(image);
    
    // Kontrast artır
    image = img.adjustColor(image, contrast: 1.5);
    
    // Threshold uygula
    image = _applyThreshold(image, 128);
    
    // Keskinlik artırma
    image = _applySharpenFilter(image);
    
    return image;
  }

  /// Basit sharpen filter
  static img.Image _applySharpenFilter(img.Image image) {
    final sharpenKernel = [
      0.0, -1.0, 0.0,
      -1.0, 5.0, -1.0,
      0.0, -1.0, 0.0
    ];
    
    return img.convolution(image, filter: sharpenKernel, div: 1, offset: 0);
  }

  /// Threshold uygular
  static img.Image _applyThreshold(img.Image image, int threshold) {
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        final gray = img.getLuminance(pixel);
        
        if (gray > threshold) {
          image.setPixel(x, y, img.ColorRgb8(255, 255, 255)); // Beyaz
        } else {
          image.setPixel(x, y, img.ColorRgb8(0, 0, 0)); // Siyah
        }
      }
    }
    
    return image;
  }

  /// Görüntü istatistiklerini analiz eder
  static ImageStats _analyzeImage(img.Image image) {
    int totalPixels = 0;
    int sumBrightness = 0;
    int darkPixels = 0;
    int brightPixels = 0;
    
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        final brightness = img.getLuminance(pixel).toInt();
        
        totalPixels++;
        sumBrightness += brightness;
        
        if (brightness < 128) {
          darkPixels++;
        } else {
          brightPixels++;
        }
      }
    }
    
    final averageBrightness = sumBrightness / totalPixels;
    final contrast = ((brightPixels - darkPixels).abs() / totalPixels) * 100;
    
    return ImageStats(
      averageBrightness: averageBrightness.toDouble(),
      contrast: contrast.toDouble(),
    );
  }

  /// Optimize edilmiş görüntüyü kaydeder
  static Future<File> _saveOptimizedImage(Uint8List bytes, String originalPath) async {
    final directory = File(originalPath).parent;
    final filename = 'optimized_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final optimizedFile = File('${directory.path}/$filename');
    
    await optimizedFile.writeAsBytes(bytes);
    return optimizedFile;
  }

  /// Preview için küçük boyutlu optimizasyon
  static Future<img.Image?> createPreview(File imageFile, ImageEnhancementLevel level) async {
    try {
      final bytes = await imageFile.readAsBytes();
      img.Image? image = img.decodeImage(bytes);
      
      if (image == null) return null;
      
      // Küçük boyuta resize et (preview için)
      image = img.copyResize(image, width: 300);
      
      // Enhancement uygula
      switch (level) {
        case ImageEnhancementLevel.basic:
          image = _applyBasicEnhancement(image);
          break;
        case ImageEnhancementLevel.advanced:
          image = _applyAdvancedEnhancement(image);
          break;
        case ImageEnhancementLevel.auto:
          image = _applyAutoEnhancement(image);
          break;
        case ImageEnhancementLevel.document:
          image = _applyDocumentEnhancement(image);
          break;
      }
      
      return image;
    } catch (e) {
      return null;
    }
  }
}

/// Enhancement seviyeleri
enum ImageEnhancementLevel {
  basic,     // Temel iyileştirmeler
  advanced,  // Gelişmiş iyileştirmeler
  auto,      // Otomatik optimizasyon
  document,  // Belge odaklı (binary)
}

/// Image processing request for isolate communication
class ImageProcessingRequest {
  final String filePath;
  final ImageEnhancementLevel level;
  final int maxSize;
  final int quality;
  
  ImageProcessingRequest({
    required this.filePath,
    required this.level,
    required this.maxSize,
    required this.quality,
  });
}

/// Görüntü istatistikleri
class ImageStats {
  final double averageBrightness;
  final double contrast;
  
  const ImageStats({
    required this.averageBrightness,
    required this.contrast,
  });
} 