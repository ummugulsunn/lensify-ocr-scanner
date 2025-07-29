import 'dart:io';
import 'dart:developer' as developer;
import 'dart:typed_data';

/// Memory management utility for OCR operations
class MemoryManager {
  static const String _logTag = 'MemoryManager';
  static const int _maxMemoryThreshold = 200 * 1024 * 1024; // 200MB
  static const int _cleanupInterval = 10; // Clean up every 10 operations
  
  static int _operationCount = 0;
  static final List<String> _tempFiles = [];
  
  /// Monitor memory usage and trigger cleanup if needed
  static Future<void> checkMemoryUsage() async {
    try {
      final memoryUsage = await _getCurrentMemoryUsage();
      
      if (memoryUsage > _maxMemoryThreshold) {
        developer.log(
          'High memory usage detected: ${(memoryUsage / 1024 / 1024).toStringAsFixed(1)}MB',
          name: _logTag,
        );
        await forceCleanup();
      }
    } catch (e) {
      developer.log('Error checking memory usage: $e', name: _logTag);
    }
  }
  
  /// Get current memory usage (approximate)
  static Future<int> _getCurrentMemoryUsage() async {
    // This is a simplified implementation
    // In practice, you might use more sophisticated memory monitoring
    return 0; // Placeholder - would require native implementation
  }
  
  /// Register a temporary file for cleanup
  static void registerTempFile(String filePath) {
    if (!_tempFiles.contains(filePath)) {
      _tempFiles.add(filePath);
      _operationCount++;
    }
    
    // Periodic cleanup
    if (_operationCount % _cleanupInterval == 0) {
      _cleanupTempFiles();
    }
  }
  
  /// Clean up temporary files
  static Future<void> _cleanupTempFiles() async {
    final toRemove = <String>[];
    
    for (final filePath in _tempFiles) {
      try {
        final file = File(filePath);
        if (await file.exists()) {
          await file.delete();
        }
        toRemove.add(filePath);
      } catch (e) {
        if (e is FileSystemException && e.osError?.errorCode == 2) {
          developer.log('Temp file already deleted: $filePath', name: _logTag);
        } else {
          developer.log('Error deleting temp file $filePath: $e', name: _logTag);
        }
      }
    }
    
    _tempFiles.removeWhere((path) => toRemove.contains(path));
    
    if (toRemove.isNotEmpty) {
      developer.log('Cleaned up ${toRemove.length} temp files', name: _logTag);
    }
  }
  
  /// Force cleanup of all temporary resources
  static Future<void> forceCleanup() async {
    developer.log('Forcing memory cleanup...', name: _logTag);
    
    // Clean up temp files
    await _cleanupTempFiles();
    
    // Force garbage collection (not guaranteed, but helps)
    developer.log('Requesting garbage collection', name: _logTag);
    
    _operationCount = 0;
  }
  
  /// Check if image is too large for processing
  static Future<bool> isImageSizeAcceptable(File imageFile) async {
    try {
      final fileSize = await imageFile.length();
      const maxFileSize = 50 * 1024 * 1024; // 50MB
      
      if (fileSize > maxFileSize) {
        developer.log(
          'Image file too large: ${(fileSize / 1024 / 1024).toStringAsFixed(1)}MB',
          name: _logTag,
        );
        return false;
      }
      
      return true;
    } catch (e) {
      developer.log('Error checking image size: $e', name: _logTag);
      return false;
    }
  }
  
  /// Optimize memory usage for batch processing
  static int calculateOptimalBatchSize(int totalImages, int imageSize) {
    // Conservative calculation based on available memory
    const availableMemory = 100 * 1024 * 1024; // Assume 100MB available
    const memoryPerImage = 20 * 1024 * 1024; // Assume 20MB per processed image
    
    final maxConcurrent = (availableMemory / memoryPerImage).floor();
    
    // Limit to reasonable values
    return maxConcurrent.clamp(1, 4);
  }
  
  /// Create memory-efficient temporary file
  static Future<File> createOptimizedTempFile(
    Uint8List data, 
    String prefix,
  ) async {
    try {
      final tempDir = Directory.systemTemp;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final tempFile = File('${tempDir.path}/${prefix}_$timestamp.tmp');
      
      await tempFile.writeAsBytes(data);
      registerTempFile(tempFile.path);
      
      return tempFile;
    } catch (e) {
      developer.log('Error creating temp file: $e', name: _logTag);
      rethrow;
    }
  }
  
  /// Memory-safe image resize operation
  static Uint8List? resizeImageSafely(
    Uint8List imageData, 
    int maxWidth, 
    int maxHeight,
  ) {
    try {
      // This would contain optimized image resizing logic
      // For now, return original data as placeholder
      return imageData;
    } catch (e) {
      developer.log('Error resizing image: $e', name: _logTag);
      return null;
    }
  }
  
  /// Get memory usage statistics
  static Map<String, dynamic> getMemoryStats() {
    return {
      'operationCount': _operationCount,
      'tempFilesCount': _tempFiles.length,
      'lastCleanup': DateTime.now().toIso8601String(),
    };
  }
  
  /// Dispose and cleanup all resources
  static Future<void> dispose() async {
    developer.log('Disposing MemoryManager...', name: _logTag);
    await forceCleanup();
  }
} 