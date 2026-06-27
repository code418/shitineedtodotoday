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
  });

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
    AppButtonSize.md: _SizeSpec(46, 20, AppTypography.title, 18, 8),
    AppButtonSize.lg: _SizeSpec(54, 26, AppTypography.h3, 20, 10),
  };

  static const _variants = {
    AppButtonVariant.primary: _VariantSpec(
      AppColors.brand,
      AppColors.textOnBrand,
      AppShadows.brand,
      null,
    ),
    AppButtonVariant.tonal: _VariantSpec(
      AppColors.brandSoft,
      AppColors.textBrand,
      [],
      null,
    ),
    AppButtonVariant.ghost: _VariantSpec(
      Colors.transparent,
      AppColors.textSecondary,
      [],
      AppColors.borderDefault,
    ),
    AppButtonVariant.danger: _VariantSpec(
      AppColors.error,
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
    final v = AppButton._variants[widget.variant]!;
    final enabled = widget.onPressed != null;

    final content = Row(
      mainAxisSize: widget.block ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.icon != null) ...[
          Icon(widget.icon, size: s.icon, color: v.fg),
          SizedBox(width: s.gap),
        ],
        Text(
          widget.label,
          style: TextStyle(
            fontFamily: AppTypography.fontSans,
            fontSize: s.font,
            fontWeight: AppTypography.bold,
            letterSpacing: -0.34,
            color: v.fg,
          ),
        ),
        if (widget.iconRight != null) ...[
          SizedBox(width: s.gap),
          Icon(widget.iconRight, size: s.icon, color: v.fg),
        ],
      ],
    );

    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      child: Opacity(
        opacity: enabled ? 1 : 0.45,
        child: GestureDetector(
          onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
          onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
          onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
          onTap: widget.onPressed,
          child: AnimatedScale(
            scale: _pressed ? 0.96 : 1,
            duration: AppMotion.of(context, AppMotion.fast),
            curve: AppMotion.spring,
            child: Container(
              height: s.height,
              width: widget.block ? double.infinity : null,
              padding: EdgeInsets.symmetric(horizontal: s.padX),
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
    );
  }
}
