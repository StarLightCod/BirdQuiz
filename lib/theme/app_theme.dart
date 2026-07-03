import 'package:flutter/material.dart';

class AppTheme {
  // ДИНАМИЧЕСКИЕ ЦВЕТА (не const!)
  static Color bg0        = const Color(0xFF0E1511);
  static Color bg1        = const Color(0xFF141C18);
  static Color bg2        = const Color(0xFF1C2820);
  static Color bg3        = const Color(0xFF243028);
  static Color cardBorder = const Color(0xFF2E3D34);
  static Color divider    = const Color(0xFF263020);

  static Color accent     = const Color(0xFF6EBF8B);
  static Color accentDim  = const Color(0xFF3D7A55);
  static Color amber      = const Color(0xFFE8A838);
  static Color coral      = const Color(0xFFE86038);
  static Color sky        = const Color(0xFF5BA8D4);
  static Color purple     = const Color(0xFFB06CF0);

  static Color textPrimary   = const Color(0xFFDCEAE0);
  static Color textSecondary = const Color(0xFF8FAF97);
  static Color textMuted     = const Color(0xFF556B5C);

  // Светлая палитра
  static Color lightBg0      = const Color(0xFFF5F7F5);
  static Color lightBg1      = const Color(0xFFE8ECE8);
  static Color lightBg2      = const Color(0xFFFFFFFF);
  static Color lightBg3      = const Color(0xFFD8DCD8);
  static Color lightBorder   = const Color(0xFFC0C8C0);
  static Color lightDivider  = const Color(0xFFD0D8D0);

  static Color lightTextPrimary   = const Color(0xFF1A2520);
  static Color lightTextSecondary = const Color(0xFF4A5A50);
  static Color lightTextMuted     = const Color(0xFF8A9A90);

  // Градиенты (не const)
  static LinearGradient get bgGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [bg0, bg1],
  );

  static LinearGradient get lightBgGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [lightBg0, lightBg1],
  );

  static LinearGradient get accentGradient => LinearGradient(
    colors: [accentDim, accent],
  );

  static LinearGradient get skyGradient => LinearGradient(
    colors: [const Color(0xFF2A5580), sky],
  );

  static LinearGradient get amberGradient => LinearGradient(
    colors: [const Color(0xFF6B3A00), amber],
  );

  static LinearGradient get purpleGradient => LinearGradient(
    colors: [const Color(0xFF4A2A70), purple],
  );

  static LinearGradient get coralGradient => LinearGradient(
    colors: [const Color(0xFF8A2A18), coral],
  );

  // Метод обновления цветов из ThemeService
  static void updateFromService(dynamic themeService) {
    accent = themeService.primaryColor;
    accentDim = themeService.secondaryColor;
    amber = themeService.accentColor;
    bg0 = themeService.bgColor0;
    bg1 = themeService.bgColor1;
    bg2 = themeService.bgColor2;
    bg3 = _lightenColor(bg2, 1.15);
    cardBorder = _lightenColor(bg2, 1.3);
    divider = _lightenColor(bg1, 1.2);
  }

  static Color _lightenColor(Color color, double factor) {
    final r = (color.red * factor).round().clamp(0, 255);
    final g = (color.green * factor).round().clamp(0, 255);
    final b = (color.blue * factor).round().clamp(0, 255);
    return Color.fromARGB(color.alpha, r, g, b);
  }

  // Тёмная тема
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bg0,
      colorScheme: ColorScheme.dark(
        surface: bg1,
        primary: accent,
        secondary: amber,
        error: coral,
        onSurface: textPrimary,
        onPrimary: bg0,
      ),
      cardTheme: CardThemeData(
        color: bg2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: cardBorder, width: 1),
        ),
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: bg0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: accent),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: bg2,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: accent, width: 1.5),
        ),
        hintStyle: TextStyle(color: textMuted),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return accent;
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(bg0),
        side: BorderSide(color: cardBorder, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: textPrimary),
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: accent,
        inactiveTrackColor: bg3,
        thumbColor: accent,
        overlayColor: accent.withOpacity(0.2),
      ),
    );
  }

  // Светлая тема
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightBg0,
      colorScheme: ColorScheme.light(
        surface: lightBg2,
        primary: accent,
        secondary: amber,
        error: coral,
        onSurface: lightTextPrimary,
        onPrimary: Colors.white,
      ),
      cardTheme: CardThemeData(
        color: lightBg2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: lightBorder, width: 1),
        ),
        elevation: 1,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: accent),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightBg2,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: accent, width: 1.5),
        ),
        hintStyle: TextStyle(color: lightTextMuted),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return accent;
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(Colors.white),
        side: BorderSide(color: lightBorder, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: lightTextPrimary),
        titleTextStyle: TextStyle(
          color: lightTextPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: accent,
        inactiveTrackColor: lightBg3,
        thumbColor: accent,
        overlayColor: accent.withOpacity(0.2),
      ),
    );
  }
}

// Текстовые стили (не const)
class AppText {
  static TextStyle get hero => TextStyle(
    color: AppTheme.textPrimary,
    fontSize: 42,
    fontWeight: FontWeight.w800,
    letterSpacing: -1,
    height: 1.1,
  );

  static TextStyle get h1 => TextStyle(
    color: AppTheme.textPrimary,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
  );

  static TextStyle get h2 => TextStyle(
    color: AppTheme.textPrimary,
    fontSize: 22,
    fontWeight: FontWeight.w600,
  );

  static TextStyle get h3 => TextStyle(
    color: AppTheme.textPrimary,
    fontSize: 17,
    fontWeight: FontWeight.w600,
  );

  static TextStyle get body => TextStyle(
    color: AppTheme.textPrimary,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static TextStyle get small => TextStyle(
    color: AppTheme.textSecondary,
    fontSize: 13,
    fontWeight: FontWeight.w400,
  );

  static TextStyle get label => TextStyle(
    color: AppTheme.textMuted,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.2,
  );
}