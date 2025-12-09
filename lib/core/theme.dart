import 'package:flutter/material.dart';
import 'widgets/app_text_style.dart';

class AppColors {
  // Light Theme Colors
  static const Color lightPrimary = Color(0xFF00BCD4); // Cyan
  static const Color lightSecondary = Color(0xFF4CAF50); // Green
  static const Color lightAccent = Color(0xFFFF9800); // Orange
  static const Color lightError = Color(0xFFE53935); // Red

  // Dark Theme Colors
  static const Color darkPrimary = Color(0xFF26C6DA); // Light Cyan
  static const Color darkSecondary = Color(0xFF66BB6A); // Light Green
  static const Color darkAccent = Color(0xFFFFB74D); // Light Orange
  static const Color darkError = Color(0xFFEF5350); // Light Red

  // Neutral Colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color lightGrey = Color(0xFFF5F5F5);
  static const Color darkGrey = Color(0xFF121212);
  static const Color mediumGrey = Color(0xFF757575);
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: AppColors.lightPrimary,
        secondary: AppColors.lightSecondary,
        tertiary: AppColors.lightAccent,
        error: AppColors.lightError,
        surface: AppColors.white,
        onPrimary: AppColors.white,
        onSecondary: AppColors.white,
        onTertiary: AppColors.white,
        onError: AppColors.white,
        onSurface: AppColors.black,
      ),
      scaffoldBackgroundColor: AppColors.lightGrey,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.black,
        titleTextStyle: TextStyle(
          color: AppColors.black,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.white,
        elevation: 2,
        shadowColor: AppColors.black.withOpacity(0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.lightPrimary,
        foregroundColor: AppColors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.lightPrimary,
          foregroundColor: AppColors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.lightPrimary),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.lightPrimary;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(AppColors.white),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.mediumGrey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.lightPrimary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      textTheme: TextTheme(
        displayLarge: AppTextStyles.light.headline1,
        displayMedium: AppTextStyles.light.headline2,
        displaySmall: AppTextStyles.light.headline3,
        headlineMedium: AppTextStyles.light.headline2,
        headlineSmall: AppTextStyles.light.headline3,
        titleLarge: AppTextStyles.light.cardTitle,
        titleMedium: AppTextStyles.light.listTitle,
        titleSmall: AppTextStyles.light.subtitle2,
        bodyLarge: AppTextStyles.light.body1,
        bodyMedium: AppTextStyles.light.body2,
        bodySmall: AppTextStyles.light.caption,
        labelLarge: AppTextStyles.light.button,
        labelMedium: AppTextStyles.light.label,
        labelSmall: AppTextStyles.light.overline,
      ),
      iconTheme: const IconThemeData(color: AppColors.mediumGrey),
      primaryIconTheme: const IconThemeData(color: AppColors.lightPrimary),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.darkPrimary,
        secondary: AppColors.darkSecondary,
        tertiary: AppColors.darkAccent,
        error: AppColors.darkError,
        surface: Color(0xFF1E1E1E),
        onPrimary: AppColors.black,
        onSecondary: AppColors.black,
        onTertiary: AppColors.black,
        onError: AppColors.black,
        onSurface: AppColors.white,
      ),
      scaffoldBackgroundColor: AppColors.darkGrey,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.white,
        titleTextStyle: TextStyle(
          color: AppColors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF1E1E1E),
        elevation: 4,
        shadowColor: AppColors.black.withOpacity(0.3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.darkPrimary,
        foregroundColor: AppColors.black,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.darkPrimary,
          foregroundColor: AppColors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.darkPrimary),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.darkPrimary;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(AppColors.black),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.mediumGrey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.darkPrimary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        fillColor: const Color(0xFF2A2A2A),
        filled: true,
      ),
      textTheme: TextTheme(
        displayLarge: AppTextStyles.dark.headline1,
        displayMedium: AppTextStyles.dark.headline2,
        displaySmall: AppTextStyles.dark.headline3,
        headlineMedium: AppTextStyles.dark.headline2,
        headlineSmall: AppTextStyles.dark.headline3,
        titleLarge: AppTextStyles.dark.cardTitle,
        titleMedium: AppTextStyles.dark.listTitle,
        titleSmall: AppTextStyles.dark.subtitle2,
        bodyLarge: AppTextStyles.dark.body1,
        bodyMedium: AppTextStyles.dark.body2,
        bodySmall: AppTextStyles.dark.caption,
        labelLarge: AppTextStyles.dark.button,
        labelMedium: AppTextStyles.dark.label,
        labelSmall: AppTextStyles.dark.overline,
      ),
      iconTheme: const IconThemeData(color: Colors.grey),
      primaryIconTheme: const IconThemeData(color: AppColors.darkPrimary),
    );
  }
}
