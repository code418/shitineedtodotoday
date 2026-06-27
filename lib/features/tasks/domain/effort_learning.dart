import 'scheduling/task_occurrence.dart';

/// Effort estimates are rounded to the nearest [kEffortRoundingMinutes] so the
/// numbers the app shows stay tidy ("~10m", not "~11m").
const int kEffortRoundingMinutes = 5;

/// How many of the most recent completions feed a learned estimate by default.
const int kEffortLearningWindow = 5;

/// Refine a task's effort estimate from how long it *actually* took recently.
///
/// Takes [actuals] in chronological order (oldest → newest), uses the most
/// recent [window] of them, and returns their mean rounded to the nearest
/// [kEffortRoundingMinutes] (and never below it). With no data it returns
/// [fallback] (the task's existing seed estimate), clamped the same way.
int learnedEstimateMinutes(
  List<int> actuals, {
  int window = kEffortLearningWindow,
  int fallback = 15,
}) {
  if (actuals.isEmpty) return _roundToStep(fallback);
  final recent = actuals.length <= window
      ? actuals
      : actuals.sublist(actuals.length - window);
  final mean = recent.reduce((a, b) => a + b) / recent.length;
  return _roundToStep(mean.round());
}

/// Whether a freshly [learned] estimate is meaningfully quicker than the
/// task's current [estimate] — drives the gentle "quicker than you thought"
/// nudge in the UI.
bool isQuickerThanExpected(int learned, int estimate) => learned < estimate;

/// The recent actual durations from [occurrences] for effort learning:
/// completed occurrences that recorded a duration, ordered oldest → newest by
/// completion time, limited to the most recent [window].
List<int> recentActualMinutes(
  Iterable<TaskOccurrence> occurrences, {
  int window = kEffortLearningWindow,
}) {
  final done =
      occurrences
          .where(
            (o) =>
                o.status == OccurrenceStatus.done &&
                o.actualDurationMinutes != null,
          )
          .toList()
        ..sort((a, b) {
          final at = a.completedAt ?? a.scheduledDate;
          final bt = b.completedAt ?? b.scheduledDate;
          return at.compareTo(bt);
        });
  final minutes = [for (final o in done) o.actualDurationMinutes!];
  return minutes.length <= window
      ? minutes
      : minutes.sublist(minutes.length - window);
}

int _roundToStep(int minutes) {
  final stepped =
      (minutes / kEffortRoundingMinutes).round() * kEffortRoundingMinutes;
  return stepped < kEffortRoundingMinutes ? kEffortRoundingMinutes : stepped;
}
