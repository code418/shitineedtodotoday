import '../task.dart';
import 'forgiving_scheduler.dart' show addDays, dateOnly;
import 'recurrence.dart';
import 'task_occurrence.dart';

/// Smart load balancing against a gentle daily energy budget — the part of the
/// forgiving scheduler that keeps any single day from becoming overwhelming.
///
/// Pure and deterministic: callers pass the occurrences, the tasks (for effort
/// + strict/flexible classification), the planning window and the budget.

/// Total estimated effort (minutes) of the *open* occurrences scheduled on
/// [day]. Drives the "today's load" meter.
int loadForDay(
  Iterable<TaskOccurrence> occurrences,
  Map<String, int> estimateByTaskId,
  DateTime day,
) {
  final d = dateOnly(day);
  var total = 0;
  for (final occurrence in occurrences) {
    if (!occurrence.isOpen) continue;
    if (dateOnly(occurrence.scheduledDate) != d) continue;
    total += estimateByTaskId[occurrence.taskId] ?? 0;
  }
  return total;
}

/// Spread the given [occurrences] across `[from, from + horizonDays)` so each
/// day stays within [dailyBudgetMinutes] where possible — the engine behind the
/// weekly rebalance and the overwhelm "reset".
///
/// Strict tasks are fixed on their scheduled day (you can't move "every
/// Monday"); flexible occurrences are placed on the earliest day inside their
/// window that still has room under the budget, falling back to the
/// least-loaded day when every day is already full. Moved occurrences become
/// [OccurrenceStatus.rescheduled] with their [TaskOccurrence.originalDate]
/// preserved; ones that don't move are returned unchanged.
List<TaskOccurrence> rebalance({
  required List<TaskOccurrence> occurrences,
  required List<Task> tasks,
  required DateTime from,
  required int horizonDays,
  required int dailyBudgetMinutes,
}) {
  final start = dateOnly(from);
  final lastDay = addDays(start, horizonDays - 1);
  final tasksById = {for (final t in tasks) t.id: t};
  final estimateByTaskId = {
    for (final t in tasks) t.id: t.estimatedEffortMinutes,
  };

  // Running load per day, seeded with the fixed (strict) occurrences.
  final load = <DateTime, int>{};
  void addLoad(DateTime day, int minutes) =>
      load[day] = (load[day] ?? 0) + minutes;

  bool isMovable(TaskOccurrence o) {
    // Done/skipped occurrences are settled — never move one (it would flip a
    // completed task back to rescheduled/open, silently undoing it). The live
    // caller already passes only open occurrences; this keeps the primitive
    // correct for any future reuse.
    if (!o.isOpen) return false;
    // Pinned occurrences were deliberately placed by the user (a drag); leave
    // them fixed even though their recurrence is flexible.
    if (o.pinned) return false;
    final task = tasksById[o.taskId];
    return task != null && task.recurrence is FlexibleRecurrence;
  }

  final fixed = <TaskOccurrence>[];
  final movable = <TaskOccurrence>[];
  for (final occurrence in occurrences) {
    if (isMovable(occurrence)) {
      movable.add(occurrence);
    } else {
      fixed.add(occurrence);
      addLoad(
        dateOnly(occurrence.scheduledDate),
        estimateByTaskId[occurrence.taskId] ?? 0,
      );
    }
  }

  // Heaviest-first within earliest window packs days more evenly.
  movable.sort((a, b) {
    final aw = dateOnly(a.windowStart ?? start);
    final bw = dateOnly(b.windowStart ?? start);
    final byWindow = aw.compareTo(bw);
    if (byWindow != 0) return byWindow;
    final ae = estimateByTaskId[a.taskId] ?? 0;
    final be = estimateByTaskId[b.taskId] ?? 0;
    return be.compareTo(ae);
  });

  final placed = <TaskOccurrence>[...fixed];
  for (final occurrence in movable) {
    final estimate = estimateByTaskId[occurrence.taskId] ?? 0;
    final candidates = _candidateDays(occurrence, start, lastDay);

    DateTime? earliestWithRoom;
    DateTime? leastLoaded;
    var leastLoad = 1 << 30;
    for (final day in candidates) {
      final current = load[day] ?? 0;
      if (current + estimate <= dailyBudgetMinutes &&
          earliestWithRoom == null) {
        earliestWithRoom = day;
      }
      if (current < leastLoad) {
        leastLoad = current;
        leastLoaded = day;
      }
    }
    final target =
        earliestWithRoom ?? leastLoaded ?? dateOnly(occurrence.scheduledDate);
    addLoad(target, estimate);

    if (target == dateOnly(occurrence.scheduledDate)) {
      placed.add(occurrence);
    } else {
      placed.add(
        occurrence.copyWith(
          scheduledDate: target,
          status: OccurrenceStatus.rescheduled,
          originalDate: occurrence.originalDate ?? occurrence.scheduledDate,
        ),
      );
    }
  }

  return placed;
}

/// The days a flexible occurrence may land on, inside both its own window and
/// the planning range.
List<DateTime> _candidateDays(
  TaskOccurrence occurrence,
  DateTime rangeStart,
  DateTime rangeEnd,
) {
  var windowStart = dateOnly(occurrence.windowStart ?? rangeStart);
  var windowEnd = dateOnly(occurrence.windowEnd ?? rangeEnd);
  if (windowStart.isBefore(rangeStart)) windowStart = rangeStart;
  if (windowEnd.isAfter(rangeEnd)) windowEnd = rangeEnd;
  if (windowEnd.isBefore(windowStart)) {
    // Window fell entirely outside the range — keep it where it is.
    return [dateOnly(occurrence.scheduledDate)];
  }
  final days = <DateTime>[];
  for (var day = windowStart; !day.isAfter(windowEnd); day = addDays(day, 1)) {
    days.add(day);
  }
  return days;
}
