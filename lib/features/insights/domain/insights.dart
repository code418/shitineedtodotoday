import '../../../core/util/date_labels.dart';
import '../../tasks/domain/scheduling/forgiving_scheduler.dart' show dateOnly;
import '../../tasks/domain/scheduling/recurrence.dart';
import '../../tasks/domain/scheduling/task_occurrence.dart';
import '../../tasks/domain/task.dart';

enum InsightsPeriod { week, month, year }

class InsightBucket {
  const InsightBucket(this.label, this.doneCount);
  final String label;
  final int doneCount;
}

class TaskSlip {
  const TaskSlip(this.taskId, this.skips);
  final String taskId;
  final int skips;
}

class AdaptiveSuggestion {
  const AdaptiveSuggestion({
    required this.taskId,
    required this.suggestedRecurrence,
  });
  final String taskId;
  final Recurrence suggestedRecurrence;
}

class InsightsSummary {
  const InsightsSummary({
    required this.completedCount,
    required this.skippedCount,
    required this.completionRate,
    required this.streakDays,
    required this.totalMinutes,
    required this.buckets,
    required this.slips,
    this.suggestion,
  });

  final int completedCount;
  final int skippedCount;
  final double completionRate; // 0..1
  final int streakDays;
  final int totalMinutes;
  final List<InsightBucket> buckets;
  final List<TaskSlip> slips;
  final AdaptiveSuggestion? suggestion;
}

/// Pure analytics function — takes a fixed [now] and makes no Firebase/clock
/// calls of its own.
InsightsSummary computeInsights({
  required List<TaskOccurrence> occurrences,
  required List<Task> tasks,
  required DateTime now,
  required InsightsPeriod period,
}) {
  final today = dateOnly(now);

  // Window: inclusive days ending today, aligned to the chart buckets.
  //   week  — 7 days  (7 daily buckets)
  //   month — 28 days (4 × 7-day buckets); subtract 27 so window = [today-27, today]
  //   year  — 12 calendar months; start on the 1st of the month 11 months ago
  final windowStart = switch (period) {
    InsightsPeriod.week => today.subtract(const Duration(days: 6)),
    InsightsPeriod.month => today.subtract(const Duration(days: 27)),
    InsightsPeriod.year => () {
      var m = today.month - 11;
      var y = today.year;
      while (m <= 0) {
        m += 12;
        y--;
      }
      return DateTime(y, m);
    }(),
  };

  // Occurrences whose scheduledDate falls within the window.
  final inWindow = occurrences.where((o) {
    final d = dateOnly(o.scheduledDate);
    return !d.isBefore(windowStart) && !d.isAfter(today);
  }).toList();

  // Aggregate window stats.
  var completedCount = 0;
  var skippedCount = 0;
  var totalMinutes = 0;
  for (final occ in inWindow) {
    if (occ.status == OccurrenceStatus.done) {
      completedCount++;
      totalMinutes += occ.actualDurationMinutes ?? 0;
    } else if (occ.status == OccurrenceStatus.skipped) {
      skippedCount++;
    }
  }

  final denominator = completedCount + skippedCount;
  final completionRate = denominator == 0 ? 0.0 : completedCount / denominator;

  // Streak — walk back from today across ALL occurrences (not window-limited).
  // Build a set of done dates first so each cursor step is O(1) not O(n).
  final doneDays = <DateTime>{
    for (final o in occurrences)
      if (o.status == OccurrenceStatus.done) dateOnly(o.scheduledDate),
  };
  var streakDays = 0;
  var cursor = today;
  while (doneDays.contains(cursor)) {
    streakDays++;
    cursor = cursor.subtract(const Duration(days: 1));
  }

  // Buckets (oldest → newest).
  final List<InsightBucket> buckets;
  switch (period) {
    case InsightsPeriod.week:
      // 7 daily buckets labelled by weekday short name.
      buckets = List.generate(7, (i) {
        final day = windowStart.add(Duration(days: i));
        final label = kWeekdayNamesShort[day.weekday - 1];
        final doneCount = inWindow
            .where(
              (o) =>
                  o.status == OccurrenceStatus.done &&
                  dateOnly(o.scheduledDate) == day,
            )
            .length;
        return InsightBucket(label, doneCount);
      });

    case InsightsPeriod.month:
      // 4 buckets of 7 days (most recent 28 days); W1 = oldest, W4 = most recent.
      buckets = List.generate(4, (i) {
        final bucketStart = today.subtract(Duration(days: 27 - i * 7));
        final bucketEnd = today.subtract(Duration(days: 21 - i * 7));
        final doneCount = inWindow.where((o) {
          final d = dateOnly(o.scheduledDate);
          return o.status == OccurrenceStatus.done &&
              !d.isBefore(bucketStart) &&
              !d.isAfter(bucketEnd);
        }).length;
        return InsightBucket('W${i + 1}', doneCount);
      });

    case InsightsPeriod.year:
      // 12 calendar-month buckets for the last 12 months (oldest → newest).
      // The oldest bucket starts on windowStart (first of the month 11 months
      // ago), so counting from inWindow keeps buckets and rate on the same span.
      buckets = List.generate(12, (i) {
        var month = today.month - 11 + i;
        var year = today.year;
        while (month <= 0) {
          month += 12;
          year--;
        }
        final monthStart = DateTime(year, month);
        // Last day of month: first day of next month minus one day.
        final monthEnd = DateTime(year, month + 1, 0);
        final label = kMonthNamesShort[month - 1];
        final doneCount = inWindow.where((o) {
          final d = dateOnly(o.scheduledDate);
          return o.status == OccurrenceStatus.done &&
              !d.isBefore(monthStart) &&
              !d.isAfter(monthEnd);
        }).length;
        return InsightBucket(label, doneCount);
      });
  }

  // Slips — skipped occurrences in window, grouped by taskId, top 3 desc.
  final slipMap = <String, int>{};
  for (final occ in inWindow) {
    if (occ.status == OccurrenceStatus.skipped) {
      slipMap[occ.taskId] = (slipMap[occ.taskId] ?? 0) + 1;
    }
  }
  final slips = slipMap.entries.map((e) => TaskSlip(e.key, e.value)).toList()
    ..sort((a, b) {
      final cmp = b.skips.compareTo(a.skips);
      return cmp != 0 ? cmp : a.taskId.compareTo(b.taskId);
    });
  final topSlips = slips.take(3).toList();

  // Suggestion — first slip with a StrictRecurrence task.
  // The human-readable message is composed in the presentation layer via
  // appStringsProvider, keeping user-facing copy out of the domain.
  AdaptiveSuggestion? suggestion;
  final taskMap = {for (final t in tasks) t.id: t};
  for (final slip in topSlips) {
    final task = taskMap[slip.taskId];
    if (task == null) continue;
    if (task.recurrence is StrictRecurrence) {
      suggestion = AdaptiveSuggestion(
        taskId: slip.taskId,
        suggestedRecurrence: const Recurrence.flexible(
          period: FrequencyPeriod.week,
        ),
      );
      break;
    }
  }

  return InsightsSummary(
    completedCount: completedCount,
    skippedCount: skippedCount,
    completionRate: completionRate,
    streakDays: streakDays,
    totalMinutes: totalMinutes,
    buckets: buckets,
    slips: topSlips,
    suggestion: suggestion,
  );
}
