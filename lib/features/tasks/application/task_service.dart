import '../data/occurrence_repository.dart';
import '../data/task_repository.dart';
import '../domain/scheduling/recurrence.dart';
import '../domain/task.dart';
import '../domain/task_suggestion.dart';

/// Owner-scoped task CRUD. Pure orchestration over a [TaskRepository] with an
/// injected clock and id source, so it's fully testable with a fake repo.
class TaskService {
  TaskService({
    required this.repository,
    required this.occurrences,
    required this.ownerId,
    required this.now,
  });

  final TaskRepository repository;
  final OccurrenceRepository occurrences;
  final String ownerId;
  final DateTime Function() now;

  /// Compose and persist a new task.
  Future<Task> addTask({
    required String title,
    required Recurrence recurrence,
    String? category,
    int estimatedEffortMinutes = 15,
    TaskPriority priority = TaskPriority.normal,
    String notes = '',
    String? reminderTimeOfDay,
  }) async {
    final ts = now();
    final task = Task(
      id: repository.newId(ownerId),
      ownerId: ownerId,
      title: title.trim(),
      notes: notes,
      category: category,
      recurrence: recurrence,
      estimatedEffortMinutes: estimatedEffortMinutes,
      priority: priority,
      reminderTimeOfDay: reminderTimeOfDay,
      createdAt: ts,
      updatedAt: ts,
    );
    await repository.upsert(task);
    return task;
  }

  /// Materialise a starter suggestion into a real, owned task.
  Future<Task> addFromSuggestion(TaskSuggestion suggestion) async {
    final ts = now();
    final task = suggestion.toTask(
      id: repository.newId(ownerId),
      ownerId: ownerId,
      now: ts,
    );
    await repository.upsert(task);
    return task;
  }

  /// Persist edits to an existing task, re-stamping [Task.updatedAt].
  Future<Task> updateTask(Task task) async {
    final updated = task.copyWith(updatedAt: now());
    await repository.upsert(updated);
    return updated;
  }

  /// Delete a task and cascade-remove its occurrences so none are orphaned.
  ///
  /// Occurrences are removed first: if that partially fails, the task simply
  /// remains and the delete can be retried — far better than deleting the task
  /// up front and orphaning its occurrences when the cascade fails.
  Future<void> deleteTask(String taskId) async {
    await occurrences.deleteForTask(ownerId, taskId);
    await repository.delete(ownerId, taskId);
  }
}
