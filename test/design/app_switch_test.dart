// test/design/app_switch_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snitd/core/design/widgets/app_switch.dart';

void main() {
  testWidgets('tapping reports the toggled value', (tester) async {
    bool? next;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: AppSwitch(value: false, onChanged: (v) => next = v),
          ),
        ),
      ),
    );
    await tester.tap(find.byType(AppSwitch));
    expect(next, isTrue);
  });
}
