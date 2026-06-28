import 'package:flutter/material.dart';

import '../tokens/tokens.dart';

enum AppBannerTone { info, offline, gentle, error }

/// Soft inline notice strip (offline state, forgiving nudges, info).
class AppBanner extends StatelessWidget {
  const AppBanner({
    super.key,
    required this.message,
    this.tone = AppBannerTone.info,
    this.icon,
    this.action,
  });

  final String message;
  final AppBannerTone tone;
  final IconData? icon;
  final Widget? action;

  ({Color bg, Color fg, IconData icon}) _spec(AppPalette c) => switch (tone) {
    AppBannerTone.info => (
      bg: c.brandSoft,
      fg: c.textBrand,
      icon: AppIcons.info,
    ),
    AppBannerTone.offline => (
      bg: c.surfaceSunken,
      fg: c.textSecondary,
      icon: AppIcons.cloudOff,
    ),
    AppBannerTone.gentle => (
      bg: c.rescheduleSoft,
      fg: c.reschedule,
      icon: AppIcons.favorite,
    ),
    AppBannerTone.error => (
      bg: Color.lerp(c.surfaceCard, c.error, 0.14)!,
      fg: c.error,
      icon: AppIcons.error,
    ),
  };

  @override
  Widget build(BuildContext context) {
    final spec = _spec(context.palette);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: spec.bg,
        borderRadius: BorderRadius.circular(AppRadii.lg),
      ),
      child: Row(
        children: [
          Icon(icon ?? spec.icon, size: 20, color: spec.fg),
          const SizedBox(width: AppSpacing.x3),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontFamily: AppTypography.fontSans,
                fontSize: AppTypography.sizeSm,
                fontWeight: AppTypography.semibold,
                height: AppTypography.leadingSnug,
                color: spec.fg,
              ),
            ),
          ),
          if (action != null) ...[
            const SizedBox(width: AppSpacing.x3),
            action!,
          ],
        ],
      ),
    );
  }
}
