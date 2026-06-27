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
  // Modular distance so the window is exactly [nudge, nudge+tolerance] mod 1440.
  // Handles midnight wrap and prevents double-sends when two scheduler ticks
  // both fall inside a window wider than the tick interval.
  const diff = ((nowMinute - nudge) % 1440 + 1440) % 1440;
  if (!(diff <= tolerance)) return false;

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

/**
 * Build a date-only UTC Date representing the LOCAL calendar day for a
 * given wall-clock instant in [timeZone].
 * Arithmetic is DST-safe because all subsequent work uses UTC getters.
 */
export function localDateOnly(now: Date, timeZone: string): Date {
  const parts = new Intl.DateTimeFormat("en-GB", {
    timeZone,
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  }).formatToParts(now);
  const y = Number(parts.find((p) => p.type === "year")?.value ?? "0");
  const m = Number(parts.find((p) => p.type === "month")?.value ?? "1");
  const d = Number(parts.find((p) => p.type === "day")?.value ?? "1");
  return new Date(Date.UTC(y, m - 1, d));
}

// ── Recurrence-aware occurrence check ─────────────────────────────────────────
// Mirrors the Dart `ForgivingScheduler._occursOn` so the server dispatcher
// fires only when something actually falls on today (not on every day for
// weekly tasks etc.). Operates on date-only UTC Dates so arithmetic is DST-safe.

export interface RecurrenceJson {
  runtimeType?: string;
  weekdays?: number[];
  dayOfMonth?: number | null;
  exactDate?: string | null;
  timesPerPeriod?: number;
  period?: string;
  season?: string | null;
}

/** Days in [month1] (1..12) of [year]. */
function daysInMonth(year: number, month1: number): number {
  return new Date(Date.UTC(year, month1, 0)).getUTCDate();
}

/** ISO weekday (1 = Mon .. 7 = Sun) of a date-only UTC Date. */
function isoWeekday(d: Date): number {
  const wd = d.getUTCDay();
  return wd === 0 ? 7 : wd;
}

/** Inclusive [start, end] of the period containing [day] (date-only UTC Dates). */
function periodBounds(period: string, day: Date): [Date, Date] {
  const y = day.getUTCFullYear(), m0 = day.getUTCMonth(), dom = day.getUTCDate();
  switch (period) {
    case "day": return [day, day];
    case "month":
      return [
        new Date(Date.UTC(y, m0, 1)),
        new Date(Date.UTC(y, m0, daysInMonth(y, m0 + 1))),
      ];
    case "year":
      return [new Date(Date.UTC(y, 0, 1)), new Date(Date.UTC(y, 11, 31))];
    case "week":
    default: {
      const wd = isoWeekday(day);
      const start = new Date(Date.UTC(y, m0, dom - (wd - 1)));
      const end = new Date(start.getTime() + 6 * 86400000);
      return [start, end];
    }
  }
}

/**
 * Returns true if [rec] produces an occurrence on calendar day [day].
 * [day] must be a date-only UTC Date (time component zero).
 * Mirrors Dart `ForgivingScheduler._occursOn`.
 */
export function occursOn(rec: RecurrenceJson, day: Date): boolean {
  const y = day.getUTCFullYear(), m = day.getUTCMonth() + 1, dom = day.getUTCDate();

  if (rec.runtimeType === "strict") {
    if (rec.exactDate) {
      const e = new Date(rec.exactDate);
      return (
        e.getUTCFullYear() === y &&
        e.getUTCMonth() + 1 === m &&
        e.getUTCDate() === dom
      );
    }
    if (rec.dayOfMonth != null) {
      const dim = daysInMonth(y, m);
      const target = rec.dayOfMonth > dim ? dim : rec.dayOfMonth;
      return dom === target;
    }
    return (rec.weekdays ?? []).includes(isoWeekday(day));
  }

  // flexible
  if (rec.season) {
    const seasonMonths: Record<string, number> = {
      spring: 3,
      summer: 6,
      autumn: 9,
      winter: 12,
    };
    const startMonth = seasonMonths[rec.season];
    return startMonth != null && m === startMonth && dom === 1;
  }
  const period = rec.period ?? "week";
  const [start, end] = periodBounds(period, day);
  const lengthDays =
    Math.round((end.getTime() - start.getTime()) / 86400000) + 1;
  const times = Math.min(Math.max(rec.timesPerPeriod ?? 1, 1), lengthDays);
  for (let i = 0; i < times; i++) {
    const offset = Math.floor((i * lengthDays) / times);
    const anchor = new Date(start.getTime() + offset * 86400000);
    if (
      anchor.getUTCFullYear() === y &&
      anchor.getUTCMonth() === day.getUTCMonth() &&
      anchor.getUTCDate() === dom
    ) {
      return true;
    }
  }
  return false;
}
