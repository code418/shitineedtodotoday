import 'package:flutter/material.dart';

import '../tokens/tokens.dart';

/// The SINTDT app mark: a rounded blue tile with a sun and a white tick.
/// Drawn with a [CustomPainter] (no SVG dependency); scales from a 96px design.
class AppBrandMark extends StatelessWidget {
  const AppBrandMark({super.key, this.size = 96});

  final double size;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CustomPaint(painter: _MarkPainter()),
  );
}

class _MarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 96.0;
    canvas.scale(s, s);

    // Tile with the brand gradient.
    final tile = RRect.fromRectAndRadius(
      const Rect.fromLTWH(0, 0, 96, 96),
      const Radius.circular(26),
    );
    final gradient = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [AppColors.blue400, AppColors.blue600],
    ).createShader(const Rect.fromLTWH(14, 8, 68, 80));
    canvas.drawRRect(tile, Paint()..shader = gradient);

    // Sun: soft halo + solid core.
    canvas.drawCircle(
      const Offset(74, 22),
      11,
      Paint()..color = AppColors.sun500.withValues(alpha: 0.28),
    );
    canvas.drawCircle(
      const Offset(74, 22),
      7,
      Paint()..color = AppColors.sun500,
    );

    // Tick.
    final tick = Path()
      ..moveTo(26, 49.5)
      ..relativeLineTo(13, 13)
      ..lineTo(70, 31.5);
    canvas.drawPath(
      tick,
      Paint()
        ..color = AppColors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
