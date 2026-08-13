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
    useMaterial3: false,
    primaryColor: const Color(0xFF8B5CF6),
    scaffoldBackgroundColor: const Color(0xFFFAFAFA),
    cardColor: const Color(0xFFFFFFFF),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black87,
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.black87),
      actionsIconTheme: IconThemeData(color: Colors.black87),
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
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: const Color(0xFF8B5CF6)),
    ),
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF8B5CF6),
      secondary: Color(0xFFF43F5E),
      surface: Color(0xFFFAFAFA),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: Color(0xFF8B5CF6),
      unselectedItemColor: Color(0xFFB0BEC5),
      showUnselectedLabels: true,
      elevation: 16,
      type: BottomNavigationBarType.fixed,
    ),
    textTheme: const TextTheme(bodySmall: TextStyle(color: Colors.black54)),
    fontFamily: 'Inter', dialogTheme: DialogThemeData(backgroundColor: const Color(0xFFFFFFFF)),
  );

  static final ThemeData _darkTheme = ThemeData.dark().copyWith(
    primaryColor: const Color(0xFF8B5CF6),
    scaffoldBackgroundColor: const Color(0xFF121212),
    cardColor: const Color(0xFF1E1E1E),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1E1E1E),
      foregroundColor: Colors.white,
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.white),
      actionsIconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF8B5CF6),
      secondary: Color(0xFFF43F5E),
      surface: Color(0xFF1E1E1E),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF8B5CF6),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: const Color(0xFF8B5CF6)),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF1E1E1E),
      selectedItemColor: Color(0xFF8B5CF6),
      unselectedItemColor: Colors.white54,
      showUnselectedLabels: true,
      elevation: 16,
      type: BottomNavigationBarType.fixed,
    ),
    textTheme: const TextTheme(bodySmall: TextStyle(color: Colors.white54)), dialogTheme: DialogThemeData(backgroundColor: const Color(0xFF1E1E1E)),
  );

  void setLightMode() {
    state = _defaultTheme;
  }

  void setDarkMode() {
    state = _darkTheme;
  }

  void setCustomTheme(Color primary, Color secondary, bool isDark) {
    final base = isDark ? _darkTheme : _defaultTheme;
    state = base.copyWith(
      primaryColor: primary,
      colorScheme: base.colorScheme.copyWith(
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
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: primary),
      ),
      bottomNavigationBarTheme: base.bottomNavigationBarTheme.copyWith(
        selectedItemColor: primary,
      ),
    );
  }
}
