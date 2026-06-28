import 'package:flutter/material.dart';

import '../tokens/tokens.dart';

/// Round, friendly tick-box — the core gesture of completing a chore.
class AppCheckbox extends StatelessWidget {
  const AppCheckbox({
    super.key,
    required this.value,
    this.onChanged,
    this.size = 26,
    this.color,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final fill = color ?? c.done;
    final enabled = onChanged != null;
    return Semantics(
      checked: value,
      enabled: enabled,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? () => onChanged!(!value) : null,
        child: Opacity(
          opacity: enabled ? 1 : 0.5,
          child: AnimatedContainer(
            duration: AppMotion.of(context, AppMotion.normal),
            curve: AppMotion.spring,
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: value ? fill : c.surfaceCard,
              border: Border.all(
                color: value ? fill : c.borderStrong,
                width: 2,
              ),
            ),
            child: AnimatedScale(
              duration: AppMotion.of(context, AppMotion.normal),
              curve: AppMotion.spring,
              scale: value ? 1 : 0,
              child: Icon(
                AppIcons.check,
                size: size * 0.66,
                color: AppColors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
