import 'package:flutter/material.dart';

// -------------------------------------------------------------
// COLOR TOKENS � Network Cloak brand palette
// -------------------------------------------------------------
class NcColors {
  NcColors._();

  // Brand (Identical for Light and Dark)
  static const primary = Color(0xFF00D4FF);       // Electric cyan
  static const primaryDark = Color(0xFF0099CC);
  static const accent = Color(0xFF7C3AED);         // Violet accent

  // Status colors
  static const protected = Color(0xFF00E676);      // Green � protected
  static const partial = Color(0xFFFFAB00);        // Amber � partial
  static const unprotected = Color(0xFFFF1744);    // Red � not protected
  static const hostile = Color(0xFFFF6D00);        // Orange � hostile

  // Rule chip colors
  static const chipAllow = Color(0xFF00C853);
  static const chipBlock = Color(0xFFD50000);
  static const chipAsk = Color(0xFFFF6F00);
  static const chipRestrict = Color(0xFF1565C0);

  // Gradient stops
  static const gradientStart = Color(0xFF00D4FF);
  static const gradientEnd = Color(0xFF7C3AED);

  // Dynamic theme-dependent colors (defaults to Dark/Stealth)
  static Color bg = const Color(0xFF080C14);             // Near-black blue
  static Color surface = const Color(0xFF0F1623);        // Card background
  static Color surfaceElevated = const Color(0xFF162030); // Elevated card
  static Color border = const Color(0xFF1E2D42);
  static Color textPrimary = const Color(0xFFE8F4FD);
  static Color textSecondary = const Color(0xFF8AA8C4);
  static Color textMuted = const Color(0xFF4A6480);

  static void updateColors(ThemeMode mode) {
    if (mode == ThemeMode.light) {
      bg = const Color(0xFFF3F4F6); // Standard light background gray
      surface = const Color(0xFFFFFFFF); // White cards
      surfaceElevated = const Color(0xFFE5E7EB); // Off-white elevated cards
      border = const Color(0xFFE5E7EB); // Soft borders
      textPrimary = const Color(0xFF111827); // Dark gray text
      textSecondary = const Color(0xFF374151); // Gray sub-text
      textMuted = const Color(0xFF6B7280); // Gray muted text
    } else {
      bg = const Color(0xFF080C14);
      surface = const Color(0xFF0F1623);
      surfaceElevated = const Color(0xFF162030);
      border = const Color(0xFF1E2D42);
      textPrimary = const Color(0xFFE8F4FD);
      textSecondary = const Color(0xFF8AA8C4);
      textMuted = const Color(0xFF4A6480);
    }
  }
}

// -------------------------------------------------------------
// TYPOGRAPHY
// -------------------------------------------------------------
class NcTextStyles {
  NcTextStyles._();

  static TextStyle get displayLarge => TextStyle(
    fontFamily: 'Inter',
    fontSize: 48,
    fontWeight: FontWeight.w700,
    color: NcColors.textPrimary,
    letterSpacing: -1.5,
  );

  static TextStyle get headlineLarge => TextStyle(
    fontFamily: 'Inter',
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: NcColors.textPrimary,
    letterSpacing: -0.5,
  );

  static TextStyle get headlineMedium => TextStyle(
    fontFamily: 'Inter',
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: NcColors.textPrimary,
  );

  static TextStyle get titleLarge => TextStyle(
    fontFamily: 'Inter',
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: NcColors.textPrimary,
  );

  static TextStyle get titleMedium => TextStyle(
    fontFamily: 'Inter',
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: NcColors.textPrimary,
  );

  static TextStyle get bodyLarge => TextStyle(
    fontFamily: 'Inter',
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: NcColors.textPrimary,
  );

  static TextStyle get bodyMedium => TextStyle(
    fontFamily: 'Inter',
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: NcColors.textSecondary,
  );

  static TextStyle get labelSmall => TextStyle(
    fontFamily: 'Inter',
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: NcColors.textMuted,
    letterSpacing: 0.8,
  );
}

// -------------------------------------------------------------
// APP THEME
// -------------------------------------------------------------
class AppTheme {
  AppTheme._();

  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: NcColors.bg,
      colorScheme: ColorScheme.dark(
        primary: NcColors.primary,
        secondary: NcColors.accent,
        surface: NcColors.surface,
        onPrimary: NcColors.bg,
        onSecondary: Colors.white,
        onSurface: NcColors.textPrimary,
      ),
      cardTheme: CardThemeData(
        color: NcColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: NcColors.border, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: NcColors.bg,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: NcTextStyles.headlineMedium,
        iconTheme: IconThemeData(color: NcColors.textPrimary),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: NcColors.surface,
        indicatorColor: NcColors.primary.withValues(alpha: 0.15),
        iconTheme: WidgetStateProperty.all(
          IconThemeData(color: NcColors.textSecondary),
        ),
        labelTextStyle: WidgetStateProperty.all(NcTextStyles.bodyMedium),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: NcColors.surfaceElevated,
        labelStyle: NcTextStyles.bodyMedium,
        side: BorderSide(color: NcColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: NcColors.primary,
          foregroundColor: NcColors.bg,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: NcTextStyles.titleMedium,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: NcColors.surfaceElevated,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: NcColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: NcColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: NcColors.primary, width: 2),
        ),
        hintStyle: TextStyle(color: NcColors.textMuted),
        labelStyle: TextStyle(color: NcColors.textSecondary),
      ),
      textTheme: TextTheme(
        displayLarge: NcTextStyles.displayLarge,
        headlineLarge: NcTextStyles.headlineLarge,
        headlineMedium: NcTextStyles.headlineMedium,
        titleLarge: NcTextStyles.titleLarge,
        titleMedium: NcTextStyles.titleMedium,
        bodyLarge: NcTextStyles.bodyLarge,
        bodyMedium: NcTextStyles.bodyMedium,
        labelSmall: NcTextStyles.labelSmall,
      ),
      dividerTheme: DividerThemeData(
        color: NcColors.border,
        thickness: 1,
        space: 0,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? NcColors.primary
              : NcColors.textMuted,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? NcColors.primary.withValues(alpha: 0.3)
              : NcColors.border,
        ),
      ),
    );
  }

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: NcColors.bg,
      colorScheme: ColorScheme.light(
        primary: NcColors.primary,
        secondary: NcColors.accent,
        surface: NcColors.surface,
        onPrimary: Colors.white,
        onSecondary: NcColors.bg,
        onSurface: NcColors.textPrimary,
      ),
      cardTheme: CardThemeData(
        color: NcColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: NcColors.border, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: NcColors.bg,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: NcTextStyles.headlineMedium,
        iconTheme: IconThemeData(color: NcColors.textPrimary),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: NcColors.surface,
        indicatorColor: NcColors.primary.withValues(alpha: 0.15),
        iconTheme: WidgetStateProperty.all(
          IconThemeData(color: NcColors.textSecondary),
        ),
        labelTextStyle: WidgetStateProperty.all(NcTextStyles.bodyMedium),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: NcColors.surfaceElevated,
        labelStyle: NcTextStyles.bodyMedium,
        side: BorderSide(color: NcColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: NcColors.primary,
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: NcTextStyles.titleMedium,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: NcColors.surfaceElevated,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: NcColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: NcColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: NcColors.primary, width: 2),
        ),
        hintStyle: TextStyle(color: NcColors.textMuted),
        labelStyle: TextStyle(color: NcColors.textSecondary),
      ),
      textTheme: TextTheme(
        displayLarge: NcTextStyles.displayLarge,
        headlineLarge: NcTextStyles.headlineLarge,
        headlineMedium: NcTextStyles.headlineMedium,
        titleLarge: NcTextStyles.titleLarge,
        titleMedium: NcTextStyles.titleMedium,
        bodyLarge: NcTextStyles.bodyLarge,
        bodyMedium: NcTextStyles.bodyMedium,
        labelSmall: NcTextStyles.labelSmall,
      ),
      dividerTheme: DividerThemeData(
        color: NcColors.border,
        thickness: 1,
        space: 0,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? NcColors.primary
              : NcColors.textMuted,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? NcColors.primary.withValues(alpha: 0.3)
              : NcColors.border,
        ),
      ),
    );
  }
}
