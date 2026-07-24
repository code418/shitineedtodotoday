import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snitd/core/design/tokens/app_icons.dart';
import 'package:snitd/features/settings/application/settings_providers.dart';
import 'package:snitd/features/tasks/application/tasks_providers.dart';
import 'package:snitd/features/tasks/data/occurrence_repository.dart';
import 'package:snitd/features/tasks/data/task_repository.dart';
import 'package:snitd/features/tasks/domain/task.dart';
import 'package:snitd/features/tasks/presentation/today_screen.dart';

import '../../occurrence_service_test.dart' show FakeOccurrenceRepository;

/// A task repository whose [upsert] blocks until [release], so a test can keep
/// the first add in-flight while attempting a second tap on the same tile.
class _BlockingTaskRepository implements TaskRepository {
  final Map<String, Task> store = {};
  final Completer<void> _gate = Completer<void>();
  int upsertCalls = 0;
  int _seq = 0;

  void release() => _gate.complete();

  @override
  Stream<List<Task>> watchTasks(String ownerId) =>
      Stream.value(store.values.where((t) => t.ownerId == ownerId).toList());

  @override
  Future<void> upsert(Task task) async {
    upsertCalls++;
    await _gate.future;
    store[task.id] = task;
  }

  @override
  Future<void> delete(String ownerId, String taskId) async =>
      store.remove(taskId);

  @override
  String newId(String ownerId) => 'task-${_seq++}';
}

void main() {
  testWidgets('double-tapping a starter suggestion adds the task only once', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final fakeTaskRepo = _BlockingTaskRepository();

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
        child: const MaterialApp(home: TodayScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // Empty checklist → starter suggestions are shown. The blocking repo
    // keeps the first add in-flight so the tile stays mounted for a second
    // tap.
    final firstSuggestion = find.byIcon(AppIcons.addCircle).first;
    expect(firstSuggestion, findsWidgets);

    await tester.tap(firstSuggestion);
    await tester.pump();
    // Second tap while the first add is still pending must be a no-op — each
    // addFromSuggestion mints a fresh task id, so two would persist two tasks.
    await tester.tap(firstSuggestion);
    await tester.pump();
    expect(
      fakeTaskRepo.upsertCalls,
      1,
      reason: 'the in-flight guard must suppress the second add',
    );

    fakeTaskRepo.release();
    await tester.pumpAndSettle();

    expect(fakeTaskRepo.upsertCalls, 1);
    expect(fakeTaskRepo.store.length, 1);
  });
}
