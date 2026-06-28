import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snitd/core/strings/app_strings.dart';
import 'package:snitd/features/settings/application/settings_providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<ProviderContainer> makeContainer() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('profanity is off by default and strings are clean', () async {
    final container = await makeContainer();

    expect(
      container.read(settingsControllerProvider).profanityEnabled,
      isFalse,
    );
    expect(container.read(appStringsProvider), same(AppStrings.clean));
    expect(
      container.read(appStringsProvider).appTitle,
      'Stuff I Need To Do Today',
    );
  });

  test('enabling profanity swaps to profane strings and persists', () async {
    final container = await makeContainer();

    await container
        .read(settingsControllerProvider.notifier)
        .setProfanityEnabled(true);

    expect(container.read(appStringsProvider), same(AppStrings.profane));
    expect(
      container.read(appStringsProvider).appTitle,
      'Shit I Need To Do Today',
    );

    // Persisted: a fresh repository over the same prefs sees it enabled.
    expect(
      container.read(settingsRepositoryProvider).load().profanityEnabled,
      isTrue,
    );
  });

  test(
    'onboardingComplete defaults to false and setOnboardingComplete persists',
    () async {
      final container = await makeContainer();

      // Default value.
      expect(
        container.read(settingsControllerProvider).onboardingComplete,
        isFalse,
      );

      // Update via controller.
      await container
          .read(settingsControllerProvider.notifier)
          .setOnboardingComplete(true);

      expect(
        container.read(settingsControllerProvider).onboardingComplete,
        isTrue,
      );

      // Persisted: loading fresh from the same prefs returns the new value.
      expect(
        container.read(settingsRepositoryProvider).load().onboardingComplete,
        isTrue,
      );
    },
  );

  test(
    'setters update state synchronously, before persistence resolves',
    () async {
      final container = await makeContainer();
      final notifier = container.read(settingsControllerProvider.notifier);

      // Fire the setter but do NOT await it yet: the state must already reflect
      // the new value so a bound control (e.g. the budget slider) responds
      // instantly rather than waiting on the disk write.
      final pending = notifier.setDailyEnergyBudget(120);
      expect(container.read(dailyEnergyBudgetProvider), 120);

      await pending;
      // And it still persists.
      expect(
        container
            .read(settingsRepositoryProvider)
            .load()
            .dailyEnergyBudgetMinutes,
        120,
      );
    },
  );

  test(
    'daily energy budget defaults to 55 and setDailyEnergyBudget persists',
    () async {
      final container = await makeContainer();

      // Default value
      expect(
        container.read(settingsControllerProvider).dailyEnergyBudgetMinutes,
        55,
      );
      expect(container.read(dailyEnergyBudgetProvider), 55);

      // Update via controller
      await container
          .read(settingsControllerProvider.notifier)
          .setDailyEnergyBudget(90);

      expect(container.read(dailyEnergyBudgetProvider), 90);
      expect(
        container.read(settingsControllerProvider).dailyEnergyBudgetMinutes,
        90,
      );

      // Persisted: loading fresh from the same prefs returns the new value.
      expect(
        container
            .read(settingsRepositoryProvider)
            .load()
            .dailyEnergyBudgetMinutes,
        90,
      );
    },
  );
}
