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

  ({Color bg, Color fg, IconData icon}) get _spec => switch (tone) {
    AppBannerTone.info => (
      bg: AppColors.brandSoft,
      fg: AppColors.textBrand,
      icon: AppIcons.info,
    ),
    AppBannerTone.offline => (
      bg: AppColors.ink100,
      fg: AppColors.ink600,
      icon: AppIcons.cloudOff,
    ),
    AppBannerTone.gentle => (
      bg: AppColors.rescheduleSoft,
      fg: AppColors.coral600,
      icon: AppIcons.favorite,
    ),
    AppBannerTone.error => (
      bg: Color.lerp(AppColors.white, AppColors.error, 0.14)!,
      fg: AppColors.red600,
      icon: AppIcons.error,
    ),
  };

  @override
  Widget build(BuildContext context) {
    final spec = _spec;
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
