import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final themeProvider = NotifierProvider<ThemeNotifier, ThemeData>(() {
  return ThemeNotifier();
});

class ThemeNotifier extends Notifier<ThemeData> {
  @override
  ThemeData build() => _defaultTheme;

  // Modern Violet/Rose App Theme
  static final ThemeData _defaultTheme = ThemeData(
    primaryColor: const Color(0xFF8B5CF6), // Violet
    scaffoldBackgroundColor: const Color(0xFFFAFAFA),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.black87),
      titleTextStyle: TextStyle(
        color: Colors.black87,
        fontSize: 20,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF8B5CF6),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(vertical: 16),
        elevation: 0,
      ),
    ),
    colorScheme: ColorScheme.fromSwatch().copyWith(
      secondary: const Color(0xFFF43F5E), // Rose Accent
      primary: const Color(0xFF8B5CF6),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: Color(0xFF8B5CF6),
      unselectedItemColor: Color(0xFFB0BEC5),
      showUnselectedLabels: true,
      elevation: 16,
      type: BottomNavigationBarType.fixed,
    ),
    fontFamily: 'Inter', // Assuming Google Fonts fallback visually
  );

  static final ThemeData _darkTheme = ThemeData.dark().copyWith(
    primaryColor: const Color(0xFF8B5CF6),
    scaffoldBackgroundColor: const Color(0xFF121212),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1E1E1E),
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF8B5CF6),
      secondary: Color(0xFFF43F5E),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF8B5CF6),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF1E1E1E),
      selectedItemColor: Color(0xFF8B5CF6),
      unselectedItemColor: Colors.white54,
      showUnselectedLabels: true,
      elevation: 16,
      type: BottomNavigationBarType.fixed,
    ),
  );

  void setLightMode() {
    state = _defaultTheme;
  }

  void setDarkMode() {
    state = _darkTheme;
  }

  void setCustomTheme(Color primary, Color secondary, bool isDark) {
    if (isDark) {
      state = _darkTheme.copyWith(
        primaryColor: primary,
        colorScheme: _darkTheme.colorScheme.copyWith(
          primary: primary,
          secondary: secondary,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      );
    } else {
      state = _defaultTheme.copyWith(
        primaryColor: primary,
        colorScheme: _defaultTheme.colorScheme.copyWith(
          primary: primary,
          secondary: secondary,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      );
    }
  }
}
