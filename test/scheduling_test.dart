import 'package:flutter_test/flutter_test.dart';
import 'package:snitd/features/tasks/domain/scheduling/recurrence.dart';

void main() {
  group('Recurrence model', () {
    test('strict recurrence survives a JSON round-trip', () {
      const recurrence = Recurrence.strict(weekdays: [DateTime.monday]);
      final decoded = Recurrence.fromJson(recurrence.toJson());
      expect(decoded, recurrence);
      expect(decoded, isA<StrictRecurrence>());
    });

    test('flexible recurrence survives a JSON round-trip', () {
      const recurrence = Recurrence.flexible(
        timesPerPeriod: 1,
        period: FrequencyPeriod.week,
        windowDays: 3,
      );
      final decoded = Recurrence.fromJson(recurrence.toJson());
      expect(decoded, recurrence);
      expect(decoded, isA<FlexibleRecurrence>());
    });
  });

  // The real engine's behaviour is covered in forgiving_scheduler_test.dart.
}
