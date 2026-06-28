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
}
