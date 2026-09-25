import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snitd/app/app.dart';
import 'package:snitd/app/router.dart';
import 'package:snitd/core/design/design.dart';
import 'package:snitd/core/strings/app_strings.dart';
import 'package:snitd/features/auth/data/auth_repository.dart';
import 'package:snitd/features/auth/domain/account_status.dart';
import 'package:snitd/features/household/data/household_repository.dart';
import 'package:snitd/features/household/domain/household.dart';
import 'package:snitd/features/notifications/data/notification_prefs_repository.dart';
import 'package:snitd/features/notifications/domain/notification_prefs.dart';
import 'package:snitd/features/settings/application/settings_providers.dart';
import 'package:snitd/features/tasks/application/tasks_providers.dart';
import 'package:snitd/features/tasks/data/occurrence_repository.dart';
import 'package:snitd/features/tasks/data/task_repository.dart';
import 'package:snitd/features/tasks/domain/scheduling/recurrence.dart';
import 'package:snitd/features/tasks/domain/task.dart';
import 'package:snitd/features/tasks/presentation/widgets/task_item.dart';

import '../occurrence_service_test.dart' show FakeOccurrenceRepository;
import '../task_service_test.dart' show FakeTaskRepository;

// P6 accessibility: every screen meets Flutter's touch-target (48dp Android)
// and labelled-control guidelines, in both themes, with real content on it.
//
// Text contrast (textContrastGuideline) is deliberately NOT asserted yet: the
// muted-text token and white-on-brand buttons measure below WCAG AA (3.7-4.2:1)
// and fixing them is a palette decision, not a mechanical one.

Task _task(String id, String title, List<int> weekdays) => Task(
  id: id,
  ownerId: 'u1',
  title: title,
  category: 'Kitchen',
  recurrence: Recurrence.strict(weekdays: weekdays),
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

class _Prefs implements NotificationPrefsRepository {
  @override
  Stream<NotificationPrefs> watch(String ownerId) =>
      Stream.value(NotificationPrefs.defaults);

  @override
  Future<void> save(String ownerId, NotificationPrefs prefs) async {}

  @override
  Future<void> saveTimeZone(String ownerId, String timeZone) async {}
}

class _Household implements HouseholdRepository {
  @override
  Stream<Household> watch(String ownerId) => Stream.value(Household.empty);

  @override
  Future<void> save(String ownerId, Household household) async {}
}

/// Only rendered here, never called.
class _Auth implements AuthRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// The whole app, onboarded, with two chores due today (Mon 29 Jun 2026) and
/// one tomorrow so every tab has real, tappable content.
Future<void> _pumpApp(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({'onboarding_complete': true});
  final prefs = await SharedPreferences.getInstance();
  final tasks = FakeTaskRepository()
    ..store['a'] = _task('a', 'Wipe the counters', [DateTime.monday])
    ..store['b'] = _task('b', 'Hoover the lounge', [DateTime.monday])
    ..store['c'] = _task('c', 'Clean the bathroom', [DateTime.tuesday]);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        currentOwnerIdProvider.overrideWithValue('u1'),
        taskRepositoryProvider.overrideWithValue(tasks),
        occurrenceRepositoryProvider.overrideWithValue(
          FakeOccurrenceRepository(),
        ),
        clockProvider.overrideWithValue(() => DateTime(2026, 6, 29, 9)),
        notificationPrefsRepositoryProvider.overrideWithValue(_Prefs()),
        householdRepositoryProvider.overrideWithValue(_Household()),
        authRepositoryProvider.overrideWithValue(_Auth()),
        accountStatusProvider.overrideWithValue(
          const AccountStatus(signedIn: true, isAnonymous: true),
        ),
      ],
      child: const SnitdApp(),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _expectAccessible(WidgetTester tester, String screen) async {
  for (final guideline in [
    androidTapTargetGuideline,
    labeledTapTargetGuideline,
  ]) {
    final result = await guideline.evaluate(tester);
    expect(
      result.passed,
      isTrue,
      reason: '$screen fails "${guideline.description}":\n${result.reason}',
    );
  }
}

void _go(WidgetTester tester, String location) =>
    GoRouter.of(tester.element(find.byType(Scaffold).first)).go(location);

void main() {
  const strings = AppStrings.clean;

  for (final brightness in Brightness.values) {
    testWidgets('every screen meets touch-target and label guidelines '
        '(${brightness.name})', (tester) async {
      tester.platformDispatcher.platformBrightnessTestValue = brightness;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      final semantics = tester.ensureSemantics();
      await _pumpApp(tester);

      await _expectAccessible(tester, 'Today');
      for (final (tab, name) in [
        (1, 'Schedule'),
        (2, 'Insights'),
        (3, 'You'),
      ]) {
        await tester.tap(find.byType(NavigationDestination).at(tab));
        await tester.pumpAndSettle();
        await _expectAccessible(tester, name);
      }
      for (final route in [
        Routes.reminders,
        Routes.account,
        Routes.household,
        Routes.taskDetailPath('a'),
      ]) {
        _go(tester, route);
        await tester.pumpAndSettle();
        await _expectAccessible(tester, route);
      }
      semantics.dispose();
    });
  }

  testWidgets('a checklist tick-box is announced with its chore', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _pumpApp(tester);

    // Previously an anonymous "checkbox, not checked" — nothing said which
    // chore it would complete.
    expect(
      tester.getSemantics(find.byType(AppCheckbox).first),
      matchesSemantics(
        label: 'Wipe the counters',
        hasCheckedState: true,
        isChecked: false,
        hasEnabledState: true,
        isEnabled: true,
        hasTapAction: true,
      ),
    );
    semantics.dispose();
  });

  testWidgets('each settings switch reads as one labelled toggle', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _pumpApp(tester);
    _go(tester, Routes.reminders);
    await tester.pumpAndSettle();

    final nudge = tester.getSemantics(find.byType(AppSwitch).first);
    expect(nudge.label, contains(strings.dailyNudgeTitle));
    expect(nudge, isSemantics(hasToggledState: true, isToggled: true));
    expect(
      tester.getSemantics(find.byType(AppSwitch).last).label,
      contains(strings.quietHoursTitle),
    );
    semantics.dispose();
  });

  testWidgets('buttons and segments say their label once, not twice', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _pumpApp(tester);

    // Was "Add task\nAdd task": the explicit label plus the inner Text.
    expect(
      tester.getSemantics(find.widgetWithText(AppButton, strings.addTask)),
      matchesSemantics(
        label: strings.addTask,
        isButton: true,
        hasEnabledState: true,
        isEnabled: true,
        hasTapAction: true,
      ),
    );

    await tester.tap(find.byType(NavigationDestination).at(2));
    await tester.pumpAndSettle();
    expect(
      tester.getSemantics(find.text(strings.periodWeek)),
      isSemantics(
        label: strings.periodWeek,
        isButton: true,
        isSelected: true,
        hasTapAction: true,
      ),
    );
    semantics.dispose();
  });

  testWidgets('tapping the row edge beside the tick completes the chore', (
    tester,
  ) async {
    await _pumpApp(tester);
    final row = tester.getRect(find.byType(AppTaskItem).first);

    // The card's left padding is now part of the tick's touch target, so a
    // slightly-off tap still completes (and opens the log-duration sheet)
    // instead of falling through to "open details".
    await tester.tapAt(Offset(row.left + 4, row.center.dy));
    await tester.pumpAndSettle();

    expect(find.byType(BottomSheet), findsOneWidget);
  });
}
