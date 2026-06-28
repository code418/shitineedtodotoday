import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snitd/core/design/tokens/app_icons.dart';
import 'package:snitd/core/strings/app_strings.dart';
import 'package:snitd/features/settings/application/settings_providers.dart';
import 'package:snitd/features/tasks/application/tasks_providers.dart';
import 'package:snitd/features/tasks/data/occurrence_repository.dart';
import 'package:snitd/features/tasks/data/task_repository.dart';
import 'package:snitd/features/tasks/domain/scheduling/recurrence.dart';
import 'package:snitd/features/tasks/domain/scheduling/task_occurrence.dart';
import 'package:snitd/features/tasks/domain/task.dart';
import 'package:snitd/features/tasks/presentation/log_duration_sheet.dart';
import 'package:snitd/features/tasks/presentation/task_composer_sheet.dart';
import 'package:snitd/features/tasks/presentation/task_detail_screen.dart';

import '../../occurrence_service_test.dart' show FakeOccurrenceRepository;

/// A task repo whose writes (`upsert`) fail — simulates offline/permission.
class _UpsertThrowsTaskRepository implements TaskRepository {
  @override
  Stream<List<Task>> watchTasks(String ownerId) => Stream.value(const <Task>[]);

  @override
  Future<void> upsert(Task task) async => throw Exception('write failed');

  @override
  Future<void> delete(String ownerId, String taskId) async {}

  @override
  String newId(String ownerId) => 'new-task';
}

/// A task repo that holds tasks but fails on `delete`.
class _DeleteThrowsTaskRepository implements TaskRepository {
  _DeleteThrowsTaskRepository(this.store);

  final Map<String, Task> store;

  @override
  Stream<List<Task>> watchTasks(String ownerId) =>
      Stream.value(store.values.where((t) => t.ownerId == ownerId).toList());

  @override
  Future<void> upsert(Task task) async => store[task.id] = task;

  @override
  Future<void> delete(String ownerId, String taskId) async =>
      throw Exception('delete failed');

  @override
  String newId(String ownerId) => 'new-task';
}

/// An occurrence repo whose writes (`upsert`) fail.
class _UpsertThrowsOccurrenceRepository implements OccurrenceRepository {
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

void main() {
  testWidgets(
    'composer save failure shows a gentle error and keeps the sheet open',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            currentOwnerIdProvider.overrideWithValue('u1'),
            taskRepositoryProvider.overrideWithValue(
              _UpsertThrowsTaskRepository(),
            ),
            occurrenceRepositoryProvider.overrideWithValue(
              FakeOccurrenceRepository(),
            ),
            // 2026-06-29 is a Monday, so the default weekday preset is valid.
            clockProvider.overrideWithValue(() => DateTime(2026, 6, 29, 9)),
          ],
          child: MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: ElevatedButton(
                  onPressed: () => showTaskComposer(context),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'Clean windows');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save task'));
      await tester.pumpAndSettle();

      // Gentle error surfaced, and the sheet is still open for a retry.
      expect(find.text(AppStrings.clean.actionFailed), findsOneWidget);
      expect(find.text('Save task'), findsOneWidget);
    },
  );

  testWidgets(
    'log-duration failure shows a gentle error and keeps the sheet open',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final task = Task(
        id: 't1',
        ownerId: 'u1',
        title: 'Wash bedding',
        recurrence: const Recurrence.strict(weekdays: [DateTime.monday]),
        estimatedEffortMinutes: 15,
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      );
      final occurrence = TaskOccurrence(
        id: 't1_2026-06-29',
        taskId: 't1',
        scheduledDate: DateTime(2026, 6, 29),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            currentOwnerIdProvider.overrideWithValue('u1'),
            taskRepositoryProvider.overrideWithValue(
              _DeleteThrowsTaskRepository({'t1': task}),
            ),
            occurrenceRepositoryProvider.overrideWithValue(
              _UpsertThrowsOccurrenceRepository(),
            ),
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

      await tester.tap(find.text('Log it'));
      await tester.pumpAndSettle();

      // Gentle error surfaced, and the sheet is still open for a retry.
      expect(find.text(AppStrings.clean.actionFailed), findsOneWidget);
      expect(find.text('Log it'), findsOneWidget);
    },
  );

  testWidgets(
    'detail delete failure shows a gentle error and stays on the screen',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final task = Task(
        id: 't1',
        ownerId: 'u1',
        title: 'Vacuum the lounge',
        recurrence: const Recurrence.strict(weekdays: [DateTime.monday]),
        estimatedEffortMinutes: 15,
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            currentOwnerIdProvider.overrideWithValue('u1'),
            taskRepositoryProvider.overrideWithValue(
              _DeleteThrowsTaskRepository({'t1': task}),
            ),
            occurrenceRepositoryProvider.overrideWithValue(
              FakeOccurrenceRepository(),
            ),
            clockProvider.overrideWithValue(() => DateTime(2026, 6, 29, 9)),
          ],
          child: const MaterialApp(home: TaskDetailScreen(taskId: 't1')),
        ),
      );
      await tester.pumpAndSettle();

      // Open the delete dialog and confirm.
      await tester.tap(find.byIcon(AppIcons.delete));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.clean.deleteConfirm));
      await tester.pumpAndSettle();

      // Gentle error surfaced, and we're still on the detail screen.
      expect(find.text(AppStrings.clean.actionFailed), findsOneWidget);
      expect(find.text('Vacuum the lounge'), findsWidgets);
    },
  );
}
