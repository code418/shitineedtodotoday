import '../../tasks/domain/scheduling/task_occurrence.dart';

/// Groups today's [occurrences] by the assignee id of their task.
///
/// The key `null` bucket is "anyone / unassigned".
/// [assigneeByTaskId] maps taskId → assigneeId (null means unassigned).
///
/// [knownAssigneeIds], when provided, is the set of ids that have their own
/// bucket (the owner sentinel + current household members). Any task assigned
/// to an id outside this set — e.g. a member who has since been removed — is
/// folded into the `null` bucket so it stays visible and re-assignable rather
/// than silently disappearing. When omitted, every assignee keeps its own
/// bucket (the original behaviour).
Map<String?, List<TaskOccurrence>> assignmentsByMember(
  Iterable<TaskOccurrence> occurrences,
  Map<String, String?> assigneeByTaskId, {
  Set<String>? knownAssigneeIds,
}) {
  final out = <String?, List<TaskOccurrence>>{};
  for (final o in occurrences) {
    final raw = assigneeByTaskId[o.taskId];
    final who =
        (raw != null &&
            (knownAssigneeIds == null || knownAssigneeIds.contains(raw)))
        ? raw
        : null;
    (out[who] ??= []).add(o);
  }
  return out;
}
