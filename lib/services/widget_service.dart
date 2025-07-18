import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

/// Widget Service
/// Handles deep links from home screen widgets and manages widget functionality
class WidgetService {
  static const String _logTag = 'WidgetService';
  static const MethodChannel _channel = MethodChannel('com.lensify.ocr_scanner/widget');
  
  static WidgetService? _instance;
  static WidgetService get instance => _instance ??= WidgetService._();
  
  WidgetService._();
  
  // Stream controller for widget actions
  final StreamController<WidgetAction> _actionController = StreamController<WidgetAction>.broadcast();
  
  /// Stream of widget actions
  Stream<WidgetAction> get actionStream => _actionController.stream;
  
  /// Initialize widget service
  Future<void> initialize() async {
    try {
      developer.log('Initializing WidgetService...', name: _logTag);
      
      // Set up method call handler for widget interactions
      _channel.setMethodCallHandler(_handleMethodCall);
      
      developer.log('WidgetService initialized successfully', name: _logTag);
    } catch (e) {
      developer.log('Error initializing WidgetService: $e', name: _logTag);
    }
  }
  
  /// Handle method calls from native platform
  Future<dynamic> _handleMethodCall(MethodCall call) async {
    developer.log('Received method call: ${call.method}', name: _logTag);
    
    switch (call.method) {
      case 'widgetAction':
        final action = call.arguments['action'] as String?;
        if (action != null) {
          _handleWidgetAction(action);
        }
        break;
      
      case 'updateWidget':
        await _updateWidgetData();
        break;
        
      default:
        developer.log('Unknown method call: ${call.method}', name: _logTag);
    }
  }
  
  /// Handle widget action
  void _handleWidgetAction(String action) {
    developer.log('Handling widget action: $action', name: _logTag);
    
    final widgetAction = WidgetAction.fromString(action);
    _actionController.add(widgetAction);
  }
  
  /// Handle deep link from widget
  void handleDeepLink(String? action) {
    if (action != null) {
      developer.log('Handling deep link: $action', name: _logTag);
      _handleWidgetAction(action);
    }
  }
  
  /// Update widget with latest data
  Future<void> _updateWidgetData() async {
    try {
      // Get recent OCR count or other relevant data
      final data = await _getWidgetData();
      
      // Send data to native widget
      await _channel.invokeMethod('updateWidgetData', data);
      
      developer.log('Widget data updated successfully', name: _logTag);
    } catch (e) {
      developer.log('Error updating widget data: $e', name: _logTag);
    }
  }
  
  /// Get data for widget display
  Future<Map<String, dynamic>> _getWidgetData() async {
    // This could be extended to show recent OCR count, etc.
    return {
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'status': 'ready',
    };
  }
  
  /// Trigger widget update from Flutter
  Future<void> updateWidget() async {
    try {
      await _updateWidgetData();
    } catch (e) {
      developer.log('Error triggering widget update: $e', name: _logTag);
    }
  }
  
  /// Check if action came from widget
  bool isWidgetAction(String? action) {
    return action != null && [
      'camera',
      'gallery', 
      'history',
      'settings'
    ].contains(action);
  }
  
  /// Dispose resources
  void dispose() {
    _actionController.close();
  }
}

/// Widget Action Types
enum WidgetActionType {
  camera,
  gallery,
  history,
  settings,
  unknown,
}

/// Widget Action Data Class
class WidgetAction {
  final WidgetActionType type;
  final Map<String, dynamic>? extras;
  
  WidgetAction({
    required this.type,
    this.extras,
  });
  
  factory WidgetAction.fromString(String action) {
    switch (action.toLowerCase()) {
      case 'camera':
        return WidgetAction(type: WidgetActionType.camera);
      case 'gallery':
        return WidgetAction(type: WidgetActionType.gallery);
      case 'history':
        return WidgetAction(type: WidgetActionType.history);
      case 'settings':
        return WidgetAction(type: WidgetActionType.settings);
      default:
        return WidgetAction(type: WidgetActionType.unknown);
    }
  }
  
  @override
  String toString() {
    return 'WidgetAction(type: $type, extras: $extras)';
  }
}

/// Widget Integration Helper
class WidgetIntegrationHelper {
  /// Handle widget camera action
  static Future<void> handleCameraAction() async {
    developer.log('Executing widget camera action', name: 'WidgetIntegration');
    
    try {
      final ImagePicker picker = ImagePicker();
      await picker.pickImage(source: ImageSource.camera);
    } catch (e) {
      developer.log('Error in widget camera action: $e', name: 'WidgetIntegration');
    }
  }
  
  /// Handle widget gallery action
  static Future<void> handleGalleryAction() async {
    developer.log('Executing widget gallery action', name: 'WidgetIntegration');
    
    try {
      final ImagePicker picker = ImagePicker();
      await picker.pickImage(source: ImageSource.gallery);
    } catch (e) {
      developer.log('Error in widget gallery action: $e', name: 'WidgetIntegration');
    }
  }
  
  /// Handle widget history action
  static Future<void> handleHistoryAction() async {
    developer.log('Executing widget history action', name: 'WidgetIntegration');
    // Navigation to history screen will be handled by main app
  }
  
  /// Handle widget settings action
  static Future<void> handleSettingsAction() async {
    developer.log('Executing widget settings action', name: 'WidgetIntegration');
    // Navigation to settings will be handled by main app
  }
} 