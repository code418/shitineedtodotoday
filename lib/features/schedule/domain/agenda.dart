import '../../tasks/domain/scheduling/forgiving_scheduler.dart' show dateOnly;
import '../../tasks/domain/scheduling/scheduler.dart';
import '../../tasks/domain/scheduling/task_occurrence.dart';
import '../../tasks/domain/task.dart';

/// One day's slot in the week agenda.
class AgendaDay {
  const AgendaDay({required this.date, required this.occurrences});

  final DateTime date;
  final List<TaskOccurrence> occurrences;
}

/// Monday of the week containing [date].
DateTime weekStartFor(DateTime date) {
  final d = dateOnly(date);
  return d.subtract(Duration(days: d.weekday - 1));
}

/// The 7 days from [weekStart], each with that day's checklist (via the
/// scheduler, merging persisted occurrences).
List<AgendaDay> buildWeekAgenda({
  required Scheduler scheduler,
  required List<Task> tasks,
  required List<TaskOccurrence> existing,
  required DateTime weekStart,
}) {
  final start = dateOnly(weekStart);
  // Defensively drop occurrences whose task no longer exists, mirroring
  // todayChecklistProvider — a deleted task should cascade its occurrences,
  // but a transient orphan (e.g. streams updating out of step) must never
  // render as a row labelled by its raw taskId.
  final taskIds = {for (final t in tasks) t.id};
  return [
    for (var i = 0; i < 7; i++)
      () {
        final day = start.add(Duration(days: i));
        final dayOccurrences = scheduler.buildToday(
          tasks: tasks,
          today: day,
          existing: existing,
        );
        return AgendaDay(
          date: day,
          occurrences: [
            for (final occ in dayOccurrences)
              if (taskIds.contains(occ.taskId)) occ,
          ],
        );
      }(),
  ];
}
