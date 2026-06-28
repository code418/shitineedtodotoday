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
    } else if (toneColor != null) {
      background = Color.lerp(c.surfaceCard, toneColor, 0.14)!;
      foreground = toneColor;
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
