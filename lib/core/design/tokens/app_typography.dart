// lib/core/design/tokens/app_typography.dart
import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Nunito for UI + display; JetBrains Mono for durations and counts.
/// Sentence case, generous line-height, tight tracking on large sizes.
abstract final class AppTypography {
  static const String fontSans = 'Nunito';
  static const String fontMono = 'JetBrains Mono';

  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w600;
  static const FontWeight semibold = FontWeight.w700;
  static const FontWeight bold = FontWeight.w800;
  static const FontWeight black = FontWeight.w900;

  // Type scale (logical px).
  static const double display = 40;
  static const double h1 = 30;
  static const double h2 = 24;
  static const double h3 = 20;
  static const double title = 17;
  static const double body = 16;
  static const double sizeSm = 14;
  static const double sizeXs = 13;
  static const double size2xs = 11;

  static const double leadingTight = 1.15;
  static const double leadingSnug = 1.3;
  static const double leadingNormal = 1.5;

  static const double trackingTight = -0.02 * 16; // applied as letterSpacing px
  static const double trackingCaps = 0.08 * 11;

  /// Material [TextTheme] mapped onto the SINTDT scale.
  static TextTheme textTheme(Brightness brightness) {
    final primary = brightness == Brightness.light
        ? AppColors.textPrimary
        : AppColors.ink50;
    final secondary = brightness == Brightness.light
        ? AppColors.textSecondary
        : AppColors.ink300;

    TextStyle sans(
      double size,
      FontWeight weight, {
      double height = leadingNormal,
      double? spacing,
      Color? color,
    }) => TextStyle(
      fontFamily: fontSans,
      fontSize: size,
      fontWeight: weight,
      height: height,
      letterSpacing: spacing,
      color: color ?? primary,
    );

    return TextTheme(
      displayLarge: sans(
        display,
        bold,
        height: leadingTight,
        spacing: trackingTight,
      ),
      headlineLarge: sans(
        h1,
        bold,
        height: leadingSnug,
        spacing: trackingTight,
      ),
      headlineMedium: sans(h2, bold, height: leadingSnug),
      titleLarge: sans(h3, bold, height: leadingSnug),
      titleMedium: sans(title, bold, height: leadingSnug),
      bodyLarge: sans(body, regular),
      bodyMedium: sans(sizeSm, regular, color: secondary),
      bodySmall: sans(sizeXs, regular, color: secondary),
      labelLarge: sans(title, bold), // buttons
      labelMedium: sans(sizeXs, semibold, color: secondary),
      labelSmall: sans(
        size2xs,
        semibold,
        height: leadingNormal,
        spacing: trackingCaps,
        color: secondary,
      ),
    );
  }

  /// Mono style for durations / counts (e.g. "~15m", "55m / 55m").
  static TextStyle mono({
    double size = sizeXs,
    FontWeight weight = medium,
    Color color = AppColors.textSecondary,
  }) => TextStyle(
    fontFamily: fontMono,
    fontSize: size,
    fontWeight: weight,
    color: color,
    letterSpacing: -0.13,
  );
}
