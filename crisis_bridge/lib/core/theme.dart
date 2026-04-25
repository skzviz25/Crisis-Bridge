import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData dark() {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF0A0F0A),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF00FF88),
        secondary: Color(0xFF00CC66),
        error: Color(0xFFFF4444),
        surface: Color(0xFF111811),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF0A0F0A),
        foregroundColor: Color(0xFF00FF88),
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: Color(0xFF00FF88),
          fontSize: 16,
          fontWeight: FontWeight.bold,
          letterSpacing: 2,
          fontFamily: 'monospace',
        ),
      ),
      cardTheme: const CardThemeData(
        color: Color(0xFF111811),
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: Color(0xFF003322)),
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF00FF88),
          foregroundColor: Colors.black,
          textStyle: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          minimumSize: const Size.fromHeight(48),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF00FF88),
          side: const BorderSide(color: Color(0xFF00FF88)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          minimumSize: const Size.fromHeight(48),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF0D150D),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: Color(0xFF003322)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: Color(0xFF003322)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: Color(0xFF00FF88)),
        ),
        labelStyle: const TextStyle(color: Color(0xFF00AA66)),
        hintStyle: const TextStyle(color: Color(0xFF335544)),
      ),
      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: Color(0xFFCCFFDD), fontFamily: 'monospace'),
        bodySmall: TextStyle(color: Color(0xFF88BBAA), fontFamily: 'monospace'),
        titleLarge: TextStyle(color: Color(0xFF00FF88), fontFamily: 'monospace', fontWeight: FontWeight.bold),
        labelLarge: TextStyle(color: Color(0xFF00FF88), fontFamily: 'monospace'),
      ),
    );
  }
}