/// User-adjustable app preferences.
///
/// Kept as a plain immutable value (no codegen) — it's tiny and lives entirely
/// on-device for now.
class AppSettings {
  const AppSettings({
    this.profanityEnabled = false,
    this.dailyEnergyBudgetMinutes = 55,
    this.onboardingComplete = false,
  });

  /// When true, app-chrome text uses the cheeky/sweary wording. Off by default.
  final bool profanityEnabled;

  /// Gentle cap on how many estimated minutes to schedule per day (default 55).
  final int dailyEnergyBudgetMinutes;

  /// True once the user has completed (or skipped) the first-run onboarding
  /// wizard. New installs default to false, gating the router to the onboarding
  /// flow.
  final bool onboardingComplete;

  AppSettings copyWith({
    bool? profanityEnabled,
    int? dailyEnergyBudgetMinutes,
    bool? onboardingComplete,
  }) => AppSettings(
    profanityEnabled: profanityEnabled ?? this.profanityEnabled,
    dailyEnergyBudgetMinutes:
        dailyEnergyBudgetMinutes ?? this.dailyEnergyBudgetMinutes,
    onboardingComplete: onboardingComplete ?? this.onboardingComplete,
  );

  // Value equality so the settings Notifier (and Riverpod's updateShouldNotify)
  // can skip redundant rebuilds when a setter writes an unchanged value — e.g.
  // the daily-pace slider re-emitting the same snapped division mid-drag.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppSettings &&
          runtimeType == other.runtimeType &&
          profanityEnabled == other.profanityEnabled &&
          dailyEnergyBudgetMinutes == other.dailyEnergyBudgetMinutes &&
          onboardingComplete == other.onboardingComplete;

  @override
  int get hashCode => Object.hash(
    profanityEnabled,
    dailyEnergyBudgetMinutes,
    onboardingComplete,
  );
}
