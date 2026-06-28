import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snitd/features/settings/application/settings_providers.dart';
import 'package:snitd/features/tasks/application/tasks_providers.dart';
import 'package:snitd/features/tasks/data/occurrence_repository.dart';
import 'package:snitd/features/tasks/data/task_repository.dart';
import 'package:snitd/features/tasks/domain/scheduling/recurrence.dart';
import 'package:snitd/features/tasks/domain/task.dart';
import 'package:snitd/features/tasks/presentation/task_composer_sheet.dart';

import 'occurrence_service_test.dart' show FakeOccurrenceRepository;
import 'task_service_test.dart' show FakeTaskRepository;

void main() {
  testWidgets(
    'showTaskComposer: entering a title and saving adds the task to the repository',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final fakeTaskRepo = FakeTaskRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            currentOwnerIdProvider.overrideWithValue('u1'),
            taskRepositoryProvider.overrideWithValue(fakeTaskRepo),
            occurrenceRepositoryProvider.overrideWithValue(
              FakeOccurrenceRepository(),
            ),
            clockProvider.overrideWithValue(() => DateTime(2026, 6, 29, 9)),
          ],
          child: MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: ElevatedButton(
                  onPressed: () => showTaskComposer(context),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      );

      // Open the composer sheet
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Enter a task title
      await tester.enterText(find.byType(TextField).first, 'Clean windows');
      await tester.pumpAndSettle();

      // Default preset is "Specific days" with Monday pre-selected.
      // Mon chip (weekday 1 = today 2026-06-29) should already be selected,
      // so we can tap Save directly.
      await tester.tap(find.text('Save task'));
      await tester.pumpAndSettle();

      expect(
        fakeTaskRepo.store.values.any((t) => t.title == 'Clean windows'),
        isTrue,
      );
    },
  );

  testWidgets(
    'showTaskComposer: selecting Seasonal + Summer saves a FlexibleRecurrence with season == summer',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final fakeTaskRepo = FakeTaskRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            currentOwnerIdProvider.overrideWithValue('u1'),
            taskRepositoryProvider.overrideWithValue(fakeTaskRepo),
            occurrenceRepositoryProvider.overrideWithValue(
              FakeOccurrenceRepository(),
            ),
            clockProvider.overrideWithValue(() => DateTime(2026, 6, 29, 9)),
          ],
          child: MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: ElevatedButton(
                  onPressed: () => showTaskComposer(context),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      );

      // Open the composer sheet
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Enter a task title
      await tester.enterText(find.byType(TextField).first, 'Clean gutters');
      await tester.pumpAndSettle();

      // Tap the Seasonal preset chip
      await tester.tap(find.text('Seasonal'));
      await tester.pumpAndSettle();

      // Tap the Summer season chip
      await tester.tap(find.text('Summer'));
      await tester.pumpAndSettle();

      // Save the task
      await tester.tap(find.text('Save task'));
      await tester.pumpAndSettle();

      final saved = fakeTaskRepo.store.values.firstWhere(
        (t) => t.title == 'Clean gutters',
      );
      expect(saved.recurrence, isA<FlexibleRecurrence>());
      expect((saved.recurrence as FlexibleRecurrence).season, Season.summer);
    },
  );

  testWidgets('editing a one-off whose date has passed opens the date picker', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final fakeTaskRepo = FakeTaskRepository();

    // A one-off task whose date (1 Jun) is before "now" (1 Jul).
    final task = Task(
      id: 't1',
      ownerId: 'u1',
      title: 'Renew passport',
      recurrence: Recurrence.strict(exactDate: DateTime(2026, 6)),
      estimatedEffortMinutes: 15,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          currentOwnerIdProvider.overrideWithValue('u1'),
          taskRepositoryProvider.overrideWithValue(fakeTaskRepo),
          occurrenceRepositoryProvider.overrideWithValue(
            FakeOccurrenceRepository(),
          ),
          clockProvider.overrideWithValue(() => DateTime(2026, 7, 1, 9)),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () => showTaskComposer(context, existing: task),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    // The one-off date button shows the past date; tapping it must open the
    // picker without tripping showDatePicker's initialDate>=firstDate assert.
    final dateButton = find.text('1 Jun 2026');
    await tester.ensureVisible(dateButton);
    await tester.pumpAndSettle();
    await tester.tap(dateButton);
    await tester.pumpAndSettle();

    expect(find.byType(DatePickerDialog), findsOneWidget);
  });
}
