// test/design/app_icon_button_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snitd/core/design/tokens/app_icons.dart';
import 'package:snitd/core/design/widgets/app_icon_button.dart';

void main() {
  testWidgets('fires onPressed', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppIconButton(
            icon: AppIcons.settings,
            tooltip: 'Settings',
            onPressed: () => taps++,
          ),
        ),
      ),
    );
    await tester.tap(find.byType(AppIconButton));
    expect(taps, 1);
  });

  testWidgets('whole circular target is tappable, not just the icon glyph', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: AppIconButton(
              icon: AppIcons.settings,
              tooltip: 'Settings',
              onPressed: () => taps++,
            ),
          ),
        ),
      ),
    );

    final rect = tester.getRect(find.byType(AppIconButton));
    // Tap near the edge of the 44px target — outside the ~22px centred icon.
    await tester.tapAt(Offset(rect.left + 3, rect.center.dy));
    await tester.pumpAndSettle();
    expect(taps, 1);
  });
}
