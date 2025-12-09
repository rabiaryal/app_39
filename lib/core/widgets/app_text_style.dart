import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTextStyles {
  // Get appropriate text theme based on current theme
  static _AppTextTheme of(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? dark : light;
  }

  // Light Theme TextStyles
  static final light = _AppTextTheme(
    primaryColor: Colors.black,
    secondaryColor: Colors.black54,
    accentColor: Colors.grey[700]!,
    errorColor: Colors.red,
    successColor: Colors.green,
    warningColor: Colors.orange,
  );

  // Dark Theme TextStyles
  static final dark = _AppTextTheme(
    primaryColor: Colors.white,
    secondaryColor: Colors.white70,
    accentColor: Colors.grey[400]!,
    errorColor: Colors.red[300]!,
    successColor: Colors.green[300]!,
    warningColor: Colors.orange[300]!,
  );
}

class _AppTextTheme {
  final Color primaryColor;
  final Color secondaryColor;
  final Color accentColor;
  final Color errorColor;
  final Color successColor;
  final Color warningColor;

  const _AppTextTheme({
    required this.primaryColor,
    required this.secondaryColor,
    required this.accentColor,
    required this.errorColor,
    required this.successColor,
    required this.warningColor,
  });

  // Headlines
  TextStyle get headline1 => GoogleFonts.inter(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: primaryColor,
  );

  TextStyle get headline2 => GoogleFonts.inter(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: primaryColor,
  );

  TextStyle get headline3 => GoogleFonts.inter(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: primaryColor,
  );

  // Subtitles
  TextStyle get subtitle1 => GoogleFonts.inter(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    color: secondaryColor,
  );

  TextStyle get subtitle2 => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: secondaryColor,
  );

  // Body text
  TextStyle get body1 => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: primaryColor,
  );

  TextStyle get body2 => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: secondaryColor,
  );

  // Caption / Labels
  TextStyle get caption => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: accentColor,
  );

  TextStyle get label => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: accentColor,
  );

  // Button
  TextStyle get button => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  TextStyle get buttonSmall => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  // Overline
  TextStyle get overline => GoogleFonts.inter(
    fontSize: 10,
    fontWeight: FontWeight.w400,
    color: accentColor,
    letterSpacing: 1.2,
  );

  // Currency and numbers
  TextStyle get currency => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: primaryColor,
  );

  TextStyle get currencyLarge => GoogleFonts.inter(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: primaryColor,
  );

  // Status colors
  TextStyle get error => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: errorColor,
  );

  TextStyle get success => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: successColor,
  );

  TextStyle get warning => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: warningColor,
  );

  // Hints and placeholders
  TextStyle get hint => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: accentColor,
  );

  // List items
  TextStyle get listTitle => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: primaryColor,
  );

  TextStyle get listSubtitle => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: secondaryColor,
  );

  // App bar
  TextStyle get appBarTitle => GoogleFonts.inter(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: primaryColor,
  );

  // Card content
  TextStyle get cardTitle => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: primaryColor,
  );

  TextStyle get cardSubtitle => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: secondaryColor,
  );
}

// Usage examples:
//
// // Theme-aware (recommended):
// Text('Hello', style: AppTextStyles.of(context).headline1)
// Text('Subtitle', style: AppTextStyles.of(context).body1)
//
// // Specific theme (if needed):
// Text('Light theme', style: AppTextStyles.light.headline1)
// Text('Dark theme', style: AppTextStyles.dark.body1)
//
// // With custom colors:
// Text('Error', style: AppTextStyles.of(context).error)
// Text('Success', style: AppTextStyles.of(context).success)
//
// // Currency formatting:
// Text('\$123.45', style: AppTextStyles.of(context).currency)
