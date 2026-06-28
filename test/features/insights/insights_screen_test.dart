import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snitd/core/strings/app_strings.dart';
import 'package:snitd/features/insights/application/insights_providers.dart';
import 'package:snitd/features/insights/domain/insights.dart';
import 'package:snitd/features/insights/presentation/insights_screen.dart';
import 'package:snitd/features/settings/application/settings_providers.dart';
import 'package:snitd/features/tasks/application/tasks_providers.dart';
import 'package:snitd/features/tasks/data/occurrence_repository.dart';
import 'package:snitd/features/tasks/data/task_repository.dart';
import 'package:snitd/features/tasks/domain/scheduling/recurrence.dart';
import 'package:snitd/features/tasks/domain/scheduling/task_occurrence.dart';
import 'package:snitd/features/tasks/domain/task.dart';

/// Task repo whose writes fail — simulates an offline/permission error.
class _ThrowingTaskRepository implements TaskRepository {
  @override
  Stream<List<Task>> watchTasks(String ownerId) => Stream.value(const <Task>[]);

  @override
  Future<void> upsert(Task task) async => throw Exception('write failed');

  @override
  Future<void> delete(String ownerId, String taskId) async {}

  @override
  String newId(String ownerId) => 'x';
}

class _FakeOccurrenceRepository implements OccurrenceRepository {
  @override
  Stream<List<TaskOccurrence>> watchOccurrences(String ownerId) =>
      Stream.value(const <TaskOccurrence>[]);

  @override
  Future<void> upsert(String ownerId, TaskOccurrence occurrence) async {}

  @override
  Future<void> delete(String ownerId, String occurrenceId) async {}

  @override
  Future<void> deleteForTask(String ownerId, String taskId) async {}
}

void main() {
  testWidgets('a failed apply-suggestion shows a gentle error snackbar', (
    tester,
  ) async {
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
    final occ = TaskOccurrence(
      id: 't1_2026-06-29',
      taskId: 't1',
      scheduledDate: DateTime(2026, 6, 29),
    );
    const summary = InsightsSummary(
      completedCount: 1,
      skippedCount: 3,
      completionRate: 0.25,
      streakDays: 0,
      totalMinutes: 10,
      buckets: [],
      slips: [TaskSlip('t1', 3)],
      suggestion: AdaptiveSuggestion(
        taskId: 't1',
        suggestedRecurrence: Recurrence.flexible(period: FrequencyPeriod.week),
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          currentOwnerIdProvider.overrideWithValue('u1'),
          occurrencesProvider.overrideWith((ref) => Stream.value([occ])),
          tasksProvider.overrideWith((ref) => Stream.value([task])),
          taskRepositoryProvider.overrideWithValue(_ThrowingTaskRepository()),
          occurrenceRepositoryProvider.overrideWithValue(
            _FakeOccurrenceRepository(),
          ),
          insightsSummaryProvider(
            InsightsPeriod.week,
          ).overrideWithValue(summary),
        ],
        child: const MaterialApp(home: InsightsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // The suggestion card and its apply button exist (below the fold).
    expect(find.text('Make it flexible'), findsOneWidget);

    await tester.ensureVisible(find.text('Make it flexible'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Make it flexible'));
    await tester.pumpAndSettle();

    // The write failed, so a gentle error is shown rather than the success
    // confirmation.
    expect(find.text(AppStrings.clean.actionFailed), findsOneWidget);
    expect(find.text(AppStrings.clean.suggestionApplied), findsNothing);
  });
}
