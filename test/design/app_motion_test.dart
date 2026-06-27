// test/design/app_motion_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snitd/core/design/tokens/app_motion.dart';

void main() {
  test('durations and curves match the design system', () {
    expect(AppMotion.normal, const Duration(milliseconds: 200));
    expect(AppMotion.spring, const Cubic(0.34, 1.56, 0.64, 1));
  });

  testWidgets('of() collapses to zero when animations are disabled', (
    tester,
  ) async {
    late Duration resolved;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: Builder(
          builder: (context) {
            resolved = AppMotion.of(context, AppMotion.normal);
            return const SizedBox();
          },
        ),
      ),
    );
    expect(resolved, Duration.zero);
  });
}
