import 'package:flutter/material.dart';

import '../tokens/tokens.dart';

class AppSegment<T> {
  const AppSegment({required this.value, required this.label});
  final T value;
  final String label;
}

/// Pill-tracked tab switch for periods & filters (Week / Month / Year).
class AppSegmentedControl<T> extends StatelessWidget {
  const AppSegmentedControl({
    super.key,
    required this.segments,
    required this.value,
    required this.onChanged,
    this.small = false,
  });

  final List<AppSegment<T>> segments;
  final T value;
  final ValueChanged<T> onChanged;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final height = small ? 34.0 : 40.0;
    const inset = 3.0;
    // The track keeps its painted height; each segment's touch target reaches
    // (invisibly) above and below it to a full 48px.
    final target = height >= kMinInteractiveDimension
        ? height
        : kMinInteractiveDimension;
    final slack = (target - height) / 2;
    return SizedBox(
      height: target,
      child: Stack(
        children: [
          Positioned.fill(
            top: slack,
            bottom: slack,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: c.surfaceSunken,
                borderRadius: BorderRadius.circular(AppRadii.pill),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: inset),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final seg in segments)
                  // Named by its Text; an explicit label as well was read
                  // twice ("Week, Week").
                  Flexible(
                    child: Semantics(
                      button: true,
                      selected: seg.value == value,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => onChanged(seg.value),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: slack + inset,
                          ),
                          child: AnimatedContainer(
                            duration: AppMotion.of(context, AppMotion.fast),
                            curve: AppMotion.soft,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: seg.value == value
                                  ? c.surfaceCard
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(
                                AppRadii.pill,
                              ),
                              boxShadow: seg.value == value
                                  ? AppShadows.sm
                                  : const [],
                            ),
                            // Shrinks only if the segments can't all fit
                            // (a large system font on a narrow phone).
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                seg.label,
                                style: TextStyle(
                                  fontFamily: AppTypography.fontSans,
                                  fontSize: small
                                      ? AppTypography.sizeXs
                                      : AppTypography.sizeSm,
                                  fontWeight: AppTypography.bold,
                                  color: seg.value == value
                                      ? c.textPrimary
                                      : c.textMuted,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
