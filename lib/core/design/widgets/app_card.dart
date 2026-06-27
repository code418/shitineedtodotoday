import 'package:flutter/material.dart';

import '../tokens/tokens.dart';

/// Soft, rounded white surface container. `interactive` lifts on hover.
class AppCard extends StatefulWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.interactive = false,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final bool interactive;
  final VoidCallback? onTap;

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final lifted = widget.interactive && _hovering;
    final card = AnimatedContainer(
      duration: AppMotion.of(context, AppMotion.normal),
      curve: AppMotion.soft,
      transform: Matrix4.translationValues(0, lifted ? -2 : 0, 0),
      padding: widget.padding ?? const EdgeInsets.all(AppSpacing.x5),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(AppRadii.xl),
        boxShadow: lifted ? AppShadows.raised : AppShadows.card,
      ),
      child: widget.child,
    );

    if (!widget.interactive && widget.onTap == null) return card;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      cursor: widget.onTap != null
          ? SystemMouseCursors.click
          : MouseCursor.defer,
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: card,
      ),
    );
  }
}
