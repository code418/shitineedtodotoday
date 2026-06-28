import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snitd/features/onboarding/presentation/onboarding_screen.dart';
import 'package:snitd/features/settings/application/settings_providers.dart';
import 'package:snitd/features/tasks/application/tasks_providers.dart';
import 'package:snitd/features/tasks/data/occurrence_repository.dart';
import 'package:snitd/features/tasks/data/task_repository.dart';
import 'package:snitd/features/tasks/domain/scheduling/task_occurrence.dart';
import 'package:snitd/features/tasks/domain/task.dart';

// Re-use FakeTaskRepository from task_service_test.dart by copy (no shared
// library export exists, so we define a minimal one here).
class _FakeTaskRepository implements TaskRepository {
  final Map<String, Task> store = {};
  int _seq = 0;

  @override
  Stream<List<Task>> watchTasks(String ownerId) =>
      Stream.value(store.values.where((t) => t.ownerId == ownerId).toList());

  @override
  Future<void> upsert(Task task) async => store[task.id] = task;

  @override
  Future<void> delete(String ownerId, String taskId) async =>
      store.remove(taskId);

  @override
  String newId(String ownerId) => 'task-${_seq++}';
}

/// No-op occurrence repo so taskServiceProvider (which now depends on it for
/// cascade-delete) builds without Firestore in tests.
class _FakeOccurrenceRepository implements OccurrenceRepository {
  @override
  Stream<List<TaskOccurrence>> watchOccurrences(String ownerId) =>
      Stream.value(const <TaskOccurrence>[]);

  @override
  Future<void> upsert(String ownerId, TaskOccurrence occurrence) async {}

  @override
  Future<void> delete(String ownerId, String occurrenceId) async {}

  @override
  Future<void> deleteForTask(String ownerId, String taskId) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'OnboardingScreen: tap through to Get started adds starter tasks and sets flag',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final fakeRepo = _FakeTaskRepository();

      // Minimal GoRouter with /onboarding and / so context.go(Routes.today) resolves.
      final router = GoRouter(
        initialLocation: '/onboarding',
        routes: [
          GoRoute(
            path: '/onboarding',
            builder: (c, s) => const OnboardingScreen(),
          ),
          GoRoute(path: '/', builder: (c, s) => const SizedBox()),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            currentOwnerIdProvider.overrideWithValue('u1'),
            taskRepositoryProvider.overrideWithValue(fakeRepo),
            occurrenceRepositoryProvider.overrideWithValue(
              _FakeOccurrenceRepository(),
            ),
            clockProvider.overrideWithValue(() => DateTime(2026, 6, 29, 9)),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      // Page 0 — Welcome: tap Next.
      expect(find.text('Next'), findsOneWidget);
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Page 1 — Pace: tap Next.
      expect(find.text('Next'), findsOneWidget);
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Page 2 — Pick: all days selected by default. Tap Get started.
      expect(find.text('Get started'), findsOneWidget);
      await tester.tap(find.text('Get started'));
      await tester.pumpAndSettle();

      // All starter tasks should now be in the fake repository.
      expect(fakeRepo.store, isNotEmpty);

      // Onboarding complete flag should be persisted.
      expect(prefs.getBool('onboarding_complete'), isTrue);
    },
  );

  testWidgets('Skip for now sets onboarding complete without adding tasks', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final fakeRepo = _FakeTaskRepository();

    final router = GoRouter(
      initialLocation: '/onboarding',
      routes: [
        GoRoute(
          path: '/onboarding',
          builder: (c, s) => const OnboardingScreen(),
        ),
        GoRoute(path: '/', builder: (c, s) => const SizedBox()),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          currentOwnerIdProvider.overrideWithValue('u1'),
          taskRepositoryProvider.overrideWithValue(fakeRepo),
          occurrenceRepositoryProvider.overrideWithValue(
            _FakeOccurrenceRepository(),
          ),
          clockProvider.overrideWithValue(() => DateTime(2026, 6, 29, 9)),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    // Tap Skip for now on the welcome page.
    expect(find.text('Skip for now'), findsOneWidget);
    await tester.tap(find.text('Skip for now'));
    await tester.pumpAndSettle();

    // No tasks added, but flag is set.
    expect(fakeRepo.store, isEmpty);
    expect(prefs.getBool('onboarding_complete'), isTrue);
  });
}
