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
    this.minutesNote,
    this.onMinutesTap,
    this.minutesTapLabel,
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

  /// Appended to the time badge, e.g. "est." for a time filled in for the
  /// user rather than reported.
  final String? minutesNote;

  /// Makes the time badge tappable (e.g. to correct a logged time), with
  /// [minutesTapLabel] as its screen-reader name.
  final VoidCallback? onMinutesTap;
  final String? minutesTapLabel;

  static const double _pad = 16;
  static const double _padV = 14;

  Widget _timeBadge() {
    final badge = AppBadge(
      label: minutesNote == null
          ? '~${minutes}m'
          : '~${minutes}m · $minutesNote',
      tone: done ? AppBadgeTone.done : null,
    );
    if (onMinutesTap == null) return badge;
    return Semantics(
      button: true,
      label: minutesTapLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onMinutesTap,
        // A full 48dp touch target around the small badge.
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: kMinInteractiveDimension,
            minHeight: kMinInteractiveDimension,
          ),
          child: Align(widthFactor: 1, heightFactor: 1, child: badge),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final container = Container(
      // The left edge + vertical padding belong to the checkbox's touch target
      // (below), so the tick is easy to hit without moving anything visually.
      padding: const EdgeInsets.only(right: _pad),
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
            // Name the tick-box for screen readers ("Wipe the counters,
            // checkbox, not checked") — otherwise it's an anonymous control.
            semanticLabel: title,
            padding: const EdgeInsets.fromLTRB(
              _pad,
              _padV,
              AppSpacing.x3,
              _padV,
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: _padV),
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
          ),
          if (minutes != null) ...[
            const SizedBox(width: AppSpacing.x2),
            _timeBadge(),
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
