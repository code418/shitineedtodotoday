import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snitd/core/design/tokens/app_icons.dart';
import 'package:snitd/core/strings/app_strings.dart';
import 'package:snitd/features/schedule/presentation/schedule_screen.dart';
import 'package:snitd/features/settings/application/settings_providers.dart';
import 'package:snitd/features/tasks/application/tasks_providers.dart';
import 'package:snitd/features/tasks/data/occurrence_repository.dart';
import 'package:snitd/features/tasks/data/task_repository.dart';
import 'package:snitd/features/tasks/domain/scheduling/recurrence.dart';
import 'package:snitd/features/tasks/domain/scheduling/task_occurrence.dart';
import 'package:snitd/features/tasks/domain/task.dart';

/// Task repo with one flexible task; occurrence repo whose writes fail.
class _StubTaskRepository implements TaskRepository {
  _StubTaskRepository(this._tasks);
  final List<Task> _tasks;
  @override
  Stream<List<Task>> watchTasks(String ownerId) => Stream.value(_tasks);
  @override
  Future<void> upsert(Task task) async {}
  @override
  Future<void> delete(String ownerId, String taskId) async {}
  @override
  String newId(String ownerId) => 'x';
}

class _ThrowingOccurrenceRepository implements OccurrenceRepository {
  @override
  Stream<List<TaskOccurrence>> watchOccurrences(String ownerId) =>
      Stream.value(const <TaskOccurrence>[]);
  @override
  Future<void> upsert(String ownerId, TaskOccurrence occurrence) async =>
      throw Exception('write failed');
  @override
  Future<void> delete(String ownerId, String occurrenceId) async {}
  @override
  Future<void> deleteForTask(String ownerId, String taskId) async {}
}

/// Records upserts so a test can assert a blocked drag wrote nothing.
class _RecordingOccurrenceRepository implements OccurrenceRepository {
  int upserts = 0;
  @override
  Stream<List<TaskOccurrence>> watchOccurrences(String ownerId) =>
      Stream.value(const <TaskOccurrence>[]);
  @override
  Future<void> upsert(String ownerId, TaskOccurrence occurrence) async =>
      upserts++;
  @override
  Future<void> delete(String ownerId, String occurrenceId) async {}
  @override
  Future<void> deleteForTask(String ownerId, String taskId) async {}
}

void main() {
  testWidgets(
    'done occurrences render non-draggable; open ones stay draggable',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      // Monday 2026-06-29 — both strict-Monday tasks land on this week's Monday.
      final monday = DateTime(2026, 6, 29);

      Task strictMonday(String id, String title) => Task(
        id: id,
        ownerId: 'u1',
        title: title,
        recurrence: const Recurrence.strict(weekdays: [DateTime.monday]),
        estimatedEffortMinutes: 15,
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      );

      // Task 'a' already completed today; task 'b' still open.
      final doneOcc = TaskOccurrence(
        id: 'a_2026-06-29',
        taskId: 'a',
        scheduledDate: monday,
        status: OccurrenceStatus.done,
        completedAt: DateTime(2026, 6, 29, 10),
        actualDurationMinutes: 12,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            clockProvider.overrideWithValue(() => DateTime(2026, 6, 29, 9)),
            tasksProvider.overrideWith(
              (ref) => Stream.value([
                strictMonday('a', 'Done task'),
                strictMonday('b', 'Open task'),
              ]),
            ),
            occurrencesProvider.overrideWith((ref) => Stream.value([doneOcc])),
          ],
          child: const MaterialApp(home: ScheduleScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Done task'), findsOneWidget);
      expect(find.text('Open task'), findsOneWidget);

      // Only the open occurrence is draggable; the done one is static.
      expect(find.byType(LongPressDraggable<TaskOccurrence>), findsOneWidget);
      // The done row shows a check marker rather than a drag handle.
      expect(find.byIcon(AppIcons.check), findsOneWidget);
    },
  );

  testWidgets(
    'dragging a task onto a day it already occupies is blocked, not duplicated',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final occRepo = _RecordingOccurrenceRepository();

      // A strict task on Mon AND Tue — so both this week's Monday and Tuesday
      // already materialise an occurrence for it.
      final task = Task(
        id: 'mt',
        ownerId: 'u1',
        title: 'Bins',
        recurrence: const Recurrence.strict(
          weekdays: [DateTime.monday, DateTime.tuesday],
        ),
        estimatedEffortMinutes: 15,
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            currentOwnerIdProvider.overrideWithValue('u1'),
            clockProvider.overrideWithValue(() => DateTime(2026, 6, 29, 9)),
            tasksProvider.overrideWith((ref) => Stream.value([task])),
            occurrencesProvider.overrideWith(
              (ref) => Stream.value(const <TaskOccurrence>[]),
            ),
            taskRepositoryProvider.overrideWithValue(
              _StubTaskRepository([task]),
            ),
            occurrenceRepositoryProvider.overrideWithValue(occRepo),
          ],
          child: const MaterialApp(home: ScheduleScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Drag Monday's occurrence onto Tuesday — which already has 'Bins'.
      final from = tester.getCenter(find.text('Bins').first);
      final to = tester.getCenter(find.text('Tue 30'));
      final gesture = await tester.startGesture(from);
      await tester.pump(const Duration(milliseconds: 500));
      await gesture.moveTo(to);
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.clean.alreadyOnThatDay), findsOneWidget);
      expect(occRepo.upserts, 0, reason: 'the blocked drop must not write');
    },
  );

  testWidgets('a failed drag-reschedule shows a gentle error snackbar', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    // A flexible-weekly task anchors on Monday (open, draggable).
    final task = Task(
      id: 'f1',
      ownerId: 'u1',
      title: 'Flexy',
      recurrence: const Recurrence.flexible(period: FrequencyPeriod.week),
      estimatedEffortMinutes: 15,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          currentOwnerIdProvider.overrideWithValue('u1'),
          clockProvider.overrideWithValue(() => DateTime(2026, 6, 29, 9)),
          tasksProvider.overrideWith((ref) => Stream.value([task])),
          occurrencesProvider.overrideWith(
            (ref) => Stream.value(const <TaskOccurrence>[]),
          ),
          taskRepositoryProvider.overrideWithValue(_StubTaskRepository([task])),
          occurrenceRepositoryProvider.overrideWithValue(
            _ThrowingOccurrenceRepository(),
          ),
        ],
        child: const MaterialApp(home: ScheduleScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // Long-press-drag the Monday occurrence onto Tuesday's section.
    final from = tester.getCenter(find.text('Flexy'));
    final to = tester.getCenter(find.text('Tue 30'));
    final gesture = await tester.startGesture(from);
    await tester.pump(const Duration(milliseconds: 500)); // exceed long-press
    await gesture.moveTo(to);
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.clean.actionFailed), findsOneWidget);
  });
}
