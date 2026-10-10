import 'package:flutter/material.dart';

abstract final class AppColors {
  static const forest = Color(0xFF283618);
  static const olive = Color(0xFF606C38);
  static const beige = Color(0xFFFEFAE0);
  static const terracotta = Color(0xFFDDA15E);
  static const ochre = Color(0xFFBC6C25);
  static const danger = Color(0xFF731414);
  static const slate = Color(0xFF283618);
  static const surface = Color(0xFFFEFAE0);
  static const iconSurface = Color(0xFFFEFAE0);
}

ThemeData buildAppTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.forest,
    brightness: Brightness.light,
    primary: AppColors.forest,
    secondary: AppColors.olive,
    tertiary: AppColors.ochre,
    surface: AppColors.surface,
    onSurface: AppColors.slate,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.beige,
    fontFamily: 'Literata',
    fontFamilyFallback: const ['serif'],
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: AppColors.slate, height: 1.6),
      bodyMedium: TextStyle(color: AppColors.slate, height: 1.6),
      titleLarge: TextStyle(
        color: AppColors.forest,
        fontFamily: 'Literata',
        fontWeight: FontWeight.w700,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.forest,
      indicatorColor: Colors.transparent,
      overlayColor: const WidgetStatePropertyAll(Colors.transparent),
      labelTextStyle: WidgetStatePropertyAll(
        TextStyle(color: AppColors.beige, fontWeight: FontWeight.w600),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: AppColors.slate,
      contentTextStyle: TextStyle(color: AppColors.beige),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.ochre,
      foregroundColor: AppColors.surface,
    ),
  );
}
