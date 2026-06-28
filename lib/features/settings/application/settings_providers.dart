import 'dart:developer' as developer;

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

  // Each setter updates state FIRST so the UI responds instantly, then persists.
  // Persisting first gates the state change (and any bound control, like the
  // budget slider's thumb) behind an async disk write, which feels laggy and,
  // for a dragged slider, janky. A failed write self-heals on the next launch.

  Future<void> setProfanityEnabled(bool value) async {
    state = state.copyWith(profanityEnabled: value);
    await _persist(
      () => ref.read(settingsRepositoryProvider).setProfanityEnabled(value),
      'profanity setting',
    );
  }

  Future<void> setDailyEnergyBudget(int minutes) async {
    state = state.copyWith(dailyEnergyBudgetMinutes: minutes);
    await _persist(
      () => ref.read(settingsRepositoryProvider).setDailyEnergyBudget(minutes),
      'daily energy budget',
    );
  }

  Future<void> setOnboardingComplete(bool value) async {
    state = state.copyWith(onboardingComplete: value);
    await _persist(
      () => ref.read(settingsRepositoryProvider).setOnboardingComplete(value),
      'onboarding-complete flag',
    );
  }

  /// Runs a local settings write, swallowing (and logging) any failure. The
  /// optimistic state update already happened and self-heals on next launch, so
  /// a benign SharedPreferences error must NOT bubble up as an unhandled async
  /// error — `main.dart`'s onError would otherwise report it as a fatal crash.
  Future<void> _persist(Future<void> Function() write, String what) async {
    try {
      await write();
    } catch (e, st) {
      developer.log(
        'Failed to persist $what',
        name: 'snitd',
        error: e,
        stackTrace: st,
      );
    }
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
