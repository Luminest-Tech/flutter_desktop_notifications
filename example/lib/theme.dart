import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Exposed through [context.palette].
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.canvas,
    required this.surface,
    required this.surfaceSoft,
    required this.surfaceRaised,
    required this.border,
    required this.borderStrong,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.caramel,
    required this.sage,
    required this.terracotta,
    required this.ink,
    required this.cream,
    required this.wine,
    required this.softShadow,
  });

  final Color canvas;
  final Color surface;
  final Color surfaceSoft;
  final Color surfaceRaised;
  final Color border;
  final Color borderStrong;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;

  final Color caramel;
  final Color sage;
  final Color terracotta;
  final Color ink;
  final Color cream;
  final Color wine;
  final Color softShadow;

  static const light = AppPalette(
    canvas: Color(0xFFF5EDDD),
    surface: Color(0xFFFBF5E8),
    surfaceSoft: Color(0xFFEFE5D0),
    surfaceRaised: Color(0xFFFFFBF2),
    border: Color(0xFFE3D5BC),
    borderStrong: Color(0xFFC9B69A),
    textPrimary: Color(0xFF2B2019),
    textSecondary: Color(0xFF7A6851),
    textTertiary: Color(0xFFA89479),
    caramel: Color(0xFFB8764C),
    sage: Color(0xFF8B9A6B),
    terracotta: Color(0xFFC66A4A),
    ink: Color(0xFF3D2E1F),
    cream: Color(0xFFF7EFDF),
    wine: Color(0xFF8B3A3A),
    softShadow: Color(0x14000000),
  );

  static const dark = AppPalette(
    canvas: Color(0xFF1C1511),
    surface: Color(0xFF261E17),
    surfaceSoft: Color(0xFF312619),
    surfaceRaised: Color(0xFF3A2E21),
    border: Color(0xFF3E3124),
    borderStrong: Color(0xFF5A4A3B),
    textPrimary: Color(0xFFF2E3C9),
    textSecondary: Color(0xFFC5B393),
    textTertiary: Color(0xFF8A7863),
    caramel: Color(0xFFD9A77A),
    sage: Color(0xFFA8B58B),
    terracotta: Color(0xFFE89773),
    ink: Color(0xFFF2E3C9),
    cream: Color(0xFFF5E6CF),
    wine: Color(0xFFB85C5C),
    softShadow: Color(0x55000000),
  );

  @override
  AppPalette copyWith({
    Color? canvas,
    Color? surface,
    Color? surfaceSoft,
    Color? surfaceRaised,
    Color? border,
    Color? borderStrong,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? caramel,
    Color? sage,
    Color? terracotta,
    Color? ink,
    Color? cream,
    Color? wine,
    Color? softShadow,
  }) =>
      AppPalette(
        canvas: canvas ?? this.canvas,
        surface: surface ?? this.surface,
        surfaceSoft: surfaceSoft ?? this.surfaceSoft,
        surfaceRaised: surfaceRaised ?? this.surfaceRaised,
        border: border ?? this.border,
        borderStrong: borderStrong ?? this.borderStrong,
        textPrimary: textPrimary ?? this.textPrimary,
        textSecondary: textSecondary ?? this.textSecondary,
        textTertiary: textTertiary ?? this.textTertiary,
        caramel: caramel ?? this.caramel,
        sage: sage ?? this.sage,
        terracotta: terracotta ?? this.terracotta,
        ink: ink ?? this.ink,
        cream: cream ?? this.cream,
        wine: wine ?? this.wine,
        softShadow: softShadow ?? this.softShadow,
      );

  @override
  AppPalette lerp(covariant AppPalette? other, double t) {
    if (other == null) return this;
    return AppPalette(
      canvas: Color.lerp(canvas, other.canvas, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceSoft: Color.lerp(surfaceSoft, other.surfaceSoft, t)!,
      surfaceRaised: Color.lerp(surfaceRaised, other.surfaceRaised, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderStrong: Color.lerp(borderStrong, other.borderStrong, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      caramel: Color.lerp(caramel, other.caramel, t)!,
      sage: Color.lerp(sage, other.sage, t)!,
      terracotta: Color.lerp(terracotta, other.terracotta, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      cream: Color.lerp(cream, other.cream, t)!,
      wine: Color.lerp(wine, other.wine, t)!,
      softShadow: Color.lerp(softShadow, other.softShadow, t)!,
    );
  }
}

// Georgia ships with Windows and macOS; on Linux the system falls back to
// another serif.
const _displayFont = 'Georgia';

TextTheme _textTheme(AppPalette p) => TextTheme(
      displayLarge: TextStyle(
        fontFamily: _displayFont,
        color: p.textPrimary,
        fontSize: 32,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.8,
        height: 1.05,
      ),
      displayMedium: TextStyle(
        fontFamily: _displayFont,
        color: p.textPrimary,
        fontSize: 24,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
        height: 1.1,
      ),
      headlineSmall: TextStyle(
        fontFamily: _displayFont,
        color: p.textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
      ),
      titleMedium: TextStyle(
        color: p.textPrimary,
        fontSize: 15,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.15,
      ),
      bodyMedium: TextStyle(
        color: p.textSecondary,
        fontSize: 13.5,
        height: 1.45,
      ),
      bodySmall: TextStyle(
        color: p.textTertiary,
        fontSize: 12,
        height: 1.45,
      ),
      labelLarge: TextStyle(
        color: p.textTertiary,
        fontSize: 10.5,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.8,
      ),
      labelMedium: TextStyle(
        color: p.textSecondary,
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.3,
      ),
    );

ThemeData buildLightTheme() => _buildTheme(AppPalette.light, Brightness.light);
ThemeData buildDarkTheme() => _buildTheme(AppPalette.dark, Brightness.dark);

ThemeData _buildTheme(AppPalette p, Brightness brightness) {
  final scheme = ColorScheme(
    brightness: brightness,
    primary: p.caramel,
    onPrimary: p.cream,
    secondary: p.sage,
    onSecondary: p.ink,
    error: p.terracotta,
    onError: p.cream,
    surface: p.surface,
    onSurface: p.textPrimary,
    surfaceContainerHighest: p.surfaceRaised,
    outline: p.border,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: p.canvas,
    canvasColor: p.canvas,
    textTheme: _textTheme(p),
    extensions: [p],
    cardTheme: CardThemeData(
      color: p.surface,
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: p.border, width: 1),
      ),
    ),
    dividerTheme: DividerThemeData(
      color: p.border,
      thickness: 1,
      space: 0,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: p.canvas,
      foregroundColor: p.textPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
      systemOverlayStyle: brightness == Brightness.light
          ? SystemUiOverlayStyle.dark
          : SystemUiOverlayStyle.light,
      titleTextStyle: TextStyle(
        fontFamily: _displayFont,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: p.textPrimary,
        letterSpacing: -0.3,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: p.caramel,
        foregroundColor: p.cream,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: p.surfaceRaised,
      contentTextStyle: TextStyle(color: p.textPrimary),
    ),
  );
}

extension AppPaletteContext on BuildContext {
  AppPalette get palette => Theme.of(this).extension<AppPalette>()!;
}
