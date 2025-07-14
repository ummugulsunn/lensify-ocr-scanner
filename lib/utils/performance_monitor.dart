import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'ocr_engine_manager.dart';

/// OCR performans monitörü ve analytics sistemi
class PerformanceMonitor {
  static const String _logTag = 'PerformanceMonitor';
  static const String _performanceDataKey = 'ocr_performance_data';
  static const String _sessionDataKey = 'current_session_data';
  
  static PerformanceMonitor? _instance;
  static PerformanceMonitor get instance => _instance ??= PerformanceMonitor._();
  
  PerformanceMonitor._();
  
  late SharedPreferences _prefs;
  bool _isInitialized = false;
  
  // Anlık performans verileri
  final List<OCRPerformanceMetric> _currentSessionMetrics = [];
  late DateTime _sessionStartTime;
  
  /// Initialize performance monitor
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      developer.log('Initializing Performance Monitor...', name: _logTag);
      
      _prefs = await SharedPreferences.getInstance();
      _sessionStartTime = DateTime.now();
      
      // Önceki session verilerini temizle
      await _clearSessionData();
      
      _isInitialized = true;
      developer.log('Performance Monitor initialized successfully', name: _logTag);
    } catch (e) {
      developer.log('Error initializing Performance Monitor: $e', name: _logTag);
      rethrow;
    }
  }
  
  /// OCR işlemini izle ve metrikleri kaydet
  Future<OCRResult> trackOCROperation(
    Future<OCRResult> Function() ocrOperation,
    OCROperationContext context,
  ) async {
    if (!_isInitialized) await initialize();
    
    final operationId = DateTime.now().millisecondsSinceEpoch.toString();
    final startTime = DateTime.now();
    final stopwatch = Stopwatch()..start();
    
    developer.log('Starting OCR operation tracking: $operationId', name: _logTag);
    
    try {
      // OCR işlemini çalıştır
      final result = await ocrOperation();
      
      stopwatch.stop();
      final endTime = DateTime.now();
      
      // Performans metriğini oluştur
      final metric = OCRPerformanceMetric(
        operationId: operationId,
        startTime: startTime,
        endTime: endTime,
        processingTime: stopwatch.elapsed,
        result: result,
        context: context,
        memoryUsage: await _getMemoryUsage(),
        isSuccess: result.isSuccess,
        errorType: result.isSuccess ? null : _categorizeError(result.errorMessage),
      );
      
      // Metriği kaydet
      await _recordMetric(metric);
      
      developer.log(
        'OCR operation completed: ${result.isSuccess ? 'SUCCESS' : 'FAILED'} '
        'in ${stopwatch.elapsedMilliseconds}ms',
        name: _logTag,
      );
      
      return result;
    } catch (e) {
      stopwatch.stop();
      
      // Hata metriğini kaydet
      final errorMetric = OCRPerformanceMetric(
        operationId: operationId,
        startTime: startTime,
        endTime: DateTime.now(),
        processingTime: stopwatch.elapsed,
        result: OCRResult.error(OCREngine.googleMLKit, e.toString(), stopwatch.elapsed),
        context: context,
        memoryUsage: await _getMemoryUsage(),
        isSuccess: false,
        errorType: _categorizeError(e.toString()),
      );
      
      await _recordMetric(errorMetric);
      
      developer.log('OCR operation failed: $e', name: _logTag);
      rethrow;
    }
  }
  
  /// Performans metriğini kaydet
  Future<void> _recordMetric(OCRPerformanceMetric metric) async {
    try {
      // Current session'a ekle
      _currentSessionMetrics.add(metric);
      
      // Persistent storage'a kaydet
      await _saveMetricToPersistentStorage(metric);
      
      // Real-time analiz
      await _analyzeRealTimePerformance(metric);
      
    } catch (e) {
      developer.log('Error recording metric: $e', name: _logTag);
    }
  }
  
  /// Metriği kalıcı depolamaya kaydet
  Future<void> _saveMetricToPersistentStorage(OCRPerformanceMetric metric) async {
    try {
      final existingData = _prefs.getString(_performanceDataKey);
      List<Map<String, dynamic>> metrics = [];
      
      if (existingData != null) {
        final decoded = jsonDecode(existingData) as List;
        metrics = decoded.cast<Map<String, dynamic>>();
      }
      
      metrics.add(metric.toJson());
      
      // Son 1000 metriği tut (storage limitini aşmamak için)
      if (metrics.length > 1000) {
        metrics = metrics.skip(metrics.length - 1000).toList();
      }
      
      await _prefs.setString(_performanceDataKey, jsonEncode(metrics));
    } catch (e) {
      developer.log('Error saving metric to persistent storage: $e', name: _logTag);
    }
  }
  
  /// Real-time performans analizi
  Future<void> _analyzeRealTimePerformance(OCRPerformanceMetric metric) async {
    try {
      // Yavaş işlemler için uyarı
      if (metric.processingTime.inSeconds > 10) {
        developer.log(
          'SLOW OCR OPERATION DETECTED: ${metric.operationId} took ${metric.processingTime.inSeconds}s',
          name: _logTag,
        );
      }
      
      // Başarısızlık oranı kontrol
      final recentFailures = _currentSessionMetrics
          .where((m) => !m.isSuccess)
          .where((m) => DateTime.now().difference(m.startTime).inMinutes < 5)
          .length;
      
      if (recentFailures >= 3) {
        developer.log(
          'HIGH FAILURE RATE DETECTED: $recentFailures failures in last 5 minutes',
          name: _logTag,
        );
      }
      
    } catch (e) {
      developer.log('Error in real-time analysis: $e', name: _logTag);
    }
  }
  
  /// Current session istatistikleri
  Future<SessionStats> getCurrentSessionStats() async {
    if (!_isInitialized) await initialize();
    
    if (_currentSessionMetrics.isEmpty) {
      return SessionStats.empty();
    }
    
    final totalOperations = _currentSessionMetrics.length;
    final successfulOperations = _currentSessionMetrics.where((m) => m.isSuccess).length;
    final avgProcessingTime = _currentSessionMetrics
        .map((m) => m.processingTime.inMilliseconds)
        .reduce((a, b) => a + b) / totalOperations;
    
    final engineStats = <OCREngine, int>{};
    final qualityStats = <OCRQuality, int>{};
    final errorStats = <ErrorType, int>{};
    
    for (final metric in _currentSessionMetrics) {
      // Engine stats
      engineStats[metric.result.engine] = (engineStats[metric.result.engine] ?? 0) + 1;
      
      // Quality stats
      qualityStats[metric.context.quality] = (qualityStats[metric.context.quality] ?? 0) + 1;
      
      // Error stats
      if (metric.errorType != null) {
        errorStats[metric.errorType!] = (errorStats[metric.errorType!] ?? 0) + 1;
      }
    }
    
    return SessionStats(
      sessionDuration: DateTime.now().difference(_sessionStartTime),
      totalOperations: totalOperations,
      successfulOperations: successfulOperations,
      avgProcessingTime: Duration(milliseconds: avgProcessingTime.round()),
      engineStats: engineStats,
      qualityStats: qualityStats,
      errorStats: errorStats,
      totalTextExtracted: _currentSessionMetrics
          .where((m) => m.isSuccess)
          .map((m) => m.result.text.length)
          .fold(0, (a, b) => a + b),
    );
  }
  
  /// Geçmiş performans verilerini al
  Future<List<OCRPerformanceMetric>> getHistoricalMetrics({
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) async {
    if (!_isInitialized) await initialize();
    
    try {
      final existingData = _prefs.getString(_performanceDataKey);
      if (existingData == null) return [];
      
      final decoded = jsonDecode(existingData) as List;
      final metrics = decoded
          .map((json) => OCRPerformanceMetric.fromJson(json))
          .toList();
      
      // Tarih filtreleme
      var filteredMetrics = metrics.where((metric) {
        if (startDate != null && metric.startTime.isBefore(startDate)) {
          return false;
        }
        if (endDate != null && metric.startTime.isAfter(endDate)) {
          return false;
        }
        return true;
      }).toList();
      
      // Sıralama (en yeni önce)
      filteredMetrics.sort((a, b) => b.startTime.compareTo(a.startTime));
      
      // Limit uygula
      if (limit != null && filteredMetrics.length > limit) {
        filteredMetrics = filteredMetrics.take(limit).toList();
      }
      
      return filteredMetrics;
    } catch (e) {
      developer.log('Error getting historical metrics: $e', name: _logTag);
      return [];
    }
  }
  
  /// Performans raporu oluştur
  Future<PerformanceReport> generatePerformanceReport({
    Duration? period,
  }) async {
    if (!_isInitialized) await initialize();
    
    final endDate = DateTime.now();
    final startDate = period != null 
        ? endDate.subtract(period)
        : endDate.subtract(const Duration(days: 7)); // Varsayılan 7 gün
    
    final metrics = await getHistoricalMetrics(
      startDate: startDate,
      endDate: endDate,
    );
    
    if (metrics.isEmpty) {
      return PerformanceReport.empty(startDate, endDate);
    }
    
    // Genel istatistikler
    final totalOperations = metrics.length;
    final successfulOperations = metrics.where((m) => m.isSuccess).length;
    final successRate = successfulOperations / totalOperations;
    
    final processingTimes = metrics.map((m) => m.processingTime.inMilliseconds).toList();
    final avgProcessingTime = processingTimes.reduce((a, b) => a + b) / processingTimes.length;
    final minProcessingTime = processingTimes.reduce((a, b) => a < b ? a : b);
    final maxProcessingTime = processingTimes.reduce((a, b) => a > b ? a : b);
    
    // Engine performans karşılaştırması
    final enginePerformance = <OCREngine, EnginePerformance>{};
    
    for (final engine in OCREngine.values) {
      final engineMetrics = metrics.where((m) => m.result.engine == engine).toList();
      
      if (engineMetrics.isNotEmpty) {
        final engineSuccessful = engineMetrics.where((m) => m.isSuccess).length;
        final engineAvgTime = engineMetrics
            .map((m) => m.processingTime.inMilliseconds)
            .reduce((a, b) => a + b) / engineMetrics.length;
        
        enginePerformance[engine] = EnginePerformance(
          totalOperations: engineMetrics.length,
          successfulOperations: engineSuccessful,
          successRate: engineSuccessful / engineMetrics.length,
          avgProcessingTime: Duration(milliseconds: engineAvgTime.round()),
        );
      }
    }
    
    return PerformanceReport(
      period: period ?? const Duration(days: 7),
      startDate: startDate,
      endDate: endDate,
      totalOperations: totalOperations,
      successfulOperations: successfulOperations,
      successRate: successRate,
      avgProcessingTime: Duration(milliseconds: avgProcessingTime.round()),
      minProcessingTime: Duration(milliseconds: minProcessingTime),
      maxProcessingTime: Duration(milliseconds: maxProcessingTime),
      enginePerformance: enginePerformance,
      totalTextExtracted: metrics
          .where((m) => m.isSuccess)
          .map((m) => m.result.text.length)
          .fold(0, (a, b) => a + b),
    );
  }
  
  /// Memory usage bilgisini al (platform specific)
  Future<int> _getMemoryUsage() async {
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        // Process info üzerinden memory usage (yaklaşık)
        return ProcessInfo.currentRss;
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }
  
  /// Hata tipini kategorize et
  ErrorType _categorizeError(String? errorMessage) {
    if (errorMessage == null) return ErrorType.unknown;
    
    final message = errorMessage.toLowerCase();
    
    if (message.contains('permission') || message.contains('access')) {
      return ErrorType.permission;
    } else if (message.contains('network') || message.contains('connection')) {
      return ErrorType.network;
    } else if (message.contains('memory') || message.contains('out of memory')) {
      return ErrorType.memory;
    } else if (message.contains('timeout')) {
      return ErrorType.timeout;
    } else if (message.contains('format') || message.contains('invalid')) {
      return ErrorType.format;
    } else {
      return ErrorType.unknown;
    }
  }
  
  /// Session verilerini temizle
  Future<void> _clearSessionData() async {
    await _prefs.remove(_sessionDataKey);
    _currentSessionMetrics.clear();
  }
  
  /// Export performance data as JSON
  Future<String> exportPerformanceData() async {
    if (!_isInitialized) await initialize();
    
    final sessionStats = await getCurrentSessionStats();
    final historicalMetrics = await getHistoricalMetrics(limit: 100);
    final performanceReport = await generatePerformanceReport();
    
    final exportData = {
      'exportDate': DateTime.now().toIso8601String(),
      'sessionStats': sessionStats.toJson(),
      'performanceReport': performanceReport.toJson(),
      'recentMetrics': historicalMetrics.map((m) => m.toJson()).toList(),
    };
    
    return jsonEncode(exportData);
  }
}

/// OCR operasyon bağlamı
class OCROperationContext {
  final OCRQuality quality;
  final String language;
  final bool isHandwritingMode;
  final bool isBatchMode;
  final int imageCount;
  final int imageSize; // bytes
  
  OCROperationContext({
    required this.quality,
    required this.language,
    required this.isHandwritingMode,
    required this.isBatchMode,
    required this.imageCount,
    required this.imageSize,
  });
  
  Map<String, dynamic> toJson() => {
    'quality': quality.name,
    'language': language,
    'isHandwritingMode': isHandwritingMode,
    'isBatchMode': isBatchMode,
    'imageCount': imageCount,
    'imageSize': imageSize,
  };
  
  factory OCROperationContext.fromJson(Map<String, dynamic> json) => 
      OCROperationContext(
        quality: OCRQuality.values.firstWhere((q) => q.name == json['quality']),
        language: json['language'],
        isHandwritingMode: json['isHandwritingMode'],
        isBatchMode: json['isBatchMode'],
        imageCount: json['imageCount'],
        imageSize: json['imageSize'],
      );
}

/// OCR performans metriği
class OCRPerformanceMetric {
  final String operationId;
  final DateTime startTime;
  final DateTime endTime;
  final Duration processingTime;
  final OCRResult result;
  final OCROperationContext context;
  final int memoryUsage;
  final bool isSuccess;
  final ErrorType? errorType;
  
  OCRPerformanceMetric({
    required this.operationId,
    required this.startTime,
    required this.endTime,
    required this.processingTime,
    required this.result,
    required this.context,
    required this.memoryUsage,
    required this.isSuccess,
    this.errorType,
  });
  
  Map<String, dynamic> toJson() => {
    'operationId': operationId,
    'startTime': startTime.toIso8601String(),
    'endTime': endTime.toIso8601String(),
    'processingTime': processingTime.inMilliseconds,
    'result': result.toJson(),
    'context': context.toJson(),
    'memoryUsage': memoryUsage,
    'isSuccess': isSuccess,
    'errorType': errorType?.name,
  };
  
  factory OCRPerformanceMetric.fromJson(Map<String, dynamic> json) => 
      OCRPerformanceMetric(
        operationId: json['operationId'],
        startTime: DateTime.parse(json['startTime']),
        endTime: DateTime.parse(json['endTime']),
        processingTime: Duration(milliseconds: json['processingTime']),
        result: OCRResult.fromJson(json['result']),
        context: OCROperationContext.fromJson(json['context']),
        memoryUsage: json['memoryUsage'],
        isSuccess: json['isSuccess'],
        errorType: json['errorType'] != null 
            ? ErrorType.values.firstWhere((e) => e.name == json['errorType'])
            : null,
      );
}

/// Session istatistikleri
class SessionStats {
  final Duration sessionDuration;
  final int totalOperations;
  final int successfulOperations;
  final Duration avgProcessingTime;
  final Map<OCREngine, int> engineStats;
  final Map<OCRQuality, int> qualityStats;
  final Map<ErrorType, int> errorStats;
  final int totalTextExtracted;
  
  SessionStats({
    required this.sessionDuration,
    required this.totalOperations,
    required this.successfulOperations,
    required this.avgProcessingTime,
    required this.engineStats,
    required this.qualityStats,
    required this.errorStats,
    required this.totalTextExtracted,
  });
  
  factory SessionStats.empty() => SessionStats(
        sessionDuration: Duration.zero,
        totalOperations: 0,
        successfulOperations: 0,
        avgProcessingTime: Duration.zero,
        engineStats: {},
        qualityStats: {},
        errorStats: {},
        totalTextExtracted: 0,
      );
  
  double get successRate => totalOperations > 0 ? successfulOperations / totalOperations : 0.0;
  
  Map<String, dynamic> toJson() => {
    'sessionDuration': sessionDuration.inMilliseconds,
    'totalOperations': totalOperations,
    'successfulOperations': successfulOperations,
    'avgProcessingTime': avgProcessingTime.inMilliseconds,
    'engineStats': engineStats.map((k, v) => MapEntry(k.name, v)),
    'qualityStats': qualityStats.map((k, v) => MapEntry(k.name, v)),
    'errorStats': errorStats.map((k, v) => MapEntry(k.name, v)),
    'totalTextExtracted': totalTextExtracted,
  };
}

/// Engine performans bilgisi
class EnginePerformance {
  final int totalOperations;
  final int successfulOperations;
  final double successRate;
  final Duration avgProcessingTime;
  
  EnginePerformance({
    required this.totalOperations,
    required this.successfulOperations,
    required this.successRate,
    required this.avgProcessingTime,
  });
}

/// Performans raporu
class PerformanceReport {
  final Duration period;
  final DateTime startDate;
  final DateTime endDate;
  final int totalOperations;
  final int successfulOperations;
  final double successRate;
  final Duration avgProcessingTime;
  final Duration minProcessingTime;
  final Duration maxProcessingTime;
  final Map<OCREngine, EnginePerformance> enginePerformance;
  final int totalTextExtracted;
  
  PerformanceReport({
    required this.period,
    required this.startDate,
    required this.endDate,
    required this.totalOperations,
    required this.successfulOperations,
    required this.successRate,
    required this.avgProcessingTime,
    required this.minProcessingTime,
    required this.maxProcessingTime,
    required this.enginePerformance,
    required this.totalTextExtracted,
  });
  
  factory PerformanceReport.empty(DateTime startDate, DateTime endDate) =>
      PerformanceReport(
        period: endDate.difference(startDate),
        startDate: startDate,
        endDate: endDate,
        totalOperations: 0,
        successfulOperations: 0,
        successRate: 0.0,
        avgProcessingTime: Duration.zero,
        minProcessingTime: Duration.zero,
        maxProcessingTime: Duration.zero,
        enginePerformance: {},
        totalTextExtracted: 0,
      );
  
  Map<String, dynamic> toJson() => {
    'period': period.inMilliseconds,
    'startDate': startDate.toIso8601String(),
    'endDate': endDate.toIso8601String(),
    'totalOperations': totalOperations,
    'successfulOperations': successfulOperations,
    'successRate': successRate,
    'avgProcessingTime': avgProcessingTime.inMilliseconds,
    'minProcessingTime': minProcessingTime.inMilliseconds,
    'maxProcessingTime': maxProcessingTime.inMilliseconds,
    'totalTextExtracted': totalTextExtracted,
  };
}

/// Hata tipleri
enum ErrorType {
  permission,
  network,
  memory,
  timeout,
  format,
  unknown,
} 