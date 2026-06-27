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
    final height = small ? 34.0 : 40.0;
    return Container(
      height: height,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.ink100,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final seg in segments)
            Semantics(
              button: true,
              selected: seg.value == value,
              label: seg.label,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onChanged(seg.value),
                child: AnimatedContainer(
                  duration: AppMotion.of(context, AppMotion.fast),
                  curve: AppMotion.soft,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: seg.value == value
                        ? AppColors.surfaceCard
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                    boxShadow: seg.value == value ? AppShadows.sm : const [],
                  ),
                  child: Text(
                    seg.label,
                    style: TextStyle(
                      fontFamily: AppTypography.fontSans,
                      fontSize: small
                          ? AppTypography.sizeXs
                          : AppTypography.sizeSm,
                      fontWeight: AppTypography.bold,
                      color: seg.value == value
                          ? AppColors.textPrimary
                          : AppColors.textMuted,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
