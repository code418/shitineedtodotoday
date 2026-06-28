import 'package:flutter/material.dart';

import '../../../../core/design/design.dart';

/// The signature SINTDT chore row: round tick, time estimate, category, and —
/// when the forgiving scheduler moved it — a gentle coral "moved from…" note.
/// Completed rows soften and strike through; nothing is ever shamed in red.
class AppTaskItem extends StatelessWidget {
  const AppTaskItem({
    super.key,
    required this.title,
    this.minutes,
    this.category,
    this.done = false,
    this.movedFrom,
    this.onToggle,
    this.onTap,
  });

  final String title;
  final int? minutes;
  final String? category;
  final bool done;
  final String? movedFrom;
  final ValueChanged<bool>? onToggle;

  /// Called when the user taps the row body (outside the checkbox). When null
  /// the row is not tappable and no [GestureDetector] is inserted.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final container = Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: c.surfaceCard,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          AppCheckbox(
            value: done,
            onChanged: onToggle == null ? null : (v) => onToggle!(v),
          ),
          const SizedBox(width: AppSpacing.x3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: AppTypography.fontSans,
                    fontSize: AppTypography.title,
                    fontWeight: AppTypography.bold,
                    color: c.textPrimary,
                    decoration: done
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                    decorationColor: c.textMuted,
                  ),
                ),
                if (category != null || movedFrom != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Row(
                      children: [
                        if (category != null)
                          Text(
                            category!,
                            style: TextStyle(
                              fontFamily: AppTypography.fontSans,
                              fontSize: AppTypography.sizeXs,
                              fontWeight: AppTypography.semibold,
                              color: c.textMuted,
                            ),
                          ),
                        if (category != null && movedFrom != null)
                          const SizedBox(width: 8),
                        if (movedFrom != null)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                AppIcons.eventRepeat,
                                size: 14,
                                color: c.reschedule,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                'moved from $movedFrom',
                                style: TextStyle(
                                  fontFamily: AppTypography.fontSans,
                                  fontSize: AppTypography.sizeXs,
                                  fontWeight: AppTypography.semibold,
                                  color: c.reschedule,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          if (minutes != null) ...[
            const SizedBox(width: AppSpacing.x2),
            AppBadge(
              label: '~${minutes}m',
              tone: done ? AppBadgeTone.done : null,
            ),
          ],
        ],
      ),
    );

    final inner = onTap != null
        ? GestureDetector(
            onTap: onTap,
            behavior: HitTestBehavior.opaque,
            child: container,
          )
        : container;

    return AnimatedOpacity(
      duration: AppMotion.of(context, AppMotion.normal),
      curve: AppMotion.soft,
      opacity: done ? 0.62 : 1,
      child: inner,
    );
  }
}
