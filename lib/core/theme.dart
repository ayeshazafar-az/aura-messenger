import 'package:flutter/material.dart';

class AppTheme {
  static final ThemeData modernTheme = ThemeData.light().copyWith(
    scaffoldBackgroundColor: const Color(0xFFF4F7F6), // Smooth light gray-blue
    primaryColor: const Color(0xFF0084FF),
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF0084FF),
      secondary: Color(0xFFFF2D55),
      surface: Colors.white,
      onSurface: Colors.black87,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black87,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        color: Colors.black87,
        letterSpacing: -0.5,
      ),
      iconTheme: IconThemeData(color: Color(0xFF0084FF)),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: Color(0xFF0084FF),
      unselectedItemColor: Color(0xFFB0BEC5),
      showUnselectedLabels: true,
      elevation: 16,
      type: BottomNavigationBarType.fixed,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF9FAFB),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF0084FF), width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      labelStyle: const TextStyle(color: Colors.black54),
      prefixIconColor: const Color(0xFF0084FF),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        enableFeedback: true,
        backgroundColor: const Color(0xFF0084FF),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(vertical: 18),
        elevation: 6,
        shadowColor: const Color(0xFF0084FF),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    ),
  );
}
