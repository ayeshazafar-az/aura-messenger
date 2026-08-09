import 'package:flutter/material.dart';

class AppTheme {
  static final ThemeData darkTheme = ThemeData.dark().copyWith(
    scaffoldBackgroundColor: const Color(0xFF0F172A),
    primaryColor: const Color(0xFF3B82F6),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF3B82F6),
      secondary: Color(0xFF8B5CF6),
      surface: Color(0xFF1E293B),
      onSurface: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF0F172A),
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF1E293B),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        enableFeedback: true,
        backgroundColor: const Color(0xFF3B82F6),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(vertical: 16),
        elevation: 0,
      ),
    ),
  );

  static final ThemeData lightTheme = ThemeData.light().copyWith(
    scaffoldBackgroundColor: const Color(0xFFF1F5F9), // Slate 100
    primaryColor: const Color(0xFF3B82F6), // Blue 500
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF3B82F6),
      secondary: Color(0xFF8B5CF6),
      surface: Colors.white,
      onSurface: Color(0xFF0F172A),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Color(0xFF0F172A),
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Color(0xFF0F172A),
      ),
      iconTheme: IconThemeData(color: Color(0xFF0F172A)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        enableFeedback: true,
        backgroundColor: const Color(0xFF3B82F6),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(vertical: 16),
        elevation: 0,
      ),
    ),
  );
}
