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
