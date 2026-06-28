// test/design/app_icon_button_test.dart
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snitd/core/design/tokens/app_colors.dart';
import 'package:snitd/core/design/tokens/app_icons.dart';
import 'package:snitd/core/design/widgets/app_icon_button.dart';

/// The current circle-fill colour of the (single) icon button on screen.
Color _bgColor(WidgetTester tester) {
  final container = tester.widget<AnimatedContainer>(
    find.descendant(
      of: find.byType(AppIconButton),
      matching: find.byType(AnimatedContainer),
    ),
  );
  return (container.decoration! as BoxDecoration).color!;
}

Future<void> _hoverCentre(WidgetTester tester) async {
  final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
  await gesture.addPointer(location: Offset.zero);
  addTearDown(gesture.removePointer);
  await tester.pump();
  await gesture.moveTo(tester.getCenter(find.byType(AppIconButton)));
  await tester.pumpAndSettle();
}

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

  testWidgets('a disabled button does not paint a hover background', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: AppIconButton(
              icon: AppIcons.settings,
              tone: AppIconButtonTone.brand,
              onPressed: null, // disabled
            ),
          ),
        ),
      ),
    );

    await _hoverCentre(tester);

    // Stays at the resting brand fill, not the hover fill.
    expect(_bgColor(tester), AppColors.brandSoft);
    expect(_bgColor(tester), isNot(AppColors.brandSoftHover));
  });

  testWidgets('an enabled button still paints a hover background', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: AppIconButton(
              icon: AppIcons.settings,
              tone: AppIconButtonTone.brand,
              onPressed: () {},
            ),
          ),
        ),
      ),
    );

    await _hoverCentre(tester);

    expect(_bgColor(tester), AppColors.brandSoftHover);
  });
}
