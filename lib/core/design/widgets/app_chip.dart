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

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final (Color bg, Color fg) = switch (tone) {
      AppChipTone.neutral => (c.surfaceSunken, c.textSecondary),
      AppChipTone.brand => (c.brandSoft, c.textBrand),
      AppChipTone.today => (c.todaySoft, c.today),
      AppChipTone.done => (c.doneSoft, c.done),
      AppChipTone.reschedule => (c.rescheduleSoft, c.reschedule),
    };
    final isFilled = selectable ? selected : true;
    final showBorder = selectable && !selected;

    return Semantics(
      button: onTap != null,
      selected: selectable ? selected : null,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: 30,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: isFilled ? bg : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadii.pill),
            border: Border.all(
              color: showBorder ? c.borderDefault : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 15, color: isFilled ? fg : c.textMuted),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  fontFamily: AppTypography.fontSans,
                  fontSize: AppTypography.sizeXs,
                  fontWeight: AppTypography.bold,
                  color: isFilled ? fg : c.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
