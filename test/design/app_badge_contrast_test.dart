import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snitd/app/theme.dart';
import 'package:snitd/core/design/widgets/app_badge.dart';

/// WCAG 2.1 relative luminance of a single 8-bit sRGB channel.
double _channel(int v) {
  final c = v / 255.0;
  return c <= 0.03928
      ? c / 12.92
      : math.pow((c + 0.055) / 1.055, 2.4).toDouble();
}

double _luminance(Color c) =>
    0.2126 * _channel((c.r * 255).round()) +
    0.7152 * _channel((c.g * 255).round()) +
    0.0722 * _channel((c.b * 255).round());

double _contrast(Color a, Color b) {
  final la = _luminance(a);
  final lb = _luminance(b);
  final hi = math.max(la, lb);
  final lo = math.min(la, lb);
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  // Badge text is mono/medium at 12px — below the WCAG "large text" threshold,
  // so the normal-text AA target (4.5:1) applies.
  const aa = 4.5;

  /// Pumps a soft AppBadge and returns its rendered (foreground, background).
  Future<(Color, Color)> render(
    WidgetTester tester,
    ThemeData theme,
    AppBadgeTone? tone,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Scaffold(
          body: Center(
            child: AppBadge(label: '~15m', tone: tone),
          ),
        ),
      ),
    );
    final text = tester.widget<Text>(find.text('~15m'));
    final container = tester.widget<Container>(
      find.ancestor(of: find.text('~15m'), matching: find.byType(Container)),
    );
    final fg = text.style!.color!;
    final bg = (container.decoration! as BoxDecoration).color!;
    return (fg, bg);
  }

  for (final (name, theme) in [
    ('light', AppTheme.light()),
    ('dark', AppTheme.dark()),
  ]) {
    group('soft AppBadge tones meet WCAG AA in $name mode', () {
      for (final tone in AppBadgeTone.values) {
        testWidgets('${tone.name}: label on its tint is >= 4.5:1', (
          tester,
        ) async {
          final (fg, bg) = await render(tester, theme, tone);
          final ratio = _contrast(fg, bg);
          expect(
            ratio,
            greaterThanOrEqualTo(aa),
            reason:
                '$name ${tone.name} badge contrast is '
                '${ratio.toStringAsFixed(2)}:1, below AA ($aa:1)',
          );
        });
      }

      testWidgets('untoned (default) label is legible', (tester) async {
        final (fg, bg) = await render(tester, theme, null);
        expect(_contrast(fg, bg), greaterThanOrEqualTo(aa));
      });
    });
  }
}
