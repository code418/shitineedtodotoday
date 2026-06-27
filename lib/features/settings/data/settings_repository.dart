import 'package:shared_preferences/shared_preferences.dart';

import '../domain/app_settings.dart';

/// Persists [AppSettings] locally via [SharedPreferences].
///
/// Local-only for now (instant, offline, no account needed); a future
/// iteration can mirror preferences to the user's Firestore doc.
class SettingsRepository {
  SettingsRepository(this._prefs);

  final SharedPreferences _prefs;

  static const _kProfanityEnabled = 'profanity_enabled';
  static const _kDailyEnergyBudget = 'daily_energy_budget_minutes';

  AppSettings load() => AppSettings(
    profanityEnabled: _prefs.getBool(_kProfanityEnabled) ?? false,
    dailyEnergyBudgetMinutes: _prefs.getInt(_kDailyEnergyBudget) ?? 55,
  );

  Future<void> setProfanityEnabled(bool value) =>
      _prefs.setBool(_kProfanityEnabled, value);

  Future<void> setDailyEnergyBudget(int minutes) =>
      _prefs.setInt(_kDailyEnergyBudget, minutes);
}
