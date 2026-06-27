import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snitd/core/design/widgets/app_checkbox.dart';

void main() {
  testWidgets('tapping toggles and reports the next value', (tester) async {
    bool? next;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: AppCheckbox(value: false, onChanged: (v) => next = v),
          ),
        ),
      ),
    );
    await tester.tap(find.byType(AppCheckbox));
    expect(next, isTrue);
  });

  testWidgets('disabled (null onChanged) does nothing', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Center(child: AppCheckbox(value: false))),
      ),
    );
    await tester.tap(find.byType(AppCheckbox));
    // No exception, nothing to assert beyond not throwing.
  });
}
