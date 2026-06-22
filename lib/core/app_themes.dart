import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppThemes {
  // Minimalistic Mode (Light)
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

  // Android 17 Sapphire Dark Mode
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF090D16), // Ultra deep sapphire black
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF3B82F6),
        brightness: Brightness.dark,
        primary: const Color(0xFF3B82F6), // Sapphire blue
        secondary: const Color(0xFF818CF8), // Indigo glow
        surface: const Color(0xFF131B2E), // Deep navy card surface
        onPrimary: Colors.white,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
        displayLarge: GoogleFonts.inter(fontWeight: FontWeight.w700, color: Colors.white),
        titleLarge: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.white),
        bodyLarge: GoogleFonts.inter(fontWeight: FontWeight.normal, color: Colors.white70),
        bodyMedium: GoogleFonts.inter(fontWeight: FontWeight.normal, color: Colors.white60),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
      ),
    );
  }
}

enum ThemeModeType { minimalistic, dark }

class ThemeProvider with ChangeNotifier {
  ThemeModeType _themeMode;

  ThemeModeType get themeMode => _themeMode;

  ThemeProvider({SharedPreferences? prefs}) : _themeMode = ThemeModeType.minimalistic {
    if (prefs != null) {
      final index = prefs.getInt('theme_mode');
      if (index != null && index < ThemeModeType.values.length) {
        _themeMode = ThemeModeType.values[index];
      }
    } else {
      _loadTheme();
    }
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final index = prefs.getInt('theme_mode');
    if (index != null && index < ThemeModeType.values.length) {
      final loadedMode = ThemeModeType.values[index];
      if (_themeMode != loadedMode) {
        _themeMode = loadedMode;
        notifyListeners();
      }
    }
  }

  Future<void> _saveTheme(ThemeModeType mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('theme_mode', mode.index);
  }

  ThemeData get currentTheme {
    switch (_themeMode) {
      case ThemeModeType.dark:
        return AppThemes.darkTheme;
      case ThemeModeType.minimalistic:
        return AppThemes.minimalisticTheme;
    }
  }

  void toggleTheme() {
    // Header button directly toggles between Light (Minimalistic) and Dark (Sapphire)
    if (_themeMode == ThemeModeType.dark) {
      _themeMode = ThemeModeType.minimalistic;
    } else {
      _themeMode = ThemeModeType.dark;
    }
    _saveTheme(_themeMode);
    notifyListeners();
  }

  void setTheme(ThemeModeType mode) {
    _themeMode = mode;
    _saveTheme(mode);
    notifyListeners();
  }
}
