import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppThemes {
  // Minimalistic Mode
  static ThemeData get minimalisticTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFFBFBFB),
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.black,
        primary: Colors.black,
        secondary: Colors.grey[800]!,
        surface: const Color(0xFFFBFBFB),
      ),
      textTheme: GoogleFonts.interTextTheme().copyWith(
        displayLarge: GoogleFonts.inter(fontWeight: FontWeight.w700, color: Colors.black),
        titleLarge: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.black),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(color: Colors.black, fontSize: 24, fontWeight: FontWeight.bold),
      ),
    );
  }

  // Liquid Glass Mode
  static ThemeData get liquidGlassTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: Colors.transparent,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF3B82F6),
        brightness: Brightness.light,
        primary: const Color(0xFF3B82F6), // Soft blue
        secondary: const Color(0xFF818CF8), // Indigo
        surface: Colors.white.withAlpha(102), // 0.4 white glass
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme).copyWith(
        displayLarge: GoogleFonts.inter(fontWeight: FontWeight.w700, color: const Color(0xFF1E293B)),
        titleLarge: GoogleFonts.inter(fontWeight: FontWeight.w600, color: const Color(0xFF1E293B)),
        bodyLarge: GoogleFonts.inter(fontWeight: FontWeight.normal, color: const Color(0xFF1E293B)),
        bodyMedium: GoogleFonts.inter(fontWeight: FontWeight.normal, color: const Color(0xFF64748B)),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(color: Color(0xFF1E293B), fontSize: 24, fontWeight: FontWeight.bold),
      ),
    );
  }
}

enum ThemeModeType { minimalistic, liquidGlass }

class ThemeProvider with ChangeNotifier {
  ThemeModeType _themeMode = ThemeModeType.minimalistic;

  ThemeModeType get themeMode => _themeMode;

  ThemeData get currentTheme => _themeMode == ThemeModeType.minimalistic 
      ? AppThemes.minimalisticTheme 
      : AppThemes.liquidGlassTheme;

  void toggleTheme() {
    _themeMode = _themeMode == ThemeModeType.minimalistic 
        ? ThemeModeType.liquidGlass 
        : ThemeModeType.minimalistic;
    notifyListeners();
  }

  void setTheme(ThemeModeType mode) {
    _themeMode = mode;
    notifyListeners();
  }
}
