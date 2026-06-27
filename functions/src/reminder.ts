/**
 * Pure reminder-timing logic for the dispatcher.
 *
 * Deliberately mirrors the Dart `reminder_logic.dart` so the client preview and
 * the server agree on when a nudge should fire. No Firebase imports here — keep
 * it pure and unit-testable.
 */

export interface NotificationPrefs {
  dailyNudgeEnabled: boolean;
  /** Local HH:mm (24-hour). */
  dailyNudgeTime: string;
  quietHoursEnabled: boolean;
  quietHoursStart: string;
  quietHoursEnd: string;
}

export const defaultPrefs: NotificationPrefs = {
  dailyNudgeEnabled: true,
  dailyNudgeTime: "08:00",
  quietHoursEnabled: true,
  quietHoursStart: "21:00",
  quietHoursEnd: "07:00",
};

/** Parse a Firestore `meta/notifications` doc into prefs, filling defaults. */
export function prefsFromDoc(
  data: FirebaseFirestore.DocumentData | undefined,
): NotificationPrefs {
  if (!data) return defaultPrefs;
  const str = (v: unknown, fallback: string) =>
    typeof v === "string" ? v : fallback;
  const bool = (v: unknown, fallback: boolean) =>
    typeof v === "boolean" ? v : fallback;
  return {
    dailyNudgeEnabled: bool(data.dailyNudgeEnabled, true),
    dailyNudgeTime: str(data.dailyNudgeTime, "08:00"),
    quietHoursEnabled: bool(data.quietHoursEnabled, true),
    quietHoursStart: str(data.quietHoursStart, "21:00"),
    quietHoursEnd: str(data.quietHoursEnd, "07:00"),
  };
}

/** Minutes since local midnight for an `HH:mm` string, or null if malformed. */
export function minuteOfDay(hhmm: string): number | null {
  const parts = hhmm.split(":");
  if (parts.length !== 2) return null;
  const h = Number(parts[0]);
  const m = Number(parts[1]);
  if (!Number.isInteger(h) || !Number.isInteger(m)) return null;
  if (h < 0 || h > 23 || m < 0 || m > 59) return null;
  return h * 60 + m;
}

/** Whether `nowMinute` is in the quiet window `[start, end)` (may wrap midnight). */
export function isWithinQuietHours(
  nowMinute: number,
  startMinute: number,
  endMinute: number,
): boolean {
  if (startMinute === endMinute) return false;
  if (startMinute < endMinute) {
    return nowMinute >= startMinute && nowMinute < endMinute;
  }
  return nowMinute >= startMinute || nowMinute < endMinute;
}

/** Whether the daily nudge should fire now. Mirrors the Dart implementation. */
export function shouldSendDailyNudge(args: {
  prefs: NotificationPrefs;
  nowMinute: number;
  hasOpenTasks: boolean;
  toleranceMinutes?: number;
}): boolean {
  const {prefs, nowMinute, hasOpenTasks} = args;
  const tolerance = args.toleranceMinutes ?? 0;
  if (!prefs.dailyNudgeEnabled) return false;
  if (!hasOpenTasks) return false;

  const nudge = minuteOfDay(prefs.dailyNudgeTime);
  if (nudge === null) return false;
  if (!(nowMinute >= nudge && nowMinute <= nudge + tolerance)) return false;

  if (prefs.quietHoursEnabled) {
    const start = minuteOfDay(prefs.quietHoursStart);
    const end = minuteOfDay(prefs.quietHoursEnd);
    if (start !== null && end !== null &&
        isWithinQuietHours(nowMinute, start, end)) {
      return false;
    }
  }
  return true;
}

/** Minutes since local midnight for [date] rendered in [timeZone]. */
export function minuteOfDayInZone(date: Date, timeZone: string): number {
  const parts = new Intl.DateTimeFormat("en-GB", {
    timeZone,
    hour: "2-digit",
    minute: "2-digit",
    hour12: false,
  }).formatToParts(date);
  const h = Number(parts.find((p) => p.type === "hour")?.value ?? "0");
  const m = Number(parts.find((p) => p.type === "minute")?.value ?? "0");
  return (h % 24) * 60 + m;
}
