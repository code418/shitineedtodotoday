import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/data/auth_repository.dart';
import '../data/occurrence_repository.dart';
import '../data/starter_tasks.dart';
import '../data/task_repository.dart';
import '../domain/scheduling/forgiving_scheduler.dart';
import '../domain/scheduling/scheduler.dart';
import '../domain/scheduling/task_occurrence.dart';
import '../domain/task.dart';
import '../domain/task_suggestion.dart';
import 'occurrence_service.dart';
import 'task_service.dart';

/// The active scheduling engine. Every consumer reads it through this provider.
final schedulerProvider = Provider<Scheduler>(
  (ref) => const ForgivingScheduler(),
);

/// The wall clock, injectable so scheduling and timestamps are testable.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// The signed-in owner's uid, or null when signed out. Scopes all task data.
final currentOwnerIdProvider = Provider<String?>(
  (ref) => ref.watch(authStateChangesProvider).value?.uid,
);

/// Streams the owner's task definitions (empty when there's no owner yet).
final tasksProvider = StreamProvider<List<Task>>((ref) {
  final ownerId = ref.watch(currentOwnerIdProvider);
  if (ownerId == null) return Stream.value(const <Task>[]);
  return ref.watch(taskRepositoryProvider).watchTasks(ownerId);
});

/// Streams the owner's persisted occurrences (ticked / skipped / rescheduled).
final occurrencesProvider = StreamProvider<List<TaskOccurrence>>((ref) {
  final ownerId = ref.watch(currentOwnerIdProvider);
  if (ownerId == null) return Stream.value(const <TaskOccurrence>[]);
  return ref.watch(occurrenceRepositoryProvider).watchOccurrences(ownerId);
});

/// Today's checklist — the owner's active tasks run through the scheduler,
/// merged with anything already persisted for today. Empty until data loads.
final todayChecklistProvider = Provider<List<TaskOccurrence>>((ref) {
  final tasks = ref.watch(tasksProvider).value ?? const <Task>[];
  final existing =
      ref.watch(occurrencesProvider).value ?? const <TaskOccurrence>[];
  final now = ref.watch(clockProvider)();
  return ref
      .watch(schedulerProvider)
      .buildToday(tasks: tasks, today: now, existing: existing);
});

/// All persisted occurrences for one task, oldest persisted order — used by the
/// task detail/history screen and effort learning.
final occurrencesForTaskProvider =
    Provider.family<List<TaskOccurrence>, String>(
      (ref, taskId) => [
        for (final o in ref.watch(occurrencesProvider).value ?? const [])
          if (o.taskId == taskId) o,
      ],
    );

/// Look up a single task by id from the live stream.
final taskByIdProvider = Provider.family<Task?, String>((ref, id) {
  for (final t in ref.watch(tasksProvider).value ?? const <Task>[]) {
    if (t.id == id) return t;
  }
  return null;
});

/// Task CRUD service, or null when there's no signed-in owner.
final taskServiceProvider = Provider<TaskService?>((ref) {
  final ownerId = ref.watch(currentOwnerIdProvider);
  if (ownerId == null) return null;
  return TaskService(
    repository: ref.watch(taskRepositoryProvider),
    ownerId: ownerId,
    now: ref.watch(clockProvider),
  );
});

/// Occurrence actions service (complete / skip / reschedule), or null when
/// there's no signed-in owner.
final occurrenceServiceProvider = Provider<OccurrenceService?>((ref) {
  final ownerId = ref.watch(currentOwnerIdProvider);
  if (ownerId == null) return null;
  return OccurrenceService(
    occurrences: ref.watch(occurrenceRepositoryProvider),
    tasks: ref.watch(taskRepositoryProvider),
    scheduler: ref.watch(schedulerProvider),
    ownerId: ownerId,
    now: ref.watch(clockProvider),
  );
});

/// Ready-made starter tasks (the curated cleaning plan from the planner PDF),
/// offered to new users so they can get going without a blank page.
final starterSuggestionsProvider = Provider<List<TaskSuggestion>>(
  (ref) => kStarterCleaningPlan,
);

/// The starter suggestions grouped by their themed day/category, preserving the
/// catalogue's order (Mon → Sun).
final starterSuggestionsByCategoryProvider =
    Provider<Map<String, List<TaskSuggestion>>>((ref) {
      final grouped = <String, List<TaskSuggestion>>{};
      for (final suggestion in ref.watch(starterSuggestionsProvider)) {
        grouped.putIfAbsent(suggestion.category, () => []).add(suggestion);
      }
      return grouped;
    });
