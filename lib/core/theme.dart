import 'package:flutter/material.dart';

class AppTheme {
  static final ThemeData modernTheme = ThemeData.light().copyWith(
    scaffoldBackgroundColor: const Color(
      0xFFF2F2F7,
    ), // Soft iOS-style background
    primaryColor: const Color(0xFF007AFF), // Vibrant iOS message blue
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF007AFF),
      secondary: Color(0xFF5856D6),
      surface: Colors.white,
      onSurface: Colors.black,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Colors.black,
        letterSpacing: -0.5,
      ),
      iconTheme: IconThemeData(color: Color(0xFF007AFF)),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: Color(0xFF007AFF),
      unselectedItemColor: Color(0xFF999999),
      showUnselectedLabels: true,
      elevation: 8,
      type: BottomNavigationBarType.fixed,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE5E5EA), width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE5E5EA), width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF007AFF), width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      labelStyle: const TextStyle(color: Colors.black54),
      prefixIconColor: const Color(0xFF007AFF),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        enableFeedback: true,
        backgroundColor: const Color(0xFF007AFF),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(vertical: 16),
        elevation: 0,
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    ),
  );
}
