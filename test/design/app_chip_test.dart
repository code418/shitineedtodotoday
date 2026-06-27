// test/design/app_chip_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snitd/core/design/widgets/app_chip.dart';

void main() {
  testWidgets('renders label and fires onTap', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: AppChip(
              label: 'Kitchen',
              tone: AppChipTone.today,
              onTap: () => taps++,
            ),
          ),
        ),
      ),
    );
    expect(find.text('Kitchen'), findsOneWidget);
    await tester.tap(find.text('Kitchen'));
    expect(taps, 1);
  });
}
