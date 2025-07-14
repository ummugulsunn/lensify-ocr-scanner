import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';
import 'dart:developer' as developer;
import 'ocr_engine_manager.dart';
import 'image_processor.dart';

/// OCR sonuçları için cache sistemi ve offline capability
class OCRCacheManager {
  static const String _logTag = 'OCRCacheManager';
  static const String _cacheDir = 'ocr_cache';
  static const String _metadataFileName = 'cache_metadata.json';
  static const int _maxCacheSize = 100 * 1024 * 1024; // 100MB
  static const int _maxCacheAge = 30; // 30 gün
  static const int _maxCacheEntries = 1000;

  static OCRCacheManager? _instance;
  static OCRCacheManager get instance => _instance ??= OCRCacheManager._();

  OCRCacheManager._();

  late Directory _cacheDirectory;
  late File _metadataFile;
  Map<String, CacheMetadata> _metadata = {};
  bool _isInitialized = false;

  /// Cache manager'ı başlat
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      developer.log('Initializing OCR cache manager...', name: _logTag);
      
      final appDir = await getApplicationDocumentsDirectory();
      _cacheDirectory = Directory('${appDir.path}/$_cacheDir');
      
      if (!await _cacheDirectory.exists()) {
        await _cacheDirectory.create(recursive: true);
      }
      
      _metadataFile = File('${_cacheDirectory.path}/$_metadataFileName');
      await _loadMetadata();
      await _cleanupExpiredEntries();
      
      _isInitialized = true;
      developer.log('OCR cache manager initialized successfully', name: _logTag);
    } catch (e) {
      developer.log('Error initializing OCR cache manager: $e', name: _logTag);
      rethrow;
    }
  }

  /// Metadata'yı yükle
  Future<void> _loadMetadata() async {
    try {
      if (await _metadataFile.exists()) {
        final content = await _metadataFile.readAsString();
        final Map<String, dynamic> json = jsonDecode(content);
        
        _metadata = json.map((key, value) => MapEntry(
          key,
          CacheMetadata.fromJson(value),
        ));
        
        developer.log('Loaded ${_metadata.length} cache entries', name: _logTag);
      }
    } catch (e) {
      developer.log('Error loading cache metadata: $e', name: _logTag);
      _metadata = {};
    }
  }

  /// Metadata'yı kaydet
  Future<void> _saveMetadata() async {
    try {
      final json = _metadata.map((key, value) => MapEntry(key, value.toJson()));
      await _metadataFile.writeAsString(jsonEncode(json));
    } catch (e) {
      developer.log('Error saving cache metadata: $e', name: _logTag);
    }
  }

  /// Resim için cache key oluştur
  String _generateCacheKey(File imageFile, OCRCacheConfig config) {
    final imageBytes = imageFile.readAsBytesSync();
    final imageHash = sha256.convert(imageBytes).toString();
    
    final configString = jsonEncode({
      'quality': config.quality.name,
      'language': config.language,
      'isHandwriting': config.isHandwriting,
      'enhancementLevel': config.enhancementLevel?.name,
    });
    
    final configHash = sha256.convert(utf8.encode(configString)).toString();
    return '${imageHash}_$configHash';
  }

  /// OCR sonucunu cache'e kaydet
  Future<void> cacheResult(
    File imageFile,
    OCRResult result,
    OCRCacheConfig config,
  ) async {
    if (!_isInitialized) await initialize();

    try {
      final cacheKey = _generateCacheKey(imageFile, config);
      final cacheFile = File('${_cacheDirectory.path}/$cacheKey.json');
      
      final cacheEntry = CacheEntry(
        result: result,
        config: config,
        timestamp: DateTime.now(),
        imageSize: await imageFile.length(),
        imagePath: imageFile.path,
      );
      
      await cacheFile.writeAsString(jsonEncode(cacheEntry.toJson()));
      
      _metadata[cacheKey] = CacheMetadata(
        cacheKey: cacheKey,
        timestamp: cacheEntry.timestamp,
        imageSize: cacheEntry.imageSize,
        imagePath: cacheEntry.imagePath,
        resultLength: result.text.length,
        engine: result.engine,
        quality: config.quality,
      );
      
      await _saveMetadata();
      await _enforceStorageLimits();
      
      developer.log('Cached OCR result for key: $cacheKey', name: _logTag);
    } catch (e) {
      developer.log('Error caching OCR result: $e', name: _logTag);
    }
  }

  /// Cache'den OCR sonucunu al
  Future<OCRResult?> getCachedResult(
    File imageFile,
    OCRCacheConfig config,
  ) async {
    if (!_isInitialized) await initialize();

    try {
      final cacheKey = _generateCacheKey(imageFile, config);
      final metadata = _metadata[cacheKey];
      
      if (metadata == null) {
        return null;
      }
      
      // Yaş kontrolü
      if (DateTime.now().difference(metadata.timestamp).inDays > _maxCacheAge) {
        await _removeCacheEntry(cacheKey);
        return null;
      }
      
      // Resim değişmiş mi kontrol et
      if (metadata.imageSize != await imageFile.length()) {
        await _removeCacheEntry(cacheKey);
        return null;
      }
      
      final cacheFile = File('${_cacheDirectory.path}/$cacheKey.json');
      if (!await cacheFile.exists()) {
        await _removeCacheEntry(cacheKey);
        return null;
      }
      
      final content = await cacheFile.readAsString();
      final cacheEntry = CacheEntry.fromJson(jsonDecode(content));
      
      // Hit count'u artır
      metadata.hitCount++;
      metadata.lastAccessed = DateTime.now();
      await _saveMetadata();
      
      developer.log('Cache hit for key: $cacheKey', name: _logTag);
      return cacheEntry.result;
    } catch (e) {
      developer.log('Error getting cached result: $e', name: _logTag);
      return null;
    }
  }

  /// Cache entry'sini sil
  Future<void> _removeCacheEntry(String cacheKey) async {
    try {
      final cacheFile = File('${_cacheDirectory.path}/$cacheKey.json');
      if (await cacheFile.exists()) {
        await cacheFile.delete();
      }
      
      _metadata.remove(cacheKey);
      await _saveMetadata();
      
      developer.log('Removed cache entry: $cacheKey', name: _logTag);
    } catch (e) {
      developer.log('Error removing cache entry: $e', name: _logTag);
    }
  }

  /// Süresi dolmuş cache entry'lerini temizle
  Future<void> _cleanupExpiredEntries() async {
    try {
      final now = DateTime.now();
      final expiredKeys = <String>[];
      
      for (final entry in _metadata.entries) {
        if (now.difference(entry.value.timestamp).inDays > _maxCacheAge) {
          expiredKeys.add(entry.key);
        }
      }
      
      for (final key in expiredKeys) {
        await _removeCacheEntry(key);
      }
      
      if (expiredKeys.isNotEmpty) {
        developer.log('Cleaned up ${expiredKeys.length} expired cache entries', name: _logTag);
      }
    } catch (e) {
      developer.log('Error cleaning up expired entries: $e', name: _logTag);
    }
  }

  /// Storage limitlerini uygula
  Future<void> _enforceStorageLimits() async {
    try {
      // Entry sayısı limiti
      if (_metadata.length > _maxCacheEntries) {
        await _evictLeastRecentlyUsed(_metadata.length - _maxCacheEntries);
      }
      
      // Boyut limiti
      final totalSize = await _calculateCacheSize();
      if (totalSize > _maxCacheSize) {
        await _evictBySize(totalSize - _maxCacheSize);
      }
    } catch (e) {
      developer.log('Error enforcing storage limits: $e', name: _logTag);
    }
  }

  /// Cache boyutunu hesapla
  Future<int> _calculateCacheSize() async {
    int totalSize = 0;
    
    try {
      await for (final entity in _cacheDirectory.list()) {
        if (entity is File) {
          totalSize += await entity.length();
        }
      }
    } catch (e) {
      developer.log('Error calculating cache size: $e', name: _logTag);
    }
    
    return totalSize;
  }

  /// En az kullanılan entry'leri sil
  Future<void> _evictLeastRecentlyUsed(int count) async {
    try {
      final sortedEntries = _metadata.entries.toList()
        ..sort((a, b) => a.value.lastAccessed.compareTo(b.value.lastAccessed));
      
      for (int i = 0; i < count && i < sortedEntries.length; i++) {
        await _removeCacheEntry(sortedEntries[i].key);
      }
      
      developer.log('Evicted $count least recently used entries', name: _logTag);
    } catch (e) {
      developer.log('Error evicting least recently used entries: $e', name: _logTag);
    }
  }

  /// Boyut bazında entry'leri sil
  Future<void> _evictBySize(int targetSize) async {
    try {
      final sortedEntries = _metadata.entries.toList()
        ..sort((a, b) => a.value.lastAccessed.compareTo(b.value.lastAccessed));
      
      int freedSize = 0;
      for (final entry in sortedEntries) {
        if (freedSize >= targetSize) break;
        
        final cacheFile = File('${_cacheDirectory.path}/${entry.key}.json');
        if (await cacheFile.exists()) {
          freedSize += await cacheFile.length();
          await _removeCacheEntry(entry.key);
        }
      }
      
      developer.log('Evicted entries to free $freedSize bytes', name: _logTag);
    } catch (e) {
      developer.log('Error evicting entries by size: $e', name: _logTag);
    }
  }

  /// Cache istatistiklerini al
  Future<CacheStats> getStats() async {
    if (!_isInitialized) await initialize();

    try {
      final totalSize = await _calculateCacheSize();
      final totalEntries = _metadata.length;
      final totalHits = _metadata.values.fold(0, (sum, metadata) => sum + metadata.hitCount);
      
      final engineStats = <OCREngine, int>{};
      final qualityStats = <OCRQuality, int>{};
      
      for (final metadata in _metadata.values) {
        engineStats[metadata.engine] = (engineStats[metadata.engine] ?? 0) + 1;
        qualityStats[metadata.quality] = (qualityStats[metadata.quality] ?? 0) + 1;
      }
      
      return CacheStats(
        totalSize: totalSize,
        totalEntries: totalEntries,
        totalHits: totalHits,
        engineStats: engineStats,
        qualityStats: qualityStats,
        oldestEntry: _metadata.values.isNotEmpty 
          ? _metadata.values.map((m) => m.timestamp).reduce((a, b) => a.isBefore(b) ? a : b)
          : null,
        newestEntry: _metadata.values.isNotEmpty 
          ? _metadata.values.map((m) => m.timestamp).reduce((a, b) => a.isAfter(b) ? a : b)
          : null,
      );
    } catch (e) {
      developer.log('Error getting cache stats: $e', name: _logTag);
      return CacheStats(
        totalSize: 0,
        totalEntries: 0,
        totalHits: 0,
        engineStats: {},
        qualityStats: {},
        oldestEntry: null,
        newestEntry: null,
      );
    }
  }

  /// Cache'i temizle
  Future<void> clearCache() async {
    if (!_isInitialized) await initialize();

    try {
      if (await _cacheDirectory.exists()) {
        await _cacheDirectory.delete(recursive: true);
        await _cacheDirectory.create(recursive: true);
      }
      
      _metadata.clear();
      await _saveMetadata();
      
      developer.log('Cache cleared successfully', name: _logTag);
    } catch (e) {
      developer.log('Error clearing cache: $e', name: _logTag);
    }
  }

  /// Belirli bir engine'in cache'ini temizle
  Future<void> clearCacheForEngine(OCREngine engine) async {
    if (!_isInitialized) await initialize();

    try {
      final keysToRemove = <String>[];
      
      for (final entry in _metadata.entries) {
        if (entry.value.engine == engine) {
          keysToRemove.add(entry.key);
        }
      }
      
      for (final key in keysToRemove) {
        await _removeCacheEntry(key);
      }
      
      developer.log('Cleared cache for engine: ${engine.name}', name: _logTag);
    } catch (e) {
      developer.log('Error clearing cache for engine: $e', name: _logTag);
    }
  }

  /// Offline capability kontrolü
  bool isOfflineCapable(OCRCacheConfig config) {
    // Tesseract offline çalışabilir, diğerleri için internet gerekli
    return config.quality == OCRQuality.fast || 
           config.quality == OCRQuality.balanced;
  }

  /// Offline mode'da kullanılabilir cache entry'leri al
  Future<List<CacheMetadata>> getOfflineCapableEntries() async {
    if (!_isInitialized) await initialize();

    return _metadata.values
        .where((metadata) => isOfflineCapable(OCRCacheConfig(
          quality: metadata.quality,
          language: 'tur',
          isHandwriting: false,
        )))
        .toList();
  }
}

/// Cache konfigürasyonu
class OCRCacheConfig {
  final OCRQuality quality;
  final String language;
  final bool isHandwriting;
  final ImageEnhancementLevel? enhancementLevel;

  OCRCacheConfig({
    required this.quality,
    required this.language,
    required this.isHandwriting,
    this.enhancementLevel,
  });

  Map<String, dynamic> toJson() => {
    'quality': quality.name,
    'language': language,
    'isHandwriting': isHandwriting,
    'enhancementLevel': enhancementLevel?.name,
  };

  factory OCRCacheConfig.fromJson(Map<String, dynamic> json) => OCRCacheConfig(
    quality: OCRQuality.values.firstWhere((q) => q.name == json['quality']),
    language: json['language'],
    isHandwriting: json['isHandwriting'],
    enhancementLevel: json['enhancementLevel'] != null 
      ? ImageEnhancementLevel.values.firstWhere((l) => l.name == json['enhancementLevel'])
      : null,
  );
}

/// Cache entry
class CacheEntry {
  final OCRResult result;
  final OCRCacheConfig config;
  final DateTime timestamp;
  final int imageSize;
  final String imagePath;

  CacheEntry({
    required this.result,
    required this.config,
    required this.timestamp,
    required this.imageSize,
    required this.imagePath,
  });

  Map<String, dynamic> toJson() => {
    'result': result.toJson(),
    'config': config.toJson(),
    'timestamp': timestamp.toIso8601String(),
    'imageSize': imageSize,
    'imagePath': imagePath,
  };

  factory CacheEntry.fromJson(Map<String, dynamic> json) => CacheEntry(
    result: OCRResult.fromJson(json['result']),
    config: OCRCacheConfig.fromJson(json['config']),
    timestamp: DateTime.parse(json['timestamp']),
    imageSize: json['imageSize'],
    imagePath: json['imagePath'],
  );
}

/// Cache metadata
class CacheMetadata {
  final String cacheKey;
  final DateTime timestamp;
  final int imageSize;
  final String imagePath;
  final int resultLength;
  final OCREngine engine;
  final OCRQuality quality;
  int hitCount;
  DateTime lastAccessed;

  CacheMetadata({
    required this.cacheKey,
    required this.timestamp,
    required this.imageSize,
    required this.imagePath,
    required this.resultLength,
    required this.engine,
    required this.quality,
    this.hitCount = 0,
    DateTime? lastAccessed,
  }) : lastAccessed = lastAccessed ?? timestamp;

  Map<String, dynamic> toJson() => {
    'cacheKey': cacheKey,
    'timestamp': timestamp.toIso8601String(),
    'imageSize': imageSize,
    'imagePath': imagePath,
    'resultLength': resultLength,
    'engine': engine.name,
    'quality': quality.name,
    'hitCount': hitCount,
    'lastAccessed': lastAccessed.toIso8601String(),
  };

  factory CacheMetadata.fromJson(Map<String, dynamic> json) => CacheMetadata(
    cacheKey: json['cacheKey'],
    timestamp: DateTime.parse(json['timestamp']),
    imageSize: json['imageSize'],
    imagePath: json['imagePath'],
    resultLength: json['resultLength'],
    engine: OCREngine.values.firstWhere((e) => e.name == json['engine']),
    quality: OCRQuality.values.firstWhere((q) => q.name == json['quality']),
    hitCount: json['hitCount'] ?? 0,
    lastAccessed: json['lastAccessed'] != null 
      ? DateTime.parse(json['lastAccessed'])
      : DateTime.parse(json['timestamp']),
  );
}

/// Cache istatistikleri
class CacheStats {
  final int totalSize;
  final int totalEntries;
  final int totalHits;
  final Map<OCREngine, int> engineStats;
  final Map<OCRQuality, int> qualityStats;
  final DateTime? oldestEntry;
  final DateTime? newestEntry;

  CacheStats({
    required this.totalSize,
    required this.totalEntries,
    required this.totalHits,
    required this.engineStats,
    required this.qualityStats,
    this.oldestEntry,
    this.newestEntry,
  });

  double get hitRate => totalEntries > 0 ? totalHits / totalEntries : 0.0;
  
  String get formattedSize {
    if (totalSize < 1024) return '${totalSize}B';
    if (totalSize < 1024 * 1024) return '${(totalSize / 1024).toStringAsFixed(1)}KB';
    return '${(totalSize / (1024 * 1024)).toStringAsFixed(1)}MB';
  }
} 