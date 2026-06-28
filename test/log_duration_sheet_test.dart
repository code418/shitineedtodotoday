import 'dart:async';

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
import 'package:snitd/features/tasks/presentation/log_duration_sheet.dart';

import 'occurrence_service_test.dart' show FakeOccurrenceRepository;
import 'task_service_test.dart' show FakeTaskRepository;

/// Occurrence repo whose upsert blocks on a gate, to test in-flight behaviour.
class _GatedOccurrenceRepository implements OccurrenceRepository {
  final Map<String, TaskOccurrence> store = {};
  int upsertCalls = 0;
  final Completer<void> _gate = Completer<void>();

  void release() => _gate.complete();

  @override
  Stream<List<TaskOccurrence>> watchOccurrences(String ownerId) =>
      Stream.value(store.values.toList());

  @override
  Future<void> upsert(String ownerId, TaskOccurrence occurrence) async {
    upsertCalls++;
    await _gate.future;
    store[occurrence.id] = occurrence;
  }

  @override
  Future<void> delete(String ownerId, String occurrenceId) async {}

  @override
  Future<void> deleteForTask(String ownerId, String taskId) async {}
}

void main() {
  testWidgets(
    'showLogDurationSheet: picking 10 m and logging marks occurrence done',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final monday = DateTime(2026, 6, 29);
      final fakeTaskRepo = FakeTaskRepository();
      final fakeOccRepo = FakeOccurrenceRepository();

      // Seed a task with a 15-minute estimate
      final task = Task(
        id: 't1',
        ownerId: 'u1',
        title: 'Wash bedding',
        recurrence: const Recurrence.strict(weekdays: [DateTime.monday]),
        estimatedEffortMinutes: 15,
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      );
      fakeTaskRepo.store['t1'] = task;

      final occurrence = TaskOccurrence(
        id: 't1_2026-06-29',
        taskId: 't1',
        scheduledDate: monday,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            currentOwnerIdProvider.overrideWithValue('u1'),
            taskRepositoryProvider.overrideWithValue(fakeTaskRepo),
            occurrenceRepositoryProvider.overrideWithValue(fakeOccRepo),
            clockProvider.overrideWithValue(() => DateTime(2026, 6, 29, 9)),
          ],
          child: MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: ElevatedButton(
                  onPressed: () => showLogDurationSheet(
                    context,
                    occurrence: occurrence,
                    task: task,
                  ),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      );

      // Open the sheet
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Tap the 10-minute quick-pick chip
      await tester.tap(find.text('10m'));
      await tester.pumpAndSettle();

      // Tap "Log it"
      await tester.tap(find.text('Log it'));
      await tester.pumpAndSettle();

      final saved = fakeOccRepo.store['t1_2026-06-29'];
      expect(saved, isNotNull);
      expect(saved!.status, OccurrenceStatus.done);
      expect(saved.actualDurationMinutes, 10);
    },
  );

  testWidgets('double-tapping "Log it" completes only once', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final monday = DateTime(2026, 6, 29);
    final fakeTaskRepo = FakeTaskRepository();
    final gatedOcc = _GatedOccurrenceRepository();

    final task = Task(
      id: 't1',
      ownerId: 'u1',
      title: 'Wash bedding',
      recurrence: const Recurrence.strict(weekdays: [DateTime.monday]),
      estimatedEffortMinutes: 15,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );
    fakeTaskRepo.store['t1'] = task;

    final occurrence = TaskOccurrence(
      id: 't1_2026-06-29',
      taskId: 't1',
      scheduledDate: monday,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          currentOwnerIdProvider.overrideWithValue('u1'),
          taskRepositoryProvider.overrideWithValue(fakeTaskRepo),
          occurrenceRepositoryProvider.overrideWithValue(gatedOcc),
          clockProvider.overrideWithValue(() => DateTime(2026, 6, 29, 9)),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () => showLogDurationSheet(
                  context,
                  occurrence: occurrence,
                  task: task,
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    // Two quick taps before the first (gated) completion resolves.
    await tester.tap(find.text('Log it'));
    await tester.tap(find.text('Log it'));
    await tester.pump();

    // Release the gate and let everything settle.
    gatedOcc.release();
    await tester.pumpAndSettle();

    expect(gatedOcc.upsertCalls, 1, reason: 'the second tap is ignored');
  });
}
