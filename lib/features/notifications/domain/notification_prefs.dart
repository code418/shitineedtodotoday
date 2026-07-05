/// The user's server-driven reminder preferences.
///
/// Reminders in SINTDT are **server-driven** (a scheduled Cloud Function sends
/// FCM pushes — there are no on-device local notifications), so these prefs are
/// persisted to Firestore where the function can read them. Times are local
/// `HH:mm` strings (24-hour), matching [Task.reminderTimeOfDay].
class NotificationPrefs {
  const NotificationPrefs({
    this.dailyNudgeEnabled = true,
    this.dailyNudgeTime = '08:00',
    this.quietHoursEnabled = true,
    this.quietHoursStart = '21:00',
    this.quietHoursEnd = '07:00',
  });

  /// A single gentle daily nudge about today's checklist.
  final bool dailyNudgeEnabled;

  /// When the daily nudge is sent, local `HH:mm`.
  final String dailyNudgeTime;

  /// Suppress all reminders during the quiet-hours window.
  final bool quietHoursEnabled;

  /// Quiet-hours window, local `HH:mm`. May wrap midnight
  /// (e.g. 21:00 → 07:00).
  final String quietHoursStart;
  final String quietHoursEnd;

  static const NotificationPrefs defaults = NotificationPrefs();

  NotificationPrefs copyWith({
    bool? dailyNudgeEnabled,
    String? dailyNudgeTime,
    bool? quietHoursEnabled,
    String? quietHoursStart,
    String? quietHoursEnd,
  }) => NotificationPrefs(
    dailyNudgeEnabled: dailyNudgeEnabled ?? this.dailyNudgeEnabled,
    dailyNudgeTime: dailyNudgeTime ?? this.dailyNudgeTime,
    quietHoursEnabled: quietHoursEnabled ?? this.quietHoursEnabled,
    quietHoursStart: quietHoursStart ?? this.quietHoursStart,
    quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
  );

  Map<String, dynamic> toJson() => {
    'dailyNudgeEnabled': dailyNudgeEnabled,
    'dailyNudgeTime': dailyNudgeTime,
    'quietHoursEnabled': quietHoursEnabled,
    'quietHoursStart': quietHoursStart,
    'quietHoursEnd': quietHoursEnd,
  };

  factory NotificationPrefs.fromJson(Map<String, dynamic> json) {
    // Read each field defensively (is-check + fallback) rather than a hard
    // `as` cast: this doc is read on a single-doc stream with no decodeDocs
    // salvage, so a wrong-typed field (a schema change or a manual console
    // edit) would otherwise throw inside the stream .map and blank the whole
    // reminders screen. Mirrors the server's defensive prefsFromDoc
    // (functions/src/reminder.ts), so the client is no stricter than the server.
    final enabled = json['dailyNudgeEnabled'];
    final time = json['dailyNudgeTime'];
    final quietEnabled = json['quietHoursEnabled'];
    final quietStart = json['quietHoursStart'];
    final quietEnd = json['quietHoursEnd'];
    return NotificationPrefs(
      dailyNudgeEnabled: enabled is bool ? enabled : true,
      dailyNudgeTime: time is String ? time : '08:00',
      quietHoursEnabled: quietEnabled is bool ? quietEnabled : true,
      quietHoursStart: quietStart is String ? quietStart : '21:00',
      quietHoursEnd: quietEnd is String ? quietEnd : '07:00',
    );
  }

  @override
  bool operator ==(Object other) =>
      other is NotificationPrefs &&
      other.dailyNudgeEnabled == dailyNudgeEnabled &&
      other.dailyNudgeTime == dailyNudgeTime &&
      other.quietHoursEnabled == quietHoursEnabled &&
      other.quietHoursStart == quietHoursStart &&
      other.quietHoursEnd == quietHoursEnd;

  @override
  int get hashCode => Object.hash(
    dailyNudgeEnabled,
    dailyNudgeTime,
    quietHoursEnabled,
    quietHoursStart,
    quietHoursEnd,
  );
}
