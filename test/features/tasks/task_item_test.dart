// test/features/tasks/task_item_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snitd/core/design/widgets/app_checkbox.dart';
import 'package:snitd/features/tasks/presentation/widgets/task_item.dart';

void main() {
  testWidgets('renders title, estimate badge and moved-from note', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AppTaskItem(
            title: 'Clean toilets',
            minutes: 5,
            category: 'Bathrooms & Mail',
            movedFrom: 'Tuesday',
          ),
        ),
      ),
    );
    expect(find.text('Clean toilets'), findsOneWidget);
    expect(find.text('~5m'), findsOneWidget);
    expect(find.textContaining('moved from Tuesday'), findsOneWidget);
  });

  testWidgets('ticking calls onToggle with the next value', (tester) async {
    bool? next;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppTaskItem(
            title: 'Wash bedding',
            minutes: 10,
            onToggle: (v) => next = v,
          ),
        ),
      ),
    );
    await tester.tap(find.byType(AppCheckbox));
    expect(next, isTrue);
  });
}
