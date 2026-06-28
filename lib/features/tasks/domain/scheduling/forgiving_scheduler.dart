import '../task.dart';
import 'recurrence.dart';
import 'scheduler.dart';
import 'task_occurrence.dart';

/// Strips a [DateTime] to its local calendar day (midnight).
DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Adds [days] calendar days to [day] via the date constructor.
///
/// DST-safe: `Duration(days:)` shifts a fixed 24h, so across a daylight-saving
/// transition it lands at 23:00/01:00 on the wrong calendar day, which then
/// fails exact-equality and map-key comparisons against local-midnight dates.
/// The constructor normalises to local midnight on the correct calendar day
/// (and rolls month/year boundaries).
DateTime addDays(DateTime day, int days) =>
    DateTime(day.year, day.month, day.day + days);

/// Deterministic id for the occurrence of [taskId] on [day] — lets us
/// regenerate the same checklist idempotently and dedupe against persisted
/// occurrences.
String occurrenceId(String taskId, DateTime day) {
  final d = dateOnly(day);
  final y = d.year.toString().padLeft(4, '0');
  final m = d.month.toString().padLeft(2, '0');
  final dd = d.day.toString().padLeft(2, '0');
  return '${taskId}_$y-$m-$dd';
}

/// The forgiving scheduling engine — the real implementation of [Scheduler].
///
/// Pure and deterministic (no clock or randomness of its own): every method
/// takes the dates it needs, so the whole engine is trivially testable.
///
/// - **Strict** recurrences materialise on their exact days (weekdays, the Nth
///   of the month — clamped to the last day for short months, or a one-off
///   date).
/// - **Flexible** recurrences float within their period: the occurrence is
///   anchored to evenly-spaced day(s) inside the current period and may slide
///   within that window (see [rescheduleMissed]) before it is considered
///   overdue. Seasonal anchors ("every summer") land on the first day of the
///   season (northern-hemisphere months).
class ForgivingScheduler implements Scheduler {
  const ForgivingScheduler();

  @override
  List<TaskOccurrence> buildToday({
    required List<Task> tasks,
    required DateTime today,
    List<TaskOccurrence> existing = const <TaskOccurrence>[],
    bool carryOverdue = false,
  }) {
    final day = dateOnly(today);
    final result = <TaskOccurrence>[];
    final claimed = <String>{};

    // 1. Keep occurrences already persisted for today in the claimed set so we
    //    never regenerate them; only add to result if not skipped (skipped =
    //    "not today" → hidden from checklist but not re-created).
    for (final occ in existing) {
      if (dateOnly(occ.scheduledDate) == day) {
        claimed.add(occ.taskId);
        if (occ.status != OccurrenceStatus.skipped) {
          result.add(occ);
        }
      }
    }

    // 1b. Forgiving carry-forward: open occurrences (pending/rescheduled) left
    //     on past days resurface on today instead of being stranded — the
    //     "neatly reschedules instead of letting work pile up" promise. Only
    //     when building the *actual* today ([carryOverdue]); the week agenda
    //     leaves past days where they are. Earliest-first so the oldest slip is
    //     the one carried, and only one per task (claimed) to avoid stacking.
    if (carryOverdue) {
      final overdue =
          existing
              .where((o) => o.isOpen && dateOnly(o.scheduledDate).isBefore(day))
              .toList()
            ..sort((a, b) => a.scheduledDate.compareTo(b.scheduledDate));
      for (final occ in overdue) {
        if (claimed.contains(occ.taskId)) continue;
        claimed.add(occ.taskId);
        result.add(
          occ.copyWith(
            scheduledDate: day,
            status: OccurrenceStatus.rescheduled,
            originalDate: occ.originalDate ?? occ.scheduledDate,
          ),
        );
      }
    }

    // Build a set of all existing occurrence ids so we can skip regeneration for
    // tasks whose cycle-occurrence was moved to another day (same id, different
    // scheduledDate).  The claimed set above only catches same-day occurrences.
    final existingIds = {for (final o in existing) o.id};

    // 2. Materialise fresh, pending occurrences for active tasks that fall on
    //    today and aren't already represented.
    for (final task in tasks) {
      if (!task.isActive) continue;
      if (claimed.contains(task.id)) continue;
      if (!_occursOn(task.recurrence, day)) continue;
      // If this cycle's deterministic occurrence already exists (possibly on a
      // different day after a reschedule), don't regenerate it here.
      final id = occurrenceId(task.id, day);
      if (existingIds.contains(id)) continue;
      final window = _windowFor(task.recurrence, day);
      result.add(
        TaskOccurrence(
          id: id,
          taskId: task.id,
          scheduledDate: day,
          originalDate: day,
          windowStart: window?.$1,
          windowEnd: window?.$2,
        ),
      );
    }

    return result;
  }

  @override
  TaskOccurrence rescheduleMissed({
    required Task task,
    required TaskOccurrence missed,
    required DateTime now,
  }) {
    final today = dateOnly(now);
    final original = missed.originalDate ?? missed.scheduledDate;
    final recurrence = task.recurrence;

    final DateTime next;
    if (recurrence is FlexibleRecurrence) {
      // Slide forward a day, never into the past; clamp at the window end so an
      // overdue task settles on its last allowed day rather than stacking.
      final slid = addDays(dateOnly(missed.scheduledDate), 1);
      var candidate = slid.isAfter(today) ? slid : today;
      final end = missed.windowEnd;
      if (end != null && candidate.isAfter(dateOnly(end))) {
        candidate = dateOnly(end);
      }
      next = candidate;
    } else {
      // Strict: roll forward to the next matching day strictly after today,
      // so we don't stack a duplicate on a day that already has this task.
      next =
          _nextStrictOnOrAfter(recurrence, addDays(today, 1)) ??
          addDays(today, 1);
    }

    return missed.copyWith(
      scheduledDate: next,
      status: OccurrenceStatus.rescheduled,
      originalDate: original,
    );
  }

  // ── recurrence evaluation ──────────────────────────────────────────────────

  bool _occursOn(Recurrence recurrence, DateTime day) {
    switch (recurrence) {
      case StrictRecurrence(
        :final weekdays,
        :final dayOfMonth,
        :final exactDate,
      ):
        if (exactDate != null) return dateOnly(exactDate) == day;
        if (dayOfMonth != null) {
          final dim = _daysInMonth(day.year, day.month);
          final target = dayOfMonth > dim ? dim : dayOfMonth;
          return day.day == target;
        }
        return weekdays.contains(day.weekday);
      case FlexibleRecurrence():
        return _flexibleOccursOn(recurrence, day);
    }
  }

  bool _flexibleOccursOn(FlexibleRecurrence r, DateTime day) {
    if (r.season != null) return _isSeasonStart(r.season!, day);
    final (start, end) = _periodBounds(r.period, day);
    // Round hours/24 rather than inDays: a span between two local midnights that
    // crosses a DST change is 23h or 25h short/long, which would truncate.
    final lengthDays = (end.difference(start).inHours / 24).round() + 1;
    final times = r.timesPerPeriod.clamp(1, lengthDays);
    for (var i = 0; i < times; i++) {
      final offset = (i * lengthDays / times).floor();
      if (addDays(start, offset) == day) return true;
    }
    return false;
  }

  /// The slide window for a freshly-materialised occurrence, or null for strict
  /// recurrences (which don't float).
  (DateTime, DateTime)? _windowFor(Recurrence recurrence, DateTime day) {
    if (recurrence is! FlexibleRecurrence) return null;
    if (recurrence.season != null) {
      return _seasonBounds(recurrence.season!, day);
    }
    final (start, end) = _periodBounds(recurrence.period, day);
    if (recurrence.windowDays > 0) {
      final capped = addDays(day, recurrence.windowDays);
      return (day, capped.isBefore(end) ? capped : end);
    }
    return (day, end);
  }

  DateTime? _nextStrictOnOrAfter(Recurrence recurrence, DateTime from) {
    if (recurrence is! StrictRecurrence) return null;
    var cursor = dateOnly(from);
    // Bounded search: covers a full year for weekday/day-of-month patterns and
    // any future one-off date within range.
    for (var i = 0; i < 366; i++) {
      if (_occursOn(recurrence, cursor)) return cursor;
      cursor = addDays(cursor, 1);
    }
    return null;
  }

  // ── period maths ───────────────────────────────────────────────────────────

  /// Inclusive [start, end] day bounds of the [period] containing [day].
  (DateTime, DateTime) _periodBounds(FrequencyPeriod period, DateTime day) {
    switch (period) {
      case FrequencyPeriod.day:
        return (day, day);
      case FrequencyPeriod.week:
        final start = addDays(day, -(day.weekday - 1)); // Monday
        return (start, addDays(start, 6));
      case FrequencyPeriod.month:
        final start = DateTime(day.year, day.month);
        final end = DateTime(
          day.year,
          day.month,
          _daysInMonth(day.year, day.month),
        );
        return (start, end);
      case FrequencyPeriod.year:
        return (DateTime(day.year), DateTime(day.year, 12, 31));
    }
  }

  /// Northern-hemisphere season month ranges; seasonal tasks anchor to the
  /// first day of the season and may slide across it.
  (DateTime, DateTime) _seasonBounds(Season season, DateTime day) {
    final (startMonth, endMonth) = switch (season) {
      Season.spring => (3, 5),
      Season.summer => (6, 8),
      Season.autumn => (9, 11),
      Season.winter => (12, 2),
    };
    if (season == Season.winter) {
      // Dec of this year through Feb of next.
      final start = DateTime(day.year, 12);
      final end = DateTime(day.year + 1, 2, _daysInMonth(day.year + 1, 2));
      return (start, end);
    }
    final start = DateTime(day.year, startMonth);
    final end = DateTime(day.year, endMonth, _daysInMonth(day.year, endMonth));
    return (start, end);
  }

  bool _isSeasonStart(Season season, DateTime day) {
    final startMonth = switch (season) {
      Season.spring => 3,
      Season.summer => 6,
      Season.autumn => 9,
      Season.winter => 12,
    };
    return day.month == startMonth && day.day == 1;
  }

  int _daysInMonth(int year, int month) => DateTime(year, month + 1, 0).day;
}
