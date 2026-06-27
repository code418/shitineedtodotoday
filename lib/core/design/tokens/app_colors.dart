import 'package:flutter/painting.dart';

/// SINTDT colour system — raw ramps + semantic aliases, ported verbatim from
/// the design system's `tokens/colors.css`. Reschedule states use a gentle
/// coral, never alarm-red; red is reserved for true errors.
abstract final class AppColors {
  // Brand — indigo-blue.
  static const blue50 = Color(0xFFEEF2FF);
  static const blue100 = Color(0xFFDDE4FF);
  static const blue200 = Color(0xFFBBC8FF);
  static const blue300 = Color(0xFF93A6FF);
  static const blue400 = Color(0xFF6B85FF);
  static const blue500 = Color(0xFF4C6FFF); // brand / seed
  static const blue600 = Color(0xFF3A55E6);
  static const blue700 = Color(0xFF2C41B8);
  static const blue800 = Color(0xFF22338C);
  static const blue900 = Color(0xFF1A2870);

  // Sun — warm amber.
  static const sun200 = Color(0xFFFFE6B0);
  static const sun300 = Color(0xFFFFD27A);
  static const sun400 = Color(0xFFFFC04D);
  static const sun500 = Color(0xFFFFB23E);
  static const sun600 = Color(0xFFF59A1E);

  // Coral — the forgiving "moved it for you" state.
  static const coral200 = Color(0xFFFFD8C8);
  static const coral300 = Color(0xFFFFB59A);
  static const coral400 = Color(0xFFFF9B78);
  static const coral500 = Color(0xFFFF8A5B);
  static const coral600 = Color(0xFFF26B3A);

  // Green — done / completed.
  static const green200 = Color(0xFFC5F2D8);
  static const green300 = Color(0xFF7DE0A8);
  static const green400 = Color(0xFF4FD089);
  static const green500 = Color(0xFF2FBF71);
  static const green600 = Color(0xFF1FA15D);

  // Red — true errors only.
  static const red300 = Color(0xFFF7A8AB);
  static const red400 = Color(0xFFF0696D);
  static const red500 = Color(0xFFE5484D);
  static const red600 = Color(0xFFC93B40);

  // Neutrals — soft indigo-charcoal ink ramp.
  static const ink900 = Color(0xFF1B1D29);
  static const ink800 = Color(0xFF292C3C);
  static const ink700 = Color(0xFF3A3D4D);
  static const ink600 = Color(0xFF565A6E);
  static const ink500 = Color(0xFF757A90);
  static const ink400 = Color(0xFF9AA0B4);
  static const ink300 = Color(0xFFC4C8D6);
  static const ink200 = Color(0xFFE2E5EE);
  static const ink100 = Color(0xFFEEF0F6);
  static const ink50 = Color(0xFFF6F7FB);
  static const white = Color(0xFFFFFFFF);

  // Surfaces.
  static const surfacePage = ink50;
  static const surfaceCard = white;
  static const surfaceSunken = ink100;
  static const surfaceBrand = blue500;
  static const surfaceBrandSoft = blue50;

  // Text.
  static const textPrimary = ink900;
  static const textSecondary = ink600;
  static const textMuted = ink500;
  static const textOnBrand = white;
  static const textBrand = blue600;

  // Brand interaction.
  static const brand = blue500;
  static const brandHover = blue600;
  static const brandPress = blue700;
  static const brandSoft = blue50;
  static const brandSoftHover = blue100;

  // Status.
  static const done = green500;
  static const doneSoft = green200;
  static const reschedule = coral500;
  static const rescheduleSoft = coral200;
  static const today = sun500;
  static const todaySoft = sun200;
  static const error = red500;
  static const errorSoft = red300;

  // Borders.
  static const borderSubtle = ink100;
  static const borderDefault = ink200;
  static const borderStrong = ink300;

  // Focus ring colour (3px outer glow when applied).
  static const focusRing = blue200;
}
