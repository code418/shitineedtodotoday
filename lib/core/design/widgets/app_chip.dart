import 'package:flutter/material.dart';

import '../tokens/tokens.dart';

enum AppChipTone { neutral, brand, today, done, reschedule }

/// Small rounded pill for categories, themed days and filters.
class AppChip extends StatelessWidget {
  const AppChip({
    super.key,
    required this.label,
    this.tone = AppChipTone.neutral,
    this.icon,
    this.selected = false,
    this.selectable = false,
    this.onTap,
  });

  final String label;
  final AppChipTone tone;
  final IconData? icon;
  final bool selected;
  final bool selectable;
  final VoidCallback? onTap;

  static const _fills = {
    AppChipTone.neutral: (AppColors.ink100, AppColors.ink600),
    AppChipTone.brand: (AppColors.brandSoft, AppColors.textBrand),
    AppChipTone.today: (AppColors.todaySoft, AppColors.sun600),
    AppChipTone.done: (AppColors.doneSoft, AppColors.green600),
    AppChipTone.reschedule: (AppColors.rescheduleSoft, AppColors.coral600),
  };

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = _fills[tone]!;
    final isFilled = selectable ? selected : true;
    final showBorder = selectable && !selected;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isFilled ? bg : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadii.pill),
          border: Border.all(
            color: showBorder ? AppColors.borderDefault : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 15, color: isFilled ? fg : AppColors.textMuted),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontFamily: AppTypography.fontSans,
                fontSize: AppTypography.sizeXs,
                fontWeight: AppTypography.bold,
                color: isFilled ? fg : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
