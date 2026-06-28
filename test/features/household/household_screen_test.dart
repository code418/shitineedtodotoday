// test/features/household/household_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snitd/core/strings/app_strings.dart';
import 'package:snitd/features/household/data/household_repository.dart';
import 'package:snitd/features/household/domain/household.dart';
import 'package:snitd/features/household/presentation/household_screen.dart';
import 'package:snitd/features/settings/application/settings_providers.dart';
import 'package:snitd/features/tasks/application/tasks_providers.dart';
import 'package:snitd/features/tasks/data/occurrence_repository.dart';
import 'package:snitd/features/tasks/data/task_repository.dart';
import 'package:snitd/features/tasks/domain/scheduling/recurrence.dart';
import 'package:snitd/features/tasks/domain/scheduling/task_occurrence.dart';
import 'package:snitd/features/tasks/domain/task.dart';

// ── Fakes ─────────────────────────────────────────────────────────────────────

class _FakeHouseholdRepository implements HouseholdRepository {
  Household current;
  List<Household> saved = [];

  _FakeHouseholdRepository(this.current);

  @override
  Stream<Household> watch(String ownerId) => Stream.value(current);

  @override
  Future<void> save(String ownerId, Household household) async {
    current = household;
    saved.add(household);
  }
}

/// A household repo whose writes fail — simulates an offline/permission error.
class _ThrowingHouseholdRepository implements HouseholdRepository {
  @override
  Stream<Household> watch(String ownerId) => Stream.value(Household.empty);

  @override
  Future<void> save(String ownerId, Household household) async =>
      throw Exception('save failed');
}

class _FakeTaskRepository implements TaskRepository {
  @override
  Stream<List<Task>> watchTasks(String ownerId) => Stream.value(const <Task>[]);

  @override
  Future<void> upsert(Task task) async {}

  @override
  Future<void> delete(String ownerId, String taskId) async {}

  @override
  String newId(String ownerId) => 'new-id';
}

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

// ── Helpers ───────────────────────────────────────────────────────────────────

Future<ProviderContainer> _buildScreen(
  WidgetTester tester,
  HouseholdRepository fakeHousehold,
) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();

  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      currentOwnerIdProvider.overrideWithValue('u1'),
      householdRepositoryProvider.overrideWithValue(fakeHousehold),
      taskRepositoryProvider.overrideWithValue(_FakeTaskRepository()),
      occurrenceRepositoryProvider.overrideWithValue(
        _FakeOccurrenceRepository(),
      ),
    ],
  );

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: HouseholdScreen()),
    ),
  );
  await tester.pump();
  return container;
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  testWidgets('renders the members heading', (tester) async {
    final fakeHousehold = _FakeHouseholdRepository(Household.empty);
    await _buildScreen(tester, fakeHousehold);

    expect(find.text('Who pitches in'), findsOneWidget);
  });

  testWidgets('shows household-empty hint when no members', (tester) async {
    final fakeHousehold = _FakeHouseholdRepository(Household.empty);
    await _buildScreen(tester, fakeHousehold);

    expect(
      find.textContaining('Add the people you share chores with'),
      findsWidgets,
    );
  });

  testWidgets('shows existing members as avatars', (tester) async {
    final fakeHousehold = _FakeHouseholdRepository(
      const Household(
        members: [HouseholdMember(id: 'm1', name: 'Alice')],
      ),
    );
    await _buildScreen(tester, fakeHousehold);

    expect(find.text('Alice'), findsOneWidget);
  });

  testWidgets(
    'opening Add someone sheet and confirming calls repository save',
    (tester) async {
      final fakeHousehold = _FakeHouseholdRepository(Household.empty);
      await _buildScreen(tester, fakeHousehold);

      // Tap 'Add someone' button.
      await tester.tap(find.text('Add someone'));
      await tester.pumpAndSettle();

      // Type a name.
      await tester.enterText(find.byType(TextField), 'Charlie');
      await tester.pumpAndSettle();

      // Tap confirm.
      await tester.tap(find.text('Add someone').last);
      await tester.pumpAndSettle();

      expect(fakeHousehold.saved, isNotEmpty);
      expect(fakeHousehold.saved.last.members.first.name, 'Charlie');
    },
  );

  testWidgets('a failed add shows a gentle error snackbar', (tester) async {
    await _buildScreen(tester, _ThrowingHouseholdRepository());

    await tester.tap(find.text('Add someone'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Charlie');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add someone').last);
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.clean.actionFailed), findsOneWidget);
  });

  testWidgets('today\'s turns card renders rows for the checklist', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final task = Task(
      id: 't1',
      ownerId: 'u1',
      title: 'Do the dishes',
      recurrence: const Recurrence.strict(weekdays: [DateTime.monday]),
      estimatedEffortMinutes: 15,
      assigneeId: 'you',
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );
    final occ = TaskOccurrence(
      id: 't1_2026-06-29',
      taskId: 't1',
      scheduledDate: DateTime(2026, 6, 29),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          currentOwnerIdProvider.overrideWithValue('u1'),
          householdRepositoryProvider.overrideWithValue(
            _FakeHouseholdRepository(Household.empty),
          ),
          taskRepositoryProvider.overrideWithValue(_FakeTaskRepository()),
          occurrenceRepositoryProvider.overrideWithValue(
            _FakeOccurrenceRepository(),
          ),
          tasksProvider.overrideWith((ref) => Stream.value([task])),
          todayChecklistProvider.overrideWithValue([occ]),
        ],
        child: const MaterialApp(home: HouseholdScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // The turn row renders (ref.watch in the StatelessWidget tree works), under
    // the "You" bucket since the task is assigned to the owner.
    expect(find.text('Do the dishes'), findsOneWidget);
  });
}
