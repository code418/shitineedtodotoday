// lib/core/design/widgets/app_progress_meter.dart
import 'package:flutter/material.dart';

import '../tokens/tokens.dart';

/// Daily-load bar against a forgiving budget. Fills brand-blue, tips to coral
/// when over — a gentle nudge, never an alarm.
class AppProgressMeter extends StatelessWidget {
  const AppProgressMeter({
    super.key,
    required this.value,
    required this.max,
    this.label,
    this.showValue = true,
    this.unit = 'm',
    this.height = 10,
  });

  final double value;
  final double max;
  final String? label;
  final bool showValue;
  final String unit;
  final double height;

  String _fmt(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();

  @override
  Widget build(BuildContext context) {
    final factor = max <= 0 ? 0.0 : (value / max).clamp(0.0, 1.0);
    final over = value > max;
    final fill = over ? AppColors.reschedule : AppColors.brand;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null || showValue)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (label != null)
                  Text(
                    label!,
                    style: TextStyle(
                      fontFamily: AppTypography.fontSans,
                      fontSize: AppTypography.sizeSm,
                      fontWeight: AppTypography.bold,
                      color: AppColors.textSecondary,
                    ),
                  )
                else
                  const SizedBox.shrink(),
                if (showValue)
                  Text(
                    '${_fmt(value)}$unit / ${_fmt(max)}$unit',
                    style: AppTypography.mono(
                      size: AppTypography.sizeXs,
                      color: over ? AppColors.coral600 : AppColors.textMuted,
                    ),
                  ),
              ],
            ),
          ),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadii.pill),
          child: Container(
            height: height,
            color: AppColors.ink200,
            child: Align(
              alignment: Alignment.centerLeft,
              child: LayoutBuilder(
                builder: (context, constraints) => AnimatedContainer(
                  key: const Key('appProgressMeterFill'),
                  duration: AppMotion.of(context, AppMotion.slow),
                  curve: AppMotion.easeOut,
                  width: constraints.maxWidth * factor,
                  height: height,
                  decoration: BoxDecoration(
                    color: fill,
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
