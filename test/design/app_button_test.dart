// test/design/app_button_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snitd/core/design/widgets/app_button.dart';

void main() {
  testWidgets('renders label and fires onPressed', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: AppButton(label: 'Add task', onPressed: () => taps++),
          ),
        ),
      ),
    );
    expect(find.text('Add task'), findsOneWidget);
    await tester.tap(find.byType(AppButton));
    expect(taps, 1);
  });

  testWidgets('disabled when onPressed is null', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: AppButton(label: 'Nope')),
        ),
      ),
    );
    await tester.tap(find.byType(AppButton));
    expect(taps, 0);
  });

  testWidgets('whole button area is tappable, not just the label', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: AppButton(
              label: 'Save',
              block: true,
              onPressed: () => taps++,
            ),
          ),
        ),
      ),
    );

    final rect = tester.getRect(find.byType(AppButton));
    // Tap near the left edge — empty space on a full-width block button, well
    // away from the centred label.
    await tester.tapAt(Offset(rect.left + 4, rect.center.dy));
    await tester.pumpAndSettle();
    expect(taps, 1);
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
              builder: (_, on, _) =>
                  AppButton(label: 'Save', onPressed: on ? () {} : null),
            ),
          ),
        ),
      ),
    );

    // Press and hold — do not release.
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(AppButton)),
    );
    await tester.pump();
    expect(_buttonScale(tester), 0.96, reason: 'shrinks while pressed');

    // Disable (onPressed -> null) while the finger is still down. The tap
    // recognizer is torn down without firing onTapCancel, so _pressed would
    // otherwise stay stuck true and the button stay permanently shrunk + dim.
    enabled.value = false;
    await tester.pump();
    expect(
      _buttonScale(tester),
      1.0,
      reason: 'must not stay shrunk after being disabled mid-press',
    );

    await gesture.up();
    await tester.pumpAndSettle();
  });
}

double _buttonScale(WidgetTester tester) => tester
    .widget<AnimatedScale>(
      find.descendant(
        of: find.byType(AppButton),
        matching: find.byType(AnimatedScale),
      ),
    )
    .scale;
