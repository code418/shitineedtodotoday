import 'package:flutter_test/flutter_test.dart';
import 'package:snitd/features/tasks/domain/scheduling/recurrence.dart';
import 'package:snitd/features/tasks/domain/scheduling/task_occurrence.dart';
import 'package:snitd/features/tasks/domain/task.dart';
import 'package:snitd/features/tasks/domain/task_suggestion.dart';

/// Mirrors the constraint of Firestore's `DocumentReference.set` codec: a value
/// is writable only if it is null, a `num`, `bool`, `String`, a `List` of safe
/// values, or a `Map<String, …>` of safe values. A live Dart object (e.g. a
/// `StrictRecurrence`) makes the native codec throw
/// `Invalid argument: Instance of 'StrictRecurrence'`.
///
/// Returns the dotted path of the first offending value, or null if safe.
String? firstUnsafePath(Object? value, [String path = r'$']) {
  if (value == null || value is num || value is bool || value is String) {
    return null;
  }
  if (value is List) {
    for (var i = 0; i < value.length; i++) {
      final bad = firstUnsafePath(value[i], '$path[$i]');
      if (bad != null) return bad;
    }
    return null;
  }
  if (value is Map) {
    for (final entry in value.entries) {
      if (entry.key is! String) {
        return '$path.<non-string-key:${entry.key.runtimeType}>';
      }
      final bad = firstUnsafePath(entry.value, '$path.${entry.key}');
      if (bad != null) return bad;
    }
    return null;
  }
  // Anything else (a model instance, an enum, a DateTime, …) is not codec-safe.
  return '$path -> ${value.runtimeType}';
}

void main() {
  final ts = DateTime.utc(2026, 6, 28, 9, 30);

  Task taskWith(Recurrence recurrence) => Task(
    id: 't1',
    ownerId: 'owner-1',
    title: 'Clean the kitchen',
    recurrence: recurrence,
    createdAt: ts,
    updatedAt: ts,
  );

  group('Task.toJson is Firestore-codec-safe', () {
    test('with a strict recurrence (the suggestion-add path)', () {
      final json = taskWith(const Recurrence.strict(weekdays: [1])).toJson();

      // The nested recurrence must be a plain Map, not a live object.
      expect(json['recurrence'], isA<Map<String, dynamic>>());
      expect(
        firstUnsafePath(json),
        isNull,
        reason: 'Task.toJson() must contain only Firestore-codec-safe values',
      );
    });

    test('with a flexible recurrence', () {
      final json = taskWith(
        const Recurrence.flexible(
          timesPerPeriod: 2,
          period: FrequencyPeriod.month,
          season: Season.summer,
        ),
      ).toJson();

      expect(json['recurrence'], isA<Map<String, dynamic>>());
      expect(firstUnsafePath(json), isNull);
    });

    test('round-trips through fromJson', () {
      final original = taskWith(const Recurrence.strict(dayOfMonth: 15));
      final restored = Task.fromJson(original.toJson());
      expect(restored, original);
    });

    test('built from a real starter suggestion', () {
      const suggestion = TaskSuggestion(
        key: 'hallway-reset',
        title: 'Hallway reset',
        category: 'Reset & Surfaces',
        weekday: 1,
        estimatedEffortMinutes: 5,
      );
      final task = suggestion.toTask(id: 't9', ownerId: 'o', now: ts);
      expect(firstUnsafePath(task.toJson()), isNull);
    });
  });

  group('TaskOccurrence.toJson is Firestore-codec-safe', () {
    test('a pending occurrence', () {
      final json = TaskOccurrence(
        id: 'o1',
        taskId: 't1',
        scheduledDate: ts,
        originalDate: ts,
      ).toJson();
      expect(firstUnsafePath(json), isNull);
    });
  });
}
