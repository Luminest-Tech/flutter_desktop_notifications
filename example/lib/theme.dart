import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Shared palette for the example app. Deep blue-black background with
/// mint primary + amber warn accents. Designed to feel closer to a modern
/// developer tool (Linear, Raycast) than the stock Material playground.
class AppColors {
  AppColors._();

  static const bg = Color(0xFF0A0E14);
  static const surface = Color(0xFF121821);
  static const surfaceElevated = Color(0xFF1B2533);
  static const border = Color(0xFF222D3D);
  static const borderStrong = Color(0xFF2E3B4E);

  static const textPrimary = Color(0xFFF4F6FA);
  static const textSecondary = Color(0xFFA5B1C2);
  static const textTertiary = Color(0xFF6B7A8F);

  static const mint = Color(0xFF4AE3B5);
  static const mintSoft = Color(0xFF0E3F32);
  static const amber = Color(0xFFFFB547);
  static const coral = Color(0xFFFF7A7A);
  static const violet = Color(0xFF9B7DFF);
  static const sky = Color(0xFF5DB4FF);
}

ThemeData buildAppTheme() {
  const scheme = ColorScheme.dark(
    surface: AppColors.surface,
    primary: AppColors.mint,
    onPrimary: Color(0xFF001F16),
    secondary: AppColors.amber,
    onSecondary: Color(0xFF2B1A00),
    error: AppColors.coral,
  );

  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.bg,
    canvasColor: AppColors.bg,
    textTheme: _textTheme,
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.border, width: 1),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.border,
      thickness: 1,
      space: 0,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.bg,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      titleTextStyle: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        letterSpacing: -0.2,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.mint,
        foregroundColor: const Color(0xFF001F16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: AppColors.surfaceElevated,
      contentTextStyle: TextStyle(color: AppColors.textPrimary),
    ),
  );

  return base;
}

TextTheme get _textTheme => const TextTheme(
      displayLarge: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 30,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.8,
        height: 1.1,
      ),
      headlineSmall: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
      ),
      titleMedium: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 15,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
      ),
      bodyMedium: TextStyle(
        color: AppColors.textSecondary,
        fontSize: 13.5,
        height: 1.4,
      ),
      bodySmall: TextStyle(
        color: AppColors.textTertiary,
        fontSize: 12,
        height: 1.4,
      ),
      labelLarge: TextStyle(
        color: AppColors.textTertiary,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
      ),
      labelMedium: TextStyle(
        color: AppColors.textSecondary,
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.3,
      ),
    );
