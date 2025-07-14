import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'l10n/app_localizations.dart';
import 'utils/text_format_analyzer.dart';

class TextEditorScreen extends StatefulWidget {
  final String initialText;
  final AppLocalizations l10n;

  const TextEditorScreen({
    super.key, 
    required this.initialText,
    required this.l10n,
  });

  @override
  State<TextEditorScreen> createState() => _TextEditorScreenState();
}

class _TextEditorScreenState extends State<TextEditorScreen> {
  late TextEditingController _textController;
  bool _isExporting = false;
  bool _hasUnsavedChanges = false;
  bool _editMode = false;

  List<AnalyzedTextLine> _analyzedLines = [];
  
  // PDF Formatting Options
  double _fontSize = 12.0;
  final String _fontFamily = 'Helvetica';
  bool _includeDateHeader = true;
  bool _includePageNumbers = true;
  PdfPageFormat _pageFormat = PdfPageFormat.a4;
  String _documentTitle = '';
  
  late TextEditingController _titleController;

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
    _titleController = TextEditingController(text: 'OCR Tarama Sonucu');
    _documentTitle = 'OCR Tarama Sonucu';
    _analyzeText();
  }

  @override
  void dispose() {
    _textController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {
      _hasUnsavedChanges = _textController.text != widget.initialText;
      _analyzeText();
    });
  }

  void _analyzeText() {
    _analyzedLines = analyzeOcrText(_textController.text);
  }

  void _copyToClipboard() {
    if (_textController.text.isEmpty) return;
    Clipboard.setData(ClipboardData(text: _textController.text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(widget.l10n.textCopied),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
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
                child: SingleChildScrollView(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      _buildFormattingToolbar(),
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.55,
                child: _buildTextEditorCard(),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 8, left: 8, right: 8),
                child: _buildActionButtons(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            tooltip: widget.l10n.back,
          ),
          Text(
            widget.l10n.textEditor,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(
            width: 48, // To balance the back button
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (!_editMode && !_isExporting)
                  IconButton(
                    onPressed: () => setState(() => _editMode = true),
                    icon: const Icon(Icons.edit, color: Colors.white),
                    tooltip: 'Düzenle',
                  ),
                if (_editMode && !_isExporting)
                  IconButton(
                    onPressed: () => setState(() => _editMode = false),
                    icon: const Icon(Icons.visibility, color: Colors.white),
                    tooltip: 'Önizleme',
                  ),
                if (_isExporting)
                  const SizedBox.shrink(),
                if (_hasUnsavedChanges && !_isExporting)
                  IconButton(
                    onPressed: _saveChanges,
                    icon: const Icon(Icons.save, color: Colors.white),
                    tooltip: widget.l10n.save,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextEditorCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Container(
      decoration: BoxDecoration(
          color: Colors.white.withAlpha(240),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(30),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: _editMode
              ? TextField(
                  controller: _textController,
                  maxLines: null,
                  expands: true,
                  keyboardType: TextInputType.multiline,
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.all(16),
                    border: InputBorder.none,
                  ),
                  style: const TextStyle(fontSize: 16, color: Colors.black87),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: RichText(
                    text: TextSpan(
                      children: _analyzedLines.map((line) {
                        switch (line.type) {
                          case TextLineType.heading:
                            return TextSpan(
                              text: '${line.text}\n',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            );
                          case TextLineType.bullet:
                            return TextSpan(
                              text: '• ${line.text.replaceFirst(RegExp(r'^[-*•\d+\). ]+'), '')}\n',
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                            );
                          case TextLineType.quote:
                            return TextSpan(
                              text: '${line.text}\n',
                              style: const TextStyle(
                                fontSize: 16,
                                fontStyle: FontStyle.italic,
                                color: Colors.grey,
                              ),
                            );
                          case TextLineType.paragraph:
                          default:
                            return TextSpan(
                              text: '${line.text}\n',
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.black87,
      ),
    );
  }
                      }).toList(),
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildFormattingToolbar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(230),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildFormatButton(
            icon: Icons.format_bold,
            tooltip: 'Kalın',
            onTap: () => _formatText('**', '**'),
          ),
          _buildFormatButton(
            icon: Icons.format_italic,
            tooltip: 'İtalik',
            onTap: () => _formatText('*', '*'),
          ),
          _buildFormatButton(
            icon: Icons.format_underlined,
            tooltip: 'Altı Çizili',
            onTap: () => _formatText('_', '_'),
          ),
          _buildFormatButton(
            icon: Icons.format_quote,
            tooltip: 'Alıntı',
            onTap: () => _formatText('> ', ''),
          ),
          _buildFormatButton(
            icon: Icons.format_list_bulleted,
            tooltip: 'Liste',
            onTap: () => _formatText('• ', ''),
          ),
          _buildFormatButton(
            icon: Icons.text_increase,
            tooltip: 'Büyük Harf',
            onTap: () => _toggleCase(),
          ),
        ],
      ),
    );
  }

  Widget _buildFormatButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        child: Icon(
          icon,
          size: 20,
          color: Colors.grey[700],
        ),
      ),
    );
  }

  void _formatText(String prefix, String suffix) {
    final selection = _textController.selection;
    if (selection.isValid) {
      final selectedText = _textController.text.substring(
        selection.start,
        selection.end,
      );
      final newText = _textController.text.replaceRange(
        selection.start,
        selection.end,
        '$prefix$selectedText$suffix',
      );
      _textController.text = newText;
      _textController.selection = TextSelection.collapsed(
        offset: selection.start + prefix.length + selectedText.length + suffix.length,
      );
    }
  }

  void _toggleCase() {
    final selection = _textController.selection;
    if (selection.isValid) {
      final selectedText = _textController.text.substring(
        selection.start,
        selection.end,
      );
      final isUpperCase = selectedText == selectedText.toUpperCase();
      final newText = _textController.text.replaceRange(
        selection.start,
        selection.end,
        isUpperCase ? selectedText.toLowerCase() : selectedText.toUpperCase(),
      );
      _textController.text = newText;
      _textController.selection = selection;
    }
  }

  Widget _buildActionButtons() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          _buildActionButton(
            icon: Icons.copy,
              label: 'Kopyala',
            onTap: _copyToClipboard,
              color: Colors.blue,
          ),
          const SizedBox(width: 8),
          _buildActionButton(
            icon: Icons.share,
            label: 'Paylaş',
            onTap: _shareText,
            color: Colors.orange,
          ),
          const SizedBox(width: 8),
          _buildActionButton(
            icon: Icons.picture_as_pdf,
            label: 'PDF',
            onTap: _showPdfSettingsDialog,
            color: Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
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
            child: _buildButtonContent(icon, label),
          ),
        ),
      ),
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

  void _shareText() {
    if (_textController.text.isEmpty) return;
    SharePlus.instance.share(ShareParams(text: _textController.text));
  }

  Future<void> _exportAsPdf() async {
    // Show PDF settings dialog first
    await _showPdfSettingsDialog();
  }

  Future<void> _showPdfSettingsDialog() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('PDF ${widget.l10n.settings}'),
        content: StatefulBuilder(
          builder: (context, setState) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Document Title
                TextField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'Belge Başlığı',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (value) => _documentTitle = value,
                ),
                const SizedBox(height: 16),
                
                // Font Size
                Row(
                  children: [
                    Text('Yazı Boyutu: ${_fontSize.round()}'),
                    Expanded(
                      child: Slider(
                        value: _fontSize,
                        min: 8.0,
                        max: 24.0,
                        divisions: 16,
                        onChanged: (value) => setState(() => _fontSize = value),
                      ),
                    ),
                  ],
                ),
                
                // Page Format
                DropdownButtonFormField<PdfPageFormat>(
                  value: _pageFormat,
                  decoration: InputDecoration(
                    labelText: 'Sayfa Formatı',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: [
                    DropdownMenuItem(value: PdfPageFormat.a4, child: Text('A4')),
                    DropdownMenuItem(value: PdfPageFormat.a5, child: Text('A5')),
                    DropdownMenuItem(value: PdfPageFormat.letter, child: Text('Letter')),
                  ],
                  onChanged: (value) => setState(() => _pageFormat = value!),
                ),
                const SizedBox(height: 16),
                
                // Options
                CheckboxListTile(
                  title: const Text('Tarih Başlığı'),
                  value: _includeDateHeader,
                  onChanged: (value) => setState(() => _includeDateHeader = value!),
                ),
                CheckboxListTile(
                  title: const Text('Sayfa Numaraları'),
                  value: _includePageNumbers,
                  onChanged: (value) => setState(() => _includePageNumbers = value!),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(widget.l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _generateAdvancedPdf();
            },
            child: Text('PDF Oluştur'),
          ),
        ],
      ),
    );
  }

  Future<void> _generateAdvancedPdf() async {
    if (_isExporting) return;
    setState(() => _isExporting = true);

    try {
      // Load NotoSans font from assets
      final fontData = await rootBundle.load('assets/fonts/NotoSans-Regular.ttf');
      final notoFont = pw.Font.ttf(fontData);
    final pdf = pw.Document();
      final currentDate = DateTime.now();
    
    pdf.addPage(
        pw.MultiPage(
          pageFormat: _pageFormat,
          margin: const pw.EdgeInsets.all(32),
          header: _includeDateHeader ? (context) => pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(bottom: 16),
            child: pw.Text(
              '${currentDate.day}/${currentDate.month}/${currentDate.year}',
              style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600, font: notoFont),
            ),
          ) : null,
          footer: _includePageNumbers ? (context) => pw.Container(
            alignment: pw.Alignment.center,
            margin: const pw.EdgeInsets.only(top: 16),
            child: pw.Text(
              'Sayfa ${context.pageNumber}/${context.pagesCount}',
              style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600, font: notoFont),
            ),
          ) : null,
          build: (context) => [
            // Title
            pw.Header(
              level: 0,
              child: pw.Text(
                _documentTitle.isEmpty ? 'OCR Tarama Sonucu' : _documentTitle,
                style: pw.TextStyle(
                  fontSize: _fontSize + 6,
                  fontWeight: pw.FontWeight.bold,
                  font: notoFont,
                ),
              ),
            ),
            pw.SizedBox(height: 20),
            // Content
            ..._analyzedLines.map((line) {
              switch (line.type) {
                case TextLineType.heading:
                  return pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 8),
                    child: pw.Text(
                      line.text,
                      style: pw.TextStyle(
                        fontSize: _fontSize + 2,
                        fontWeight: pw.FontWeight.bold,
                        font: notoFont,
                      ),
                    ),
                  );
                case TextLineType.bullet:
                  return pw.Bullet(
                    text: line.text.replaceFirst(RegExp(r'^[-*•\d+\). ]+'), ''),
      style: pw.TextStyle(
                      fontSize: _fontSize,
                      font: notoFont,
                    ),
                  );
                case TextLineType.quote:
                  return pw.Padding(
                    padding: const pw.EdgeInsets.only(left: 16, bottom: 8),
                    child: pw.Text(
                      line.text,
      style: pw.TextStyle(
                        fontSize: _fontSize,
                        fontStyle: pw.FontStyle.italic,
        color: PdfColors.grey600,
                        font: notoFont,
                      ),
                    ),
                  );
                case TextLineType.paragraph:
                default:
                  return pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Text(
                      line.text,
                      style: pw.TextStyle(
                        fontSize: _fontSize,
                        font: notoFont,
        ),
      ),
    );
  }
            }),
          ],
        ),
      );
      
      final output = await getTemporaryDirectory();
      final fileName = _documentTitle.isEmpty ? 'exported_text' : _documentTitle.replaceAll(' ', '_');
      final file = File("${output.path}/$fileName.pdf");
    await file.writeAsBytes(await pdf.save());
      
      await Share.shareXFiles([XFile(file.path)], text: 'PDF Belgesi');
      _showSnackBar('PDF başarıyla oluşturuldu!', Colors.green);
    } catch (e) {
      _showSnackBar('${widget.l10n.error}: $e', Colors.red);
    } finally {
      setState(() => _isExporting = false);
    }
  }
  
  void _saveChanges() {
    // Future: Implement save functionality
    setState(() {
      _hasUnsavedChanges = false;
    });
    _showSnackBar('Changes saved (mock)', Colors.green);
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
} 