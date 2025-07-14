import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_theme.dart';
import '../l10n/app_localizations.dart';

/// Tema modlarını tanımlayan enum
enum AppThemeMode {
  system,
  light,
  dark,
}

extension AppThemeModeExtension on AppThemeMode {
  ThemeMode toMaterialThemeMode() {
    switch (this) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.system:
        return ThemeMode.system;
    }
  }
}

/// Tema ve dil durumunu yöneten provider
class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  static const String _localeKey = 'app_locale';
  
  AppThemeMode _themeMode = AppThemeMode.system;
  Locale _locale = const Locale('tr', 'TR'); // Varsayılan Türkçe
  late SharedPreferences _prefs;
  
  AppThemeMode get themeMode => _themeMode;
  Locale get locale => _locale;
  
  /// Sistem tema durumuna göre tema döndür
  ThemeData getTheme(BuildContext context) {
    switch (_themeMode) {
      case AppThemeMode.light:
        return AppTheme.lightTheme;
      case AppThemeMode.dark:
        return AppTheme.darkTheme;
      case AppThemeMode.system:
        final brightness = MediaQuery.of(context).platformBrightness;
        return brightness == Brightness.dark 
            ? AppTheme.darkTheme 
            : AppTheme.lightTheme;
    }
  }
  
  /// Mevcut tema dark mı kontrol et
  bool isDarkMode(BuildContext context) {
    switch (_themeMode) {
      case AppThemeMode.light:
        return false;
      case AppThemeMode.dark:
        return true;
      case AppThemeMode.system:
        return MediaQuery.of(context).platformBrightness == Brightness.dark;
    }
  }
  
  /// Tema modunu değiştir
  Future<void> setThemeMode(AppThemeMode mode) async {
    if (_themeMode == mode) return;
    
    _themeMode = mode;
    await _saveThemeMode();
    _updateSystemUI();
    notifyListeners();
  }
  
  /// Dil değiştir
  Future<void> setLocale(Locale locale) async {
    if (_locale == locale) return;
    
    _locale = locale;
    await _saveLocale();
    notifyListeners();
  }
  
  /// Tema provider'ı başlat
  Future<void> initialize() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      await _loadThemeMode();
      await _loadLocale();
      _updateSystemUI();
    } catch (e) {
      // Log error if needed in production
      rethrow;
    }
  }
  
  /// Kaydedilen tema modunu yükle
  Future<void> _loadThemeMode() async {
    final savedMode = _prefs.getString(_themeKey);
    if (savedMode != null) {
      _themeMode = AppThemeMode.values.firstWhere(
        (mode) => mode.name == savedMode,
        orElse: () => AppThemeMode.system,
      );
    }
  }
  
  /// Tema modunu kaydet
  Future<void> _saveThemeMode() async {
    await _prefs.setString(_themeKey, _themeMode.name);
  }
  
  /// Locale'i kaydet
  Future<void> _saveLocale() async {
    await _prefs.setString(_localeKey, '${_locale.languageCode}_${_locale.countryCode}');
  }
  
  /// Locale'i yükle
  Future<void> _loadLocale() async {
    final savedLocale = _prefs.getString(_localeKey);
    if (savedLocale != null) {
      final parts = savedLocale.split('_');
      if (parts.length == 2) {
        final locale = Locale(parts[0], parts[1]);
        // Desteklenen dillerde kontrol et
        if (AppLocalizations.supportedLocales.contains(locale)) {
          _locale = locale;
        }
      }
    }
  }
  
  /// Sistem UI'sini güncelle (status bar, navigation bar)
  void _updateSystemUI() {
    // Bu method context gerektirmediği için generic bir yapı kullanıyoruz
    // Gerçek implementation'da context'e göre ayarlanacak
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: _themeMode == AppThemeMode.dark 
            ? Brightness.light 
            : Brightness.dark,
        systemNavigationBarColor: _themeMode == AppThemeMode.dark 
            ? const Color(0xFF0F172A) 
            : const Color(0xFFF8FAFC),
        systemNavigationBarIconBrightness: _themeMode == AppThemeMode.dark 
            ? Brightness.light 
            : Brightness.dark,
      ),
    );
  }
  
  /// Context'li sistem UI güncelleme
  void updateSystemUIWithContext(BuildContext context) {
    final isDark = isDarkMode(context);
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: isDark 
            ? const Color(0xFF0F172A) 
            : const Color(0xFFF8FAFC),
        systemNavigationBarIconBrightness: isDark 
            ? Brightness.light 
            : Brightness.dark,
      ),
    );
  }
  
  /// Tema modunu toggle et (light <-> dark)
  Future<void> toggleTheme() async {
    switch (_themeMode) {
      case AppThemeMode.light:
        await setThemeMode(AppThemeMode.dark);
        break;
      case AppThemeMode.dark:
        await setThemeMode(AppThemeMode.light);
        break;
      case AppThemeMode.system:
        // System modundayken light'a geçiş yap
        await setThemeMode(AppThemeMode.light);
        break;
    }
  }
  
  /// Tüm tema modlarını listele
  List<AppThemeMode> get availableThemes => AppThemeMode.values;
  
  /// Tema değişim animasyonu için callback
  void Function()? onThemeChanged;
  
  /// Tema değişimini animate et
  Future<void> animateThemeChange(AppThemeMode newMode) async {
    onThemeChanged?.call();
    await setThemeMode(newMode);
  }
}

/// Tema provider'ı kolay kullanım için extension
extension ThemeProviderExtension on BuildContext {
  /// Tema provider'ı global olarak erişim için
  static ThemeProvider? _instance;
  
  /// Global tema provider instance'ı
  static ThemeProvider get instance => _instance ??= ThemeProvider();
  
  /// Tema provider'ı al
  ThemeProvider get themeProvider => instance;
  
  /// Mevcut tema dark mı kontrol et
  bool get isDarkMode => instance.isDarkMode(this);
  
  /// Mevcut tema modunu al
  AppThemeMode get currentTheme => instance.themeMode;
} 