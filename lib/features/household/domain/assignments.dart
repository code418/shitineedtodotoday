import '../../tasks/domain/scheduling/task_occurrence.dart';

/// Groups today's [occurrences] by the assignee id of their task.
///
/// The key `null` bucket is "anyone / unassigned".
/// [assigneeByTaskId] maps taskId → assigneeId (null means unassigned).
Map<String?, List<TaskOccurrence>> assignmentsByMember(
  Iterable<TaskOccurrence> occurrences,
  Map<String, String?> assigneeByTaskId,
) {
  final out = <String?, List<TaskOccurrence>>{};
  for (final o in occurrences) {
    final who = assigneeByTaskId[o.taskId];
    (out[who] ??= []).add(o);
  }
  return out;
}
