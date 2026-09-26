import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snitd/core/design/design.dart';
import 'package:snitd/core/strings/app_strings.dart';
import 'package:snitd/features/settings/application/settings_providers.dart';
import 'package:snitd/features/tasks/application/tasks_providers.dart';
import 'package:snitd/features/tasks/data/occurrence_repository.dart';
import 'package:snitd/features/tasks/data/task_repository.dart';
import 'package:snitd/features/tasks/domain/scheduling/recurrence.dart';
import 'package:snitd/features/tasks/domain/scheduling/task_occurrence.dart';
import 'package:snitd/features/tasks/domain/task.dart';
import 'package:snitd/features/tasks/presentation/task_detail_screen.dart';
import 'package:snitd/features/tasks/presentation/today_screen.dart';

import '../../occurrence_service_test.dart' show FakeOccurrenceRepository;
import '../../task_service_test.dart' show FakeTaskRepository;

// A chore ticked off on the home-screen widget has its estimate logged as the
// time. Wherever a completion's time shows, it's flagged and can be corrected.

final _monday = DateTime(2026, 6, 29);

Task _bins() => Task(
  id: 'bins',
  ownerId: 'u1',
  title: 'Put the bins out',
  recurrence: const Recurrence.strict(weekdays: [DateTime.monday]),
  estimatedEffortMinutes: 15,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

/// Today's bins, ticked on the widget: 15m logged for the user.
TaskOccurrence _widgetTick() => TaskOccurrence(
  id: 'bins_2026-06-29',
  taskId: 'bins',
  scheduledDate: _monday,
  status: OccurrenceStatus.done,
  completedAt: DateTime(2026, 6, 29, 8),
  actualDurationMinutes: 15,
  durationEstimated: true,
);

void main() {
  const strings = AppStrings.clean;
  late FakeTaskRepository tasks;
  late FakeOccurrenceRepository occurrences;

  setUp(() {
    tasks = FakeTaskRepository()..store['bins'] = _bins();
    occurrences = FakeOccurrenceRepository()
      ..store['bins_2026-06-29'] = _widgetTick();
  });

  Future<void> pump(WidgetTester tester, Widget home) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          currentOwnerIdProvider.overrideWithValue('u1'),
          taskRepositoryProvider.overrideWithValue(tasks),
          occurrenceRepositoryProvider.overrideWithValue(occurrences),
          clockProvider.overrideWithValue(() => DateTime(2026, 6, 29, 9)),
        ],
        child: MaterialApp(home: home),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> correctTo(WidgetTester tester, String minutes) async {
    // The sheet opens on the time on record, as an edit.
    expect(find.text(strings.durationUpdate), findsOneWidget);
    await tester.tap(find.widgetWithText(AppChip, minutes));
    await tester.tap(find.widgetWithText(AppButton, strings.durationUpdate));
    await tester.pumpAndSettle();
  }

  testWidgets('Today flags an estimated time and lets it be corrected', (
    tester,
  ) async {
    await pump(tester, const TodayScreen());

    expect(find.text('~15m · ${strings.timeEstimatedShort}'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel(RegExp(strings.editTime)));
    await tester.pumpAndSettle();
    await correctTo(tester, '30m');

    final corrected = occurrences.store['bins_2026-06-29']!;
    expect(corrected.actualDurationMinutes, 30);
    expect(corrected.durationEstimated, isFalse);
    // Still done: correcting the time never re-opens the chore.
    expect(corrected.status, OccurrenceStatus.done);
  });

  testWidgets('a task\'s history flags and corrects it too', (tester) async {
    await pump(tester, const TaskDetailScreen(taskId: 'bins'));

    expect(find.text('~15m · ${strings.timeEstimatedShort}'), findsOneWidget);
    await tester.tap(find.text('~15m · ${strings.timeEstimatedShort}'));
    await tester.pumpAndSettle();
    await correctTo(tester, '10m');

    expect(occurrences.store['bins_2026-06-29']!.actualDurationMinutes, 10);
    expect(occurrences.store['bins_2026-06-29']!.durationEstimated, isFalse);
  });

  testWidgets('a reported time shows plainly, still editable', (tester) async {
    occurrences.store['bins_2026-06-29'] = _widgetTick().copyWith(
      actualDurationMinutes: 20,
      durationEstimated: false,
    );
    await pump(tester, const TodayScreen());

    expect(find.text('~20m'), findsOneWidget);
    expect(find.textContaining(strings.timeEstimatedShort), findsNothing);
    await tester.tap(find.bySemanticsLabel(RegExp(strings.editTime)));
    await tester.pumpAndSettle();
    expect(find.text(strings.durationUpdate), findsOneWidget);
  });
}
