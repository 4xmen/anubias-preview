import 'package:flutter/material.dart';

class AppDesignConfig extends ChangeNotifier {
  Color _mainColor;
  bool _isRTL;
  bool _isDark;
  String _language;
  String _country;

  AppDesignConfig({
    this._mainColor = Colors.blue,
    this._isRTL = false,
    this._isDark = false,
    this._language = 'en',
    this._country = 'US',
  });

  // ─────────────────────────────
  // Getters
  // ─────────────────────────────

  Color get mainColor => _mainColor;

  bool get isRTL => _isRTL;

  bool get isDark => _isDark;

  String get language => _language;

  String get country => _country;

  // ─────────────────────────────
  // Setters
  // ─────────────────────────────

  void setMainColor(Color color) {
    _mainColor = color;
    notifyListeners();
  }

  void setDarkMode(bool value) {
    _isDark = value;
    notifyListeners();
  }

  void toggleDarkMode() {
    _isDark = !_isDark;
    notifyListeners();
  }

  void setRTL(bool value) {
    _isRTL = value;
    notifyListeners();
  }

  void toggleRTL() {
    _isRTL = !_isRTL;
    notifyListeners();
  }

  void setLanguage(String value) {
    _language = value;
    notifyListeners();
  }

  void setCountry(String value) {
    _country = value;
    notifyListeners();
  }

  // ─────────────────────────────
  // Theme
  // ─────────────────────────────

  ThemeData get theme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _mainColor,
      brightness: _isDark ? Brightness.dark : Brightness.light,
    );

    return ThemeData(
      // old flutter
      useMaterial3: false,

      brightness: _isDark ? Brightness.dark : Brightness.light,

      primaryColor: _mainColor,

      colorScheme: colorScheme,

      scaffoldBackgroundColor: _isDark ? const Color(0xFF121212) : Colors.white,

      appBarTheme: AppBarTheme(
        backgroundColor: _mainColor,
        foregroundColor: Colors.white,
        elevation: 4,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _mainColor,
          foregroundColor: Colors.white,
        ),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: _mainColor,
        foregroundColor: Colors.white,
      ),

      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.all(_mainColor),
      ),

      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.all(_mainColor),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.all(_mainColor),
      ),

      inputDecorationTheme: InputDecorationTheme(
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: _mainColor, width: 2),
        ),
      ),
    );
  }

  // ─────────────────────────────
  // Direction
  // ─────────────────────────────

  TextDirection get textDirection =>
      _isRTL ? TextDirection.rtl : TextDirection.ltr;
}