// test/design/app_progress_meter_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snitd/core/design/tokens/app_colors.dart';
import 'package:snitd/core/design/widgets/app_progress_meter.dart';

BoxDecoration _fillDecoration(WidgetTester tester) {
  final c = tester.widget<AnimatedContainer>(
    find.byKey(const Key('appProgressMeterFill')),
  );
  return c.decoration! as BoxDecoration;
}

void main() {
  testWidgets('fills brand under budget', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: AppProgressMeter(value: 30, max: 55)),
      ),
    );
    await tester.pumpAndSettle();
    expect(_fillDecoration(tester).color, AppColors.brand);
  });

  testWidgets('tips to coral when over budget', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: AppProgressMeter(value: 70, max: 55)),
      ),
    );
    await tester.pumpAndSettle();
    expect(_fillDecoration(tester).color, AppColors.reschedule);
    expect(find.text('70m / 55m'), findsOneWidget);
  });
}
