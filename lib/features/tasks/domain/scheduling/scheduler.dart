import '../task.dart';
import 'task_occurrence.dart';

/// The forgiving scheduling engine — the core of the app.
///
/// It turns [Task] definitions into the concrete [TaskOccurrence]s that make up
/// each day's checklist, and it neatly reschedules anything that slips so work
/// never piles up into an overwhelming day.
///
/// The real implementation is `ForgivingScheduler`
/// (`forgiving_scheduler.dart`), wired in through `schedulerProvider`.
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
