import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Brightness-aware semantic colours.
///
/// [AppColors] holds the raw ramps + the light-mode aliases (kept for the many
/// fixed accent/on-accent uses). The *semantic surface / text / border / soft
/// tint* roles, which must differ between light and dark, live here as a
/// [ThemeExtension] so widgets resolve them from the active theme:
///
/// ```dart
/// final c = context.palette;
/// color: c.surfaceCard, // white in light, dark ink in dark
/// ```
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.surfacePage,
    required this.surfaceCard,
    required this.surfaceSunken,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.textBrand,
    required this.borderSubtle,
    required this.borderDefault,
    required this.borderStrong,
    required this.brand,
    required this.brandSoft,
    required this.brandSoftHover,
    required this.done,
    required this.doneSoft,
    required this.today,
    required this.todaySoft,
    required this.reschedule,
    required this.rescheduleSoft,
    required this.error,
  });

  final Color surfacePage;
  final Color surfaceCard;
  final Color surfaceSunken;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color textBrand;
  final Color borderSubtle;
  final Color borderDefault;
  final Color borderStrong;
  final Color brand;
  final Color brandSoft;
  final Color brandSoftHover;
  final Color done;
  final Color doneSoft;
  final Color today;
  final Color todaySoft;
  final Color reschedule;
  final Color rescheduleSoft;
  final Color error;

  /// Light mode — mirrors the existing [AppColors] semantic aliases exactly, so
  /// light rendering is unchanged by the migration.
  static const light = AppPalette(
    surfacePage: AppColors.ink50,
    surfaceCard: AppColors.white,
    surfaceSunken: AppColors.ink100,
    textPrimary: AppColors.ink900,
    textSecondary: AppColors.ink600,
    textMuted: AppColors.ink500,
    textBrand: AppColors.blue600,
    borderSubtle: AppColors.ink100,
    borderDefault: AppColors.ink200,
    borderStrong: AppColors.ink300,
    brand: AppColors.blue500,
    brandSoft: AppColors.blue50,
    brandSoftHover: AppColors.blue100,
    done: AppColors.green500,
    doneSoft: AppColors.green200,
    today: AppColors.sun500,
    todaySoft: AppColors.sun200,
    reschedule: AppColors.coral500,
    rescheduleSoft: AppColors.coral200,
    error: AppColors.red500,
  );

  /// Dark mode — dark ink surfaces, light text, lightened accents, and "soft"
  /// tints rebuilt as low-mix overlays on the dark base (the light tints are
  /// pale-on-white; their dark counterparts are subtle-on-ink).
  static final dark = AppPalette(
    surfacePage: AppColors.ink900,
    surfaceCard: AppColors.ink800,
    surfaceSunken: AppColors.ink700,
    textPrimary: AppColors.ink50,
    textSecondary: AppColors.ink300,
    textMuted: AppColors.ink400,
    textBrand: AppColors.blue300,
    borderSubtle: AppColors.ink800,
    borderDefault: AppColors.ink700,
    borderStrong: AppColors.ink600,
    brand: AppColors.blue400,
    brandSoft: Color.lerp(AppColors.ink900, AppColors.blue500, 0.28)!,
    brandSoftHover: Color.lerp(AppColors.ink900, AppColors.blue500, 0.40)!,
    done: AppColors.green400,
    doneSoft: Color.lerp(AppColors.ink900, AppColors.green500, 0.24)!,
    today: AppColors.sun400,
    todaySoft: Color.lerp(AppColors.ink900, AppColors.sun500, 0.24)!,
    reschedule: AppColors.coral400,
    rescheduleSoft: Color.lerp(AppColors.ink900, AppColors.coral500, 0.24)!,
    error: AppColors.red400,
  );

  @override
  AppPalette copyWith({
    Color? surfacePage,
    Color? surfaceCard,
    Color? surfaceSunken,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? textBrand,
    Color? borderSubtle,
    Color? borderDefault,
    Color? borderStrong,
    Color? brand,
    Color? brandSoft,
    Color? brandSoftHover,
    Color? done,
    Color? doneSoft,
    Color? today,
    Color? todaySoft,
    Color? reschedule,
    Color? rescheduleSoft,
    Color? error,
  }) => AppPalette(
    surfacePage: surfacePage ?? this.surfacePage,
    surfaceCard: surfaceCard ?? this.surfaceCard,
    surfaceSunken: surfaceSunken ?? this.surfaceSunken,
    textPrimary: textPrimary ?? this.textPrimary,
    textSecondary: textSecondary ?? this.textSecondary,
    textMuted: textMuted ?? this.textMuted,
    textBrand: textBrand ?? this.textBrand,
    borderSubtle: borderSubtle ?? this.borderSubtle,
    borderDefault: borderDefault ?? this.borderDefault,
    borderStrong: borderStrong ?? this.borderStrong,
    brand: brand ?? this.brand,
    brandSoft: brandSoft ?? this.brandSoft,
    brandSoftHover: brandSoftHover ?? this.brandSoftHover,
    done: done ?? this.done,
    doneSoft: doneSoft ?? this.doneSoft,
    today: today ?? this.today,
    todaySoft: todaySoft ?? this.todaySoft,
    reschedule: reschedule ?? this.reschedule,
    rescheduleSoft: rescheduleSoft ?? this.rescheduleSoft,
    error: error ?? this.error,
  );

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      surfacePage: Color.lerp(surfacePage, other.surfacePage, t)!,
      surfaceCard: Color.lerp(surfaceCard, other.surfaceCard, t)!,
      surfaceSunken: Color.lerp(surfaceSunken, other.surfaceSunken, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      textBrand: Color.lerp(textBrand, other.textBrand, t)!,
      borderSubtle: Color.lerp(borderSubtle, other.borderSubtle, t)!,
      borderDefault: Color.lerp(borderDefault, other.borderDefault, t)!,
      borderStrong: Color.lerp(borderStrong, other.borderStrong, t)!,
      brand: Color.lerp(brand, other.brand, t)!,
      brandSoft: Color.lerp(brandSoft, other.brandSoft, t)!,
      brandSoftHover: Color.lerp(brandSoftHover, other.brandSoftHover, t)!,
      done: Color.lerp(done, other.done, t)!,
      doneSoft: Color.lerp(doneSoft, other.doneSoft, t)!,
      today: Color.lerp(today, other.today, t)!,
      todaySoft: Color.lerp(todaySoft, other.todaySoft, t)!,
      reschedule: Color.lerp(reschedule, other.reschedule, t)!,
      rescheduleSoft: Color.lerp(rescheduleSoft, other.rescheduleSoft, t)!,
      error: Color.lerp(error, other.error, t)!,
    );
  }
}

/// Ergonomic access: `context.palette.surfaceCard`.
extension AppPaletteX on BuildContext {
  AppPalette get palette =>
      Theme.of(this).extension<AppPalette>() ?? AppPalette.light;
}
