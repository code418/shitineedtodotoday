// test/task_detail_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snitd/features/settings/application/settings_providers.dart';
import 'package:snitd/features/tasks/application/tasks_providers.dart';
import 'package:snitd/features/tasks/data/occurrence_repository.dart';
import 'package:snitd/features/tasks/data/task_repository.dart';
import 'package:snitd/features/tasks/domain/scheduling/recurrence.dart';
import 'package:snitd/features/tasks/domain/scheduling/task_occurrence.dart';
import 'package:snitd/features/tasks/domain/task.dart';
import 'package:snitd/features/tasks/presentation/task_detail_screen.dart';

import 'occurrence_service_test.dart' show FakeOccurrenceRepository;
import 'task_service_test.dart' show FakeTaskRepository;

void main() {
  testWidgets('TaskDetailScreen renders task details and history', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final fakeTaskRepo = FakeTaskRepository();
    final fakeOccRepo = FakeOccurrenceRepository();

    // Seed a task.
    final task = Task(
      id: 't1',
      ownerId: 'u1',
      title: 'Vacuum the lounge',
      recurrence: const Recurrence.strict(weekdays: [DateTime.monday]),
      estimatedEffortMinutes: 15,
      category: 'Living room',
      createdAt: _clock,
      updatedAt: _clock,
    );
    fakeTaskRepo.store['t1'] = task;

    // Seed two done occurrences with durations.
    final occ1 = TaskOccurrence(
      id: 't1_2026-06-15',
      taskId: 't1',
      scheduledDate: DateTime(2026, 6, 15),
      status: OccurrenceStatus.done,
      completedAt: DateTime(2026, 6, 15, 10),
      actualDurationMinutes: 12,
    );
    final occ2 = TaskOccurrence(
      id: 't1_2026-06-22',
      taskId: 't1',
      scheduledDate: DateTime(2026, 6, 22),
      status: OccurrenceStatus.done,
      completedAt: DateTime(2026, 6, 22, 10),
      actualDurationMinutes: 10,
    );
    fakeOccRepo.store[occ1.id] = occ1;
    fakeOccRepo.store[occ2.id] = occ2;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          currentOwnerIdProvider.overrideWithValue('u1'),
          taskRepositoryProvider.overrideWithValue(fakeTaskRepo),
          occurrenceRepositoryProvider.overrideWithValue(fakeOccRepo),
          clockProvider.overrideWithValue(() => _clock),
        ],
        child: const MaterialApp(home: TaskDetailScreen(taskId: 't1')),
      ),
    );

    await tester.pumpAndSettle();

    // Task title in the app bar.
    expect(find.text('Vacuum the lounge'), findsWidgets);

    // Recurrence description.
    expect(find.text('Every Monday'), findsOneWidget);

    // Effort and History headings.
    expect(find.text('Effort'), findsOneWidget);
    expect(find.text('History'), findsOneWidget);

    // A done occurrence's duration badge — '~12m' or '~10m'.
    expect(find.text('~12m'), findsOneWidget);
    expect(find.text('~10m'), findsOneWidget);
  });

  testWidgets('TaskDetailScreen shows gentle message for missing task', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final fakeTaskRepo = FakeTaskRepository(); // empty — task not found
    final fakeOccRepo = FakeOccurrenceRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          currentOwnerIdProvider.overrideWithValue('u1'),
          taskRepositoryProvider.overrideWithValue(fakeTaskRepo),
          occurrenceRepositoryProvider.overrideWithValue(fakeOccRepo),
          clockProvider.overrideWithValue(() => _clock),
        ],
        child: const MaterialApp(home: TaskDetailScreen(taskId: 'missing')),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('This task is no longer here.'), findsOneWidget);
  });
}

final _clock = DateTime(2026, 6, 29, 9);
