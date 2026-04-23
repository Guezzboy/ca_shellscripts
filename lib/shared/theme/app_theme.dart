import 'package:flutter/material.dart';

class AppTheme {
  static const Color cardboard = Color(0xFFF5E6C8);
  static const Color cardboardDark = Color(0xFFD4B896);
  static const Color primaryBrown = Color(0xFF5C4033);
  static const Color ownedGreen = Color(0xFF4CAF50);
  static const Color ownedGreenLight = Color(0xFFE8F5E9);
  static const Color cardCream = Color(0xFFFFFBF0);

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryBrown,
          brightness: Brightness.light,
        ).copyWith(
          surface: cardboard,
          primary: primaryBrown,
          secondary: ownedGreen,
        ),
        scaffoldBackgroundColor: cardboard,
        appBarTheme: const AppBarTheme(
          backgroundColor: primaryBrown,
          foregroundColor: Colors.white,
          elevation: 2,
          centerTitle: false,
        ),
        cardTheme: CardThemeData(
          color: cardCream,
          elevation: 3,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryBrown,
            foregroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: primaryBrown,
          foregroundColor: Colors.white,
        ),
      );
}
