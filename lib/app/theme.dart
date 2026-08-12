import 'package:flutter/material.dart';

// ============================================================
// Manage Bills — Premium App Theme
// Primary: Electric Indigo   #4F46E5
// Secondary: Cyan            #06B6D4
// Follows system dark/light mode
// ============================================================

class AppTheme {
  AppTheme._();

  // ── Palette tokens ─────────────────────────────────────────
  static const Color _indigo = Color(0xFF4F46E5);
  static const Color _indigoLight = Color(0xFF818CF8);
  static const Color _cyan = Color(0xFF06B6D4);
  static const Color _darkBg = Color(0xFF0A0E1A);
  static const Color _darkSurface = Color(0xFF111827);
  static const Color _darkCard = Color(0xFF1F2937);
  static const Color _lightBg = Color(0xFFF0F2FF);
  static const Color _lightSurface = Color(0xFFFFFFFF);

  // ── Gradient helpers ──────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cyanGradient = LinearGradient(
    colors: [Color(0xFF06B6D4), Color(0xFF3B82F6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkBgGradient = LinearGradient(
    colors: [Color(0xFF0A0E1A), Color(0xFF111827), Color(0xFF1a1040)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient lightBgGradient = LinearGradient(
    colors: [Color(0xFFEEF2FF), Color(0xFFF5F3FF), Color(0xFFE0F2FE)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Shared shape ───────────────────────────────────────────
  static final _cardShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(16),
  );

  // ── Dark theme ─────────────────────────────────────────────
  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark(
          primary: _indigo,
          onPrimary: Colors.white,
          primaryContainer: Color(0xFF312E81),
          onPrimaryContainer: _indigoLight,
          secondary: _cyan,
          onSecondary: Colors.black,
          secondaryContainer: Color(0xFF164E63),
          onSecondaryContainer: Color(0xFF67E8F9),
          surface: _darkSurface,
          onSurface: Colors.white,
          surfaceContainerLow: _darkCard,
          surfaceContainerHigh: Color(0xFF374151),
          outline: Color(0xFF4B5563),
          outlineVariant: Color(0xFF374151),
          error: Color(0xFFEF4444),
          onError: Colors.white,
        ),
        scaffoldBackgroundColor: _darkBg,
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
          scrolledUnderElevation: 0,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.3,
          ),
        ),
        cardTheme: CardTheme(
          elevation: 0,
          color: _darkCard,
          shape: _cardShape,
          clipBehavior: Clip.antiAlias,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF1F2937),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF374151)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF374151)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _indigo, width: 2),
          ),
          labelStyle: const TextStyle(color: Color(0xFF9CA3AF)),
          prefixIconColor: const Color(0xFF6B7280),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: _indigo,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: Color(0xFF1F2937),
          thickness: 1,
        ),
        chipTheme: ChipThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );

  // ── Light theme ────────────────────────────────────────────
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: const ColorScheme.light(
          primary: _indigo,
          onPrimary: Colors.white,
          primaryContainer: Color(0xFFEEF2FF),
          onPrimaryContainer: Color(0xFF312E81),
          secondary: _cyan,
          onSecondary: Colors.white,
          secondaryContainer: Color(0xFFE0F2FE),
          onSecondaryContainer: Color(0xFF0E7490),
          surface: _lightSurface,
          onSurface: Color(0xFF111827),
          surfaceContainerLow: Color(0xFFF9FAFB),
          surfaceContainerHigh: Color(0xFFF3F4F6),
          outline: Color(0xFFD1D5DB),
          outlineVariant: Color(0xFFE5E7EB),
          error: Color(0xFFDC2626),
          onError: Colors.white,
        ),
        scaffoldBackgroundColor: _lightBg,
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: Color(0xFF111827),
          elevation: 0,
          centerTitle: false,
          scrolledUnderElevation: 0,
          titleTextStyle: TextStyle(
            color: Color(0xFF111827),
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.3,
          ),
        ),
        cardTheme: CardTheme(
          elevation: 0,
          color: Colors.white,
          shape: _cardShape,
          clipBehavior: Clip.antiAlias,
          shadowColor: Colors.black12,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF9FAFB),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _indigo, width: 2),
          ),
          labelStyle: const TextStyle(color: Color(0xFF6B7280)),
          prefixIconColor: const Color(0xFF9CA3AF),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: _indigo,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: Color(0xFFE5E7EB),
          thickness: 1,
        ),
        chipTheme: ChipThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
}
