import 'package:flutter/material.dart';

import '../tokens/tokens.dart';

/// Pill toggle switch for settings (e.g. Profanity mode).
class AppSwitch extends StatelessWidget {
  const AppSwitch({super.key, required this.value, this.onChanged});

  final bool value;
  final ValueChanged<bool>? onChanged;

  static const double _w = 52;
  static const double _h = 30;
  static const double _knob = 24;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final enabled = onChanged != null;
    return Semantics(
      toggled: value,
      enabled: enabled,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? () => onChanged!(!value) : null,
        // Invisible vertical slack so the touch target is 48 tall, not the
        // 30px pill. Label it by wrapping the host row in MergeSemantics, so a
        // screen reader reads the row's title with the switch's state.
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: (kMinInteractiveDimension - _h) / 2,
          ),
          child: Opacity(
            opacity: enabled ? 1 : 0.5,
            child: AnimatedContainer(
              duration: AppMotion.of(context, AppMotion.normal),
              curve: AppMotion.soft,
              width: _w,
              height: _h,
              decoration: BoxDecoration(
                color: value ? c.brand : c.borderStrong,
                borderRadius: BorderRadius.circular(AppRadii.pill),
              ),
              child: AnimatedAlign(
                duration: AppMotion.of(context, AppMotion.normal),
                curve: AppMotion.spring,
                alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Container(
                    width: _knob,
                    height: _knob,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.white,
                      boxShadow: AppShadows.sm,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
