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

  testWidgets('press-scale resets to 1.0 when disabled mid-press', (
    tester,
  ) async {
    final enabled = ValueNotifier<bool>(true);
    addTearDown(enabled.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: ValueListenableBuilder<bool>(
              valueListenable: enabled,
              builder: (_, on, _) => AppIconButton(
                icon: AppIcons.settings,
                onPressed: on ? () {} : null,
              ),
            ),
          ),
        ),
      ),
    );

    // Press and hold — do not release.
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(AppIconButton)),
    );
    await tester.pump();
    expect(_scale(tester), 0.9, reason: 'shrinks while pressed');

    // Disable (onPressed -> null) while the finger is still down. The tap
    // recognizer is torn down without firing onTapCancel, so _pressed would
    // otherwise stay stuck true and the icon stay permanently shrunk + dim.
    enabled.value = false;
    await tester.pump();
    expect(
      _scale(tester),
      1.0,
      reason: 'must not stay shrunk after being disabled mid-press',
    );

    await gesture.up();
    await tester.pumpAndSettle();
  });
}

double _scale(WidgetTester tester) => tester
    .widget<AnimatedScale>(
      find.descendant(
        of: find.byType(AppIconButton),
        matching: find.byType(AnimatedScale),
      ),
    )
    .scale;
