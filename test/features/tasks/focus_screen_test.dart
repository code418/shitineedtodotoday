import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snitd/app/router.dart';
import 'package:snitd/core/design/design.dart';
import 'package:snitd/core/strings/app_strings.dart';
import 'package:snitd/features/settings/application/settings_providers.dart';
import 'package:snitd/features/tasks/application/tasks_providers.dart';
import 'package:snitd/features/tasks/data/occurrence_repository.dart';
import 'package:snitd/features/tasks/data/task_repository.dart';
import 'package:snitd/features/tasks/domain/scheduling/recurrence.dart';
import 'package:snitd/features/tasks/domain/scheduling/task_occurrence.dart';
import 'package:snitd/features/tasks/domain/task.dart';
import 'package:snitd/features/tasks/presentation/focus_screen.dart';
import 'package:snitd/features/tasks/presentation/today_screen.dart';

import '../../task_service_test.dart' show FakeTaskRepository;

/// Occurrences that re-emit on every write, like a Firestore listener, so the
/// screen moves on when a chore is done or skipped.
class _LiveOccurrences implements OccurrenceRepository {
  final store = <String, TaskOccurrence>{};
  final _changes = StreamController<void>.broadcast();

  @override
  Stream<List<TaskOccurrence>> watchOccurrences(String ownerId) async* {
    yield store.values.toList();
    await for (final _ in _changes.stream) {
      yield store.values.toList();
    }
  }

  @override
  Future<void> upsert(String ownerId, TaskOccurrence occurrence) async {
    store[occurrence.id] = occurrence;
    _changes.add(null);
  }

  @override
  Future<void> delete(String ownerId, String occurrenceId) async {
    store.remove(occurrenceId);
    _changes.add(null);
  }

  @override
  Future<void> deleteForTask(String ownerId, String taskId) async {}
}

Task _task(String id, String title) => Task(
  id: id,
  ownerId: 'u1',
  title: title,
  category: 'Kitchen',
  recurrence: const Recurrence.strict(weekdays: [DateTime.monday]),
  estimatedEffortMinutes: 10,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

void main() {
  const strings = AppStrings.clean;
  late _LiveOccurrences occurrences;
  late FakeTaskRepository tasks;

  setUp(() {
    occurrences = _LiveOccurrences();
    tasks = FakeTaskRepository()
      ..store['a'] = _task('a', 'Wipe the counters')
      ..store['b'] = _task('b', 'Hoover the lounge')
      ..store['c'] = _task('c', 'Clean the bathroom');
  });

  Future<void> pump(WidgetTester tester, {String start = Routes.focus}) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final router = GoRouter(
      initialLocation: Routes.today,
      routes: [
        GoRoute(path: Routes.today, builder: (_, _) => const TodayScreen()),
        GoRoute(path: Routes.focus, builder: (_, _) => const FocusScreen()),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          currentOwnerIdProvider.overrideWithValue('u1'),
          taskRepositoryProvider.overrideWithValue(tasks),
          occurrenceRepositoryProvider.overrideWithValue(occurrences),
          clockProvider.overrideWithValue(() => DateTime(2026, 6, 29, 9)),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    if (start == Routes.focus) {
      unawaited(router.push(Routes.focus));
      await tester.pumpAndSettle();
    }
  }

  String shown(WidgetTester tester) =>
      tester.widget<Text>(find.byKey(const Key('focus-title'))).data!;

  testWidgets('shows one open chore at a time, with what is left', (
    tester,
  ) async {
    // One of today's chores is already done: it isn't offered again.
    occurrences.store['a_2026-06-29'] = TaskOccurrence(
      id: 'a_2026-06-29',
      taskId: 'a',
      scheduledDate: DateTime(2026, 6, 29),
      status: OccurrenceStatus.done,
      completedAt: DateTime(2026, 6, 29, 8),
      actualDurationMinutes: 5,
    );
    await pump(tester);

    expect(find.byKey(const Key('focus-title')), findsOneWidget);
    expect(shown(tester), isNot('Wipe the counters'));
    expect(
      find.text(strings.focusProgressText(left: 2, total: 3)),
      findsOneWidget,
    );
  });

  testWidgets('"Later" moves on and comes back round', (tester) async {
    await pump(tester);
    final seen = <String>[shown(tester)];

    for (var i = 0; i < 3; i++) {
      await tester.tap(find.text(strings.focusLater));
      await tester.pumpAndSettle();
      seen.add(shown(tester));
    }

    // Three different chores, then back to the first; nothing was written.
    expect(seen.take(3).toSet(), hasLength(3));
    expect(seen.last, seen.first);
    expect(occurrences.store, isEmpty);
  });

  testWidgets('"Not today" skips it and shows the next', (tester) async {
    await pump(tester);
    final first = shown(tester);
    final firstId = tasks.store.values.firstWhere((t) => t.title == first).id;

    await tester.tap(find.widgetWithText(AppButton, strings.notToday));
    await tester.pumpAndSettle();

    expect(
      occurrences.store['${firstId}_2026-06-29']?.status,
      OccurrenceStatus.skipped,
    );
    expect(shown(tester), isNot(first));
    expect(
      find.text(strings.focusProgressText(left: 2, total: 2)),
      findsOneWidget,
    );
  });

  testWidgets('"Done" logs the time like ticking it on Today, then moves on', (
    tester,
  ) async {
    await pump(tester);
    final first = shown(tester);

    await tester.tap(find.widgetWithText(AppButton, strings.focusDone));
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsOneWidget);
    await tester.tap(find.widgetWithText(AppButton, strings.durationSave));
    await tester.pumpAndSettle();

    expect(
      occurrences.store.values.where((o) => o.status == OccurrenceStatus.done),
      hasLength(1),
    );
    expect(shown(tester), isNot(first));
  });

  testWidgets('when nothing is left it says so and returns to Today', (
    tester,
  ) async {
    await pump(tester);
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.widgetWithText(AppButton, strings.notToday));
      await tester.pumpAndSettle();
    }

    expect(find.text(strings.focusAllDoneTitle), findsOneWidget);
    await tester.tap(find.text(strings.focusBackToToday));
    await tester.pumpAndSettle();
    expect(find.byType(TodayScreen), findsOneWidget);
    expect(find.byType(FocusScreen), findsNothing);
  });

  testWidgets('Today offers Focus while there is open work', (tester) async {
    await pump(tester, start: Routes.today);
    await tester.tap(find.byTooltip(strings.focusAction));
    await tester.pumpAndSettle();
    expect(find.byType(FocusScreen), findsOneWidget);
  });

  testWidgets('with nothing open, Today offers no Focus', (tester) async {
    tasks.store.clear();
    await pump(tester, start: Routes.today);
    expect(find.byTooltip(strings.focusAction), findsNothing);
  });
}
