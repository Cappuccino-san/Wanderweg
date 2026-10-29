import 'package:flutter/material.dart';

class AppTheme {
  static bool isDark = true;

  // Base Light Palette (Outdoor sunlight-ready, high contrast)
  static const Color _lightInkBlack = Color(0xFF111418);
  static const Color _lightWarmCanvas = Color(0xFFF7F8FA);
  static const Color _lightCardSurface = Color(0xFFFFFFFF);
  static const Color _lightGermanGold = Color(0xFFC98A1B);
  static const Color _lightBerlinBrick = Color(0xFFB33927);
  static const Color _lightForestGreen = Color(0xFF1E5B3A);
  static const Color _lightTransitBlue = Color(0xFF1A5694);
  static const Color _lightMutedText = Color(0xFF555F6D);
  static const Color _lightBorderOutline = Color(0xFFDCE2E9);
  static const Color _lightWarningAmber = Color(0xFFB86200);

  // Base Dark Palette (Outdoor night-ready, low eye-strain, battery saving)
  static const Color _darkInkBlack = Color(0xFFF2F5F8);
  static const Color _darkWarmCanvas = Color(0xFF101418);
  static const Color _darkCardSurface = Color(0xFF192027);
  static const Color _darkGermanGold = Color(0xFFE5A62D);
  static const Color _darkBerlinBrick = Color(0xFFE05642);
  static const Color _darkForestGreen = Color(0xFF2EA568);
  static const Color _darkTransitBlue = Color(0xFF4C93E6);
  static const Color _darkMutedText = Color(0xFF9AA8B6);
  static const Color _darkBorderOutline = Color(0xFF2C3844);
  static const Color _darkWarningAmber = Color(0xFFF59E0B);

  // Dynamic getters based on active theme
  static Color get inkBlack => isDark ? _darkInkBlack : _lightInkBlack;
  static Color get warmCanvas => isDark ? _darkWarmCanvas : _lightWarmCanvas;
  static Color get cardSurface => isDark ? _darkCardSurface : _lightCardSurface;
  static Color get germanGold => isDark ? _darkGermanGold : _lightGermanGold;
  static Color get berlinBrick => isDark ? _darkBerlinBrick : _lightBerlinBrick;
  static Color get forestGreen => isDark ? _darkForestGreen : _lightForestGreen;
  static Color get transitBlue => isDark ? _darkTransitBlue : _lightTransitBlue;
  static Color get mutedText => isDark ? _darkMutedText : _lightMutedText;
  static Color get borderOutline => isDark ? _darkBorderOutline : _lightBorderOutline;
  static Color get warningAmber => isDark ? _darkWarningAmber : _lightWarningAmber;

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: _lightWarmCanvas,
      colorScheme: const ColorScheme.light(
        primary: _lightInkBlack,
        secondary: _lightForestGreen,
        tertiary: _lightBerlinBrick,
        surface: _lightCardSurface,
        onPrimary: Colors.white,
        onSurface: _lightInkBlack,
        outline: _lightBorderOutline,
      ),
      fontFamily: 'Segoe UI',
      appBarTheme: const AppBarTheme(
        backgroundColor: _lightCardSurface,
        foregroundColor: _lightInkBlack,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: _lightInkBlack,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: _lightCardSurface,
        selectedItemColor: _lightInkBlack,
        unselectedItemColor: _lightMutedText,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
        unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      cardTheme: CardThemeData(
        color: _lightCardSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: _lightBorderOutline, width: 1.2),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _lightInkBlack,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(54),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.1,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _lightInkBlack,
          side: const BorderSide(color: _lightInkBlack, width: 1.5),
          minimumSize: const Size(64, 44),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: _darkWarmCanvas,
      colorScheme: const ColorScheme.dark(
        primary: _darkInkBlack,
        secondary: _darkForestGreen,
        tertiary: _darkBerlinBrick,
        surface: _darkCardSurface,
        onPrimary: _darkWarmCanvas,
        onSurface: _darkInkBlack,
        outline: _darkBorderOutline,
      ),
      fontFamily: 'Segoe UI',
      appBarTheme: const AppBarTheme(
        backgroundColor: _darkCardSurface,
        foregroundColor: _darkInkBlack,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: _darkInkBlack,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: _darkCardSurface,
        selectedItemColor: _darkInkBlack,
        unselectedItemColor: _darkMutedText,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
        unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      cardTheme: CardThemeData(
        color: _darkCardSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: _darkBorderOutline, width: 1.2),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _darkInkBlack,
          foregroundColor: _darkWarmCanvas,
          minimumSize: const Size.fromHeight(54),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.1,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _darkInkBlack,
          side: const BorderSide(color: _darkInkBlack, width: 1.5),
          minimumSize: const Size(64, 44),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
