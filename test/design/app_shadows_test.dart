import 'package:flutter_test/flutter_test.dart';
import 'package:snitd/core/design/tokens/app_shadows.dart';

void main() {
  test(
    'card shadow is a soft two-layer stack; brand shadow is blue-tinted',
    () {
      expect(AppShadows.card.length, 2);
      expect((AppShadows.brand.first.color.b * 255.0).round(), 255);
      expect(AppShadows.raised.first.blurRadius, 24);
    },
  );
}
