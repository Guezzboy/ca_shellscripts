import 'package:flutter/material.dart';

/// Colectio design tokens — 3 themes matching the wireframe spec.
class AppTheme {
  AppTheme._();

  // ── Solaire palette (default) ──
  static const _solaire = ThemeTokens(
    bg: Color(0xFFFAF6EC),
    surface: Color(0xFFFFFFFF),
    ink: Color(0xFF2A251F),
    accent: Color(0xFFF4A72B),
    accentDeep: Color(0xFFE07A1F),
    accent2: Color(0xFFFFD166),
    accentSoft: Color(0xFFFFE9B8),
    label: 'Solaire',
  );

  // ── Naturel & Doux palette ──
  static const _naturel = ThemeTokens(
    bg: Color(0xFFF3EDE0),
    surface: Color(0xFFFBF6EC),
    ink: Color(0xFF3A2F24),
    accent: Color(0xFF94A87A),
    accentDeep: Color(0xFFC87655),
    accent2: Color(0xFFD8B88B),
    accentSoft: Color(0xFFDDE4CB),
    label: 'Naturel',
  );

  // ── Nuit palette (dark) ──
  static const _nuit = ThemeTokens(
    bg: Color(0xFF1C1A17),
    surface: Color(0xFF26231E),
    ink: Color(0xFFF5ECD9),
    accent: Color(0xFFF4B73A),
    accentDeep: Color(0xFFFF8A3D),
    accent2: Color(0xFFFFD479),
    accentSoft: Color(0x33F4B73A), // rgba(244,183,58,0.18)
    label: 'Nuit',
  );

  static const _tokens = <String, ThemeTokens>{
    'solaire': _solaire,
    'naturel': _naturel,
    'nuit': _nuit,
  };

  static ThemeTokens tokensOf(String key) => _tokens[key] ?? _solaire;

  static ThemeData buildTheme(String key) {
    final t = tokensOf(key);
    final isDark = key == 'nuit';
    final scheme = ColorScheme(
      brightness: isDark ? Brightness.dark : Brightness.light,
      primary: t.accent,
      onPrimary: isDark ? t.ink : Colors.white,
      secondary: t.accentDeep,
      onSecondary: Colors.white,
      surface: t.surface,
      onSurface: t.ink,
      error: const Color(0xFFD63B2F),
      onError: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Roboto',
      colorScheme: scheme,
      scaffoldBackgroundColor: t.bg,
      appBarTheme: AppBarTheme(
        backgroundColor: t.bg,
        foregroundColor: t.ink,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: t.ink,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: t.surface,
        selectedItemColor: t.accentDeep,
        unselectedItemColor: t.ink.withOpacity(0.4),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 9, fontWeight: FontWeight.w500),
      ),
      dividerTheme: DividerThemeData(
        color: t.ink.withOpacity(0.08),
        thickness: 1,
        space: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: t.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: t.ink.withOpacity(0.15)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: t.ink.withOpacity(0.15)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: t.accent, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: t.accent,
          foregroundColor: isDark ? t.ink : Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: t.ink,
          side: BorderSide(color: t.ink.withOpacity(0.15)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: t.accent,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: const CircleBorder(),
      ),
      cardTheme: CardThemeData(
        color: t.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

/// Raw color tokens for one theme.
class ThemeTokens {
  final Color bg;
  final Color surface;
  final Color ink;
  final Color accent;
  final Color accentDeep;
  final Color accent2;
  final Color accentSoft;
  final String label;

  const ThemeTokens({
    required this.bg,
    required this.surface,
    required this.ink,
    required this.accent,
    required this.accentDeep,
    required this.accent2,
    required this.accentSoft,
    required this.label,
  });
}

/// Convenience extension to access theme tokens from BuildContext.
extension AppThemeExtension on BuildContext {
  ThemeTokens get themeTokens {
    final brightness = Theme.of(this).brightness;
    final isDark = brightness == Brightness.dark;
    if (isDark) return AppTheme._nuit;
    // Heuristic: check primary color to determine solaire vs naturel
    final primary = Theme.of(this).colorScheme.primary;
    if (primary == AppTheme._naturel.accent) return AppTheme._naturel;
    return AppTheme._solaire;
  }

  String get currentThemeKey {
    final primary = Theme.of(this).colorScheme.primary;
    if (primary == AppTheme._nuit.accent) return 'nuit';
    if (primary == AppTheme._naturel.accent) return 'naturel';
    return 'solaire';
  }
}
