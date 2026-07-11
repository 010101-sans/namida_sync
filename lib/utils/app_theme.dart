import 'package:flutter/material.dart';

class AppColors {
  // Dark Theme
  static const Color darkBackground = Color(0xFF0A0A0A);
  static const Color darkSurface = Color(0xFF1C1C1E);
  static const Color darkCard = Color(0xFF2C2C2E);
  static const Color darkText = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFF8E8E93);
  static const Color darkTextTertiary = Color(0xFF48484A);
  static const Color accentPurple = Color(0xFF6366F1);
  static const Color accentPurpleLight = Color(0xFF8B5CF6);
  static const Color successGreen = Color(0xFF34D399);
  static const Color warningOrange = Color(0xFFF59E0B);
  static const Color errorRed = Color(0xFFEF4444);

  // Light Theme
  static const Color lightBackground = Color(0xFFF8F7FA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFF3F0FF);
  static const Color lightText = Color(0xFF1C1C1E);
  static const Color lightTextSecondary = Color(0xFF6C6C70);
  static const Color lightTextTertiary = Color(0xFF8E8E93);
  static const Color accentIndigo = Color(0xFF6366F1);
  static const Color accentIndigoLight = Color(0xFF8B5CF6);
}

class AppTheme {
  // [1] Pitch black mode toggle (static for now, can be made dynamic)
  static bool pitchBlackMode = false;

  // [2] Returns a ThemeData matching Namida's advanced theming logic
  static ThemeData getAppTheme({
    Color seedColor = const Color(0xFF6366F1),
    bool isLight = true,
    bool lighterDialog = true,
  }) {
    final shouldUseAMOLED = !isLight && pitchBlackMode;
    final pitchBlack = shouldUseAMOLED ? const Color(0xFF000000) : null;
    final mainColorMultiplier = pitchBlack == null ? 0.8 : 0.1;
    final pitchGrey = pitchBlack == null ? const Color(0xFF232323) : const Color(0xFF141414);

    int getColorAlpha(int a) => (a * mainColorMultiplier).round();
    Color getMainColorWithAlpha(int a) => seedColor.withAlpha(getColorAlpha(a));

    final cardColor = Color.alphaBlend(getMainColorWithAlpha(35), isLight ? const Color(0xFFFFFFFF) : pitchGrey);

    const fontFallback = ['sans-serif', 'Roboto'];
    final brightness = isLight ? Brightness.light : Brightness.dark;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(seedColor: seedColor, brightness: brightness, contrastLevel: 0.05),
      fontFamily: 'LexendDeca',
      fontFamilyFallback: fontFallback,
      scaffoldBackgroundColor: pitchBlack ?? (isLight ? Color.alphaBlend(seedColor.withAlpha(60), Colors.white) : null),
      cardColor: cardColor,
      cardTheme: CardThemeData(
        elevation: 12.0,
        color: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.0)),
      ),
      popupMenuTheme: PopupMenuThemeData(
        surfaceTintColor: Colors.transparent,
        elevation: 12.0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
        color: isLight
            ? Color.alphaBlend(cardColor.withAlpha(180), Colors.white)
            : Color.alphaBlend(cardColor.withAlpha(180), Colors.black),
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        backgroundColor: pitchBlack ?? (isLight ? Color.alphaBlend(seedColor.withAlpha(25), Colors.white) : null),
        actionsIconTheme: IconThemeData(
          color: isLight ? const Color.fromARGB(200, 40, 40, 40) : const Color.fromARGB(200, 233, 233, 233),
        ),
      ),
      iconTheme: IconThemeData(
        color: isLight ? const Color.fromARGB(200, 40, 40, 40) : const Color.fromARGB(200, 233, 233, 233),
      ),
      shadowColor: isLight ? const Color.fromARGB(180, 100, 100, 100) : const Color.fromARGB(222, 10, 10, 10),
      dividerTheme: const DividerThemeData(thickness: 4, indent: 0.0, endIndent: 0.0),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0)),
          iconSize: const WidgetStatePropertyAll(21.0),
          backgroundColor: WidgetStatePropertyAll(
            isLight
                ? Color.alphaBlend(seedColor.withAlpha(30), Colors.white)
                : pitchBlack != null
                ? Color.alphaBlend(seedColor.withAlpha(60), pitchBlack)
                : null,
          ),
        ),
      ),
      textTheme: TextTheme(
        bodyMedium: const TextStyle(fontSize: 14.0, fontWeight: FontWeight.normal, fontFamilyFallback: fontFallback),
        bodySmall: const TextStyle(fontSize: 14.0, fontWeight: FontWeight.normal, fontFamilyFallback: fontFallback),
        titleSmall: const TextStyle(fontSize: 14.0, fontWeight: FontWeight.w600, fontFamilyFallback: fontFallback),
        titleLarge: const TextStyle(fontSize: 20.0, fontWeight: FontWeight.w600, fontFamilyFallback: fontFallback),
        displayLarge: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 17.0,
          color: isLight ? Colors.black.withAlpha(160) : Colors.white.withAlpha(210),
          fontFamilyFallback: fontFallback,
        ),
        displayMedium: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 15.0,
          color: isLight ? Colors.black.withAlpha(150) : Colors.white.withAlpha(180),
          fontFamilyFallback: fontFallback,
        ),
        displaySmall: TextStyle(
          fontWeight: FontWeight.w400,
          fontSize: 13.0,
          color: isLight ? Colors.black.withAlpha(120) : Colors.white.withAlpha(170),
          fontFamilyFallback: fontFallback,
        ),
        headlineMedium: const TextStyle(
          fontWeight: FontWeight.normal,
          fontSize: 14.0,
          fontFamilyFallback: fontFallback,
        ),
        headlineSmall: const TextStyle(fontWeight: FontWeight.normal, fontSize: 14.0, fontFamilyFallback: fontFallback),
      ),
    );
  }

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    fontFamily: 'LexendDeca',
    fontFamilyFallback: ['sans-serif', 'Roboto'],
    scaffoldBackgroundColor: AppColors.darkBackground,
    cardColor: AppColors.darkCard,
    primaryColor: AppColors.accentPurple,
    colorScheme: ColorScheme.dark(
      primary: AppColors.accentPurple,
      secondary: AppColors.accentPurpleLight,
      surface: AppColors.darkSurface,
      onSurface: AppColors.darkText,
      error: AppColors.errorRed,
      onError: AppColors.darkText,
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: AppColors.darkText,
        letterSpacing: -0.5,
      ),
      displayMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: AppColors.darkText,
        letterSpacing: -0.25,
      ),
      titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: AppColors.darkText, letterSpacing: 0),
      titleMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: AppColors.darkText, letterSpacing: 0.15),
      titleSmall: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: AppColors.darkTextSecondary,
        letterSpacing: 0.1,
      ),
      bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: AppColors.darkText, letterSpacing: 0.5),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: AppColors.darkTextSecondary,
        letterSpacing: 0.25,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        color: AppColors.darkTextTertiary,
        letterSpacing: 0.4,
      ),
    ),
    iconTheme: const IconThemeData(color: AppColors.darkText, size: 24),
    cardTheme: CardThemeData(
      color: AppColors.darkCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.1),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.accentPurple,
        foregroundColor: AppColors.darkText,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        elevation: 0,
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.1),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.accentPurple,
        side: const BorderSide(color: AppColors.accentPurple, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.1),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.accentPurple,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 0.1),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.darkSurface,
      foregroundColor: AppColors.darkText,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.darkText,
        letterSpacing: 0.15,
      ),
    ),
    dividerTheme: const DividerThemeData(color: AppColors.darkTextTertiary, thickness: 0.5, space: 1),
  );

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    fontFamily: 'LexendDeca',
    fontFamilyFallback: ['sans-serif', 'Roboto'],
    scaffoldBackgroundColor: AppColors.lightBackground,
    cardColor: AppColors.lightCard,
    primaryColor: AppColors.accentIndigo,
    colorScheme: ColorScheme.light(
      primary: AppColors.accentIndigo,
      secondary: AppColors.accentIndigoLight,
      surface: AppColors.lightSurface,
      onSurface: AppColors.lightText,
      error: AppColors.errorRed,
      onError: AppColors.lightText,
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: AppColors.lightText,
        letterSpacing: -0.5,
      ),
      displayMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: AppColors.lightText,
        letterSpacing: -0.25,
      ),
      titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: AppColors.lightText, letterSpacing: 0),
      titleMedium: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: AppColors.lightText,
        letterSpacing: 0.15,
      ),
      titleSmall: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: AppColors.lightTextSecondary,
        letterSpacing: 0.1,
      ),
      bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: AppColors.lightText, letterSpacing: 0.5),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: AppColors.lightTextSecondary,
        letterSpacing: 0.25,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        color: AppColors.lightTextTertiary,
        letterSpacing: 0.4,
      ),
    ),
    iconTheme: const IconThemeData(color: AppColors.accentIndigo, size: 24),
    cardTheme: CardThemeData(
      color: AppColors.lightCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: AppColors.accentIndigoLight.withValues(alpha: 0.13), width: 1.2),
      ),
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      elevation: 2,
      shadowColor: AppColors.accentIndigoLight.withValues(alpha: 0.08),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.accentIndigo,
        foregroundColor: AppColors.lightText,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        elevation: 0,
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.1),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.accentIndigo,
        side: const BorderSide(color: AppColors.accentIndigo, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.1),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.accentIndigo,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 0.1),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.lightSurface,
      foregroundColor: AppColors.lightText,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.lightText,
        letterSpacing: 0.15,
      ),
    ),
    dividerTheme: const DividerThemeData(color: AppColors.lightTextTertiary, thickness: 0.5, space: 1),
  );
}
