import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snitd/app/app.dart';
import 'package:snitd/features/settings/application/settings_providers.dart';

void main() {
  testWidgets(
    'app stays in the readable light theme even when the device is in dark mode',
    (tester) async {
      // Simulate the OS being set to dark mode.
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

      SharedPreferences.setMockInitialValues({'onboarding_complete': true});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          child: const SnitdApp(),
        ),
      );
      await tester.pumpAndSettle();

      // The effective theme must be light — the design system has only light
      // tokens, so a dark theme would render text on hardcoded-light surfaces.
      final context = tester.element(find.byType(Scaffold).first);
      expect(Theme.of(context).brightness, Brightness.light);
    },
  );
}
