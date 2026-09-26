// lib/core/design/widgets/app_button.dart
import 'package:flutter/material.dart';

import '../tokens/tokens.dart';

enum AppButtonVariant { primary, tonal, ghost, danger }

enum AppButtonSize { sm, md, lg }

class _SizeSpec {
  const _SizeSpec(this.height, this.padX, this.font, this.icon, this.gap);
  final double height;
  final double padX;
  final double font;
  final double icon;
  final double gap;
}

class _VariantSpec {
  const _VariantSpec(this.bg, this.fg, this.shadow, this.border);
  final Color bg;
  final Color fg;
  final List<BoxShadow> shadow;
  final Color? border;
}

/// Friendly, rounded, soft-shadowed call-to-action button.
class AppButton extends StatefulWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.md,
    this.pill = false,
    this.block = false,
    this.icon,
    this.iconRight,
  }) : assert(
         size != AppButtonSize.sm ||
             variant == AppButtonVariant.tonal ||
             variant == AppButtonVariant.ghost,
         'A small button\'s 14px label is too small for white on a filled '
         'background to meet WCAG AA contrast; use tonal/ghost, or md/lg.',
       );

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final bool pill;
  final bool block;
  final IconData? icon;
  final IconData? iconRight;

  static const _sizes = {
    AppButtonSize.sm: _SizeSpec(36, 14, AppTypography.sizeSm, 16, 6),
    AppButtonSize.md: _SizeSpec(46, 20, AppTypography.button, 18, 8),
    AppButtonSize.lg: _SizeSpec(54, 26, AppTypography.h3, 20, 10),
  };

  static _VariantSpec _variantSpec(AppButtonVariant variant, AppPalette c) =>
      switch (variant) {
        AppButtonVariant.primary => _VariantSpec(
          c.brand,
          AppColors.textOnBrand,
          AppShadows.brand,
          null,
        ),
        AppButtonVariant.tonal => _VariantSpec(
          c.brandSoft,
          c.textBrand,
          const [],
          null,
        ),
        AppButtonVariant.ghost => _VariantSpec(
          Colors.transparent,
          c.textSecondary,
          const [],
          c.borderDefault,
        ),
        AppButtonVariant.danger => _VariantSpec(
          c.error,
          AppColors.white,
          AppShadows.danger,
          null,
        ),
      };

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final s = AppButton._sizes[widget.size]!;
    final v = AppButton._variantSpec(widget.variant, context.palette);
    final enabled = widget.onPressed != null;

    final content = Row(
      mainAxisSize: widget.block ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.icon != null) ...[
          Icon(widget.icon, size: s.icon, color: v.fg),
          SizedBox(width: s.gap),
        ],
        // Flexible so a long label at a large system font wraps (and the
        // button grows) instead of overflowing.
        Flexible(
          child: Text(
            widget.label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppTypography.fontSans,
              fontSize: s.font,
              fontWeight: AppTypography.bold,
              letterSpacing: -0.34,
              color: v.fg,
            ),
          ),
        ),
        if (widget.iconRight != null) ...[
          SizedBox(width: s.gap),
          Icon(widget.iconRight, size: s.icon, color: v.fg),
        ],
      ],
    );

    // No explicit `label:` — the inner Text already names the button, and
    // setting both made screen readers say it twice ("Add task, Add task").
    // (Don't swap in excludeSemantics: that would also drop the tap action.)
    return Semantics(
      button: true,
      enabled: enabled,
      child: Opacity(
        opacity: enabled ? 1 : 0.45,
        child: GestureDetector(
          // Make the whole button rect tappable, not just the painted label —
          // a BoxDecoration container defers hit-testing to its child, so
          // without this the horizontal padding (and a block button's empty
          // width) are dead zones.
          behavior: HitTestBehavior.opaque,
          // Track the press unconditionally (the visual is gated on [enabled]
          // below). Gating these on [enabled] would drop every tap callback
          // when the button is disabled mid-press, so GestureDetector tears the
          // recognizer down without an onTapUp/Cancel — leaving _pressed stuck
          // true and the button permanently shrunk + dimmed. Keeping them live
          // lets the press resolve normally when the finger lifts.
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          onTap: widget.onPressed,
          // Invisible vertical slack up to a 48px touch target for the
          // shorter sizes; the painted button keeps its own height.
          child: Padding(
            padding: EdgeInsets.symmetric(
              vertical: s.height >= kMinInteractiveDimension
                  ? 0
                  : (kMinInteractiveDimension - s.height) / 2,
            ),
            child: AnimatedScale(
              // Only show the press-shrink when interactive — a disabled button
              // must not read as pressable, and (with the above) never gets stuck.
              scale: (enabled && _pressed) ? 0.96 : 1,
              duration: AppMotion.of(context, AppMotion.fast),
              curve: AppMotion.spring,
              child: Container(
                // A minimum, not a fixed height: a wrapped label grows it.
                constraints: BoxConstraints(minHeight: s.height),
                width: widget.block ? double.infinity : null,
                padding: EdgeInsets.symmetric(
                  horizontal: s.padX,
                  vertical: AppSpacing.x1,
                ),
                decoration: BoxDecoration(
                  color: v.bg,
                  borderRadius: BorderRadius.circular(
                    widget.pill ? AppRadii.pill : AppRadii.md,
                  ),
                  boxShadow: enabled ? v.shadow : const [],
                  border: v.border == null
                      ? null
                      : Border.all(color: v.border!, width: 1),
                ),
                child: content,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
