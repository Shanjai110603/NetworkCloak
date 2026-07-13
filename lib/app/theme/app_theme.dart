import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────
// COLOR TOKENS — Network Cloak brand palette
// ─────────────────────────────────────────────────────────────
class NcColors {
  NcColors._();

  // Brand
  static const primary = Color(0xFF00D4FF);       // Electric cyan
  static const primaryDark = Color(0xFF0099CC);
  static const accent = Color(0xFF7C3AED);         // Violet accent

  // Status colors
  static const protected = Color(0xFF00E676);      // Green — protected
  static const partial = Color(0xFFFFAB00);        // Amber — partial
  static const unprotected = Color(0xFFFF1744);    // Red — not protected
  static const hostile = Color(0xFFFF6D00);        // Orange — hostile

  // Rule chip colors
  static const chipAllow = Color(0xFF00C853);
  static const chipBlock = Color(0xFFD50000);
  static const chipAsk = Color(0xFFFF6F00);
  static const chipRestrict = Color(0xFF1565C0);

  // Dark surface palette
  static const bg = Color(0xFF080C14);             // Near-black blue
  static const surface = Color(0xFF0F1623);        // Card background
  static const surfaceElevated = Color(0xFF162030); // Elevated card
  static const border = Color(0xFF1E2D42);
  static const textPrimary = Color(0xFFE8F4FD);
  static const textSecondary = Color(0xFF8AA8C4);
  static const textMuted = Color(0xFF4A6480);

  // Gradient stops
  static const gradientStart = Color(0xFF00D4FF);
  static const gradientEnd = Color(0xFF7C3AED);
}

// ─────────────────────────────────────────────────────────────
// TYPOGRAPHY
// ─────────────────────────────────────────────────────────────
class NcTextStyles {
  NcTextStyles._();

  static const TextStyle displayLarge = TextStyle(
    fontFamily: 'Inter',
    fontSize: 48,
    fontWeight: FontWeight.w700,
    color: NcColors.textPrimary,
    letterSpacing: -1.5,
  );

  static const TextStyle headlineLarge = TextStyle(
    fontFamily: 'Inter',
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: NcColors.textPrimary,
    letterSpacing: -0.5,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontFamily: 'Inter',
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: NcColors.textPrimary,
  );

  static const TextStyle titleLarge = TextStyle(
    fontFamily: 'Inter',
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: NcColors.textPrimary,
  );

  static const TextStyle titleMedium = TextStyle(
    fontFamily: 'Inter',
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: NcColors.textPrimary,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontFamily: 'Inter',
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: NcColors.textPrimary,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: 'Inter',
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: NcColors.textSecondary,
  );

  static const TextStyle labelSmall = TextStyle(
    fontFamily: 'Inter',
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: NcColors.textMuted,
    letterSpacing: 0.8,
  );
}

// ─────────────────────────────────────────────────────────────
// APP THEME
// ─────────────────────────────────────────────────────────────
class AppTheme {
  AppTheme._();

  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: NcColors.bg,
      colorScheme: const ColorScheme.dark(
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
          side: const BorderSide(color: NcColors.border, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      appBarTheme: const AppBarTheme(
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
          const IconThemeData(color: NcColors.textSecondary),
        ),
        labelTextStyle: WidgetStateProperty.all(NcTextStyles.bodyMedium),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: NcColors.surfaceElevated,
        labelStyle: NcTextStyles.bodyMedium,
        side: const BorderSide(color: NcColors.border),
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
          borderSide: const BorderSide(color: NcColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: NcColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: NcColors.primary, width: 2),
        ),
        hintStyle: const TextStyle(color: NcColors.textMuted),
        labelStyle: const TextStyle(color: NcColors.textSecondary),
      ),
      textTheme: const TextTheme(
        displayLarge: NcTextStyles.displayLarge,
        headlineLarge: NcTextStyles.headlineLarge,
        headlineMedium: NcTextStyles.headlineMedium,
        titleLarge: NcTextStyles.titleLarge,
        titleMedium: NcTextStyles.titleMedium,
        bodyLarge: NcTextStyles.bodyLarge,
        bodyMedium: NcTextStyles.bodyMedium,
        labelSmall: NcTextStyles.labelSmall,
      ),
      dividerTheme: const DividerThemeData(
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
