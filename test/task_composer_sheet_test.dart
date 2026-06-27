import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snitd/features/settings/application/settings_providers.dart';
import 'package:snitd/features/tasks/application/tasks_providers.dart';
import 'package:snitd/features/tasks/data/task_repository.dart';
import 'package:snitd/features/tasks/presentation/task_composer_sheet.dart';

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
}
