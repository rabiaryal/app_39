import 'package:flutter/material.dart';

/// Comprehensive Design System for the app
/// Following the improvement brief specifications

class AppDesignSystem {
  // ============================================================================
  // COLOR PALETTE
  // ============================================================================

  /// Primary Colors
  static const Color primaryBlue = Color(0xFF3B82F6);
  static const Color primaryPurple = Color(0xFFA855F7);

  static LinearGradient get gradientPrimary => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryBlue, primaryPurple],
  );

  /// Semantic Colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);
  static const Color info = Color(0xFF06B6D4);

  /// Neutrals
  static const Color gray50 = Color(0xFFF9FAFB);
  static const Color gray100 = Color(0xFFF3F4F6);
  static const Color gray300 = Color(0xFFD1D5DB);
  static const Color gray500 = Color(0xFF6B7280);
  static const Color gray700 = Color(0xFF374151);
  static const Color gray900 = Color(0xFF111827);

  /// Backgrounds
  static const Color bgPrimary = Colors.white;
  static const Color bgSecondary = Color(0xFFF9FAFB);

  static LinearGradient get bgApp => const LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFF9FAFB), Color(0xFFEFF6FF)],
  );

  // ============================================================================
  // TYPOGRAPHY SCALE
  // ============================================================================

  static const String fontFamily = 'Inter'; // Fallback to system fonts

  /// Headings
  static const TextStyle text3xl = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.5,
    height: 1.2,
  );

  static const TextStyle text2xl = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.3,
    height: 1.3,
  );

  static const TextStyle textXl = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  /// Body
  static const TextStyle textBase = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.5,
  );

  static const TextStyle textSm = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    height: 1.4,
  );

  static const TextStyle textXs = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    height: 1.3,
  );

  // ============================================================================
  // SPACING SYSTEM (multiples of 4px)
  // ============================================================================

  static const double spacingXs = 4.0; // Tight gaps
  static const double spacingSm = 8.0; // Related items
  static const double spacingMd = 12.0; // List item padding
  static const double spacingBase = 16.0; // Card/button padding
  static const double spacingLg = 24.0; // Section spacing
  static const double spacingXl = 32.0; // Major sections
  static const double spacing2xl = 48.0; // Page margins

  // ============================================================================
  // COMPONENT STYLES
  // ============================================================================

  /// Card Decoration
  static BoxDecoration cardDecoration({Color? color, bool elevated = false}) {
    return BoxDecoration(
      color: color ?? Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: gray100),
      boxShadow: elevated
          ? [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ]
          : [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
    );
  }

  /// Button Styles
  static ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    backgroundColor: primaryBlue,
    foregroundColor: Colors.white,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    elevation: 0,
    textStyle: textBase.copyWith(fontWeight: FontWeight.w600),
  );

  static ButtonStyle secondaryButtonStyle = OutlinedButton.styleFrom(
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    backgroundColor: Colors.white,
    foregroundColor: gray700,
    side: const BorderSide(color: gray300, width: 2),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    textStyle: textBase.copyWith(fontWeight: FontWeight.w600),
  );

  static ButtonStyle ghostButtonStyle = TextButton.styleFrom(
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    foregroundColor: gray700,
    backgroundColor: Colors.transparent,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    textStyle: textBase.copyWith(fontWeight: FontWeight.w600),
  );

  /// Input Decoration
  static InputDecoration inputDecoration({
    String? hintText,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: gray300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: gray300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: primaryBlue, width: 2),
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  // ============================================================================
  // CATEGORY COLORS & ICONS
  // ============================================================================

  static const Map<String, CategoryStyle> categoryStyles = {
    'Work': CategoryStyle(color: Color(0xFF3B82F6), icon: '💼'),
    'Personal': CategoryStyle(color: Color(0xFF10B981), icon: '🏠'),
    'Social': CategoryStyle(color: Color(0xFFA855F7), icon: '👥'),
    'Health': CategoryStyle(color: Color(0xFFEF4444), icon: '❤️'),
    'Other': CategoryStyle(color: Color(0xFF6B7280), icon: '📌'),

    // Transaction categories
    'Food & Dining': CategoryStyle(color: Color(0xFFF59E0B), icon: '🍔'),
    'Transportation': CategoryStyle(color: Color(0xFF3B82F6), icon: '🚗'),
    'Housing': CategoryStyle(color: Color(0xFF8B5CF6), icon: '🏠'),
    'Entertainment': CategoryStyle(color: Color(0xFFEC4899), icon: '🎉'),
    'Income': CategoryStyle(color: Color(0xFF10B981), icon: '💰'),
    'Shopping': CategoryStyle(color: Color(0xFF06B6D4), icon: '🛒'),
    'Utilities': CategoryStyle(color: Color(0xFFF59E0B), icon: '⚡'),
  };

  // ============================================================================
  // PRIORITY SYSTEM
  // ============================================================================

  static const Map<String, PriorityStyle> priorityStyles = {
    'high': PriorityStyle(
      color: danger,
      icon: Icons.flag_rounded,
      label: 'High',
    ),
    'medium': PriorityStyle(
      color: warning,
      icon: Icons.circle,
      label: 'Medium',
    ),
    'low': PriorityStyle(color: gray500, icon: Icons.remove, label: 'Low'),
  };

  // ============================================================================
  // ANIMATION DURATIONS
  // ============================================================================

  static const Duration animationFast = Duration(milliseconds: 150);
  static const Duration animationNormal = Duration(milliseconds: 250);
  static const Duration animationSlow = Duration(milliseconds: 400);

  // ============================================================================
  // RESPONSIVE BREAKPOINTS
  // ============================================================================

  static const double breakpointMobile = 640;
  static const double breakpointTablet = 1024;

  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < breakpointMobile;
  }

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= breakpointMobile && width < breakpointTablet;
  }

  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= breakpointTablet;
  }
}

class CategoryStyle {
  final Color color;
  final String icon;

  const CategoryStyle({required this.color, required this.icon});
}

class PriorityStyle {
  final Color color;
  final IconData icon;
  final String label;

  const PriorityStyle({
    required this.color,
    required this.icon,
    required this.label,
  });
}
