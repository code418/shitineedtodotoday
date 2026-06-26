import 'package:flutter_test/flutter_test.dart';
import 'package:snitd/features/tasks/data/starter_tasks.dart';
import 'package:snitd/features/tasks/domain/scheduling/recurrence.dart';

void main() {
  group('Starter cleaning plan', () {
    test('is non-empty with unique keys', () {
      expect(kStarterCleaningPlan, isNotEmpty);
      final keys = kStarterCleaningPlan.map((s) => s.key).toSet();
      expect(keys.length, kStarterCleaningPlan.length, reason: 'keys unique');
    });

    test('covers all seven days with sensible estimates', () {
      final weekdays = kStarterCleaningPlan.map((s) => s.weekday).toSet();
      expect(weekdays, {1, 2, 3, 4, 5, 6, 7});
      for (final suggestion in kStarterCleaningPlan) {
        expect(suggestion.title, isNotEmpty);
        expect(suggestion.category, isNotEmpty);
        expect(suggestion.estimatedEffortMinutes, greaterThan(0));
      }
    });

    test('toTask builds a weekly strict recurrence on the suggested day', () {
      final monday = kStarterCleaningPlan.firstWhere(
        (s) => s.weekday == DateTime.monday,
      );
      final now = DateTime(2026, 6, 29);
      final task = monday.toTask(id: 't1', ownerId: 'u1', now: now);

      expect(task.id, 't1');
      expect(task.ownerId, 'u1');
      expect(task.title, monday.title);
      expect(task.estimatedEffortMinutes, monday.estimatedEffortMinutes);
      final recurrence = task.recurrence;
      expect(recurrence, isA<StrictRecurrence>());
      expect((recurrence as StrictRecurrence).weekdays, [DateTime.monday]);
    });
  });
}
