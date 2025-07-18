import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import '../l10n/app_localizations.dart';

/// Comprehensive error handling ve user feedback sistemi
class ErrorHandler {
  static const String _logTag = 'ErrorHandler';

  /// Hata tiplerini kategorize et
  static ErrorType _categorizeError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    
    if (errorString.contains('permission')) {
      return ErrorType.permission;
    } else if (errorString.contains('network') || errorString.contains('internet')) {
      return ErrorType.network;
    } else if (errorString.contains('storage') || errorString.contains('space')) {
      return ErrorType.storage;
    } else if (errorString.contains('camera') || errorString.contains('picker')) {
      return ErrorType.camera;
    } else if (errorString.contains('ocr') || errorString.contains('text')) {
      return ErrorType.ocr;
    } else if (errorString.contains('credit') || errorString.contains('subscription')) {
      return ErrorType.credit;
    } else if (errorString.contains('file') || errorString.contains('path')) {
      return ErrorType.file;
    } else {
      return ErrorType.unknown;
    }
  }

  /// Hata mesajını kullanıcı dostu hale getir
  static String _getUserFriendlyMessage(ErrorType type, String originalError) {
    switch (type) {
      case ErrorType.permission:
        return 'İzin gerekli. Lütfen uygulama ayarlarından gerekli izinleri verin.';
      case ErrorType.network:
        return 'İnternet bağlantısı sorunu. Lütfen bağlantınızı kontrol edin.';
      case ErrorType.storage:
        return 'Depolama alanı yetersiz. Lütfen cihazınızda yer açın.';
      case ErrorType.camera:
        return 'Kamera erişimi sorunu. Lütfen kamera izinlerini kontrol edin.';
      case ErrorType.ocr:
        return 'Metin çıkarma işlemi başarısız. Lütfen daha net bir resim deneyin.';
      case ErrorType.credit:
        return 'Kredi sistemi sorunu. Lütfen daha sonra tekrar deneyin.';
      case ErrorType.file:
        return 'Dosya işlemi başarısız. Lütfen farklı bir dosya deneyin.';
      case ErrorType.unknown:
        return 'Beklenmeyen bir hata oluştu. Lütfen tekrar deneyin.';
    }
  }

  /// Hata recovery önerileri
  static List<RecoveryAction> _getRecoveryActions(ErrorType type) {
    switch (type) {
      case ErrorType.permission:
        return [
          RecoveryAction(
            title: 'Ayarlara Git',
            action: RecoveryActionType.openSettings,
            icon: Icons.settings,
          ),
          RecoveryAction(
            title: 'Tekrar Dene',
            action: RecoveryActionType.retry,
            icon: Icons.refresh,
          ),
        ];
      case ErrorType.network:
        return [
          RecoveryAction(
            title: 'Bağlantıyı Kontrol Et',
            action: RecoveryActionType.checkConnection,
            icon: Icons.wifi,
          ),
          RecoveryAction(
            title: 'Offline Moda Geç',
            action: RecoveryActionType.goOffline,
            icon: Icons.offline_bolt,
          ),
        ];
      case ErrorType.storage:
        return [
          RecoveryAction(
            title: 'Depolama Temizle',
            action: RecoveryActionType.clearStorage,
            icon: Icons.cleaning_services,
          ),
        ];
      case ErrorType.camera:
        return [
          RecoveryAction(
            title: 'Galeri Kullan',
            action: RecoveryActionType.useGallery,
            icon: Icons.photo_library,
          ),
          RecoveryAction(
            title: 'İzinleri Kontrol Et',
            action: RecoveryActionType.checkPermissions,
            icon: Icons.security,
          ),
        ];
      case ErrorType.ocr:
        return [
          RecoveryAction(
            title: 'Başka Resim Dene',
            action: RecoveryActionType.tryDifferentImage,
            icon: Icons.photo_camera,
          ),
          RecoveryAction(
            title: 'Resim Kalitesini Artır',
            action: RecoveryActionType.enhanceImage,
            icon: Icons.auto_fix_high,
          ),
        ];
      case ErrorType.credit:
        return [
          RecoveryAction(
            title: 'Kredi Satın Al',
            action: RecoveryActionType.buyCredits,
            icon: Icons.credit_card,
          ),
        ];
      case ErrorType.file:
        return [
          RecoveryAction(
            title: 'Farklı Dosya Seç',
            action: RecoveryActionType.selectDifferentFile,
            icon: Icons.folder_open,
          ),
        ];
      case ErrorType.unknown:
        return [
          RecoveryAction(
            title: 'Tekrar Dene',
            action: RecoveryActionType.retry,
            icon: Icons.refresh,
          ),
          RecoveryAction(
            title: 'Destek Al',
            action: RecoveryActionType.contactSupport,
            icon: Icons.support_agent,
          ),
        ];
    }
  }

  /// Ana hata handling metodu
  static Future<void> handleError(
    BuildContext context,
    dynamic error, {
    String? customMessage,
    VoidCallback? onRetry,
    bool showSnackBar = true,
    bool logError = true,
  }) async {
    if (logError) {
      developer.log(
        'Error occurred: $error',
        name: _logTag,
        error: error,
        stackTrace: StackTrace.current,
      );
    }

    final errorType = _categorizeError(error);
    final userMessage = customMessage ?? _getUserFriendlyMessage(errorType, error.toString());
    final recoveryActions = _getRecoveryActions(errorType);

    if (showSnackBar) {
      _showErrorSnackBar(context, userMessage, errorType);
    }

    // Kritik hatalar için dialog göster
    if (_isCriticalError(errorType)) {
      await _showErrorDialog(context, userMessage, recoveryActions, onRetry);
    }
  }

  /// Kritik hata kontrolü
  static bool _isCriticalError(ErrorType type) {
    return [
      ErrorType.permission,
      ErrorType.storage,
      ErrorType.credit,
    ].contains(type);
  }

  /// Error SnackBar göster
  static void _showErrorSnackBar(BuildContext context, String message, ErrorType type) {
    if (!context.mounted) return;

    final color = _getErrorColor(type);
    final icon = _getErrorIcon(type);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        action: SnackBarAction(
          label: 'Tamam',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  /// Error dialog göster
  static Future<void> _showErrorDialog(
    BuildContext context,
    String message,
    List<RecoveryAction> actions,
    VoidCallback? onRetry,
  ) async {
    if (!context.mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 12),
            Text('Hata'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            if (actions.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Önerilen çözümler:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              ...actions.map((action) => _buildActionButton(context, action, onRetry)),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }

  /// Recovery action button oluştur
  static Widget _buildActionButton(
    BuildContext context,
    RecoveryAction action,
    VoidCallback? onRetry,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () {
            Navigator.of(context).pop();
            _executeRecoveryAction(context, action.action, onRetry);
          },
          icon: Icon(action.icon, size: 16),
          label: Text(action.title),
          style: OutlinedButton.styleFrom(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ),
    );
  }

  /// Recovery action'ı execute et
  static void _executeRecoveryAction(
    BuildContext context,
    RecoveryActionType actionType,
    VoidCallback? onRetry,
  ) {
    switch (actionType) {
      case RecoveryActionType.retry:
        onRetry?.call();
        break;
      case RecoveryActionType.openSettings:
        // Uygulama ayarlarını aç
        break;
      case RecoveryActionType.checkConnection:
        _showConnectionTips(context);
        break;
      case RecoveryActionType.goOffline:
        // Offline moda geç
        break;
      case RecoveryActionType.clearStorage:
        _showStorageTips(context);
        break;
      case RecoveryActionType.useGallery:
        // Galeri kullanmaya yönlendir
        break;
      case RecoveryActionType.checkPermissions:
        // İzin kontrolü yap
        break;
      case RecoveryActionType.tryDifferentImage:
        // Farklı resim seçmeye yönlendir
        break;
      case RecoveryActionType.enhanceImage:
        // Resim enhancement ipuçları göster
        break;
      case RecoveryActionType.buyCredits:
        // Kredi satın alma ekranına yönlendir
        break;
      case RecoveryActionType.selectDifferentFile:
        // Farklı dosya seçmeye yönlendir
        break;
      case RecoveryActionType.contactSupport:
        _showSupportDialog(context);
        break;
    }
  }

  /// Hata tipine göre renk
  static Color _getErrorColor(ErrorType type) {
    switch (type) {
      case ErrorType.permission:
        return Colors.orange;
      case ErrorType.network:
        return Colors.blue;
      case ErrorType.storage:
        return Colors.purple;
      case ErrorType.camera:
        return Colors.green;
      case ErrorType.ocr:
        return Colors.teal;
      case ErrorType.credit:
        return Colors.amber;
      case ErrorType.file:
        return Colors.indigo;
      case ErrorType.unknown:
        return Colors.red;
    }
  }

  /// Hata tipine göre ikon
  static IconData _getErrorIcon(ErrorType type) {
    switch (type) {
      case ErrorType.permission:
        return Icons.security;
      case ErrorType.network:
        return Icons.wifi_off;
      case ErrorType.storage:
        return Icons.storage;
      case ErrorType.camera:
        return Icons.camera_alt;
      case ErrorType.ocr:
        return Icons.text_fields;
      case ErrorType.credit:
        return Icons.credit_card;
      case ErrorType.file:
        return Icons.folder;
      case ErrorType.unknown:
        return Icons.error;
    }
  }

  /// Bağlantı ipuçları göster
  static void _showConnectionTips(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.connectionTips),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.l10n.checkWifi),
            Text(context.l10n.enableMobileData),
            Text(context.l10n.disableAirplaneMode),
            Text(context.l10n.restartRouter),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(context.l10n.ok),
          ),
        ],
      ),
    );
  }

  /// Depolama ipuçları göster
  static void _showStorageTips(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.storageTips),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.l10n.deleteUnnecessaryPhotos),
            Text(context.l10n.clearCache),
            Text(context.l10n.uninstallUnusedApps),
            Text(context.l10n.moveFilesToCloud),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(context.l10n.ok),
          ),
        ],
      ),
    );
  }

  /// Destek bilgileri göster
  static void _showSupportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.support),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.l10n.ifProblemPersists),
            const SizedBox(height: 8),
            Text(context.l10n.restartApp),
            Text(context.l10n.restartDevice),
            Text(context.l10n.checkAppUpdates),
            Text(context.l10n.contactDeveloper),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(context.l10n.ok),
          ),
        ],
      ),
    );
  }

  /// Success mesajı göster
  static void showSuccess(BuildContext context, String message, {IconData? icon}) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon ?? Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  /// Warning mesajı göster
  static void showWarning(BuildContext context, String message, {IconData? icon}) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon ?? Icons.warning, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  /// Info mesajı göster
  static void showInfo(BuildContext context, String message, {IconData? icon}) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon ?? Icons.info, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}

/// Hata tipleri
enum ErrorType {
  permission,
  network,
  storage,
  camera,
  ocr,
  credit,
  file,
  unknown,
}

/// Recovery action tipleri
enum RecoveryActionType {
  retry,
  openSettings,
  checkConnection,
  goOffline,
  clearStorage,
  useGallery,
  checkPermissions,
  tryDifferentImage,
  enhanceImage,
  buyCredits,
  selectDifferentFile,
  contactSupport,
}

/// Recovery action modeli
class RecoveryAction {
  final String title;
  final RecoveryActionType action;
  final IconData icon;

  RecoveryAction({
    required this.title,
    required this.action,
    required this.icon,
  });
} 