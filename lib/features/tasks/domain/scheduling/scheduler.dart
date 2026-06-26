import '../task.dart';
import 'task_occurrence.dart';

/// The forgiving scheduling engine — the core of the app.
///
/// It turns [Task] definitions into the concrete [TaskOccurrence]s that make up
/// each day's checklist, and it neatly reschedules anything that slips so work
/// never piles up into an overwhelming day.
///
/// The real algorithm is intentionally **not** implemented in this scaffold;
/// [PlaceholderScheduler] documents the contract and the intended behaviour so
/// upcoming development has a clear seam to fill in. See `docs/ROADMAP.md`
/// (P1/P2) for the planned evolution.
abstract interface class Scheduler {
  /// Build the list of occurrences that should appear on [today]'s checklist,
  /// given the user's active [tasks] and any [existing] occurrences already
  /// persisted (so we don't double-generate).
  List<TaskOccurrence> buildToday({
    required List<Task> tasks,
    required DateTime today,
    List<TaskOccurrence> existing,
  });

  /// Neatly reschedule a [missed] occurrence rather than letting it lapse.
  ///
  /// Intended behaviour:
  /// - **Flexible** tasks: slide within the remaining window
  ///   ([TaskOccurrence.windowEnd]); only escalate once the window closes.
  /// - **Strict** tasks: roll forward to the next sensible slot without
  ///   stacking duplicates, spreading load so no single day is overwhelming.
  ///
  /// Returns the updated occurrence (typically with
  /// [OccurrenceStatus.rescheduled] and a new [TaskOccurrence.scheduledDate]).
  TaskOccurrence rescheduleMissed({
    required Task task,
    required TaskOccurrence missed,
    required DateTime now,
  });
}

/// Documented no-op [Scheduler] used until the real engine lands.
///
/// [buildToday] returns an empty checklist; [rescheduleMissed] is unimplemented
/// on purpose so callers fail loudly rather than silently dropping work.
class PlaceholderScheduler implements Scheduler {
  const PlaceholderScheduler();

  @override
  List<TaskOccurrence> buildToday({
    required List<Task> tasks,
    required DateTime today,
    List<TaskOccurrence> existing = const <TaskOccurrence>[],
  }) {
    // TODO(upcoming): materialise occurrences from each active task's
    // recurrence (strict -> exact days; flexible -> a day chosen within the
    // window), skipping any already present in [existing].
    return const <TaskOccurrence>[];
  }

  @override
  TaskOccurrence rescheduleMissed({
    required Task task,
    required TaskOccurrence missed,
    required DateTime now,
  }) {
    // TODO(upcoming): implement the forgiving reschedule described on
    // [Scheduler.rescheduleMissed].
    throw UnimplementedError(
      'PlaceholderScheduler.rescheduleMissed is not implemented yet. '
      'Replace PlaceholderScheduler with the real engine (see docs/ROADMAP.md).',
    );
  }
}
