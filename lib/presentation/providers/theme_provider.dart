import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';
import 'package:flutter/services.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  String _fontFamily = 'Default';
  bool _isInitialized = false;

  bool get isDarkMode => _isDarkMode;
  String get fontFamily => _fontFamily;
  bool get isInitialized => _isInitialized;

  ThemeProvider() {
    _loadThemeFromPrefs();
  }

  // Load theme preference from SharedPreferences
  Future<void> _loadThemeFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isDarkMode = prefs.getBool(AppConstants.isDarkModeKey) ?? false;
      _fontFamily = prefs.getString('selected_font_family') ?? 'Default';
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      print('Error loading theme preference: $e');
      _isInitialized = true;
      notifyListeners();
    }
  }

  // Toggle theme
  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
    await _saveThemeToPrefs();
  }

  // Set theme
  Future<void> setTheme(bool isDark) async {
    if (_isDarkMode != isDark) {
      _isDarkMode = isDark;
      notifyListeners();
      await _saveThemeToPrefs();
    }
  }

  // Save theme preference to SharedPreferences
  Future<void> _saveThemeToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AppConstants.isDarkModeKey, _isDarkMode);
    } catch (e) {
      print('Error saving theme preference: $e');
    }
  }

  // Get theme mode
  ThemeMode get themeMode {
    return _isDarkMode ? ThemeMode.dark : ThemeMode.light;
  }

  // Check if theme is dark
  bool get isLightMode => !_isDarkMode;

  // Reset theme to default (light)
  Future<void> resetTheme() async {
    _isDarkMode = false;
    notifyListeners();
    await _saveThemeToPrefs();
  }

  // Set font family
  Future<void> setFontFamily(String family, {String? assetPath}) async {
    if (_fontFamily == family) return;

    // Dinamik olarak fontu yükle (Default harici)
    if (family != 'Default' && assetPath != null && assetPath.isNotEmpty) {
      try {
        final loader = FontLoader(family)..addFont(rootBundle.load(assetPath));
        await loader.load();
        print('ThemeProvider: Font yüklendi - $family');
      } catch (e) {
        print('ThemeProvider: Font yükleme hatası ($family): $e');
      }
    }

    _fontFamily = family;
    print('ThemeProvider: Font ayarlandı - $_fontFamily');
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('selected_font_family', _fontFamily);
      print('ThemeProvider: Font kaydedildi - $_fontFamily');
    } catch (e) {
      print('ThemeProvider: Font kaydetme hatası: $e');
    }
  }

  // Get current font family for TextStyle
  String? get currentFontFamily {
    return _fontFamily == 'Default' ? null : _fontFamily;
  }

  // Set Google Font
  Future<void> setGoogleFont(String fontName) async {
    if (_fontFamily == fontName) return;

    _fontFamily = fontName;
    print('ThemeProvider: Google Font ayarlandı - $_fontFamily');
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('selected_font_family', _fontFamily);
      await prefs.setString('font_type', 'google'); // Fontu google olarak işaretle
      print('ThemeProvider: Google Font kaydedildi - $_fontFamily');
    } catch (e) {
      print('ThemeProvider: Google Font kaydetme hatası: $e');
    }
  }

  // Get font type (google, asset, system)
  Future<String> getFontType() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('font_type') ?? 'system';
    } catch (e) {
      return 'system';
    }
  }
} 