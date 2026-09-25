import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snitd/core/strings/app_strings.dart';
import 'package:snitd/features/settings/application/settings_providers.dart';
import 'package:snitd/features/tasks/application/tasks_providers.dart';
import 'package:snitd/features/tasks/data/occurrence_repository.dart';
import 'package:snitd/features/tasks/data/task_repository.dart';
import 'package:snitd/features/tasks/domain/scheduling/recurrence.dart';
import 'package:snitd/features/tasks/domain/scheduling/task_occurrence.dart';
import 'package:snitd/features/tasks/domain/task.dart';
import 'package:snitd/features/tasks/presentation/today_screen.dart';

import '../../occurrence_service_test.dart' show FakeOccurrenceRepository;
import '../../task_service_test.dart' show FakeTaskRepository;

Task _task(String id, String title) => Task(
  id: id,
  ownerId: 'u1',
  title: title,
  recurrence: const Recurrence.strict(weekdays: [DateTime.monday]),
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

void main() {
  const strings = AppStrings.clean;
  late FakeOccurrenceRepository occurrences;
  final monday = DateTime(2026, 6, 29);

  Future<void> pumpToday(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final tasks = FakeTaskRepository()
      ..store['open'] = _task('open', 'Open chore')
      ..store['done'] = _task('done', 'Done chore');
    occurrences = FakeOccurrenceRepository()
      ..store['done_2026-06-29'] = TaskOccurrence(
        id: 'done_2026-06-29',
        taskId: 'done',
        scheduledDate: monday,
        status: OccurrenceStatus.done,
        completedAt: DateTime(2026, 6, 29, 8),
        actualDurationMinutes: 12,
      );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          currentOwnerIdProvider.overrideWithValue('u1'),
          taskRepositoryProvider.overrideWithValue(tasks),
          occurrenceRepositoryProvider.overrideWithValue(occurrences),
          clockProvider.overrideWithValue(() => DateTime(2026, 6, 29, 9)),
        ],
        child: const MaterialApp(home: TodayScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('a ticked-off chore cannot be swiped to "Not today"', (
    tester,
  ) async {
    await pumpToday(tester);

    // Swiping the done row must not turn the completion into a skip.
    await tester.drag(find.text('Done chore'), const Offset(-600, 0));
    await tester.pumpAndSettle();

    expect(find.text('Done chore'), findsOneWidget);
    expect(occurrences.store['done_2026-06-29']!.status, OccurrenceStatus.done);
    expect(find.text(strings.taskSkipped), findsNothing);
  });

  testWidgets('"Not today" is a screen-reader action on open chores only', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pumpToday(tester);
    final notToday = CustomSemanticsAction.getIdentifier(
      CustomSemanticsAction(label: strings.notToday),
    );

    final done = tester.getSemantics(find.text('Done chore'));
    expect(done.getSemanticsData().customSemanticsActionIds ?? [], isEmpty);

    // The swipe is invisible to TalkBack; the same skip is offered by name.
    final open = tester.getSemantics(find.text('Open chore'));
    expect(open.getSemanticsData().customSemanticsActionIds, [notToday]);
    open.owner!.performAction(open.id, SemanticsAction.customAction, notToday);
    await tester.pumpAndSettle();

    expect(
      occurrences.store['open_2026-06-29']?.status,
      OccurrenceStatus.skipped,
    );
    expect(find.text(strings.taskSkipped), findsOneWidget);
    semantics.dispose();
  });
}
