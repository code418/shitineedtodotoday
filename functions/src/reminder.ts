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
  // Mirror Dart's `int.tryParse` exactly so the server never accepts a time the
  // client rejects (or vice versa): it trims surrounding whitespace, then wants
  // an optional sign + digits. A naive `Number()` diverges — `Number("")` is 0,
  // so a malformed "08:" would fire at 08:00 on the server while the Dart client
  // treats it as invalid; `Number("8.5")` is 8.5 (a non-integer, so rejected).
  const parseIntLike = (s: string): number | null => {
    const t = s.trim();
    return /^[+-]?\d+$/.test(t) ? Number(t) : null;
  };
  const h = parseIntLike(parts[0]);
  const m = parseIntLike(parts[1]);
  if (h === null || m === null) return null;
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

/**
 * Whether the nudge's *timing* allows firing now — enabled, inside the
 * [nudge, nudge+tolerance] window, and outside quiet hours. Independent of
 * whether there's anything to do, so the dispatcher can apply this cheap gate
 * before doing any per-task occurrence reads.
 */
export function nudgeTimingAllows(args: {
  prefs: NotificationPrefs;
  nowMinute: number;
  toleranceMinutes?: number;
}): boolean {
  const {prefs, nowMinute} = args;
  const tolerance = args.toleranceMinutes ?? 0;
  if (!prefs.dailyNudgeEnabled) return false;

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
    // Judge quiet hours against the configured `nudge` time, NOT `nowMinute`:
    // the tick that catches the nudge can land up to `tolerance` minutes later,
    // on the far side of a quiet boundary. Using the nudge time keeps the
    // decision independent of the tick grid and consistent with the client's
    // `nudgeFallsInQuietHours` warning — a nudge outside quiet hours always
    // fires; one inside is always suppressed.
    if (start !== null && end !== null &&
        isWithinQuietHours(nudge, start, end)) {
      return false;
    }
  }
  return true;
}

/** Whether the daily nudge should fire now. Mirrors the Dart implementation. */
export function shouldSendDailyNudge(args: {
  prefs: NotificationPrefs;
  nowMinute: number;
  hasOpenTasks: boolean;
  toleranceMinutes?: number;
}): boolean {
  if (!args.hasOpenTasks) return false;
  return nudgeTimingAllows(args);
}

/** `yyyy-MM-dd` for a date-only UTC Date. */
export function isoDay(day: Date): string {
  const y = day.getUTCFullYear().toString().padStart(4, "0");
  const m = (day.getUTCMonth() + 1).toString().padStart(2, "0");
  const d = day.getUTCDate().toString().padStart(2, "0");
  return `${y}-${m}-${d}`;
}

/**
 * Deterministic occurrence document id, mirroring the Dart `occurrenceId`
 * (`{taskId}_yyyy-MM-dd`). [day] must be a date-only UTC Date. Lets the
 * dispatcher look up "is this task already handled today?" with an index-free
 * GET by id rather than a query.
 */
export function occurrenceIdFor(taskId: string, day: Date): string {
  return `${taskId}_${isoDay(day)}`;
}

// ── What the client would show as outstanding ─────────────────────────────────
// Mirrors `ForgivingScheduler.buildToday(carryOverdue: true)` + the live-task
// filter in `todayChecklistProvider`. The server has to agree with what the
// user can actually see, in BOTH directions: nudging for work the checklist
// hides is as wrong as staying silent on work it shows.

/** Occurrence statuses that still need attention — mirrors Dart `isOpen`. */
export const OPEN_OCCURRENCE_STATUSES = ["pending", "rescheduled"];

/**
 * Start-of-day Firestore range operand for [day]. `scheduledDate` persists as a
 * LOCAL ISO-8601 string (never a Timestamp), and ISO-8601 sorts
 * lexicographically in chronological order, so string bounds are exact.
 */
export function dayStartBound(day: Date): string {
  return `${isoDay(day)}T00:00:00.000`;
}

/** [day] plus [days], for date-only UTC Dates (no DST in UTC). */
export function addUtcDays(day: Date, days: number): Date {
  return new Date(day.getTime() + days * 86400000);
}

/** The shape the dispatcher reads off an occurrence document. */
export interface OccurrenceRow {
  taskId?: unknown;
  status?: unknown;
  scheduledDate?: unknown;
}

/** The `yyyy-MM-dd` a row is scheduled on, or null if it isn't a usable date. */
function rowDay(row: OccurrenceRow): string | null {
  // Typed `unknown` on purpose: a wrong-typed field must be skipped, not throw.
  // Everything else that reads Firestore here salvages bad docs the same way
  // (see the Dart `firestore_decode.dart`), and `.slice` on a non-string would
  // take out this user's whole nudge.
  if (typeof row.scheduledDate !== "string") return null;
  const day = row.scheduledDate.slice(0, 10);
  return /^\d{4}-\d{2}-\d{2}$/.test(day) ? day : null;
}

function isOpenRow(row: OccurrenceRow): boolean {
  return (
    typeof row.status === "string" &&
    OPEN_OCCURRENCE_STATUSES.includes(row.status)
  );
}

/** The row's task id, if it names a task that still exists and is active. */
function liveTaskId(
  row: OccurrenceRow,
  activeTaskIds: ReadonlySet<string>,
): string | null {
  const taskId = row.taskId;
  // An empty id is malformed rather than a real task — Firestore document ids
  // are never empty — so reject it before it can match a stray "" in the set.
  if (typeof taskId !== "string" || taskId === "") return null;
  return activeTaskIds.has(taskId) ? taskId : null;
}

/**
 * The task ids the client's checklist would show as still needing attention on
 * [today]. Empty means "genuinely nothing to nudge about".
 *
 * The three sources mirror `buildToday`'s three steps:
 *  1. an open occurrence already dated today;
 *  2. an open occurrence left on an earlier day, carried forward — but only if
 *     the task has no occurrence dated today at all, which is the client's
 *     `claimed` set. Without that guard a weekly task missed last Monday and
 *     ticked off today would still nudge, while the checklist showed nothing;
 *  3. a task due today that hasn't been materialised yet. Deduped by occurrence
 *     *id*, not by date — an occurrence dragged to a future day keeps the id it
 *     was generated under, and the client won't regenerate it.
 *
 * Tasks that are inactive or no longer exist are dropped throughout, matching
 * `todayChecklistProvider`, so a half-failed cascade-delete can't nudge forever.
 */
export function outstandingTaskIds(args: {
  /** Every occurrence row dated today, whatever its status. */
  todayRows: OccurrenceRow[];
  /** Open occurrence rows dated before today (from the bounded scan). */
  pastOpenRows: OccurrenceRow[];
  /** Active task ids whose recurrence lands on today. */
  dueTodayTaskIds: string[];
  /** Active task ids whose `{taskId}_{today}` document already exists. */
  materialisedTaskIds: ReadonlySet<string>;
  activeTaskIds: ReadonlySet<string>;
  today: Date;
}): Set<string> {
  const todayIso = isoDay(args.today);
  const outstanding = new Set<string>();
  // Any occurrence dated today claims its task, settled or not.
  const claimedToday = new Set<string>();

  for (const row of args.todayRows) {
    const taskId = liveTaskId(row, args.activeTaskIds);
    if (taskId === null) continue;
    if (rowDay(row) !== todayIso) continue;
    claimedToday.add(taskId);
    if (isOpenRow(row)) outstanding.add(taskId);
  }

  for (const row of args.pastOpenRows) {
    const taskId = liveTaskId(row, args.activeTaskIds);
    if (taskId === null) continue;
    if (!isOpenRow(row)) continue;
    const day = rowDay(row);
    if (day === null || !(day < todayIso)) continue;
    if (claimedToday.has(taskId)) continue;
    outstanding.add(taskId);
  }

  for (const taskId of args.dueTodayTaskIds) {
    if (!args.activeTaskIds.has(taskId)) continue;
    if (claimedToday.has(taskId)) continue;
    if (args.materialisedTaskIds.has(taskId)) continue;
    outstanding.add(taskId);
  }

  return outstanding;
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

// ── Once-per-day send claim ───────────────────────────────────────────────────
// `onSchedule` guarantees at-least-once delivery, so the same tick can be
// delivered twice and the 14-minute tolerance only separates *distinct* ticks.
// The dispatcher therefore claims the day atomically (`create()`, which fails
// if the doc exists) before sending, and releases the claim if the send turned
// out to reach nobody. Nudging twice is worse than nudging late, so the claim
// deliberately errs towards at-most-once.

/** Document id for a user's once-per-day send claim. */
export function reminderClaimId(day: Date): string {
  return isoDay(day);
}

/** How long a spent claim is kept before Firestore's TTL collects it. */
export const CLAIM_RETENTION_DAYS = 7;

/**
 * When a claim written at [now] may be garbage-collected. Comfortably longer
 * than the day it guards, so a claim is never collected while its own local
 * day is still in progress in some time zone.
 */
export function claimExpiry(
  now: Date,
  retentionDays: number = CLAIM_RETENTION_DAYS,
): Date {
  return new Date(now.getTime() + retentionDays * 86400000);
}

/**
 * Whether [err] is Firestore's "document already exists" rejection — i.e.
 * another delivery of this tick already claimed the day.
 *
 * Checked across every shape the code can arrive in (numeric gRPC status,
 * string enum, hyphenated client-SDK spelling, bare message), because getting
 * this wrong fails in both directions: too narrow double-sends, too broad
 * silently swallows a real error and drops the day's nudge.
 */
export function isAlreadyExistsError(err: unknown): boolean {
  if (typeof err !== "object" || err === null) return false;
  const code = (err as {code?: unknown}).code;
  if (code === 6 || code === "ALREADY_EXISTS" || code === "already-exists") {
    return true;
  }
  const message = (err as {message?: unknown}).message;
  return typeof message === "string" && message.includes("ALREADY_EXISTS");
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
