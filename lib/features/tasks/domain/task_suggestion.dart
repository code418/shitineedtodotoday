import 'scheduling/recurrence.dart';
import 'task.dart';

/// A ready-made task the app can offer the user as a starting point — e.g. the
/// curated cleaning plan in `data/starter_tasks.dart`.
///
/// Suggestions are *templates*: lightweight and `const`, with no owner or
/// timestamps. Call [toTask] to turn one into a real, ownable [Task].
class TaskSuggestion {
  const TaskSuggestion({
    required this.key,
    required this.title,
    required this.category,
    required this.weekday,
    required this.estimatedEffortMinutes,
  });

  /// Stable slug, handy as a de-dupe key and a seed for generated ids.
  final String key;

  final String title;

  /// The themed grouping this belongs to, e.g. "Reset & Surfaces".
  final String category;

  /// ISO weekday this is suggested for (1 = Mon … 7 = Sun).
  final int weekday;

  final int estimatedEffortMinutes;

  /// The strict, weekly recurrence implied by [weekday].
  Recurrence get recurrence => Recurrence.strict(weekdays: [weekday]);

  /// Materialise this suggestion into a concrete [Task] for [ownerId].
  ///
  /// [id] and [now] are passed in so callers control id generation and clock
  /// (keeping this pure and easy to test).
  Task toTask({
    required String id,
    required String ownerId,
    required DateTime now,
  }) {
    return Task(
      id: id,
      ownerId: ownerId,
      title: title,
      category: category,
      recurrence: recurrence,
      estimatedEffortMinutes: estimatedEffortMinutes,
      createdAt: now,
      updatedAt: now,
    );
  }
}
