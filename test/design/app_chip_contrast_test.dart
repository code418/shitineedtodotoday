import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:snitd/core/design/tokens/app_palette.dart';

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

/// WCAG contrast ratio between two opaque colours (1..21).
double _contrast(Color a, Color b) {
  final la = _luminance(a);
  final lb = _luminance(b);
  final hi = math.max(la, lb);
  final lo = math.min(la, lb);
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  // Chip labels are bold but 12px — below the 14px-bold WCAG "large text"
  // threshold — so the AA target for normal text (4.5:1) applies.
  const aa = 4.5;

  /// Every (background, foreground) pair AppChip actually renders, per tone.
  List<(String, Color, Color)> pairs(AppPalette p) => [
    ('neutral', p.surfaceSunken, p.textSecondary),
    ('brand', p.brandSoft, p.textBrand),
    ('today', p.todaySoft, p.onTodaySoft),
    ('done', p.doneSoft, p.onDoneSoft),
    ('reschedule', p.rescheduleSoft, p.onRescheduleSoft),
  ];

  for (final (name, palette) in [
    ('light', AppPalette.light),
    ('dark', AppPalette.dark),
  ]) {
    group('AppChip tones meet WCAG AA in $name mode', () {
      for (final (tone, bg, fg) in pairs(palette)) {
        test('$tone: label on its tint is >= 4.5:1', () {
          final ratio = _contrast(fg, bg);
          expect(
            ratio,
            greaterThanOrEqualTo(aa),
            reason:
                '$name $tone chip contrast is '
                '${ratio.toStringAsFixed(2)}:1, below AA ($aa:1)',
          );
        });
      }
    });
  }

  test('the status on-tint role is NOT the mid accent in light mode', () {
    // Guards the regression directly: reverting onTodaySoft back to the accent
    // (`today`) is exactly what put contrast at ~1.5:1. The accent-on-tint pair
    // must fail AA — proving the dedicated role is doing the work.
    const p = AppPalette.light;
    expect(p.onTodaySoft, isNot(p.today));
    expect(_contrast(p.today, p.todaySoft), lessThan(aa));
    expect(_contrast(p.onTodaySoft, p.todaySoft), greaterThanOrEqualTo(aa));
  });
}
