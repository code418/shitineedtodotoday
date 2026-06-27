import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snitd/core/design/widgets/app_segmented_control.dart';

void main() {
  testWidgets('tapping a segment reports its value', (tester) async {
    String? picked;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: AppSegmentedControl<String>(
              value: 'week',
              onChanged: (v) => picked = v,
              segments: const [
                AppSegment(value: 'week', label: 'Week'),
                AppSegment(value: 'month', label: 'Month'),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Month'));
    expect(picked, 'month');
  });
}
