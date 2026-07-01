import '../data/occurrence_repository.dart';
import '../data/task_repository.dart';
import '../domain/effort_learning.dart';
import '../domain/scheduling/forgiving_scheduler.dart' show dateOnly;
import '../domain/scheduling/load_balancer.dart';
import '../domain/scheduling/scheduler.dart';
import '../domain/scheduling/task_occurrence.dart';
import '../domain/task.dart';

/// The outcome of completing an occurrence — the persisted done occurrence and,
/// when effort learning moved the estimate, the re-baselined task.
class CompletionResult {
  const CompletionResult({required this.occurrence, this.updatedTask});

  final TaskOccurrence occurrence;

  /// Non-null when the recorded duration changed the task's learned estimate.
  final Task? updatedTask;
}

/// Owner-scoped actions on checklist occurrences: complete (with duration +
/// effort learning), skip, and the forgiving reschedule. Orchestration only —
/// testable with fake repositories.
class OccurrenceService {
  OccurrenceService({
    required this.occurrences,
    required this.tasks,
    required this.scheduler,
    required this.ownerId,
    required this.now,
  });

  final OccurrenceRepository occurrences;
  final TaskRepository tasks;
  final Scheduler scheduler;
  final String ownerId;
  final DateTime Function() now;

  /// Tick a task off and record how long it actually took. Persists the done
  /// occurrence, then re-bases the task's estimate from its recent actuals
  /// ([history] = the task's prior occurrences, used to learn).
  Future<CompletionResult> complete({
    required TaskOccurrence occurrence,
    required Task task,
    required int actualMinutes,
    Iterable<TaskOccurrence> history = const [],
  }) async {
    final done = occurrence.copyWith(
      status: OccurrenceStatus.done,
      completedAt: now(),
      actualDurationMinutes: actualMinutes,
    );
    await occurrences.upsert(ownerId, done);

    // Drop any prior copy of this occurrence from history before learning: if
    // the caller's history still holds a stale *done* copy of it (e.g. a
    // complete → reopen → re-complete flow, or a not-yet-refreshed stream), it
    // would otherwise be counted alongside `done` and double-weight this one
    // occurrence in the mean. Mirrors the same guard in [reopen].
    final priorActuals = history.where((o) => o.id != occurrence.id);
    final actuals = recentActualMinutes([...priorActuals, done]);
    final learned = learnedEstimateMinutes(
      actuals,
      fallback: task.estimatedEffortMinutes,
    );
    Task? updatedTask;
    if (learned != task.estimatedEffortMinutes) {
      updatedTask = task.copyWith(
        estimatedEffortMinutes: learned,
        updatedAt: now(),
      );
      await tasks.upsert(updatedTask);
    }
    return CompletionResult(occurrence: done, updatedTask: updatedTask);
  }

  /// "Not today" — forgiven, not failed.
  Future<TaskOccurrence> skip(TaskOccurrence occurrence) async {
    final skipped = occurrence.copyWith(status: OccurrenceStatus.skipped);
    await occurrences.upsert(ownerId, skipped);
    return skipped;
  }

  /// Neatly move a missed occurrence to a new day via the scheduler.
  Future<TaskOccurrence> reschedule({
    required Task task,
    required TaskOccurrence occurrence,
  }) async {
    final moved = scheduler.rescheduleMissed(
      task: task,
      missed: occurrence,
      now: now(),
    );
    await occurrences.upsert(ownerId, moved);
    return moved;
  }

  /// Overwhelm reset: spread the given OPEN occurrences across the next
  /// [horizonDays] under [dailyBudgetMinutes], persisting any that moved.
  Future<List<TaskOccurrence>> rebalanceOpen({
    required List<TaskOccurrence> open,
    required List<Task> tasks,
    required int dailyBudgetMinutes,
    int horizonDays = 7,
  }) async {
    final balanced = rebalance(
      occurrences: open,
      tasks: tasks,
      from: now(),
      horizonDays: horizonDays,
      dailyBudgetMinutes: dailyBudgetMinutes,
    );
    final byId = {for (final o in open) o.id: o};
    for (final o in balanced) {
      final before = byId[o.id];
      if (before == null ||
          before.scheduledDate != o.scheduledDate ||
          before.status != o.status) {
        await occurrences.upsert(ownerId, o);
      }
    }
    return balanced;
  }

  /// Move an occurrence to an explicit [day] (drag-to-reschedule). Marks it
  /// rescheduled, preserves its originalDate so the "moved from…" note shows,
  /// and pins it so a later "spread it out" rebalance won't move it away from
  /// the day the user deliberately chose.
  Future<TaskOccurrence> moveTo(TaskOccurrence occurrence, DateTime day) async {
    final moved = occurrence.copyWith(
      scheduledDate: dateOnly(day),
      status: OccurrenceStatus.rescheduled,
      originalDate: occurrence.originalDate ?? occurrence.scheduledDate,
      pinned: true,
    );
    await occurrences.upsert(ownerId, moved);
    return moved;
  }

  /// Un-tick a previously completed or skipped occurrence, returning it to
  /// pending so the user can re-do it.
  ///
  /// When [task] and its [history] are supplied, the task's learned estimate is
  /// recomputed from the *remaining* actuals (this occurrence's recorded
  /// duration no longer counts), undoing the bump [complete] applied — so a
  /// mistaken or fat-fingered completion that is immediately un-ticked doesn't
  /// leave the estimate stuck. With no other completions left there is nothing
  /// to relearn from, so the estimate is left as-is.
  Future<CompletionResult> reopen(
    TaskOccurrence occurrence, {
    Task? task,
    Iterable<TaskOccurrence> history = const [],
  }) async {
    final reopened = occurrence.copyWith(
      status: OccurrenceStatus.pending,
      completedAt: null,
      actualDurationMinutes: null,
    );
    await occurrences.upsert(ownerId, reopened);

    Task? updatedTask;
    if (task != null) {
      final remaining = history.where((o) => o.id != occurrence.id);
      final actuals = recentActualMinutes(remaining);
      // Only relearn when actuals remain; otherwise keep the current estimate
      // (there's no recorded duration left to derive a new one from).
      if (actuals.isNotEmpty) {
        final learned = learnedEstimateMinutes(
          actuals,
          fallback: task.estimatedEffortMinutes,
        );
        if (learned != task.estimatedEffortMinutes) {
          updatedTask = task.copyWith(
            estimatedEffortMinutes: learned,
            updatedAt: now(),
          );
          await tasks.upsert(updatedTask);
        }
      }
    }
    return CompletionResult(occurrence: reopened, updatedTask: updatedTask);
  }
}
