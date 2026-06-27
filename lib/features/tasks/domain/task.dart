import 'package:freezed_annotation/freezed_annotation.dart';

import 'scheduling/recurrence.dart';

part 'task.freezed.dart';
part 'task.g.dart';

/// Relative importance, used by the scheduler when balancing a day's load.
enum TaskPriority { low, normal, high }

/// A thing the user wants to do on a recurring basis.
///
/// A [Task] is the *definition* (what + how often + how much effort); the
/// concrete daily checklist items it generates are [TaskOccurrence]s.
@freezed
abstract class Task with _$Task {
  const Task._();

  const factory Task({
    required String id,

    /// The owning user's uid (anonymous or upgraded account).
    required String ownerId,
    required String title,
    @Default('') String notes,

    /// Optional grouping such as a room or zone ("Kitchen", "Bathroom").
    String? category,

    /// How often this task needs doing — strict or fuzzy.
    required Recurrence recurrence,

    /// Best current estimate of how long it takes, in minutes. Seeded on
    /// creation and refined from recorded actuals
    /// ([TaskOccurrence.actualDurationMinutes]) over time.
    @Default(15) int estimatedEffortMinutes,
    @Default(TaskPriority.normal) TaskPriority priority,

    /// Household member this task is currently assigned to ("whose turn"), or
    /// null for unassigned / anyone.
    String? assigneeId,

    /// Preferred reminder time as `HH:mm` (local). Drives the future
    /// server-side FCM reminder scheduling.
    String? reminderTimeOfDay,
    @Default(true) bool isActive,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Task;

  factory Task.fromJson(Map<String, dynamic> json) => _$TaskFromJson(json);
}
