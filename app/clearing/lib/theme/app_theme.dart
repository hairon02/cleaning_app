import 'package:flutter/material.dart';

abstract final class AppColors {
  static const forest = Color(0xFF2D4F1E);
  static const beige = Color(0xFFF5E6CC);
  static const terracotta = Color(0xFFE27D60);
  static const slate = Color(0xFF4A4A4A);
  static const surface = Color(0xFFFBF3E4);
  static const iconSurface = Color(0xFFFFFFFF);
}

ThemeData buildAppTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.forest,
    brightness: Brightness.light,
    primary: AppColors.forest,
    secondary: AppColors.terracotta,
    surface: AppColors.surface,
    onSurface: AppColors.slate,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.beige,
    fontFamily: 'serif',
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: AppColors.slate, height: 1.6),
      bodyMedium: TextStyle(color: AppColors.slate, height: 1.6),
      titleLarge: TextStyle(color: AppColors.forest, fontWeight: FontWeight.w700),
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
      backgroundColor: AppColors.terracotta,
      foregroundColor: AppColors.beige,
    ),
  );
}
