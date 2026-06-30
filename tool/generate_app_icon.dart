// Tooling (NOT a unit test): renders the SINTDT brand mark to PNGs used to
// generate the Android launcher icons. Prefer running the orchestrator, which
// also downsamples into res/mipmap-* with ImageMagick:
//
//   tool/generate_app_icon.sh
//
// or just this render step on its own:
//
//   flutter test tool/generate_app_icon.dart
//
// It writes two 1024² PNGs to build/app_icon/ (git-ignored):
//   icon_full.png        — the full gradient tile + sun + tick (legacy icon)
//   icon_foreground.png  — sun + tick only, transparent (adaptive foreground)
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snitd/core/design/widgets/app_brand_mark.dart';

const _outDir = 'build/app_icon';

/// Foreground-only mark for the adaptive icon: the sun + white tick on a
/// transparent field, using the exact coordinates/colours of [AppBrandMark]
/// (which already sit inside the adaptive safe zone), so no tile is baked in —
/// the blue gradient is supplied by the adaptive background instead.
class _ForegroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 96.0;
    canvas.scale(s, s);

    canvas.drawCircle(
      const Offset(74, 22),
      11,
      Paint()..color = const Color(0xFFFFB23E).withValues(alpha: 0.28),
    );
    canvas.drawCircle(
      const Offset(74, 22),
      7,
      Paint()..color = const Color(0xFFFFB23E),
    );

    final tick = Path()
      ..moveTo(26, 49.5)
      ..relativeLineTo(13, 13)
      ..lineTo(70, 31.5);
    canvas.drawPath(
      tick,
      Paint()
        ..color = const Color(0xFFFFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

Future<void> _export(WidgetTester tester, Widget child, String file) async {
  final key = GlobalKey();
  await tester.pumpWidget(
    RepaintBoundary(
      key: key,
      child: SizedBox.square(dimension: 1024, child: child),
    ),
  );
  await tester.pump();
  final boundary =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  late Uint8List bytes;
  await tester.runAsync(() async {
    final image = await boundary.toImage();
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    bytes = data!.buffer.asUint8List();
  });
  Directory(_outDir).createSync(recursive: true);
  File('$_outDir/$file').writeAsBytesSync(bytes);
}

void main() {
  testWidgets('export brand-mark PNGs for the Android launcher icon', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1024, 1024);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await _export(tester, const AppBrandMark(size: 1024), 'icon_full.png');
    await _export(
      tester,
      CustomPaint(painter: _ForegroundPainter()),
      'icon_foreground.png',
    );
  });
}
