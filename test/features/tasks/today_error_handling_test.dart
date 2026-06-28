import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snitd/core/design/tokens/app_icons.dart';
import 'package:snitd/core/strings/app_strings.dart';
import 'package:snitd/features/settings/application/settings_providers.dart';
import 'package:snitd/features/tasks/application/tasks_providers.dart';
import 'package:snitd/features/tasks/data/occurrence_repository.dart';
import 'package:snitd/features/tasks/data/task_repository.dart';
import 'package:snitd/features/tasks/domain/task.dart';
import 'package:snitd/features/tasks/presentation/today_screen.dart';

import '../../occurrence_service_test.dart' show FakeOccurrenceRepository;

/// A task repo whose writes fail — simulating an offline/permission error.
class _ThrowingTaskRepository implements TaskRepository {
  @override
  Stream<List<Task>> watchTasks(String ownerId) => Stream.value(const <Task>[]);

  @override
  Future<void> upsert(Task task) async => throw Exception('write failed');

  @override
  Future<void> delete(String ownerId, String taskId) async {}

  @override
  String newId(String ownerId) => 'new-task';
}

void main() {
  testWidgets('a failed suggestion-add shows a gentle error snackbar', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          currentOwnerIdProvider.overrideWithValue('u1'),
          taskRepositoryProvider.overrideWithValue(_ThrowingTaskRepository()),
          occurrenceRepositoryProvider.overrideWithValue(
            FakeOccurrenceRepository(),
          ),
          clockProvider.overrideWithValue(() => DateTime(2026, 6, 29, 9)),
        ],
        child: const MaterialApp(home: TodayScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // Empty checklist → starter suggestions are shown; tap the first one.
    final firstSuggestion = find.byIcon(AppIcons.addCircle).first;
    expect(firstSuggestion, findsOneWidget);
    await tester.tap(firstSuggestion);
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.clean.actionFailed), findsOneWidget);
  });
}
