// lib/core/design/widgets/app_icon_button.dart
import 'package:flutter/material.dart';

import '../tokens/tokens.dart';

enum AppIconButtonTone { normal, brand, onBrand }

/// Round icon control for app-bar actions and inline affordances.
class AppIconButton extends StatefulWidget {
  const AppIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.size = 44,
    this.tone = AppIconButtonTone.normal,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final double size;
  final AppIconButtonTone tone;
  final String? tooltip;

  @override
  State<AppIconButton> createState() => _AppIconButtonState();
}

class _AppIconButtonState extends State<AppIconButton> {
  bool _pressed = false;
  bool _hovering = false;

  ({Color fg, Color bg, Color hover}) _spec(AppPalette c) =>
      switch (widget.tone) {
        AppIconButtonTone.normal => (
          fg: c.textSecondary,
          bg: Colors.transparent,
          hover: c.surfaceSunken,
        ),
        AppIconButtonTone.brand => (
          fg: c.brand,
          bg: c.brandSoft,
          hover: c.brandSoftHover,
        ),
        AppIconButtonTone.onBrand => (
          fg: AppColors.white,
          bg: AppColors.white.withValues(alpha: 0.16),
          hover: AppColors.white.withValues(alpha: 0.28),
        ),
      };

  @override
  Widget build(BuildContext context) {
    final spec = _spec(context.palette);
    final enabled = widget.onPressed != null;
    final button = MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        // Tap the whole circular target, not just the centred icon glyph — a
        // BoxDecoration container defers hit-testing to its child, which would
        // otherwise shrink the touch target to the icon (~half the size).
        behavior: HitTestBehavior.opaque,
        onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
        onTap: widget.onPressed,
        child: AnimatedScale(
          scale: _pressed ? 0.9 : 1,
          duration: AppMotion.of(context, AppMotion.fast),
          curve: AppMotion.spring,
          child: AnimatedContainer(
            duration: AppMotion.of(context, AppMotion.fast),
            curve: AppMotion.soft,
            width: widget.size,
            height: widget.size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _hovering ? spec.hover : spec.bg,
            ),
            child: Opacity(
              opacity: enabled ? 1 : 0.5,
              child: Icon(
                widget.icon,
                size: (widget.size * 0.5).roundToDouble(),
                color: spec.fg,
              ),
            ),
          ),
        ),
      ),
    );
    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.tooltip,
      child: widget.tooltip == null
          ? button
          : Tooltip(message: widget.tooltip!, child: button),
    );
  }
}
