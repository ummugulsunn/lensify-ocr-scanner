// OCR metin format analizörü
// Her satırı analiz edip tipini belirler: başlık, madde, paragraf, alıntı

enum TextLineType {
  heading,
  bullet,
  quote,
  paragraph,
}

class AnalyzedTextLine {
  final String text;
  final TextLineType type;

  AnalyzedTextLine(this.text, this.type);
}

/// OCR çıktısını satır bazında analiz eder ve her satırı tipine göre etiketler.
List<AnalyzedTextLine> analyzeOcrText(String ocrText) {
  final lines = ocrText.split(RegExp(r'\r?\n'));
  final result = <AnalyzedTextLine>[];

  for (final rawLine in lines) {
    final line = rawLine.trim();
    if (line.isEmpty) continue;

    // --- Türkçe için gelişmiş başlık tespiti ---
    // İlk harf büyük, kısa (<50 karakter), sonunda nokta yok, az noktalama
    final isLikelyHeading =
        line.length < 50 &&
        RegExp(r'^[A-ZÇĞİÖŞÜ][^.!?]*[a-zçğıöşüA-ZÇĞİÖŞÜ0-9 ]? 0$').hasMatch(line) &&
        line.replaceAll(RegExp(r'[A-Za-zÇĞİÖŞÜçğıöşü0-9 ]'), '').length < 3;
    if (isLikelyHeading) {
      result.add(AnalyzedTextLine(line, TextLineType.heading));
      continue;
    }

    // --- Türkçe için gelişmiş madde işareti tespiti ---
    // -, *, •, 1), 1., a), i., •, • gibi
    if (RegExp(r'^([-*•‣‣•]|\d+[\).]|[a-zA-Z][\).]) ?').hasMatch(line)) {
      result.add(AnalyzedTextLine(line, TextLineType.bullet));
      continue;
    }

    // --- Türkçe için gelişmiş alıntı tespiti ---
    // >, “, ", ‘, -, -- ile başlıyorsa ve kısa ise
    if (RegExp(r'^(>|"|“|‘|--? |– |— |-)').hasMatch(line) && line.length < 80) {
      result.add(AnalyzedTextLine(line, TextLineType.quote));
      continue;
    }

    // --- Paragraf ---
    result.add(AnalyzedTextLine(line, TextLineType.paragraph));
  }

  return result;
} 