// lib/theme/app_theme.dart
import 'package:flutter/material.dart';

class AppTheme {
  // Colors
  static const Color primaryColor = Color(0xFF2D5BFF);
  static const Color secondaryColor = Color(0xFF91A3FF);
  static const Color errorColor = Color(0xFFE53935);
  static const Color successColor = Color(0xFF43A047);
  static const Color warningColor = Color(0xFFFFA000);
  static const Color backgroundColor = Color(0xFFF5F7FA);
  static const Color cardColor = Colors.white;
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color dividerColor = Color(0xFFEEEEEE);

  // Typography
  static const TextStyle headingLarge = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: textPrimary,
    height: 1.2,
  );

  static const TextStyle headingMedium = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: textPrimary,
    height: 1.2,
  );

  static const TextStyle headingSmall = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    height: 1.2,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: textPrimary,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: textPrimary,
    height: 1.5,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: textSecondary,
    height: 1.5,
  );

  static const TextStyle buttonText = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    height: 1.2,
  );

  // Spacing
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXL = 32.0;
  static const double spacingXXL = 48.0;

  // Radius
  static const double radiusS = 4.0;
  static const double radiusM = 8.0;
  static const double radiusL = 12.0;
  static const double radiusXL = 16.0;
  static const double radiusXXL = 24.0;

  // Shadows
  static List<BoxShadow> lightShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.05),
      blurRadius: 6,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> mediumShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.1),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];

  // Theme Data
  static ThemeData themeData = ThemeData(
    primaryColor: primaryColor,
    colorScheme: ColorScheme.light(
      primary: primaryColor,
      secondary: secondaryColor,
      error: errorColor,
      background: backgroundColor,
    ),
    scaffoldBackgroundColor: backgroundColor,
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        textStyle: buttonText,
        padding: const EdgeInsets.symmetric(
          horizontal: spacingL,
          vertical: spacingM,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusM),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryColor,
        textStyle: buttonText.copyWith(color: primaryColor),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusM),
        borderSide: BorderSide(color: dividerColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusM),
        borderSide: BorderSide(color: dividerColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusM),
        borderSide: BorderSide(color: primaryColor),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusM),
        borderSide: BorderSide(color: errorColor),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: spacingM,
        vertical: spacingM,
      ),
    ),
    cardTheme: CardTheme(
      color: cardColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusL),
      ),
    ),
  );
}