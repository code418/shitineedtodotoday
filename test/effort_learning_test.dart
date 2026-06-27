import 'package:flutter_test/flutter_test.dart';
import 'package:snitd/features/tasks/domain/effort_learning.dart';
import 'package:snitd/features/tasks/domain/scheduling/task_occurrence.dart';

TaskOccurrence _done(int minutes, DateTime completedAt) => TaskOccurrence(
  id: 'o-${completedAt.toIso8601String()}',
  taskId: 't1',
  scheduledDate: completedAt,
  status: OccurrenceStatus.done,
  completedAt: completedAt,
  actualDurationMinutes: minutes,
);

void main() {
  group('learnedEstimateMinutes', () {
    test('returns the fallback when there is no data', () {
      expect(learnedEstimateMinutes([], fallback: 15), 15);
    });

    test('means and rounds to the nearest 5 minutes', () {
      expect(learnedEstimateMinutes([10, 12, 9]), 10); // mean 10.33 -> 10
      expect(learnedEstimateMinutes([13]), 15); // 13 -> 15
      expect(learnedEstimateMinutes([8]), 10); // 8 -> 10
    });

    test('never drops below the rounding step', () {
      expect(learnedEstimateMinutes([1, 2]), kEffortRoundingMinutes);
    });

    test('uses only the most recent window of actuals', () {
      // Older big values are dropped; last 5 average to ~10.
      final actuals = [60, 60, 10, 10, 10, 10, 10];
      expect(learnedEstimateMinutes(actuals, window: 5), 10);
    });
  });

  group('isQuickerThanExpected', () {
    test('true only when learned is below the current estimate', () {
      expect(isQuickerThanExpected(10, 15), isTrue);
      expect(isQuickerThanExpected(15, 15), isFalse);
      expect(isQuickerThanExpected(20, 15), isFalse);
    });
  });

  group('recentActualMinutes', () {
    test('extracts done durations oldest-first, capped to the window', () {
      final occ = [
        _done(20, DateTime(2026, 6, 1)),
        _done(10, DateTime(2026, 6, 3)),
        _done(12, DateTime(2026, 6, 2)),
        // a pending occurrence with no duration is ignored
        TaskOccurrence(
          id: 'pending',
          taskId: 't1',
          scheduledDate: DateTime(2026, 6, 4),
        ),
      ];
      expect(recentActualMinutes(occ), [20, 12, 10]); // sorted by completedAt
    });

    test('keeps only the most recent window entries', () {
      final occ = [
        for (var i = 0; i < 8; i++) _done(i, DateTime(2026, 6, 1 + i)),
      ];
      expect(recentActualMinutes(occ, window: 3), [5, 6, 7]);
    });
  });
}
