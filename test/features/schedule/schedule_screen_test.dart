import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snitd/core/design/tokens/app_icons.dart';
import 'package:snitd/features/schedule/presentation/schedule_screen.dart';
import 'package:snitd/features/settings/application/settings_providers.dart';
import 'package:snitd/features/tasks/application/tasks_providers.dart';
import 'package:snitd/features/tasks/domain/scheduling/recurrence.dart';
import 'package:snitd/features/tasks/domain/scheduling/task_occurrence.dart';
import 'package:snitd/features/tasks/domain/task.dart';

void main() {
  testWidgets(
    'done occurrences render non-draggable; open ones stay draggable',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      // Monday 2026-06-29 — both strict-Monday tasks land on this week's Monday.
      final monday = DateTime(2026, 6, 29);

      Task strictMonday(String id, String title) => Task(
        id: id,
        ownerId: 'u1',
        title: title,
        recurrence: const Recurrence.strict(weekdays: [DateTime.monday]),
        estimatedEffortMinutes: 15,
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      );

      // Task 'a' already completed today; task 'b' still open.
      final doneOcc = TaskOccurrence(
        id: 'a_2026-06-29',
        taskId: 'a',
        scheduledDate: monday,
        status: OccurrenceStatus.done,
        completedAt: DateTime(2026, 6, 29, 10),
        actualDurationMinutes: 12,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            clockProvider.overrideWithValue(() => DateTime(2026, 6, 29, 9)),
            tasksProvider.overrideWith(
              (ref) => Stream.value([
                strictMonday('a', 'Done task'),
                strictMonday('b', 'Open task'),
              ]),
            ),
            occurrencesProvider.overrideWith((ref) => Stream.value([doneOcc])),
          ],
          child: const MaterialApp(home: ScheduleScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Done task'), findsOneWidget);
      expect(find.text('Open task'), findsOneWidget);

      // Only the open occurrence is draggable; the done one is static.
      expect(find.byType(LongPressDraggable<TaskOccurrence>), findsOneWidget);
      // The done row shows a check marker rather than a drag handle.
      expect(find.byIcon(AppIcons.check), findsOneWidget);
    },
  );
}
