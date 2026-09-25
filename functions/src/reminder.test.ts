import assert from "node:assert/strict";
import test from "node:test";

import {
  addUtcDays,
  claimExpiry,
  dayStartBound,
  defaultPrefs,
  isAlreadyExistsError,
  isWithinQuietHours,
  isoDay,
  localDateOnly,
  minuteOfDay,
  minuteOfDayInZone,
  nudgeTimingAllows,
  occurrenceIdFor,
  occursOn,
  outstandingTaskIds,
  prefsFromDoc,
  reminderClaimId,
  resolveZone,
  shouldSendDailyNudge,
} from "./reminder";
import type {RecurrenceJson} from "./reminder";

test("minuteOfDay parses valid times and rejects bad ones", () => {
  assert.equal(minuteOfDay("00:00"), 0);
  assert.equal(minuteOfDay("08:30"), 8 * 60 + 30);
  assert.equal(minuteOfDay("23:59"), 23 * 60 + 59);
  assert.equal(minuteOfDay("8"), null);
  assert.equal(minuteOfDay("24:00"), null);
  assert.equal(minuteOfDay("10:60"), null);
  assert.equal(minuteOfDay("aa:bb"), null);
});

test("minuteOfDay rejects empty components but mirrors Dart int.tryParse", () => {
  // Regression: `Number("")` is 0, so without a grammar check the server would
  // parse an empty component ("08:" -> 08:00) where the Dart client returns null
  // — breaking the documented client/server agreement.
  assert.equal(minuteOfDay("08:"), null);
  assert.equal(minuteOfDay(":30"), null);
  assert.equal(minuteOfDay(":"), null);
  assert.equal(minuteOfDay("8.5:00"), null);
  // Dart's int.tryParse trims surrounding whitespace, so these are VALID in both
  // languages — the parser must agree, not just be strict.
  assert.equal(minuteOfDay(" 8:30"), 8 * 60 + 30);
  assert.equal(minuteOfDay("8:3 "), 8 * 60 + 3);
  // A leading '+' is accepted (int.tryParse("+8") == 8); a negative parses but
  // fails the range check — same as Dart.
  assert.equal(minuteOfDay("+8:30"), 8 * 60 + 30);
  assert.equal(minuteOfDay("-1:00"), null);
});

test("isWithinQuietHours handles non-wrapping windows", () => {
  assert.equal(isWithinQuietHours(13 * 60, 13 * 60, 14 * 60), true);
  assert.equal(isWithinQuietHours(14 * 60, 13 * 60, 14 * 60), false); // end exclusive
  assert.equal(isWithinQuietHours(12 * 60, 13 * 60, 14 * 60), false);
});

test("isWithinQuietHours wraps past midnight (21:00-07:00)", () => {
  assert.equal(isWithinQuietHours(23 * 60, 21 * 60, 7 * 60), true);
  assert.equal(isWithinQuietHours(2 * 60, 21 * 60, 7 * 60), true);
  assert.equal(isWithinQuietHours(7 * 60, 21 * 60, 7 * 60), false);
  assert.equal(isWithinQuietHours(12 * 60, 21 * 60, 7 * 60), false);
});

test("isWithinQuietHours: empty window is never quiet", () => {
  assert.equal(isWithinQuietHours(600, 600, 600), false);
});

test("shouldSendDailyNudge fires at the nudge time with open tasks", () => {
  assert.equal(
    shouldSendDailyNudge({prefs: defaultPrefs, nowMinute: 8 * 60, hasOpenTasks: true}),
    true,
  );
});

test("shouldSendDailyNudge: nothing open -> no nudge", () => {
  assert.equal(
    shouldSendDailyNudge({prefs: defaultPrefs, nowMinute: 8 * 60, hasOpenTasks: false}),
    false,
  );
});

test("shouldSendDailyNudge: off the minute without tolerance -> no nudge", () => {
  assert.equal(
    shouldSendDailyNudge({prefs: defaultPrefs, nowMinute: 8 * 60 + 1, hasOpenTasks: true}),
    false,
  );
});

test("shouldSendDailyNudge: tolerance widens the window", () => {
  assert.equal(
    shouldSendDailyNudge({
      prefs: defaultPrefs,
      nowMinute: 8 * 60 + 10,
      hasOpenTasks: true,
      toleranceMinutes: 15,
    }),
    true,
  );
});

test("shouldSendDailyNudge: disabled never fires", () => {
  assert.equal(
    shouldSendDailyNudge({
      prefs: {...defaultPrefs, dailyNudgeEnabled: false},
      nowMinute: 8 * 60,
      hasOpenTasks: true,
    }),
    false,
  );
});

test("shouldSendDailyNudge: suppressed inside quiet hours", () => {
  const early = {...defaultPrefs, dailyNudgeTime: "06:00"};
  assert.equal(
    shouldSendDailyNudge({prefs: early, nowMinute: 6 * 60, hasOpenTasks: true}),
    false,
  );
  assert.equal(
    shouldSendDailyNudge({
      prefs: {...early, quietHoursEnabled: false},
      nowMinute: 6 * 60,
      hasOpenTasks: true,
    }),
    true,
  );
});

test("shouldSendDailyNudge: no double-send at boundary (tolerance 14)", () => {
  // Nudge at 08:00 (480), tolerance 14 → window [480, 494].
  // Tick at 480 fires; next tick at 495 must not fire.
  assert.equal(
    shouldSendDailyNudge({
      prefs: defaultPrefs,
      nowMinute: 480,
      hasOpenTasks: true,
      toleranceMinutes: 14,
    }),
    true,
  );
  assert.equal(
    shouldSendDailyNudge({
      prefs: defaultPrefs,
      nowMinute: 495,
      hasOpenTasks: true,
      toleranceMinutes: 14,
    }),
    false,
    "second tick 15 min later is outside the 14-min window",
  );
});

test("shouldSendDailyNudge: wraps midnight", () => {
  // Nudge at 23:50 (1430), tolerance 14 → window wraps: 00:00 (0) is 10 min after.
  // Quiet hours are disabled so 00:00 (inside the default 21:00-07:00 window)
  // is not suppressed.
  const latePrefs = {...defaultPrefs, dailyNudgeTime: "23:50", quietHoursEnabled: false};
  assert.equal(
    shouldSendDailyNudge({
      prefs: latePrefs,
      nowMinute: 0,
      hasOpenTasks: true,
      toleranceMinutes: 14,
    }),
    true,
    "midnight (00:00) is 10 min after 23:50, within tolerance",
  );
  assert.equal(
    shouldSendDailyNudge({
      prefs: latePrefs,
      nowMinute: 1425,
      hasOpenTasks: true,
      toleranceMinutes: 14,
    }),
    false,
    "23:45 is 5 min before 23:50, outside the window",
  );
});

test("prefsFromDoc fills defaults and reads overrides", () => {
  assert.deepEqual(prefsFromDoc(undefined), defaultPrefs);
  assert.equal(prefsFromDoc({dailyNudgeEnabled: false}).dailyNudgeEnabled, false);
  assert.equal(prefsFromDoc({dailyNudgeTime: "09:15"}).dailyNudgeTime, "09:15");
});

test("prefsFromDoc reads the stored time zone, defaulting for missing/bad", () => {
  assert.equal(prefsFromDoc(undefined).timeZone, "Europe/London");
  assert.equal(
    prefsFromDoc({timeZone: "America/New_York"}).timeZone,
    "America/New_York",
  );
  // A wrong-typed field falls back rather than throwing, like every other field.
  assert.equal(prefsFromDoc({timeZone: 42}).timeZone, "Europe/London");
});

test("resolveZone: passes valid IANA zones, falls back on anything else", () => {
  assert.equal(resolveZone("America/New_York"), "America/New_York");
  assert.equal(resolveZone("Asia/Kolkata"), "Asia/Kolkata"); // +5:30 offset
  assert.equal(resolveZone("UTC"), "UTC");
  // Unknown zone, empty, wrong type → the London fallback (previous behaviour),
  // never a throw: Intl.DateTimeFormat rejects a bad zone with a RangeError, and
  // one bad prefs doc must not take out that user's nudge.
  assert.equal(resolveZone("Mars/Olympus_Mons"), "Europe/London");
  assert.equal(resolveZone(""), "Europe/London");
  assert.equal(resolveZone(undefined), "Europe/London");
  assert.equal(resolveZone("Not A Zone"), "Europe/London");
  // Explicit fallback is honoured.
  assert.equal(resolveZone(undefined, "UTC"), "UTC");
});

test("minuteOfDayInZone / localDateOnly honour a non-London zone", () => {
  // 2026-07-24T02:30:00Z is 22:30 on 2026-07-23 in New York (EDT, -4).
  const t = new Date("2026-07-24T02:30:00Z");
  assert.equal(minuteOfDayInZone(t, "America/New_York"), 22 * 60 + 30);
  assert.equal(isoDay(localDateOnly(t, "America/New_York")), "2026-07-23");
  // Same instant in London (BST, +1) is 03:30 on the 24th.
  assert.equal(minuteOfDayInZone(t, "Europe/London"), 3 * 60 + 30);
  assert.equal(isoDay(localDateOnly(t, "Europe/London")), "2026-07-24");
});

test("minuteOfDayInZone respects the time zone (BST in June)", () => {
  // 08:30 UTC on 29 Jun 2026 is 09:30 in London (BST, +1).
  const m = minuteOfDayInZone(new Date("2026-06-29T08:30:00Z"), "Europe/London");
  assert.equal(m, 9 * 60 + 30);
});

// ── occursOn ──────────────────────────────────────────────────────────────────

test("occursOn: strict weekday — Mon-only true on Monday, false on Tuesday", () => {
  // 2026-06-29 is a Monday (UTC day-only).
  const mon = new Date(Date.UTC(2026, 5, 29)); // June 29
  const tue = new Date(Date.UTC(2026, 5, 30)); // June 30
  const rec = {runtimeType: "strict", weekdays: [1]}; // ISO 1 = Monday
  assert.equal(occursOn(rec, mon), true);
  assert.equal(occursOn(rec, tue), false);
});

test("occursOn: strict dayOfMonth clamps to last day of a short month", () => {
  // Day 31 in February 2026 (not a leap year): clamp to 28.
  const rec = {runtimeType: "strict", dayOfMonth: 31};
  const feb28 = new Date(Date.UTC(2026, 1, 28));
  const feb27 = new Date(Date.UTC(2026, 1, 27));
  assert.equal(occursOn(rec, feb28), true);
  assert.equal(occursOn(rec, feb27), false);
});

test("occursOn: strict dayOfMonth respects leap years and 30-day months", () => {
  const rec29 = {runtimeType: "strict", dayOfMonth: 29};
  // 2028 is a leap year → the 29th exists, so it lands on Feb 29 (not 28).
  assert.equal(occursOn(rec29, new Date(Date.UTC(2028, 1, 29))), true);
  assert.equal(occursOn(rec29, new Date(Date.UTC(2028, 1, 28))), false);
  // 2027 is not a leap year → Feb has 28 days, so the 29th clamps to the 28th.
  assert.equal(occursOn(rec29, new Date(Date.UTC(2027, 1, 28))), true);

  // A 31st task clamps to the last day of a 30-day month (April).
  const rec31 = {runtimeType: "strict", dayOfMonth: 31};
  assert.equal(occursOn(rec31, new Date(Date.UTC(2026, 3, 30))), true);
  assert.equal(occursOn(rec31, new Date(Date.UTC(2026, 3, 29))), false);
});

/**
 * Runs [fn] with the process time zone set to [zone]. Node re-reads
 * `process.env.TZ` on assignment, so this exercises host-zone-dependent parsing
 * deterministically, whatever machine the suite runs on.
 */
function inProcessZone(zone: string, fn: () => void): void {
  const previous = process.env.TZ;
  process.env.TZ = zone;
  try {
    fn();
  } finally {
    if (previous === undefined) delete process.env.TZ;
    else process.env.TZ = previous;
  }
}

test("occursOn: a one-off (exactDate) fires on its own calendar day in any host zone", () => {
  // Dart persists the picked date as a LOCAL-midnight toIso8601String(): no
  // zone designator. It must match on its calendar day wherever the function
  // (or the emulator / a developer's test run) happens to be hosted.
  const rec = {runtimeType: "strict", exactDate: "2026-07-24T00:00:00.000"};
  for (const zone of ["UTC", "Europe/London", "Asia/Tokyo", "America/New_York"]) {
    inProcessZone(zone, () => {
      assert.equal(occursOn(rec, new Date(Date.UTC(2026, 6, 24))), true, zone);
      assert.equal(occursOn(rec, new Date(Date.UTC(2026, 6, 23))), false, zone);
      assert.equal(occursOn(rec, new Date(Date.UTC(2026, 6, 25))), false, zone);
    });
  }
});

test("occursOn: a UTC-suffixed exactDate matches its date, like Dart's dateOnly", () => {
  const rec = {runtimeType: "strict", exactDate: "2026-07-24T00:00:00.000Z"};
  inProcessZone("Asia/Tokyo", () => {
    assert.equal(occursOn(rec, new Date(Date.UTC(2026, 6, 24))), true);
    assert.equal(occursOn(rec, new Date(Date.UTC(2026, 6, 23))), false);
  });
});

test("occursOn: a non-string exactDate never matches (and never throws)", () => {
  // A malformed doc (e.g. a Timestamp where an ISO string was expected) fails
  // to decode on the client, so the task isn't shown there either.
  const rec = {
    runtimeType: "strict",
    exactDate: { seconds: 1784851200, nanoseconds: 0 },
  } as unknown as RecurrenceJson;
  assert.equal(occursOn(rec, new Date(Date.UTC(2026, 6, 24))), false);
});

test("occursOn: flexible weekly fires only on the week's Monday", () => {
  // timesPerPeriod=1 → anchor at offset 0 of the ISO week = Monday.
  const rec = {runtimeType: "flexible", period: "week", timesPerPeriod: 1};
  const mon = new Date(Date.UTC(2026, 5, 29)); // 2026-06-29 Mon
  const wed = new Date(Date.UTC(2026, 6, 1));  // 2026-07-01 Wed
  assert.equal(occursOn(rec, mon), true);
  assert.equal(occursOn(rec, wed), false);
});

test("occursOn: flexible three-times-a-week hits evenly-spaced anchors", () => {
  // lengthDays=7, times=3 → offsets 0,2,4 = Mon, Wed, Fri.
  const rec = {runtimeType: "flexible", period: "week", timesPerPeriod: 3};
  assert.equal(occursOn(rec, new Date(Date.UTC(2026, 5, 29))), true); // Mon
  assert.equal(occursOn(rec, new Date(Date.UTC(2026, 6, 1))), true); // Wed
  assert.equal(occursOn(rec, new Date(Date.UTC(2026, 6, 3))), true); // Fri
  assert.equal(occursOn(rec, new Date(Date.UTC(2026, 5, 30))), false); // Tue
  assert.equal(occursOn(rec, new Date(Date.UTC(2026, 6, 2))), false); // Thu
});

test("occursOn: flexible daily fires on any day", () => {
  const rec = {runtimeType: "flexible", period: "day", timesPerPeriod: 1};
  const mon = new Date(Date.UTC(2026, 5, 29));
  const sat = new Date(Date.UTC(2026, 5, 27));
  assert.equal(occursOn(rec, mon), true);
  assert.equal(occursOn(rec, sat), true);
});

test("occursOn: seasonal summer fires on 1 June only", () => {
  const rec = {runtimeType: "flexible", season: "summer"};
  const jun1 = new Date(Date.UTC(2026, 5, 1)); // June 1 = summer start
  const jun2 = new Date(Date.UTC(2026, 5, 2)); // June 2
  const sep1 = new Date(Date.UTC(2026, 8, 1)); // Sep 1 (autumn start, not summer)
  assert.equal(occursOn(rec, jun1), true);
  assert.equal(occursOn(rec, jun2), false);
  assert.equal(occursOn(rec, sep1), false);
});

test("nudgeTimingAllows: true in window, ignores whether there are tasks", () => {
  // 08:00 nudge, now 08:00, outside default quiet hours (21:00-07:00).
  assert.equal(
    nudgeTimingAllows({prefs: defaultPrefs, nowMinute: 8 * 60}),
    true,
  );
});

test("nudgeTimingAllows: false when disabled, outside window, or quiet", () => {
  assert.equal(
    nudgeTimingAllows({
      prefs: {...defaultPrefs, dailyNudgeEnabled: false},
      nowMinute: 8 * 60,
    }),
    false,
  );
  // Outside the [nudge, nudge+tolerance] window.
  assert.equal(
    nudgeTimingAllows({prefs: defaultPrefs, nowMinute: 10 * 60}),
    false,
  );
  // Nudge time inside quiet hours is suppressed.
  assert.equal(
    nudgeTimingAllows({
      prefs: {...defaultPrefs, dailyNudgeTime: "22:00"},
      nowMinute: 22 * 60,
    }),
    false,
  );
});

test("nudgeTimingAllows: quiet hours are judged on the nudge time, not the tick", () => {
  // The scheduler ticks on a ~15-min grid with a 14-min tolerance, so the tick
  // that catches a nudge can land on the far side of a quiet boundary. The
  // decision must judge the nudge time itself, matching the client's
  // nudgeFallsInQuietHours warning.

  // Nudge 20:55 is OUTSIDE quiet hours 21:00–07:00; the 21:00 tick catches it
  // (diff 5 ≤ 14). A tick-based check would suppress it and the user would
  // never get the nudge they set.
  assert.equal(
    nudgeTimingAllows({
      prefs: {...defaultPrefs, dailyNudgeTime: "20:55"},
      nowMinute: 21 * 60,
      toleranceMinutes: 14,
    }),
    true,
    "nudge 20:55 outside quiet hours must fire even when caught by the 21:00 tick",
  );

  // Nudge 06:50 is INSIDE quiet hours; the 07:00 tick catches it (diff 10 ≤ 14)
  // but is itself outside quiet hours. A tick-based check would wrongly send.
  assert.equal(
    nudgeTimingAllows({
      prefs: {...defaultPrefs, dailyNudgeTime: "06:50"},
      nowMinute: 7 * 60,
      toleranceMinutes: 14,
    }),
    false,
    "nudge 06:50 inside quiet hours must stay suppressed even at the 07:00 tick",
  );
});

test("occurrenceIdFor: matches the Dart {taskId}_yyyy-MM-dd format", () => {
  assert.equal(
    occurrenceIdFor("t1", new Date(Date.UTC(2026, 5, 29))),
    "t1_2026-06-29",
  );
  // Single-digit month/day are zero-padded.
  assert.equal(
    occurrenceIdFor("abc", new Date(Date.UTC(2026, 0, 5))),
    "abc_2026-01-05",
  );
});

// ── Outstanding work (what the checklist would show) ─────────────────────────
// `outstandingTaskIds` mirrors ForgivingScheduler.buildToday(carryOverdue:true)
// plus todayChecklistProvider's live-task filter. It has to agree with the
// client in BOTH directions — nudging for hidden work is as wrong as silence.

const TODAY = new Date(Date.UTC(2026, 6, 24)); // 2026-07-24
const at = (day: string) => `${day}T00:00:00.000`;

/** Defaults every field so each test states only what it is about. */
function outstanding(over: Partial<Parameters<typeof outstandingTaskIds>[0]>) {
  return [
    ...outstandingTaskIds({
      todayRows: [],
      pastOpenRows: [],
      dueTodayTaskIds: [],
      materialisedTaskIds: new Set<string>(),
      activeTaskIds: new Set(["t1", "t2", "live"]),
      today: TODAY,
      ...over,
    }),
  ].sort();
}

test("isoDay: renders a date-only UTC Date as yyyy-MM-dd", () => {
  assert.equal(isoDay(TODAY), "2026-07-24");
  assert.equal(isoDay(new Date(Date.UTC(2026, 0, 5))), "2026-01-05");
});

test("dayStartBound / addUtcDays: exact string bounds around a local day", () => {
  assert.equal(dayStartBound(TODAY), "2026-07-24T00:00:00.000");
  assert.equal(dayStartBound(addUtcDays(TODAY, 1)), "2026-07-25T00:00:00.000");
  // The scan window is [todayStart, tomorrowStart) for today's rows and
  // everything below todayStart for the past — ISO-8601 sorts chronologically.
  assert.ok(at("2026-07-23") < dayStartBound(TODAY));
  assert.ok(at("2026-07-24") >= dayStartBound(TODAY));
  assert.ok(at("2026-07-24") < dayStartBound(addUtcDays(TODAY, 1)));
  assert.ok(!(at("2026-07-25") < dayStartBound(addUtcDays(TODAY, 1))));
});

test("outstanding: a task due today that isn't materialised yet", () => {
  assert.deepEqual(outstanding({dueTodayTaskIds: ["t1"]}), ["t1"]);
});

test("outstanding: an open occurrence dated today", () => {
  assert.deepEqual(
    outstanding({
      todayRows: [{taskId: "t1", status: "pending", scheduledDate: at("2026-07-24")}],
    }),
    ["t1"],
  );
});

test("outstanding: settled today -> nothing to nudge about", () => {
  assert.deepEqual(
    outstanding({
      dueTodayTaskIds: ["t1", "t2"],
      materialisedTaskIds: new Set(["t1", "t2"]),
      todayRows: [
        {taskId: "t1", status: "done", scheduledDate: at("2026-07-24")},
        {taskId: "t2", status: "skipped", scheduledDate: at("2026-07-24")},
      ],
    }),
    [],
  );
});

test("outstanding: open work left on an earlier day is carried forward", () => {
  // The whole point of the carry-forward: nothing recurs today, but the
  // checklist still shows Monday's miss, so the nudge must fire.
  assert.deepEqual(
    outstanding({
      pastOpenRows: [
        {taskId: "t1", status: "pending", scheduledDate: at("2026-07-20")},
        {taskId: "t2", status: "rescheduled", scheduledDate: at("2026-07-23")},
      ],
    }),
    ["t1", "t2"],
  );
});

test("outstanding: a row dated today blocks carry-forward for that task", () => {
  // REGRESSION. The client's `claimed` set means a task with ANY occurrence
  // dated today never also carries an older one. A weekly task missed last
  // Monday and ticked off today shows nothing on the checklist — so nudging
  // for it would be a phantom reminder.
  assert.deepEqual(
    outstanding({
      dueTodayTaskIds: ["t1"],
      materialisedTaskIds: new Set(["t1"]),
      todayRows: [{taskId: "t1", status: "done", scheduledDate: at("2026-07-24")}],
      pastOpenRows: [
        {taskId: "t1", status: "pending", scheduledDate: at("2026-07-20")},
      ],
    }),
    [],
  );
});

test("outstanding: an occurrence dragged to a future day is not regenerated", () => {
  // REGRESSION. buildToday dedupes step 2 by occurrence *id*, and a moved
  // occurrence keeps the id it was generated under. The client shows nothing
  // today, so neither should the nudge — even though the task recurs today and
  // has no row dated today.
  assert.deepEqual(
    outstanding({
      dueTodayTaskIds: ["t1"],
      materialisedTaskIds: new Set(["t1"]),
    }),
    [],
  );
});

test("outstanding: counts a task once however many days it slipped", () => {
  assert.deepEqual(
    outstanding({
      pastOpenRows: [
        {taskId: "t1", status: "pending", scheduledDate: at("2026-07-20")},
        {taskId: "t1", status: "pending", scheduledDate: at("2026-07-21")},
        {taskId: "t1", status: "rescheduled", scheduledDate: at("2026-07-22")},
      ],
    }),
    ["t1"],
  );
});

test("outstanding: drops orphaned and inactive tasks everywhere", () => {
  // A half-failed cascade-delete must not nudge forever, and the client filters
  // the checklist to tasks that still exist.
  assert.deepEqual(
    outstanding({
      dueTodayTaskIds: ["gone"],
      todayRows: [{taskId: "gone", status: "pending", scheduledDate: at("2026-07-24")}],
      pastOpenRows: [
        {taskId: "gone", status: "pending", scheduledDate: at("2026-07-20")},
        {taskId: "live", status: "pending", scheduledDate: at("2026-07-20")},
      ],
    }),
    ["live"],
  );
});

test("outstanding: settled rows in the past are forgiven, not carried", () => {
  assert.deepEqual(
    outstanding({
      pastOpenRows: [
        {taskId: "t1", status: "done", scheduledDate: at("2026-07-20")},
        {taskId: "t2", status: "skipped", scheduledDate: at("2026-07-20")},
      ],
    }),
    [],
  );
});

test("outstanding: tolerates malformed and wrong-typed rows", () => {
  // Defensive in the same way the Dart read paths are: one bad document must
  // not throw and take out this user's entire nudge. A Firestore Timestamp
  // where an ISO string was expected is the shape that would bite hardest —
  // `.slice` on it throws, and Timestamps sort BEFORE strings, so such a row
  // always matches the range filter.
  assert.deepEqual(
    outstanding({
      activeTaskIds: new Set(["t1", "t2", "t3", "t4", ""]),
      pastOpenRows: [
        {taskId: "t1", status: "pending"},
        {taskId: "", status: "pending", scheduledDate: at("2026-07-20")},
        {taskId: "t2", scheduledDate: at("2026-07-20")},
        {taskId: "t3", status: "pending", scheduledDate: "not-a-date"},
        {taskId: "t4", status: "pending", scheduledDate: {seconds: 1770000000}},
        {status: "pending", scheduledDate: at("2026-07-20")},
      ],
      todayRows: [{taskId: 42, status: "pending", scheduledDate: at("2026-07-24")}],
    }),
    [],
  );
});

// ── Once-per-day send claim ───────────────────────────────────────────────────
// `onSchedule` delivers at-least-once, so the same tick can run twice. The
// dispatcher claims the day atomically with `create()` before sending; these
// pin the classifier that decides "someone already claimed it" (a
// misclassification either double-sends or silently suppresses the nudge).

test("reminderClaimId: one claim per local calendar day", () => {
  assert.equal(reminderClaimId(new Date(Date.UTC(2026, 6, 24))), "2026-07-24");
  assert.notEqual(
    reminderClaimId(new Date(Date.UTC(2026, 6, 24))),
    reminderClaimId(new Date(Date.UTC(2026, 6, 25))),
  );
});

test("isAlreadyExistsError: recognises the gRPC ALREADY_EXISTS shapes", () => {
  // firebase-admin surfaces the numeric gRPC status (ALREADY_EXISTS === 6).
  assert.equal(isAlreadyExistsError(Object.assign(new Error("x"), {code: 6})), true);
  // Some layers use the string enum / hyphenated client-SDK spelling instead.
  assert.equal(
    isAlreadyExistsError(Object.assign(new Error("x"), {code: "ALREADY_EXISTS"})),
    true,
  );
  assert.equal(
    isAlreadyExistsError(Object.assign(new Error("x"), {code: "already-exists"})),
    true,
  );
  // Fallback: the status name in the message, when no structured code survives.
  assert.equal(
    isAlreadyExistsError(new Error("6 ALREADY_EXISTS: entity already exists")),
    true,
  );
});

test("isAlreadyExistsError: does NOT swallow other failures", () => {
  // A transient/permission error must propagate — treating it as "already
  // nudged" would silently drop the day's reminder.
  assert.equal(isAlreadyExistsError(Object.assign(new Error("x"), {code: 7})), false);
  assert.equal(
    isAlreadyExistsError(Object.assign(new Error("x"), {code: "PERMISSION_DENIED"})),
    false,
  );
  assert.equal(isAlreadyExistsError(new Error("UNAVAILABLE: backend down")), false);
  assert.equal(isAlreadyExistsError(undefined), false);
  assert.equal(isAlreadyExistsError(null), false);
  assert.equal(isAlreadyExistsError("ALREADY_EXISTS"), false);
});

test("claimExpiry: sets a TTL well past the day it guards", () => {
  const now = new Date(Date.UTC(2026, 6, 24, 8, 5));
  const expiry = claimExpiry(now);
  assert.ok(expiry.getTime() > now.getTime(), "expiry is in the future");
  // Must outlive the local day it protects by a comfortable margin, so a claim
  // can never be collected while its own day is still in progress anywhere.
  const daysOut = (expiry.getTime() - now.getTime()) / 86400000;
  assert.ok(daysOut >= 2, `expected >= 2 days of retention, got ${daysOut}`);
});
