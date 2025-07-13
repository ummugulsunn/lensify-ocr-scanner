// This is a basic Flutter widget test for Lensify OCR Scanner & PDF.

import 'package:flutter_test/flutter_test.dart';

import 'package:lensify/main.dart';

void main() {
  testWidgets('Lensify app loads correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that our app title is displayed.
    expect(find.text('Lensify'), findsOneWidget);
    expect(find.text('OCR Scanner & PDF'), findsOneWidget);
    
    // Verify that camera and gallery buttons are present.
    expect(find.text('Kamera'), findsOneWidget);
    expect(find.text('Galeri'), findsOneWidget);
    
    // Verify that the image placeholder is shown.
    expect(find.text('Resim Seçin'), findsOneWidget);
  });
}
