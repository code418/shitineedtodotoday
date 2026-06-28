import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snitd/core/strings/app_strings.dart';
import 'package:snitd/features/notifications/data/notification_prefs_repository.dart';
import 'package:snitd/features/notifications/domain/notification_prefs.dart';
import 'package:snitd/features/notifications/presentation/reminders_screen.dart';
import 'package:snitd/features/settings/application/settings_providers.dart';
import 'package:snitd/features/tasks/application/tasks_providers.dart';
import 'package:snitd/features/tasks/domain/scheduling/task_occurrence.dart';

// ── In-memory fake ───────────────────────────────────────────────────────────

class _FakeNotificationPrefsRepository implements NotificationPrefsRepository {
  NotificationPrefs current = NotificationPrefs.defaults;
  NotificationPrefs? saved;

  @override
  Stream<NotificationPrefs> watch(String ownerId) => Stream.value(current);

  @override
  Future<void> save(String ownerId, NotificationPrefs prefs) async {
    current = prefs;
    saved = prefs;
  }
}

/// A prefs repo whose writes fail — simulates an offline/permission error.
class _ThrowingNotificationPrefsRepository
    implements NotificationPrefsRepository {
  @override
  Stream<NotificationPrefs> watch(String ownerId) =>
      Stream.value(NotificationPrefs.defaults);

  @override
  Future<void> save(String ownerId, NotificationPrefs prefs) async =>
      throw Exception('save failed');
}

// ── Tests ────────────────────────────────────────────────────────────────────

void main() {
  testWidgets('renders daily-nudge and quiet-hours titles', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final fakeRepo = _FakeNotificationPrefsRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          currentOwnerIdProvider.overrideWithValue('u1'),
          notificationPrefsRepositoryProvider.overrideWithValue(fakeRepo),
          todayChecklistProvider.overrideWithValue(const <TaskOccurrence>[]),
        ],
        child: const MaterialApp(home: RemindersScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Daily nudge'), findsOneWidget);
    expect(find.text('Quiet hours'), findsOneWidget);
  });

  testWidgets('toggling the daily-nudge switch saves prefs with flag flipped', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final fakeRepo = _FakeNotificationPrefsRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          currentOwnerIdProvider.overrideWithValue('u1'),
          notificationPrefsRepositoryProvider.overrideWithValue(fakeRepo),
          todayChecklistProvider.overrideWithValue(const <TaskOccurrence>[]),
        ],
        child: const MaterialApp(home: RemindersScreen()),
      ),
    );

    await tester.pumpAndSettle();

    // The first AppSwitch is the daily-nudge toggle (defaults to enabled=true).
    // Tapping it should flip dailyNudgeEnabled to false.
    final switches = find.byWidgetPredicate(
      (w) => w.runtimeType.toString() == 'AppSwitch',
    );
    expect(switches, findsWidgets);
    await tester.tap(switches.first);
    await tester.pumpAndSettle();

    expect(fakeRepo.saved, isNotNull);
    expect(fakeRepo.saved!.dailyNudgeEnabled, isFalse);
  });

  testWidgets('a failed pref write surfaces a gentle error', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          currentOwnerIdProvider.overrideWithValue('u1'),
          notificationPrefsRepositoryProvider.overrideWithValue(
            _ThrowingNotificationPrefsRepository(),
          ),
          todayChecklistProvider.overrideWithValue(const <TaskOccurrence>[]),
        ],
        child: const MaterialApp(home: RemindersScreen()),
      ),
    );
    await tester.pumpAndSettle();

    final switches = find.byWidgetPredicate(
      (w) => w.runtimeType.toString() == 'AppSwitch',
    );
    await tester.tap(switches.first);
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.clean.actionFailed), findsOneWidget);
  });

  testWidgets('toggling with no signed-in owner shows not-configured', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          // No owner → notificationPrefsControllerProvider is null.
          currentOwnerIdProvider.overrideWithValue(null),
          todayChecklistProvider.overrideWithValue(const <TaskOccurrence>[]),
        ],
        child: const MaterialApp(home: RemindersScreen()),
      ),
    );
    await tester.pumpAndSettle();

    final switches = find.byWidgetPredicate(
      (w) => w.runtimeType.toString() == 'AppSwitch',
    );
    await tester.tap(switches.first);
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.clean.firebaseNotConfigured), findsOneWidget);
  });

  testWidgets('preview shows clean push copy even with profanity mode on', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final fakeRepo = _FakeNotificationPrefsRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          currentOwnerIdProvider.overrideWithValue('u1'),
          notificationPrefsRepositoryProvider.overrideWithValue(fakeRepo),
          todayChecklistProvider.overrideWithValue(const <TaskOccurrence>[]),
          // Profanity mode ON — in-app chrome goes profane, but the push (and
          // its preview) must stay clean.
          appStringsProvider.overrideWithValue(AppStrings.profane),
        ],
        child: const MaterialApp(home: RemindersScreen()),
      ),
    );

    await tester.pumpAndSettle();

    // The preview mirrors the always-clean OS notification copy...
    expect(find.text('Stuff I Need To Do Today'), findsOneWidget);
    expect(find.text('Nothing on today. Enjoy the breather.'), findsOneWidget);
    // ...never the profane register the server never sends.
    expect(find.text('Shit I Need To Do Today'), findsNothing);
    expect(find.text('Sweet F.A. today. Enjoy the breather.'), findsNothing);
  });
}
