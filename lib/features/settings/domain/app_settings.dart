/// User-adjustable app preferences.
///
/// Kept as a plain immutable value (no codegen) — it's tiny and lives entirely
/// on-device for now.
class AppSettings {
  const AppSettings({
    this.profanityEnabled = false,
    this.dailyEnergyBudgetMinutes = 55,
  });

  /// When true, app-chrome text uses the cheeky/sweary wording. Off by default.
  final bool profanityEnabled;

  /// Gentle cap on how many estimated minutes to schedule per day (default 55).
  final int dailyEnergyBudgetMinutes;

  AppSettings copyWith({
    bool? profanityEnabled,
    int? dailyEnergyBudgetMinutes,
  }) => AppSettings(
    profanityEnabled: profanityEnabled ?? this.profanityEnabled,
    dailyEnergyBudgetMinutes:
        dailyEnergyBudgetMinutes ?? this.dailyEnergyBudgetMinutes,
  );
}
