/// User-adjustable app preferences.
///
/// Kept as a plain immutable value (no codegen) — it's tiny and lives entirely
/// on-device for now.
class AppSettings {
  const AppSettings({this.profanityEnabled = false});

  /// When true, app-chrome text uses the cheeky/sweary wording. Off by default.
  final bool profanityEnabled;

  AppSettings copyWith({bool? profanityEnabled}) =>
      AppSettings(profanityEnabled: profanityEnabled ?? this.profanityEnabled);
}
