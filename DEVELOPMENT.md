# Lensify OCR Scanner - Development Guide

## 🚀 Getting Started

### Prerequisites

- **Flutter SDK**: 3.7.2 or higher
- **Dart SDK**: 3.0 or higher
- **Android Studio** or **VS Code** with Flutter extensions
- **Git** for version control
- **Android SDK** (for Android development)
- **Xcode** (for iOS development, macOS only)

### Environment Setup

1. **Install Flutter**
   ```bash
   # Download Flutter SDK
   git clone https://github.com/flutter/flutter.git
   export PATH="$PATH:`pwd`/flutter/bin"
   
   # Verify installation
   flutter doctor
   ```

2. **Clone the Repository**
   ```bash
   git clone https://github.com/yourusername/lensify-ocr-scanner.git
   cd lensify-ocr-scanner
   ```

3. **Install Dependencies**
   ```bash
   flutter pub get
   ```

4. **Configure Environment Variables**
   ```bash
   # Copy example environment file
   cp .env.example .env.local
   
   # Edit with your API keys
   nano .env.local
   ```

### Environment Variables

Create a `.env.local` file with the following variables:

```env
# AdMob Configuration
ADMOB_APP_ID=ca-app-pub-xxxxxxxxxxxxxxxx~yyyyyyyyyy
ADMOB_BANNER_ID=ca-app-pub-xxxxxxxxxxxxxxxx/zzzzzzzzzz

# Google Cloud Vision API (Premium Feature)
GOOGLE_CLOUD_VISION_API_KEY=your_cloud_vision_api_key

# In-App Purchase IDs
IAP_PREMIUM_MONTHLY=premium_monthly
IAP_PREMIUM_YEARLY=premium_yearly
IAP_CREDITS_100=credits_100
IAP_CREDITS_500=credits_500

# Debug Mode
NEXT_PUBLIC_DEBUG_MODE=true
DEBUG_MODE=true
```

## 🏗️ Project Structure

```
lib/
├── animations/          # Animation utilities
│   └── animations.dart
├── database/           # SQLite database operations
│   └── ocr_history_database.dart
├── l10n/              # Localization files
│   └── app_localizations.dart
├── screens/            # App screens
│   └── ocr_history_screen.dart
├── services/           # Business logic services
│   ├── admob_service.dart
│   ├── credit_manager.dart
│   ├── subscription_manager.dart
│   └── widget_service.dart
├── theme/              # Theme and styling
│   ├── animations.dart
│   ├── app_theme.dart
│   ├── components.dart
│   └── theme_provider.dart
├── utils/              # Utility functions
│   ├── analytics_service.dart
│   ├── async_ocr_processor.dart
│   ├── error_handler.dart
│   ├── image_processor.dart
│   ├── memory_manager.dart
│   ├── ocr_cache_manager.dart
│   ├── ocr_engine_manager.dart
│   ├── optimized_ocr_manager.dart
│   ├── performance_monitor.dart
│   └── text_format_analyzer.dart
├── widgets/            # Reusable UI components
│   └── banner_ad_widget.dart
├── main.dart           # App entry point
├── settings_dialog.dart # Settings UI
└── text_editor_screen.dart # Text editing screen
```

## 🧪 Testing

### Running Tests

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/ocr_engine_manager_test.dart

# Run tests with coverage
flutter test --coverage

# Generate coverage report
genhtml coverage/lcov.info -o coverage/html
```

### Test Structure

```
test/
├── widget_test.dart              # Widget tests
├── ocr_engine_manager_test.dart  # OCR engine tests
├── credit_manager_test.dart      # Credit system tests
├── performance_test.dart         # Performance tests
└── integration_test.dart         # Integration tests
```

### Writing Tests

1. **Unit Tests**: Test individual functions and classes
2. **Widget Tests**: Test UI components
3. **Integration Tests**: Test complete user flows
4. **Performance Tests**: Test app performance

Example test structure:

```dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Feature Tests', () {
    setUp(() {
      // Setup test environment
    });

    tearDown(() {
      // Cleanup after tests
    });

    test('should perform expected behavior', () {
      // Test implementation
    });

    testWidgets('should display correctly', (tester) async {
      // Widget test implementation
    });
  });
}
```

## 🔧 Development Workflow

### 1. Feature Development

1. **Create Feature Branch**
   ```bash
   git checkout -b feature/new-feature
   ```

2. **Implement Feature**
   - Follow coding standards
   - Write tests
   - Update documentation

3. **Test Implementation**
   ```bash
   flutter test
   flutter analyze
   ```

4. **Create Pull Request**
   ```bash
   git push origin feature/new-feature
   # Create PR on GitHub
   ```

### 2. Code Review Process

1. **Self Review**
   - Run tests locally
   - Check code formatting
   - Verify functionality

2. **Peer Review**
   - Request review from team members
   - Address feedback
   - Update code as needed

3. **Merge**
   - Squash commits
   - Merge to main branch
   - Delete feature branch

### 3. Release Process

1. **Version Update**
   ```bash
   # Update version in pubspec.yaml
   version: 1.1.0+3
   ```

2. **Build Release**
   ```bash
   # Android
   flutter build appbundle --release
   
   # iOS
   flutter build ios --release
   ```

3. **Deploy**
   - Upload to Google Play Console
   - Submit to App Store
   - Create GitHub release

## 📝 Coding Standards

### Dart/Flutter Standards

1. **Naming Conventions**
   ```dart
   // Classes: PascalCase
   class OCRManager {}
   
   // Variables and functions: camelCase
   String userName = 'John';
   void performOCR() {}
   
   // Constants: SCREAMING_SNAKE_CASE
   const int MAX_RETRY_COUNT = 3;
   ```

2. **File Organization**
   ```dart
   // Imports
   import 'dart:io';
   import 'package:flutter/material.dart';
   import 'package:provider/provider.dart';
   
   // Exports
   export 'package:my_app/utils/helpers.dart';
   
   // Class definition
   class MyClass {
     // Static members
     static const String title = 'My App';
     
     // Instance variables
     final String name;
     
     // Constructor
     MyClass(this.name);
     
     // Methods
     void doSomething() {}
   }
   ```

3. **Error Handling**
   ```dart
   try {
     final result = await performOperation();
     return result;
   } catch (e) {
     debugPrint('Error: $e');
     rethrow;
   }
   ```

### Performance Guidelines

1. **Memory Management**
   ```dart
   // Dispose resources properly
   @override
   void dispose() {
     _controller.dispose();
     _subscription.cancel();
     super.dispose();
   }
   ```

2. **Async Operations**
   ```dart
   // Use proper async/await
   Future<void> performAsyncOperation() async {
     final result = await someAsyncCall();
     return result;
   }
   ```

3. **Widget Optimization**
   ```dart
   // Use const constructors
   const MyWidget({Key? key}) : super(key: key);
   
   // Implement shouldRebuild
   @override
   bool shouldRebuild(covariant CustomPainter oldDelegate) => false;
   ```

## 🔍 Debugging

### Debug Tools

1. **Flutter Inspector**
   ```bash
   flutter run --debug
   # Open Flutter Inspector in IDE
   ```

2. **Performance Profiling**
   ```bash
   flutter run --profile
   # Use DevTools for profiling
   ```

3. **Memory Profiling**
   ```bash
   flutter run --profile
   # Use DevTools Memory tab
   ```

### Logging

```dart
import 'dart:developer' as developer;

// Debug logging
developer.log('Debug message', name: 'MyApp');

// Error logging
developer.log('Error occurred', error: error, stackTrace: stackTrace);
```

## 🚀 Performance Optimization

### 1. Image Processing

```dart
// Optimize image size before OCR
Future<File> optimizeImage(File imageFile) async {
  final image = await decodeImageFromList(await imageFile.readAsBytes());
  
  if (image.width > 1920 || image.height > 1080) {
    // Resize image for better performance
    return resizeImage(imageFile, 1920, 1080);
  }
  
  return imageFile;
}
```

### 2. Memory Management

```dart
// Implement proper memory management
class MemoryManager {
  static Future<void> checkMemoryUsage() async {
    // Monitor memory usage
    // Clean up if necessary
  }
  
  static void dispose() {
    // Clean up resources
  }
}
```

### 3. Caching

```dart
// Implement intelligent caching
class CacheManager {
  static Future<T?> getCached<T>(String key) async {
    // Get from cache
  }
  
  static Future<void> setCached<T>(String key, T value) async {
    // Set cache value
  }
}
```

## 🔒 Security Best Practices

### 1. API Key Management

```dart
// Use environment variables
const apiKey = String.fromEnvironment('API_KEY');
```

### 2. Data Validation

```dart
// Validate user input
String validateInput(String input) {
  if (input.isEmpty) {
    throw ArgumentError('Input cannot be empty');
  }
  return input.trim();
}
```

### 3. Secure Storage

```dart
// Use secure storage for sensitive data
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final storage = FlutterSecureStorage();
await storage.write(key: 'api_key', value: apiKey);
```

## 📊 Analytics and Monitoring

### 1. Performance Monitoring

```dart
// Track performance metrics
class PerformanceMonitor {
  static Future<T> trackOperation<T>(
    Future<T> Function() operation,
    String operationName,
  ) async {
    final stopwatch = Stopwatch()..start();
    try {
      final result = await operation();
      stopwatch.stop();
      
      // Log performance metric
      _logPerformance(operationName, stopwatch.elapsed);
      
      return result;
    } catch (e) {
      stopwatch.stop();
      _logError(operationName, e, stopwatch.elapsed);
      rethrow;
    }
  }
}
```

### 2. Error Tracking

```dart
// Track errors for debugging
class ErrorTracker {
  static void trackError(
    dynamic error,
    StackTrace? stackTrace,
    {String? context}
  ) {
    // Log error to analytics service
    AnalyticsService().trackError(
      errorType: error.runtimeType.toString(),
      errorMessage: error.toString(),
      stackTrace: stackTrace.toString(),
      context: context != null ? {'context': context} : null,
    );
  }
}
```

## 🧪 Continuous Integration

### GitHub Actions Workflow

The project includes a comprehensive CI/CD pipeline:

1. **Code Analysis**: Runs `flutter analyze`
2. **Testing**: Runs all tests with coverage
3. **Building**: Builds Android and iOS apps
4. **Security Scan**: Checks for vulnerabilities
5. **Performance Test**: Runs performance tests
6. **Deployment**: Deploys to staging/production

### Local CI Checks

```bash
# Run all CI checks locally
flutter analyze
flutter test --coverage
flutter build apk --release
flutter build ios --release --no-codesign
```

## 📚 Documentation

### Code Documentation

```dart
/// Performs OCR on the given image file.
/// 
/// [imageFile] The image file to process
/// [quality] The OCR quality level to use
/// [language] The language code for OCR
/// [isHandwritingMode] Whether to use handwriting recognition
/// 
/// Returns an [OCRResult] containing the extracted text and metadata.
/// 
/// Throws [OCRException] if the operation fails.
Future<OCRResult> performOCR(
  File imageFile, {
  OCRQuality quality = OCRQuality.balanced,
  String language = 'tur',
  bool isHandwritingMode = false,
}) async {
  // Implementation
}
```

### API Documentation

Generate API documentation:

```bash
# Generate documentation
dart doc

# Serve documentation locally
dart doc --serve
```

## 🤝 Contributing

### Contribution Guidelines

1. **Fork the repository**
2. **Create a feature branch**
3. **Make your changes**
4. **Write tests**
5. **Update documentation**
6. **Submit a pull request**

### Code Review Checklist

- [ ] Code follows style guidelines
- [ ] Tests pass
- [ ] Documentation updated
- [ ] No security vulnerabilities
- [ ] Performance impact considered
- [ ] Error handling implemented
- [ ] Accessibility considered

## 🚀 Deployment

### Android Deployment

1. **Build App Bundle**
   ```bash
   flutter build appbundle --release
   ```

2. **Upload to Google Play Console**
   - Sign in to Google Play Console
   - Upload the AAB file
   - Fill in store listing
   - Submit for review

### iOS Deployment

1. **Build iOS App**
   ```bash
   flutter build ios --release
   ```

2. **Archive in Xcode**
   - Open `ios/Runner.xcworkspace`
   - Select "Any iOS Device"
   - Product → Archive

3. **Upload to App Store Connect**
   - Use Xcode Organizer
   - Upload to App Store Connect
   - Submit for review

## 📞 Support

### Getting Help

- **Documentation**: Check the README and ARCHITECTURE.md
- **Issues**: Create an issue on GitHub
- **Discussions**: Use GitHub Discussions
- **Email**: support@lensify.app

### Development Resources

- [Flutter Documentation](https://flutter.dev/docs)
- [Dart Language Tour](https://dart.dev/guides/language/language-tour)
- [Flutter Testing](https://flutter.dev/docs/testing)
- [Flutter Performance](https://flutter.dev/docs/perf)

---

This development guide provides comprehensive information for contributing to the Lensify OCR Scanner project. Follow these guidelines to ensure code quality, maintainability, and team collaboration. 