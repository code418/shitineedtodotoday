import 'package:flutter/material.dart';

import '../tokens/tokens.dart';

enum AppBadgeTone { done, today, reschedule, brand }

/// Mono duration / count pill (e.g. "~15m", "55m budget").
class AppBadge extends StatelessWidget {
  const AppBadge({super.key, required this.label, this.tone, this.soft = true});

  final String label;
  final AppBadgeTone? tone;
  final bool soft;

  static const _toneColors = {
    AppBadgeTone.done: AppColors.done,
    AppBadgeTone.today: AppColors.today,
    AppBadgeTone.reschedule: AppColors.reschedule,
    AppBadgeTone.brand: AppColors.brand,
  };

  @override
  Widget build(BuildContext context) {
    final toneColor = tone == null ? null : _toneColors[tone];
    final Color background;
    final Color foreground;
    if (!soft) {
      background = toneColor ?? AppColors.ink500;
      foreground = AppColors.white;
    } else if (toneColor != null) {
      background = Color.lerp(AppColors.white, toneColor, 0.14)!;
      foreground = toneColor;
    } else {
      background = AppColors.ink100;
      foreground = AppColors.ink600;
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
