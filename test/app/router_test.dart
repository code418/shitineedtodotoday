import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snitd/app/router.dart';
import 'package:snitd/features/settings/application/settings_providers.dart';

/// Pumps the real [routerProvider] with onboarding either complete or not,
/// and returns the router so tests can drive navigation directly.
Future<GoRouter> _pumpRouter(
  WidgetTester tester, {
  required bool onboarded,
}) async {
  SharedPreferences.setMockInitialValues({'onboarding_complete': onboarded});
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    // Firebase-backed providers error in the offline test environment; disable
    // Riverpod's automatic retry so no background timer outlives the test.
    retry: (_, _) => null,
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );
  addTearDown(container.dispose);
  final router = container.read(routerProvider);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

String _path(GoRouter router) =>
    router.routerDelegate.currentConfiguration.uri.path;

void main() {
  testWidgets('un-onboarded launch lands on onboarding', (tester) async {
    final router = await _pumpRouter(tester, onboarded: false);
    expect(_path(router), Routes.onboarding);
  });

  testWidgets(
    'un-onboarded deep links to non-Today routes are funnelled to onboarding',
    (tester) async {
      final router = await _pumpRouter(tester, onboarded: false);

      // A notification tap / deep link straight to the week agenda.
      router.go(Routes.schedule);
      await tester.pumpAndSettle();
      expect(_path(router), Routes.onboarding);

      // A deep link to a specific task's detail screen.
      router.go(Routes.taskDetailPath('abc'));
      await tester.pumpAndSettle();
      expect(_path(router), Routes.onboarding);
    },
  );

  testWidgets('completed onboarding lets deep links through', (tester) async {
    final router = await _pumpRouter(tester, onboarded: true);

    router.go(Routes.settings);
    await tester.pumpAndSettle();
    expect(_path(router), Routes.settings);
  });

  testWidgets('completed onboarding redirects away from onboarding', (
    tester,
  ) async {
    final router = await _pumpRouter(tester, onboarded: true);

    router.go(Routes.onboarding);
    await tester.pumpAndSettle();
    expect(_path(router), Routes.today);
  });
}
