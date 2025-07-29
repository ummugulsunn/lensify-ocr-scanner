import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'ocr_engine_manager.dart';

/// Analytics Service for tracking user behavior and app performance
class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  static const String _analyticsKey = 'analytics_data';
  static const int _maxEventsPerSession = 100;
  static const Duration _flushInterval = Duration(minutes: 5);

  final List<AnalyticsEvent> _events = [];
  final StreamController<AnalyticsEvent> _eventController = StreamController<AnalyticsEvent>.broadcast();
  Timer? _flushTimer;
  bool _isInitialized = false;

  /// Initialize analytics service
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Load existing analytics data
    await _loadAnalyticsData();
    
    // Start periodic flush timer
    _flushTimer = Timer.periodic(_flushInterval, (_) => _flushAnalytics());
    
    _isInitialized = true;
  }

  /// Track an analytics event
  void trackEvent({
    required String eventName,
    Map<String, dynamic>? parameters,
    AnalyticsEventType type = AnalyticsEventType.user,
  }) {
    if (!_isInitialized) return;

    final event = AnalyticsEvent(
      name: eventName,
      parameters: parameters ?? {},
      type: type,
      timestamp: DateTime.now(),
      sessionId: _getCurrentSessionId(),
    );

    _events.add(event);
    _eventController.add(event);

    // Flush if we have too many events
    if (_events.length >= _maxEventsPerSession) {
      _flushAnalytics();
    }
  }

  /// Track OCR operation
  void trackOCROperation({
    required OCRQuality quality,
    required bool isHandwriting,
    required bool isBatchMode,
    required int imageCount,
    required Duration processingTime,
    required double confidence,
    required bool isSuccess,
    String? errorMessage,
  }) {
    trackEvent(
      eventName: 'ocr_operation',
      parameters: {
        'quality': quality.name,
        'is_handwriting': isHandwriting,
        'is_batch_mode': isBatchMode,
        'image_count': imageCount,
        'processing_time_ms': processingTime.inMilliseconds,
        'confidence': confidence,
        'is_success': isSuccess,
        if (errorMessage != null) 'error_message': errorMessage,
      },
      type: AnalyticsEventType.performance,
    );
  }

  /// Track credit usage
  void trackCreditUsage({
    required int creditsUsed,
    required OCRType ocrType,
    required bool isHandwriting,
    required bool isPremiumQuality,
  }) {
    trackEvent(
      eventName: 'credit_usage',
      parameters: {
        'credits_used': creditsUsed,
        'ocr_type': ocrType.name,
        'is_handwriting': isHandwriting,
        'is_premium_quality': isPremiumQuality,
      },
      type: AnalyticsEventType.business,
    );
  }

  /// Track subscription events
  void trackSubscriptionEvent({
    required String eventName,
    required String productId,
    double? price,
    String? currency,
  }) {
    trackEvent(
      eventName: eventName,
      parameters: {
        'product_id': productId,
        if (price != null) 'price': price,
        if (currency != null) 'currency': currency,
      },
      type: AnalyticsEventType.business,
    );
  }

  /// Track feature usage
  void trackFeatureUsage({
    required String featureName,
    Map<String, dynamic>? additionalData,
  }) {
    trackEvent(
      eventName: 'feature_usage',
      parameters: {
        'feature_name': featureName,
        ...?additionalData,
      },
      type: AnalyticsEventType.user,
    );
  }

  /// Track error events
  void trackError({
    required String errorType,
    required String errorMessage,
    String? stackTrace,
    Map<String, dynamic>? context,
  }) {
    trackEvent(
      eventName: 'error',
      parameters: {
        'error_type': errorType,
        'error_message': errorMessage,
        if (stackTrace != null) 'stack_trace': stackTrace,
        if (context != null) 'context': context,
      },
      type: AnalyticsEventType.error,
    );
  }

  /// Track performance metrics
  void trackPerformance({
    required String metricName,
    required double value,
    String? unit,
    Map<String, dynamic>? tags,
  }) {
    trackEvent(
      eventName: 'performance',
      parameters: {
        'metric_name': metricName,
        'value': value,
        if (unit != null) 'unit': unit,
        if (tags != null) 'tags': tags,
      },
      type: AnalyticsEventType.performance,
    );
  }

  /// Track user engagement
  void trackEngagement({
    required String action,
    required String screen,
    Map<String, dynamic>? additionalData,
  }) {
    trackEvent(
      eventName: 'engagement',
      parameters: {
        'action': action,
        'screen': screen,
        ...?additionalData,
      },
      type: AnalyticsEventType.user,
    );
  }

  /// Get analytics stream
  Stream<AnalyticsEvent> get eventStream => _eventController.stream;

  /// Get current analytics data
  List<AnalyticsEvent> get currentEvents => List.unmodifiable(_events);

  /// Get analytics summary
  Future<AnalyticsSummary> getAnalyticsSummary() async {
    final now = DateTime.now();
    final last30Days = now.subtract(const Duration(days: 30));
    
    final recentEvents = _events.where((event) => 
      event.timestamp.isAfter(last30Days)
    ).toList();

    return AnalyticsSummary(
      totalEvents: _events.length,
      eventsLast30Days: recentEvents.length,
      sessionCount: _getSessionCount(),
      averageSessionDuration: _calculateAverageSessionDuration(),
      mostUsedFeatures: _getMostUsedFeatures(recentEvents),
      errorRate: _calculateErrorRate(recentEvents),
      performanceMetrics: _getPerformanceMetrics(recentEvents),
    );
  }

  /// Flush analytics data to storage
  Future<void> _flushAnalytics() async {
    if (_events.isEmpty) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final existingData = prefs.getString(_analyticsKey);
      
      List<Map<String, dynamic>> allEvents = [];
      
      if (existingData != null) {
        final existingEvents = jsonDecode(existingData) as List;
        allEvents.addAll(existingEvents.cast<Map<String, dynamic>>());
      }

      // Add current events
      allEvents.addAll(_events.map((event) => event.toJson()));

      // Keep only last 1000 events to prevent storage bloat
      if (allEvents.length > 1000) {
        allEvents = allEvents.sublist(allEvents.length - 1000);
      }

      await prefs.setString(_analyticsKey, jsonEncode(allEvents));
      
      // Clear current events after successful flush
      _events.clear();
    } catch (e) {
      debugPrint('Failed to flush analytics: $e');
    }
  }

  /// Load analytics data from storage
  Future<void> _loadAnalyticsData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_analyticsKey);
      
      if (data != null) {
        final events = jsonDecode(data) as List;
        _events.clear();
        _events.addAll(
          events.map((event) => AnalyticsEvent.fromJson(event as Map<String, dynamic>))
        );
      }
    } catch (e) {
      debugPrint('Failed to load analytics data: $e');
    }
  }

  /// Get current session ID
  String _getCurrentSessionId() {
    final now = DateTime.now();
    final sessionKey = '${now.year}-${now.month}-${now.day}-${now.hour}';
    return _hashString(sessionKey);
  }

  /// Hash string for privacy
  String _hashString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString().substring(0, 8);
  }

  /// Get session count
  int _getSessionCount() {
    final sessions = _events.map((e) => e.sessionId).toSet();
    return sessions.length;
  }

  /// Calculate average session duration
  Duration _calculateAverageSessionDuration() {
    // Simplified calculation - in real app, you'd track session start/end
    return const Duration(minutes: 5);
  }

  /// Get most used features
  List<String> _getMostUsedFeatures(List<AnalyticsEvent> events) {
    final featureCounts = <String, int>{};
    
    for (final event in events) {
      if (event.name == 'feature_usage') {
        final featureName = event.parameters['feature_name'] as String?;
        if (featureName != null) {
          featureCounts[featureName] = (featureCounts[featureName] ?? 0) + 1;
        }
      }
    }

    final sortedFeatures = featureCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sortedFeatures.take(5).map((e) => e.key).toList();
  }

  /// Calculate error rate
  double _calculateErrorRate(List<AnalyticsEvent> events) {
    if (events.isEmpty) return 0.0;
    
    final errorCount = events.where((e) => e.type == AnalyticsEventType.error).length;
    return errorCount / events.length;
  }

  /// Get performance metrics
  Map<String, double> _getPerformanceMetrics(List<AnalyticsEvent> events) {
    final metrics = <String, List<double>>{};
    
    for (final event in events) {
      if (event.name == 'performance') {
        final metricName = event.parameters['metric_name'] as String?;
        final value = event.parameters['value'] as double?;
        
        if (metricName != null && value != null) {
          metrics.putIfAbsent(metricName, () => []).add(value);
        }
      }
    }

    return metrics.map((key, values) => MapEntry(key, values.reduce((a, b) => a + b) / values.length));
  }

  /// Dispose resources
  void dispose() {
    _flushTimer?.cancel();
    _eventController.close();
  }
}

/// Analytics event model
class AnalyticsEvent {
  final String name;
  final Map<String, dynamic> parameters;
  final AnalyticsEventType type;
  final DateTime timestamp;
  final String sessionId;

  const AnalyticsEvent({
    required this.name,
    required this.parameters,
    required this.type,
    required this.timestamp,
    required this.sessionId,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'parameters': parameters,
    'type': type.name,
    'timestamp': timestamp.toIso8601String(),
    'session_id': sessionId,
  };

  factory AnalyticsEvent.fromJson(Map<String, dynamic> json) => AnalyticsEvent(
    name: json['name'] as String,
    parameters: Map<String, dynamic>.from(json['parameters'] as Map),
    type: AnalyticsEventType.values.firstWhere(
      (e) => e.name == json['type'],
      orElse: () => AnalyticsEventType.user,
    ),
    timestamp: DateTime.parse(json['timestamp'] as String),
    sessionId: json['session_id'] as String,
  );
}

/// Analytics event types
enum AnalyticsEventType {
  user,
  performance,
  business,
  error,
}

/// Analytics summary model
class AnalyticsSummary {
  final int totalEvents;
  final int eventsLast30Days;
  final int sessionCount;
  final Duration averageSessionDuration;
  final List<String> mostUsedFeatures;
  final double errorRate;
  final Map<String, double> performanceMetrics;

  const AnalyticsSummary({
    required this.totalEvents,
    required this.eventsLast30Days,
    required this.sessionCount,
    required this.averageSessionDuration,
    required this.mostUsedFeatures,
    required this.errorRate,
    required this.performanceMetrics,
  });
}

/// OCR Type for analytics
enum OCRType {
  single,
  batch,
}
