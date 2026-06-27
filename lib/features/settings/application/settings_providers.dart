import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/strings/app_strings.dart';
import '../data/settings_repository.dart';
import '../domain/app_settings.dart';

/// The [SharedPreferences] instance. Overridden in `main()` with the real
/// (async-loaded) instance so the rest of the app can read settings
/// synchronously.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError(
    'sharedPreferencesProvider must be overridden in main().',
  ),
);

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SettingsRepository(ref.watch(sharedPreferencesProvider)),
);

/// Holds the current [AppSettings] and writes changes through to storage.
class SettingsController extends Notifier<AppSettings> {
  @override
  AppSettings build() => ref.watch(settingsRepositoryProvider).load();

  Future<void> setProfanityEnabled(bool value) async {
    await ref.read(settingsRepositoryProvider).setProfanityEnabled(value);
    state = state.copyWith(profanityEnabled: value);
  }

  Future<void> setDailyEnergyBudget(int minutes) async {
    await ref.read(settingsRepositoryProvider).setDailyEnergyBudget(minutes);
    state = state.copyWith(dailyEnergyBudgetMinutes: minutes);
  }

  Future<void> setOnboardingComplete(bool value) async {
    await ref.read(settingsRepositoryProvider).setOnboardingComplete(value);
    state = state.copyWith(onboardingComplete: value);
  }
}

final settingsControllerProvider =
    NotifierProvider<SettingsController, AppSettings>(SettingsController.new);

/// True once the user has completed (or skipped) the first-run onboarding wizard.
final onboardingCompleteProvider = Provider<bool>(
  (ref) =>
      ref.watch(settingsControllerProvider.select((s) => s.onboardingComplete)),
);

/// The current daily energy budget in minutes.
final dailyEnergyBudgetProvider = Provider<int>(
  (ref) => ref.watch(
    settingsControllerProvider.select((s) => s.dailyEnergyBudgetMinutes),
  ),
);

/// The active [AppStrings] set, chosen by the profanity toggle. Defaults to the
/// clean wording.
final appStringsProvider = Provider<AppStrings>((ref) {
  final profanity = ref.watch(
    settingsControllerProvider.select((s) => s.profanityEnabled),
  );
  return profanity ? AppStrings.profane : AppStrings.clean;
});
