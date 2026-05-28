import 'package:flutter/material.dart';

class AppConstants {
  static const String appName = '墨匣';
  static const String dbName = 'mo_xia.db';
}

const _seedColor = Color(0xFF6750A4);

class AppTheme {
  static ThemeData get lightTheme => _buildTheme(Brightness.light);
  static ThemeData get darkTheme => _buildTheme(Brightness.dark);

  static ThemeData _buildTheme(Brightness brightness) {
    return ThemeData(
      useMaterial3: true,
      colorSchemeSeed: _seedColor,
      brightness: brightness,
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        scrolledUnderElevation: 1,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
              color: brightness == Brightness.light
                  ? const Color(0xFFE0E0E0)
                  : const Color(0xFF3A3A3A)),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        elevation: 2,
      ),
    );
  }

  // KaiTi typography
  static const String _kaitiFamily = 'KaiTi';
  static const List<String> _kaitiFallback = [
    'STKaiti',
    '楷体',
    'Noto Serif CJK SC',
    'serif',
  ];

  static TextStyle get editorContentStyle => const TextStyle(
        fontFamily: _kaitiFamily,
        fontFamilyFallback: _kaitiFallback,
        fontSize: 18,
        height: 1.8,
        letterSpacing: 0.5,
      );

  static TextStyle get editorTitleStyle => const TextStyle(
        fontFamily: _kaitiFamily,
        fontFamilyFallback: _kaitiFallback,
        fontSize: 22,
        fontWeight: FontWeight.w600,
        height: 1.4,
      );
}
