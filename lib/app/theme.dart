// lib/app/theme.dart
import 'package:flutter/material.dart';

import '../core/design/tokens/tokens.dart';

/// App theming, built from the SINTDT design tokens (not `fromSeed`).
/// Light is design-authoritative; dark is a best-effort adaptation pending
/// dark tokens in the design system.
class AppTheme {
  const AppTheme._();

  static ThemeData light() {
    const scheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.brand,
      onPrimary: AppColors.textOnBrand,
      primaryContainer: AppColors.brandSoft,
      onPrimaryContainer: AppColors.textBrand,
      secondary: AppColors.today,
      onSecondary: AppColors.ink900,
      tertiary: AppColors.reschedule,
      onTertiary: AppColors.white,
      error: AppColors.error,
      onError: AppColors.white,
      surface: AppColors.surfaceCard,
      onSurface: AppColors.textPrimary,
      onSurfaceVariant: AppColors.textSecondary,
      outline: AppColors.borderStrong,
      outlineVariant: AppColors.borderDefault,
    );
    return _build(scheme, AppColors.surfacePage);
  }

  static ThemeData dark() {
    const scheme = ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.blue400,
      onPrimary: AppColors.ink900,
      primaryContainer: AppColors.blue800,
      onPrimaryContainer: AppColors.blue100,
      secondary: AppColors.sun400,
      onSecondary: AppColors.ink900,
      tertiary: AppColors.coral400,
      onTertiary: AppColors.ink900,
      error: AppColors.red400,
      onError: AppColors.ink900,
      surface: AppColors.ink800,
      onSurface: AppColors.ink50,
      onSurfaceVariant: AppColors.ink300,
      outline: AppColors.ink600,
      outlineVariant: AppColors.ink700,
    );
    return _build(scheme, AppColors.ink900);
  }

  static ThemeData _build(ColorScheme scheme, Color background) {
    final isLight = scheme.brightness == Brightness.light;
    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      scaffoldBackgroundColor: background,
      textTheme: AppTypography.textTheme(scheme.brightness),
      fontFamily: AppTypography.fontSans,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: background,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: AppTypography.textTheme(scheme.brightness)
            .headlineMedium!
            .copyWith(color: scheme.onSurface),
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.xl),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isLight ? AppColors.ink900 : AppColors.ink700,
        contentTextStyle: TextStyle(
          fontFamily: AppTypography.fontSans,
          fontWeight: AppTypography.semibold,
          color: AppColors.white,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(AppRadii.xxl)),
        ),
      ),
      splashFactory: InkRipple.splashFactory,
    );
  }
}
