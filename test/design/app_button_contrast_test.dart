import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snitd/app/theme.dart';
import 'package:snitd/core/design/tokens/app_typography.dart';
import 'package:snitd/core/design/widgets/app_button.dart';

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
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

/// WCAG AA target for [style]: 3:1 for "large text" (≥ 24px, or bold from
/// 14pt ≈ 18.67px), otherwise 4.5:1.
double _aaTarget(TextStyle style) {
  final size = style.fontSize!;
  final bold = style.fontWeight!.value >= FontWeight.w700.value;
  return (size >= 24 || (bold && size >= 18.67)) ? 3.0 : 4.5;
}

void main() {
  for (final (name, theme) in [
    ('light', AppTheme.light()),
    ('dark', AppTheme.dark()),
  ]) {
    for (final variant in AppButtonVariant.values) {
      for (final size in AppButtonSize.values) {
        final filled =
            variant == AppButtonVariant.primary ||
            variant == AppButtonVariant.danger;
        // Small filled buttons are rejected by an assert (below).
        if (filled && size == AppButtonSize.sm) continue;

        testWidgets('$name ${variant.name} ${size.name} label meets WCAG AA', (
          tester,
        ) async {
          await tester.pumpWidget(
            MaterialApp(
              theme: theme,
              home: Scaffold(
                body: Center(
                  child: AppButton(
                    label: 'Go',
                    variant: variant,
                    size: size,
                    onPressed: () {},
                  ),
                ),
              ),
            ),
          );
          final style = tester.widget<Text>(find.text('Go')).style!;
          final box = tester.widget<Container>(
            find
                .ancestor(of: find.text('Go'), matching: find.byType(Container))
                .first,
          );
          var background = (box.decoration! as BoxDecoration).color!;
          // A ghost button is see-through: its label sits on the page.
          if (background.a == 0) background = theme.scaffoldBackgroundColor;

          expect(
            _contrast(style.color!, background),
            greaterThanOrEqualTo(_aaTarget(style)),
          );
        });
      }
    }
  }

  test('white-on-fill labels rely on the large-text allowance', () {
    // The md label is sized to count as large text; at the old 17px it didn't,
    // and white on brand (4.18:1 light, 3.27:1 dark) failed 4.5:1.
    expect(AppTypography.button, greaterThanOrEqualTo(18.67));
  });

  test('a small filled button is refused', () {
    for (final variant in [AppButtonVariant.primary, AppButtonVariant.danger]) {
      expect(
        () => AppButton(label: 'Go', variant: variant, size: AppButtonSize.sm),
        throwsAssertionError,
      );
    }
  });
}
