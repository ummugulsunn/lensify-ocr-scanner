import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:flutter_tesseract_ocr/flutter_tesseract_ocr.dart';
import 'ocr_engine_manager.dart';

/// Async OCR processor using Dart Isolates for non-blocking operations
class AsyncOCRProcessor {
  /// Perform OCR in a separate isolate to avoid blocking the main thread
  static Future<OCRResult> performOCRAsync(OCRRequest request) async {
    try {
      // For ML Kit operations, we need to run on main thread due to platform channel restrictions
      // But we can optimize other parts and use compute() for heavy computations
      
      if (request.engine == OCREngine.tesseract) {
        // Tesseract can run in isolate
        return await compute(_performTesseractOCRInIsolate, request);
      } else {
        // ML Kit must run on main thread, but we optimize the process
        return await _performMLKitOCROptimized(request);
      }
    } catch (e) {
      return OCRResult.error(
        request.engine,
        'Async OCR failed: $e',
        Duration.zero,
      );
    }
  }
  
  /// Perform batch OCR with parallel processing
  static Future<List<OCRResult>> performBatchOCRAsync(
    List<OCRRequest> requests, {
    int maxConcurrent = 3, // Limit concurrent operations to prevent memory issues
  }) async {
    final results = <OCRResult>[];
    
    // Process requests in chunks to control memory usage
    for (int i = 0; i < requests.length; i += maxConcurrent) {
      final chunk = requests.skip(i).take(maxConcurrent).toList();
      
      // Process chunk in parallel
      final chunkResults = await Future.wait(
        chunk.map((request) => performOCRAsync(request)),
      );
      
      results.addAll(chunkResults);
      
      // Small delay to prevent overwhelming the system
      if (i + maxConcurrent < requests.length) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }
    
    return results;
  }
  
  /// Optimized ML Kit OCR for main thread
  static Future<OCRResult> _performMLKitOCROptimized(OCRRequest request) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      // Pre-process image asynchronously
      final optimizedImageData = await compute(_optimizeImageData, request.imageBytes);
      
      // Create input image from optimized data
      final tempFile = await _createTempFile(optimizedImageData);
      final inputImage = InputImage.fromFilePath(tempFile.path);
      
      // Perform OCR on main thread (required for ML Kit)
      final result = await _performMLKitOCR(inputImage, request.engine);
      
      // Cleanup temp file
      await tempFile.delete();
      
      stopwatch.stop();
      
      return OCRResult(
        text: result,
        confidence: result.isNotEmpty ? 0.85 : 0.0,
        engine: request.engine,
        processingTime: stopwatch.elapsed,
        isSuccess: true,
      );
    } catch (e) {
      stopwatch.stop();
      return OCRResult.error(request.engine, e.toString(), stopwatch.elapsed);
    }
  }
  
  /// Perform ML Kit OCR
  static Future<String> _performMLKitOCR(InputImage inputImage, OCREngine engine) async {
    late final TextRecognizer recognizer;
    
    switch (engine) {
      case OCREngine.googleMLKit:
        recognizer = TextRecognizer();
        break;
      case OCREngine.googleMLKitHandwriting:
        recognizer = TextRecognizer(script: TextRecognitionScript.latin);
        break;
      default:
        throw Exception('Unsupported ML Kit engine: $engine');
    }
    
    try {
      final recognizedText = await recognizer.processImage(inputImage);
      return recognizedText.text;
    } finally {
      await recognizer.close();
    }
  }
  
  /// Tesseract OCR in isolate (top-level function for compute())
  static Future<OCRResult> _performTesseractOCRInIsolate(OCRRequest request) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      // Create temp file from bytes
      final tempFile = await _createTempFile(request.imageBytes);
      
      // Perform Tesseract OCR
      final result = await FlutterTesseractOcr.extractText(
        tempFile.path,
        language: request.language,
        args: {
          "preserve_interword_spaces": "1",
          "psm": "6", // Uniform block of text
          "oem": "3", // Default OCR Engine Mode
        },
      );
      
      // Cleanup
      await tempFile.delete();
      
      stopwatch.stop();
      
      return OCRResult(
        text: result.trim(),
        confidence: result.trim().isNotEmpty ? 0.75 : 0.0,
        engine: OCREngine.tesseract,
        processingTime: stopwatch.elapsed,
        isSuccess: true,
      );
    } catch (e) {
      stopwatch.stop();
      return OCRResult.error(OCREngine.tesseract, e.toString(), stopwatch.elapsed);
    }
  }
  
  /// Optimize image data in isolate (top-level function for compute())
  static Uint8List _optimizeImageData(Uint8List imageBytes) {
    // This is a simplified optimization
    // In practice, you might want to resize, compress, or enhance the image
    return imageBytes;
  }
  
  /// Create temporary file from bytes
  static Future<File> _createTempFile(Uint8List bytes) async {
    final tempDir = Directory.systemTemp;
    final tempFile = File('${tempDir.path}/temp_ocr_${DateTime.now().millisecondsSinceEpoch}.jpg');
    await tempFile.writeAsBytes(bytes);
    return tempFile;
  }
}

/// OCR request model for isolate communication
class OCRRequest {
  final Uint8List imageBytes;
  final OCREngine engine;
  final String language;
  final OCRQuality quality;
  final bool isHandwriting;
  
  OCRRequest({
    required this.imageBytes,
    required this.engine,
    required this.language,
    required this.quality,
    required this.isHandwriting,
  });
}

/// Enhanced OCR context for better performance tracking
class EnhancedOCRContext {
  final String operationId;
  final DateTime startTime;
  final int imageCount;
  final int totalImageSize;
  final OCRQuality quality;
  final bool isBatchMode;
  final bool isParallelProcessing;
  
  EnhancedOCRContext({
    required this.operationId,
    required this.startTime,
    required this.imageCount,
    required this.totalImageSize,
    required this.quality,
    required this.isBatchMode,
    required this.isParallelProcessing,
  });
}

/// Performance-optimized OCR manager
class OptimizedOCRManager {
  /// Perform single OCR with async processing
  static Future<OCRResult> performOptimizedOCR(
    File imageFile, {
    OCRQuality quality = OCRQuality.balanced,
    String language = 'tur',
    bool isHandwritingMode = false,
  }) async {
    // Read image bytes asynchronously
    final imageBytes = await imageFile.readAsBytes();
    
    // Choose optimal engine based on quality
    final engine = _selectOptimalEngine(quality, isHandwritingMode);
    
    final request = OCRRequest(
      imageBytes: imageBytes,
      engine: engine,
      language: language,
      quality: quality,
      isHandwriting: isHandwritingMode,
    );
    
    return await AsyncOCRProcessor.performOCRAsync(request);
  }
  
  /// Perform batch OCR with parallel processing
  static Future<List<OCRResult>> performOptimizedBatchOCR(
    List<File> imageFiles, {
    OCRQuality quality = OCRQuality.balanced,
    String language = 'tur',
    bool isHandwritingMode = false,
    int maxConcurrent = 3,
  }) async {
    // Create requests asynchronously
    final requests = await Future.wait(
      imageFiles.map((file) async {
        final bytes = await file.readAsBytes();
        return OCRRequest(
          imageBytes: bytes,
          engine: _selectOptimalEngine(quality, isHandwritingMode),
          language: language,
          quality: quality,
          isHandwriting: isHandwritingMode,
        );
      }),
    );
    
    return await AsyncOCRProcessor.performBatchOCRAsync(
      requests,
      maxConcurrent: maxConcurrent,
    );
  }
  
  /// Select optimal engine based on quality and mode
  static OCREngine _selectOptimalEngine(OCRQuality quality, bool isHandwriting) {
    if (isHandwriting) {
      return OCREngine.googleMLKitHandwriting;
    }
    
    switch (quality) {
      case OCRQuality.fast:
        return OCREngine.googleMLKit;
      case OCRQuality.balanced:
        return OCREngine.googleMLKit; // Start with fastest for async processing
      case OCRQuality.accurate:
        return OCREngine.tesseract; // Can run in isolate
      case OCRQuality.premium:
        return OCREngine.googleMLKit; // Premium features will be added later
    }
  }
}
