// This is a basic Flutter widget test for Lensify OCR Scanner & PDF.

import 'package:flutter_test/flutter_test.dart';
import 'package:lensify/theme/theme_provider.dart';
import 'package:lensify/services/credit_manager.dart';

import 'package:lensify/main.dart';

void main() {
  testWidgets('Lensify app loads correctly', (WidgetTester tester) async {
    // Initialize services for testing
    final themeProvider = ThemeProvider();
    final creditManager = CreditManager();
    
    await themeProvider.initialize();
    await creditManager.initialize();
    
    // Build our app and trigger a frame.
    await tester.pumpWidget(MyApp(
      themeProvider: themeProvider,
      creditManager: creditManager,
    ));

    // Verify that our app title is displayed.
    expect(find.text('Lensify'), findsOneWidget);
    expect(find.text('OCR Scanner & PDF'), findsOneWidget);
    
    // Verify that camera and gallery buttons are present (check for Turkish text).
    expect(find.textContaining('Kamera'), findsOneWidget);
    expect(find.textContaining('Galeri'), findsOneWidget);
    
    // Verify that the image placeholder is shown (check for Turkish text).
    expect(find.textContaining('Resim'), findsOneWidget);
  });
}
