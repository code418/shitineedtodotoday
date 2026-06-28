import 'notification_prefs.dart';

/// Pure reminder-timing logic, shared in concept with the Cloud Function
/// dispatcher (`functions/src/index.ts`) so the client preview and the server
/// agree on when a nudge should fire.

/// Minutes since local midnight for an `HH:mm` string, or null if malformed.
int? minuteOfDay(String hhmm) {
  final parts = hhmm.split(':');
  if (parts.length != 2) return null;
  final h = int.tryParse(parts[0]);
  final m = int.tryParse(parts[1]);
  if (h == null || m == null || h < 0 || h > 23 || m < 0 || m > 59) return null;
  return h * 60 + m;
}

/// Whether [nowMinute] falls inside the quiet-hours window
/// `[startMinute, endMinute)`. The window may wrap midnight (start > end); an
/// empty window (start == end) is treated as "no quiet hours".
bool isWithinQuietHours({
  required int nowMinute,
  required int startMinute,
  required int endMinute,
}) {
  if (startMinute == endMinute) return false;
  if (startMinute < endMinute) {
    return nowMinute >= startMinute && nowMinute < endMinute;
  }
  // Wraps past midnight, e.g. 21:00 → 07:00.
  return nowMinute >= startMinute || nowMinute < endMinute;
}

/// Whether the configured daily-nudge time itself falls inside the active
/// quiet-hours window — in which case [shouldSendDailyNudge] always suppresses
/// the nudge, so the user would never receive one. The UI uses this to warn
/// them instead of silently never sending. Returns false when either toggle is
/// off or any time string is malformed.
bool nudgeFallsInQuietHours(NotificationPrefs prefs) {
  if (!prefs.dailyNudgeEnabled || !prefs.quietHoursEnabled) return false;
  final nudge = minuteOfDay(prefs.dailyNudgeTime);
  final start = minuteOfDay(prefs.quietHoursStart);
  final end = minuteOfDay(prefs.quietHoursEnd);
  if (nudge == null || start == null || end == null) return false;
  return isWithinQuietHours(
    nowMinute: nudge,
    startMinute: start,
    endMinute: end,
  );
}

/// Whether the gentle daily nudge should be sent at [nowMinute] (minutes since
/// local midnight). [toleranceMinutes] widens the firing window so a scheduler
/// that ticks every N minutes can still catch the nudge time.
///
/// Suppressed when the nudge is off, there's nothing open to nudge about, the
/// time hasn't come, or it falls inside quiet hours.
bool shouldSendDailyNudge({
  required NotificationPrefs prefs,
  required int nowMinute,
  required bool hasOpenTasks,
  int toleranceMinutes = 0,
}) {
  if (!prefs.dailyNudgeEnabled) return false;
  if (!hasOpenTasks) return false;

  final nudge = minuteOfDay(prefs.dailyNudgeTime);
  if (nudge == null) return false;
  // Modular distance so the window is exactly [nudge, nudge+tolerance] mod 1440.
  // This handles midnight wrap and prevents double-sends when two scheduler
  // ticks both fall inside a window wider than the tick interval.
  final diff = (nowMinute - nudge + 1440) % 1440;
  final due = diff <= toleranceMinutes;
  if (!due) return false;

  if (prefs.quietHoursEnabled) {
    final start = minuteOfDay(prefs.quietHoursStart);
    final end = minuteOfDay(prefs.quietHoursEnd);
    if (start != null &&
        end != null &&
        isWithinQuietHours(
          nowMinute: nowMinute,
          startMinute: start,
          endMinute: end,
        )) {
      return false;
    }
  }
  return true;
}
