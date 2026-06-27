import 'package:flutter_test/flutter_test.dart';
import 'package:snitd/core/design/tokens/app_spacing.dart';

void main() {
  test('spacing follows the 4px grid', () {
    expect(AppSpacing.x4, 16.0);
    expect(AppSpacing.x7, 32.0);
    expect(AppSpacing.x11, 80.0);
  });
  test('radii and layout constants match the design system', () {
    expect(AppRadii.lg, 18.0);
    expect(AppRadii.xl, 24.0);
    expect(AppRadii.pill, 999.0);
    expect(AppLayout.tapMin, 48.0);
    expect(AppLayout.contentMax, 480.0);
  });
}
