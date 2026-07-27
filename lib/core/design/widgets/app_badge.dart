import 'package:flutter/material.dart';

import '../tokens/tokens.dart';

enum AppBadgeTone { done, today, reschedule, brand }

/// Mono duration / count pill (e.g. "~15m", "55m budget").
class AppBadge extends StatelessWidget {
  const AppBadge({super.key, required this.label, this.tone, this.soft = true});

  final String label;
  final AppBadgeTone? tone;
  final bool soft;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final toneColor = switch (tone) {
      AppBadgeTone.done => c.done,
      AppBadgeTone.today => c.today,
      AppBadgeTone.reschedule => c.reschedule,
      AppBadgeTone.brand => c.brand,
      null => null,
    };
    final Color background;
    final Color foreground;
    if (!soft) {
      background = toneColor ?? c.textMuted;
      foreground = AppColors.white;
    } else if (tone != null) {
      // Foreground is a dedicated on-tint role, not the accent itself: the mid
      // accent on its own soft tint fails WCAG AA in light mode (the done pill
      // was ~2.1:1). Mirrors AppChip — brand keeps the darker textBrand, status
      // tones use the on-soft roles (dark ink in light, lightened accent in
      // dark). See AppPalette.onDoneSoft.
      background = Color.lerp(c.surfaceCard, toneColor!, 0.14)!;
      foreground = switch (tone!) {
        AppBadgeTone.brand => c.textBrand,
        AppBadgeTone.done => c.onDoneSoft,
        AppBadgeTone.today => c.onTodaySoft,
        AppBadgeTone.reschedule => c.onRescheduleSoft,
      };
    } else {
      background = c.surfaceSunken;
      foreground = c.textSecondary;
    }

    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 9),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Text(
        label,
        style: AppTypography.mono(
          size: AppTypography.sizeXs,
          weight: AppTypography.medium,
          color: foreground,
        ),
      ),
    );
  }
}
