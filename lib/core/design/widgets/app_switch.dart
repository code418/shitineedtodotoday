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
    final enabled = onChanged != null;
    return Semantics(
      toggled: value,
      enabled: enabled,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? () => onChanged!(!value) : null,
        child: Opacity(
          opacity: enabled ? 1 : 0.5,
          child: AnimatedContainer(
            duration: AppMotion.of(context, AppMotion.normal),
            curve: AppMotion.soft,
            width: _w,
            height: _h,
            decoration: BoxDecoration(
              color: value ? AppColors.brand : AppColors.ink300,
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
    );
  }
}
