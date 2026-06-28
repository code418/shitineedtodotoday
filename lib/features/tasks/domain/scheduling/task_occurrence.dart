import 'package:freezed_annotation/freezed_annotation.dart';

part 'task_occurrence.freezed.dart';
part 'task_occurrence.g.dart';

/// The lifecycle status of a single [TaskOccurrence].
enum OccurrenceStatus {
  /// Scheduled but not yet acted on.
  pending,

  /// Completed by the user.
  done,

  /// Explicitly skipped ("not today") — forgiven, not failed.
  skipped,

  /// Moved to a different day by the forgiving scheduler.
  rescheduled,
}

/// One concrete instance of a task on a specific day — i.e. a single line on
/// the daily checklist.
///
/// Occurrences are generated from a [Task]'s recurrence by the [Scheduler] and
/// are what the "today" screen renders.
@freezed
abstract class TaskOccurrence with _$TaskOccurrence {
  const TaskOccurrence._();

  const factory TaskOccurrence({
    required String id,
    required String taskId,

    /// The day this occurrence is currently planned for.
    required DateTime scheduledDate,

    /// For flexible recurrences, the inclusive window the occurrence may move
    /// within before it is considered overdue.
    DateTime? windowStart,
    DateTime? windowEnd,

    @Default(OccurrenceStatus.pending) OccurrenceStatus status,

    /// The day this occurrence was first planned for, preserved across
    /// reschedules so we can reason about how far it has slipped.
    DateTime? originalDate,

    /// When the user marked it done.
    DateTime? completedAt,

    /// How long the user reported it actually took. Feeds effort learning so
    /// future scheduling can be more realistic.
    int? actualDurationMinutes,

    /// Set when the user has *deliberately* placed this occurrence on a day
    /// (e.g. dragged it on the agenda). The load balancer leaves pinned
    /// occurrences where they are rather than spreading them.
    @Default(false) bool pinned,
  }) = _TaskOccurrence;

  factory TaskOccurrence.fromJson(Map<String, dynamic> json) =>
      _$TaskOccurrenceFromJson(json);

  /// Whether this occurrence still needs the user's attention.
  bool get isOpen =>
      status == OccurrenceStatus.pending ||
      status == OccurrenceStatus.rescheduled;
}
