import 'dart:io';
import 'dart:async';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'ocr_engine_manager.dart';
import 'performance_monitor.dart';
import 'memory_manager.dart';

/// Optimized OCR Manager for high-performance text recognition
class OptimizedOCRManager {
  static const int _maxConcurrentOperations = 3;
  static const int _maxImageSize = 10 * 1024 * 1024; // 10MB
  static const Duration _operationTimeout = Duration(seconds: 30);
  
  static final Map<String, Completer<OCRResult>> _pendingOperations = {};
  static final Queue<OCROperation> _operationQueue = Queue();
  static bool _isProcessing = false;

  /// Perform optimized single image OCR
  static Future<OCRResult> performOptimizedOCR(
    File imageFile, {
    OCRQuality quality = OCRQuality.balanced,
    String language = 'tur',
    bool isHandwritingMode = false,
  }) async {
    // Validate input
    if (!await imageFile.exists()) {
      return OCRResult.error(
        OCREngine.googleMLKit,
        'Image file does not exist',
        Duration.zero,
      );
    }

    // Check memory before processing
    await MemoryManager.checkMemoryUsage();
    
    // Create operation context
    final context = OCROperationContext(
      quality: quality,
      language: language,
      isHandwritingMode: isHandwritingMode,
      isBatchMode: false,
      imageCount: 1,
      imageSize: await imageFile.length(),
    );

    // Track performance
    return PerformanceMonitor.instance.trackOCROperation(
      () => _performOptimizedSingleOCR(imageFile, context),
      context,
    );
  }

  /// Perform optimized batch OCR with controlled concurrency
  static Future<List<OCRResult>> performOptimizedBatchOCR(
    List<File> imageFiles, {
    OCRQuality quality = OCRQuality.balanced,
    String language = 'tur',
    bool isHandwritingMode = false,
    int? maxConcurrent,
  }) async {
    if (imageFiles.isEmpty) {
      return [];
    }

    // Validate all files
    for (final file in imageFiles) {
      if (!await file.exists()) {
        throw Exception('One or more image files do not exist');
      }
    }

    // Check memory before batch processing
    await MemoryManager.checkMemoryUsage();

    final effectiveMaxConcurrent = maxConcurrent ?? _calculateOptimalConcurrency(imageFiles.length);
    final results = <OCRResult>[];
    final semaphore = Semaphore(effectiveMaxConcurrent);

    // Process images in batches
    final futures = imageFiles.map((file) async {
      await semaphore.acquire();
      try {
        final context = OCROperationContext(
          quality: quality,
          language: language,
          isHandwritingMode: isHandwritingMode,
          isBatchMode: true,
          imageCount: imageFiles.length,
          imageSize: await file.length(),
        );

        return await PerformanceMonitor.instance.trackOCROperation(
          () => _performOptimizedSingleOCR(file, context),
          context,
        );
      } finally {
        semaphore.release();
      }
    });

    // Wait for all operations to complete
    final batchResults = await Future.wait(futures);
    results.addAll(batchResults);

    // Cleanup memory after batch processing
    await MemoryManager.checkMemoryUsage();

    return results;
  }

  /// Perform optimized single OCR with enhanced preprocessing
  static Future<OCRResult> _performOptimizedSingleOCR(
    File imageFile,
    OCROperationContext context,
  ) async {
    final stopwatch = Stopwatch()..start();

    try {
      // 1. Preprocess image for optimal OCR performance
      final processedImage = await _preprocessImage(imageFile, context);
      
      // 2. Select optimal engine based on context
      final engine = _selectOptimalEngine(context);
      
      // 3. Perform OCR with timeout protection
      final result = await _performOCROperation(processedImage, engine, context)
          .timeout(_operationTimeout);

      stopwatch.stop();
      
      return OCRResult(
        text: result.text,
        confidence: result.confidence,
        engine: result.engine,
        processingTime: stopwatch.elapsed,
        isSuccess: result.isSuccess,
        errorMessage: result.errorMessage,
      );
    } catch (e) {
      stopwatch.stop();
      return OCRResult.error(
        OCREngine.googleMLKit,
        'OCR processing failed: ${e.toString()}',
        stopwatch.elapsed,
      );
    }
  }

  /// Enhanced image preprocessing for better OCR accuracy
  static Future<File> _preprocessImage(
    File imageFile,
    OCROperationContext context,
  ) async {
    final imageBytes = await imageFile.readAsBytes();
    
    // Decode image
    final image = img.decodeImage(imageBytes);
    if (image == null) {
      throw Exception('Failed to decode image');
    }

    // Apply preprocessing based on context
    img.Image processedImage = image;

    // 1. Resize if too large (memory optimization)
    if (image.width > 1920 || image.height > 1080) {
      processedImage = img.copyResize(
        processedImage,
        width: 1920,
        height: 1080,
        interpolation: img.Interpolation.linear,
      );
    }

    // 2. Enhance contrast for better text recognition
    processedImage = img.contrast(processedImage, contrast: 1.2);

    // 3. Apply noise reduction
    processedImage = img.gaussianBlur(processedImage, radius: 1);

    // 4. Convert to grayscale for better OCR
    processedImage = img.grayscale(processedImage);

    // 5. Apply adaptive threshold for better text separation
    processedImage = _applyAdaptiveThreshold(processedImage);

    // Save processed image to temporary file
    final tempDir = Directory.systemTemp;
    final tempFile = File('${tempDir.path}/processed_${DateTime.now().millisecondsSinceEpoch}.jpg');
    
    final processedBytes = img.encodeJpg(processedImage, quality: 90);
    await tempFile.writeAsBytes(processedBytes);

    return tempFile;
  }

  /// Apply adaptive threshold for better text recognition
  static img.Image _applyAdaptiveThreshold(img.Image image) {
    final width = image.width;
    final height = image.height;
    final result = img.Image(width: width, height: height);

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final pixel = image.getPixel(x, y);
        final gray = img.getLuminance(pixel);
        
        // Calculate local threshold
        final localThreshold = _calculateLocalThreshold(image, x, y, 15);
        
        // Apply threshold
        final newGray = gray > localThreshold ? 255 : 0;
        result.setPixel(x, y, img.ColorRgb8(newGray, newGray, newGray));
      }
    }

    return result;
  }

  /// Calculate local threshold for adaptive thresholding
  static int _calculateLocalThreshold(
    img.Image image,
    int centerX,
    int centerY,
    int windowSize,
  ) {
    int sum = 0;
    int count = 0;
    final halfWindow = windowSize ~/ 2;

    for (int y = centerY - halfWindow; y <= centerY + halfWindow; y++) {
      for (int x = centerX - halfWindow; x <= centerX + halfWindow; x++) {
        if (x >= 0 && x < image.width && y >= 0 && y < image.height) {
          final pixel = image.getPixel(x, y);
          sum += img.getLuminance(pixel).round();
          count++;
        }
      }
    }

    return count > 0 ? (sum ~/ count) : 128;
  }

  /// Select optimal OCR engine based on context
  static OCREngine _selectOptimalEngine(OCROperationContext context) {
    if (context.isHandwritingMode) {
      return OCREngine.googleMLKitHandwriting;
    }

    switch (context.quality) {
      case OCRQuality.fast:
        return OCREngine.googleMLKit;
      case OCRQuality.balanced:
        return OCREngine.googleMLKit; // Primary engine
      case OCRQuality.accurate:
        return OCREngine.tesseract; // More accurate for complex text
      case OCRQuality.premium:
        return OCREngine.cloudVision;
    }
  }

  /// Perform OCR operation with error handling
  static Future<OCRResult> _performOCROperation(
    File imageFile,
    OCREngine engine,
    OCROperationContext context,
  ) async {
    try {
      switch (engine) {
        case OCREngine.googleMLKit:
          return await _performGoogleMLKitOCR(imageFile, context);
        case OCREngine.googleMLKitHandwriting:
          return await _performGoogleMLKitHandwritingOCR(imageFile, context);
        case OCREngine.tesseract:
          return await _performTesseractOCR(imageFile, context);
        case OCREngine.cloudVision:
          return await _performCloudVisionOCR(imageFile, context);
      }
    } catch (e) {
      // Fallback to Google ML Kit if primary engine fails
      if (engine != OCREngine.googleMLKit) {
        return await _performGoogleMLKitOCR(imageFile, context);
      }
      rethrow;
    }
  }

  /// Perform Google ML Kit OCR
  static Future<OCRResult> _performGoogleMLKitOCR(
    File imageFile,
    OCROperationContext context,
  ) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      final result = await OCREngineManager.performOCR(
        imageFile,
        quality: context.quality,
        language: context.language,
        isHandwritingMode: context.isHandwritingMode,
      );
      
      stopwatch.stop();
      return result;
    } catch (e) {
      stopwatch.stop();
      return OCRResult.error(
        OCREngine.googleMLKit,
        e.toString(),
        stopwatch.elapsed,
      );
    }
  }

  /// Perform Google ML Kit Handwriting OCR
  static Future<OCRResult> _performGoogleMLKitHandwritingOCR(
    File imageFile,
    OCROperationContext context,
  ) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      final result = await OCREngineManager.performOCR(
        imageFile,
        quality: context.quality,
        language: context.language,
        isHandwritingMode: true,
      );
      
      stopwatch.stop();
      return result;
    } catch (e) {
      stopwatch.stop();
      return OCRResult.error(
        OCREngine.googleMLKitHandwriting,
        e.toString(),
        stopwatch.elapsed,
      );
    }
  }

  /// Perform Tesseract OCR
  static Future<OCRResult> _performTesseractOCR(
    File imageFile,
    OCROperationContext context,
  ) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      final result = await OCREngineManager.performOCR(
        imageFile,
        quality: context.quality,
        language: context.language,
        isHandwritingMode: context.isHandwritingMode,
      );
      
      stopwatch.stop();
      return result;
    } catch (e) {
      stopwatch.stop();
      return OCRResult.error(
        OCREngine.tesseract,
        e.toString(),
        stopwatch.elapsed,
      );
    }
  }

  /// Perform Cloud Vision OCR (Premium feature)
  static Future<OCRResult> _performCloudVisionOCR(
    File imageFile,
    OCROperationContext context,
  ) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      // TODO: Implement Cloud Vision API integration
      // For now, fallback to Google ML Kit
      final result = await _performGoogleMLKitOCR(imageFile, context);
      
      stopwatch.stop();
      return result;
    } catch (e) {
      stopwatch.stop();
      return OCRResult.error(
        OCREngine.cloudVision,
        e.toString(),
        stopwatch.elapsed,
      );
    }
  }

  /// Calculate optimal concurrency based on device capabilities and image count
  static int _calculateOptimalConcurrency(int imageCount) {
    // Conservative approach to prevent memory issues
    if (imageCount <= 3) {
      return imageCount; // Process all at once for small batches
    } else if (imageCount <= 10) {
      return 3; // Moderate concurrency
    } else {
      return 2; // Conservative for large batches
    }
  }
}

/// Semaphore for controlling concurrent operations
class Semaphore {
  final int _maxCount;
  int _currentCount;
  final Queue<Completer<void>> _waiting = Queue();

  Semaphore(this._maxCount) : _currentCount = _maxCount;

  Future<void> acquire() async {
    if (_currentCount > 0) {
      _currentCount--;
      return;
    }

    final completer = Completer<void>();
    _waiting.add(completer);
    await completer.future;
  }

  void release() {
    if (_waiting.length > 0) {
      final completer = _waiting.removeFirst();
      completer?.complete();
    } else {
      _currentCount++;
    }
  }
}

/// OCR Operation for queue management
class OCROperation {
  final File imageFile;
  final OCROperationContext context;
  final Completer<OCRResult> completer;

  OCROperation({
    required this.imageFile,
    required this.context,
    required this.completer,
  });
}

/// Queue implementation for operation management
class Queue<T> {
  final List<T> _items = [];

  void add(T item) => _items.add(item);
  T? removeFirst() => _items.isNotEmpty ? _items.removeAt(0) : null;
  bool get isEmpty => _items.isEmpty;
  int get length => _items.length;
} 