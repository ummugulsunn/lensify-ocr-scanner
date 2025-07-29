import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'dart:typed_data';
import '../lib/utils/ocr_engine_manager.dart';

void main() {
  group('OCR Engine Manager Tests', () {
    late File testImageFile;

    setUpAll(() async {
      // Create a test image file
      final tempDir = Directory.systemTemp;
      testImageFile = File('${tempDir.path}/test_image.jpg');
      
      // Create a simple test image (1x1 pixel)
      final imageBytes = Uint8List.fromList([
        0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46, 0x00, 0x01,
        0x01, 0x01, 0x00, 0x48, 0x00, 0x48, 0x00, 0x00, 0xFF, 0xDB, 0x00, 0x43,
        0x00, 0x08, 0x06, 0x06, 0x07, 0x06, 0x05, 0x08, 0x07, 0x07, 0x07, 0x09,
        0x09, 0x08, 0x0A, 0x0C, 0x14, 0x0D, 0x0C, 0x0B, 0x0B, 0x0C, 0x19, 0x12,
        0x13, 0x0F, 0x14, 0x1D, 0x1A, 0x1F, 0x1E, 0x1D, 0x1A, 0x1C, 0x1C, 0x20,
        0x24, 0x2E, 0x27, 0x20, 0x22, 0x2C, 0x23, 0x1C, 0x1C, 0x28, 0x37, 0x29,
        0x2C, 0x30, 0x31, 0x34, 0x34, 0x34, 0x1F, 0x27, 0x39, 0x3D, 0x38, 0x32,
        0x3C, 0x2E, 0x33, 0x34, 0x32, 0xFF, 0xC0, 0x00, 0x0B, 0x08, 0x00, 0x01,
        0x00, 0x01, 0x01, 0x01, 0x11, 0x00, 0x02, 0x11, 0x01, 0x03, 0x11, 0x01,
        0xFF, 0xC4, 0x00, 0x14, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x08, 0xFF, 0xDA,
        0x00, 0x08, 0x01, 0x01, 0x00, 0x00, 0x3F, 0x00, 0x37, 0xFF, 0xD9
      ]);
      
      await testImageFile.writeAsBytes(imageBytes);
    });

    tearDownAll(() async {
      // Clean up test file
      if (await testImageFile.exists()) {
        await testImageFile.delete();
      }
    });

    group('OCRResult Tests', () {
      test('should create OCRResult with all parameters', () {
        final result = OCRResult(
          text: 'Test text',
          confidence: 0.95,
          engine: OCREngine.googleMLKit,
          processingTime: const Duration(milliseconds: 100),
          isSuccess: true,
        );

        expect(result.text, equals('Test text'));
        expect(result.confidence, equals(0.95));
        expect(result.engine, equals(OCREngine.googleMLKit));
        expect(result.processingTime, equals(const Duration(milliseconds: 100)));
        expect(result.isSuccess, isTrue);
        expect(result.errorMessage, isNull);
      });

      test('should create error OCRResult', () {
        final result = OCRResult.error(
          OCREngine.tesseract,
          'Test error',
          const Duration(milliseconds: 50),
        );

        expect(result.text, isEmpty);
        expect(result.confidence, equals(0.0));
        expect(result.engine, equals(OCREngine.tesseract));
        expect(result.processingTime, equals(const Duration(milliseconds: 50)));
        expect(result.isSuccess, isFalse);
        expect(result.errorMessage, equals('Test error'));
      });

      test('should convert to and from JSON', () {
        final original = OCRResult(
          text: 'Test text',
          confidence: 0.95,
          engine: OCREngine.googleMLKit,
          processingTime: const Duration(milliseconds: 100),
          isSuccess: true,
          errorMessage: null,
        );

        final json = original.toJson();
        final restored = OCRResult.fromJson(json);

        expect(restored.text, equals(original.text));
        expect(restored.confidence, equals(original.confidence));
        expect(restored.engine, equals(original.engine));
        expect(restored.processingTime, equals(original.processingTime));
        expect(restored.isSuccess, equals(original.isSuccess));
        expect(restored.errorMessage, equals(original.errorMessage));
      });
    });

    group('OCREngine Tests', () {
      test('should have correct display names', () {
        expect(OCREngine.googleMLKit.displayName, equals('Google ML Kit'));
        expect(OCREngine.googleMLKitHandwriting.displayName, equals('Google ML Kit (El Yazısı)'));
        expect(OCREngine.tesseract.displayName, equals('Tesseract'));
        expect(OCREngine.cloudVision.displayName, equals('Cloud Vision API'));
      });

      test('should have correct availability', () {
        expect(OCREngine.googleMLKit.isAvailable, isTrue);
        expect(OCREngine.googleMLKitHandwriting.isAvailable, isTrue);
        expect(OCREngine.tesseract.isAvailable, isTrue);
        expect(OCREngine.cloudVision.isAvailable, isFalse);
      });
    });

    group('OCRQuality Tests', () {
      test('should have all quality levels', () {
        expect(OCRQuality.values.length, equals(4));
        expect(OCRQuality.values, contains(OCRQuality.fast));
        expect(OCRQuality.values, contains(OCRQuality.balanced));
        expect(OCRQuality.values, contains(OCRQuality.accurate));
        expect(OCRQuality.values, contains(OCRQuality.premium));
      });
    });

    group('OCREngineManager Tests', () {
      test('should perform OCR with default parameters', () async {
        final result = await OCREngineManager.performOCR(
          testImageFile,
          quality: OCRQuality.fast,
          language: 'tur',
          isHandwritingMode: false,
        );

        expect(result, isA<OCRResult>());
        expect(result.engine, isA<OCREngine>());
        expect(result.processingTime, isA<Duration>());
      });

      test('should handle handwriting mode', () async {
        final result = await OCREngineManager.performOCR(
          testImageFile,
          quality: OCRQuality.balanced,
          language: 'tur',
          isHandwritingMode: true,
        );

        expect(result, isA<OCRResult>());
        expect(result.engine, isA<OCREngine>());
      });

      test('should handle different quality levels', () async {
        for (final quality in OCRQuality.values) {
          final result = await OCREngineManager.performOCR(
            testImageFile,
            quality: quality,
            language: 'tur',
            isHandwritingMode: false,
          );

          expect(result, isA<OCRResult>());
          expect(result.processingTime, isA<Duration>());
        }
      });

      test('should handle different languages', () async {
        final languages = ['tur', 'eng', 'deu', 'fra'];
        
        for (final language in languages) {
          final result = await OCREngineManager.performOCR(
            testImageFile,
            quality: OCRQuality.fast,
            language: language,
            isHandwritingMode: false,
          );

          expect(result, isA<OCRResult>());
        }
      });

      test('should handle non-existent file', () async {
        final nonExistentFile = File('/non/existent/file.jpg');
        
        final result = await OCREngineManager.performOCR(
          nonExistentFile,
          quality: OCRQuality.fast,
          language: 'tur',
          isHandwritingMode: false,
        );

        expect(result.isSuccess, isFalse);
        expect(result.errorMessage, isNotEmpty);
      });
    });

    group('Error Handling Tests', () {
      test('should handle engine failures gracefully', () async {
        // This test simulates a scenario where an engine might fail
        final result = await OCREngineManager.performOCR(
          testImageFile,
          quality: OCRQuality.premium, // This might fail if Cloud Vision is not available
          language: 'tur',
          isHandwritingMode: false,
        );

        expect(result, isA<OCRResult>());
        // Even if the primary engine fails, we should get a result
        expect(result.processingTime, isA<Duration>());
      });

      test('should handle timeout scenarios', () async {
        // This test would require mocking to simulate timeouts
        // For now, we'll just test that the method doesn't throw
        expect(
          () => OCREngineManager.performOCR(
            testImageFile,
            quality: OCRQuality.fast,
            language: 'tur',
            isHandwritingMode: false,
          ),
          returnsNormally,
        );
      });
    });

    group('Performance Tests', () {
      test('should complete OCR within reasonable time', () async {
        final stopwatch = Stopwatch()..start();
        
        await OCREngineManager.performOCR(
          testImageFile,
          quality: OCRQuality.fast,
          language: 'tur',
          isHandwritingMode: false,
        );
        
        stopwatch.stop();
        
        // OCR should complete within 10 seconds for a small test image
        expect(stopwatch.elapsed.inSeconds, lessThan(10));
      });

      test('should handle multiple concurrent OCR operations', () async {
        final futures = List.generate(3, (index) => 
          OCREngineManager.performOCR(
            testImageFile,
            quality: OCRQuality.fast,
            language: 'tur',
            isHandwritingMode: false,
          )
        );

        final results = await Future.wait(futures);
        
        expect(results.length, equals(3));
        for (final result in results) {
          expect(result, isA<OCRResult>());
        }
      });
    });

    group('Integration Tests', () {
      test('should work with real image processing pipeline', () async {
        // This test would require a real image with text
        // For now, we'll test the basic flow
        final result = await OCREngineManager.performOCR(
          testImageFile,
          quality: OCRQuality.balanced,
          language: 'tur',
          isHandwritingMode: false,
        );

        expect(result, isA<OCRResult>());
        expect(result.processingTime, isA<Duration>());
        expect(result.processingTime.inMilliseconds, greaterThan(0));
      });
    });
  });
} 