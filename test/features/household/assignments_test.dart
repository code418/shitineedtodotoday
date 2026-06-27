// test/features/household/assignments_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:snitd/features/household/domain/assignments.dart';
import 'package:snitd/features/tasks/domain/scheduling/task_occurrence.dart';

void main() {
  final today = DateTime(2026, 6, 27);

  TaskOccurrence occ(String taskId) => TaskOccurrence(
    id: '${taskId}_2026-06-27',
    taskId: taskId,
    scheduledDate: today,
  );

  test('groups by assignee id', () {
    final occurrences = [occ('t1'), occ('t2'), occ('t3')];
    final assignees = {'t1': 'alice', 't2': 'alice', 't3': 'bob'};

    final result = assignmentsByMember(occurrences, assignees);

    expect(result['alice']?.map((o) => o.taskId).toList(), ['t1', 't2']);
    expect(result['bob']?.map((o) => o.taskId).toList(), ['t3']);
    expect(result.containsKey(null), isFalse);
  });

  test('places unassigned tasks in the null bucket', () {
    final occurrences = [occ('t1'), occ('t2')];
    final assignees = <String, String?>{'t1': null, 't2': null};

    final result = assignmentsByMember(occurrences, assignees);

    expect(result[null]?.length, 2);
  });

  test('mixes assigned and unassigned into correct buckets', () {
    final occurrences = [occ('t1'), occ('t2'), occ('t3')];
    final assignees = <String, String?>{
      't1': 'alice',
      't2': null,
      't3': 'alice',
    };

    final result = assignmentsByMember(occurrences, assignees);

    expect(result['alice']?.map((o) => o.taskId).toList(), ['t1', 't3']);
    expect(result[null]?.map((o) => o.taskId).toList(), ['t2']);
  });

  test('returns empty map for empty occurrences', () {
    final result = assignmentsByMember([], {});
    expect(result, isEmpty);
  });

  test('occurrence with no assignee entry falls into null bucket', () {
    final occurrences = [occ('unknown')];
    final assignees = <String, String?>{};

    final result = assignmentsByMember(occurrences, assignees);
    // assigneeByTaskId['unknown'] == null (key absent -> null)
    expect(result[null], isNotEmpty);
  });
}
