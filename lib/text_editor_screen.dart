import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';

class TextEditorScreen extends StatefulWidget {
  final String initialText;

  const TextEditorScreen({super.key, required this.initialText});

  @override
  State<TextEditorScreen> createState() => _TextEditorScreenState();
}

class _TextEditorScreenState extends State<TextEditorScreen> {
  late TextEditingController _textController;
  bool _isExporting = false;
  bool _hasUnsavedChanges = false;

  // Color constants for consistency
  static const _gradientColors = [
    Color(0xFF667eea),
    Color(0xFF764ba2),
    Color(0xFFf093fb),
    Color(0xFFf5576c),
  ];

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.initialText);
    _textController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {
      _hasUnsavedChanges = _textController.text != widget.initialText;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _gradientColors,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: _buildTextEditorCard(),
              ),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          _buildBackButton(),
          const SizedBox(width: 15),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Metin Düzenleyici',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'OCR sonucunu düzenleyin',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          if (_hasUnsavedChanges) _buildChangesIndicator(),
        ],
      ),
    );
  }

  Widget _buildBackButton() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: _onBackPressed,
          child: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildChangesIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        'Değiştirildi',
        style: TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildTextEditorCard() {
    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: _buildTextEditor(),
    );
  }

  Widget _buildTextEditor() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildEditorHeader(),
          const SizedBox(height: 15),
          Expanded(child: _buildTextInput()),
          const SizedBox(height: 15),
          _buildCharacterCount(),
        ],
      ),
    );
  }

  Widget _buildEditorHeader() {
    return const Row(
      children: [
        Icon(Icons.edit_outlined, color: Colors.white, size: 20),
        SizedBox(width: 8),
        Text(
          'Metin İçeriği',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildTextInput() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: TextField(
        controller: _textController,
        maxLines: null,
        expands: true,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          height: 1.5,
        ),
        decoration: InputDecoration(
          hintText: 'Metni düzenleyin...',
          hintStyle: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 16,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(20),
        ),
      ),
    );
  }

  Widget _buildCharacterCount() {
    return Row(
      children: [
        const Icon(Icons.info_outline, color: Colors.white70, size: 16),
        const SizedBox(width: 8),
        Text(
          'Karakter sayısı: ${_textController.text.length}',
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: _buildActionButton(
              icon: Icons.copy_outlined,
              label: 'Kopyala',
              color: Colors.blue,
              onTap: _copyToClipboard,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: _buildActionButton(
              icon: Icons.picture_as_pdf_outlined,
              label: _isExporting ? 'Dışa aktarılıyor...' : 'PDF Dışa Aktar',
              color: Colors.green,
              onTap: _isExporting ? null : _exportToPDF,
              isLoading: _isExporting,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onTap,
    bool isLoading = false,
  }) {
    return Container(
      height: 55,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Center(
            child: isLoading
                ? _buildLoadingIndicator()
                : _buildButtonContent(icon, label),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
        SizedBox(width: 8),
        Text(
          'Dışa aktarılıyor...',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildButtonContent(IconData icon, String label) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  void _onBackPressed() {
    if (_hasUnsavedChanges) {
      _showUnsavedChangesDialog();
    } else {
      Navigator.pop(context);
    }
  }

  void _showUnsavedChangesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kaydedilmemiş Değişiklikler'),
        content: const Text('Değişikliklerinizi kaydetmeden çıkmak istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Çık'),
          ),
        ],
      ),
    );
  }

  void _copyToClipboard() {
    if (_textController.text.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: _textController.text));
      _showSnackBar('Metin panoya kopyalandı', Colors.green);
    }
  }

  Future<void> _exportToPDF() async {
    if (_textController.text.isEmpty) {
      _showSnackBar('Metin alanı boş!', Colors.red);
      return;
    }

    setState(() {
      _isExporting = true;
    });

    try {
      final pdf = await _createPDF();
      final file = await _savePDF(pdf);
      await _sharePDF(file);
      
      _showSnackBar('PDF başarıyla oluşturuldu ve paylaşıldı!', Colors.green);
    } catch (e) {
      _showSnackBar('PDF oluşturulurken hata oluştu', Colors.red);
    } finally {
      setState(() {
        _isExporting = false;
      });
    }
  }

  Future<pw.Document> _createPDF() async {
    final pdf = pw.Document();
    final now = DateTime.now();
    
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(20),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildPDFHeader(),
                pw.SizedBox(height: 20),
                _buildPDFDate(now),
                pw.SizedBox(height: 30),
                _buildPDFContent(),
                pw.SizedBox(height: 20),
                pw.Divider(),
                pw.SizedBox(height: 10),
                _buildPDFFooter(),
              ],
            ),
          );
        },
      ),
    );
    
    return pdf;
  }

  pw.Widget _buildPDFHeader() {
    return pw.Text(
      'Lensify OCR - Metin Çıktısı',
      style: pw.TextStyle(
        fontSize: 24,
        fontWeight: pw.FontWeight.bold,
      ),
    );
  }

  pw.Widget _buildPDFDate(DateTime date) {
    return pw.Text(
      'Çıkarma Tarihi: ${date.day}/${date.month}/${date.year}',
      style: pw.TextStyle(
        fontSize: 12,
        color: PdfColors.grey600,
      ),
    );
  }

  pw.Widget _buildPDFContent() {
    return pw.Expanded(
      child: pw.Text(
        _textController.text,
        style: const pw.TextStyle(
          fontSize: 14,
          lineSpacing: 1.5,
        ),
      ),
    );
  }

  pw.Widget _buildPDFFooter() {
    return pw.Text(
      'Lensify OCR Scanner & PDF tarafından oluşturuldu',
      style: pw.TextStyle(
        fontSize: 10,
        color: PdfColors.grey600,
        fontStyle: pw.FontStyle.italic,
      ),
    );
  }

  Future<File> _savePDF(pw.Document pdf) async {
    final directory = await getApplicationDocumentsDirectory();
    final fileName = 'lensify_ocr_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  Future<void> _sharePDF(File file) async {
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        text: 'Lensify OCR - PDF Export',
      ),
    );
  }

  void _showSnackBar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
} 