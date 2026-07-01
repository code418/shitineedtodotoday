import assert from "node:assert/strict";
import test from "node:test";

import {
  defaultPrefs,
  isWithinQuietHours,
  minuteOfDay,
  minuteOfDayInZone,
  nudgeTimingAllows,
  occurrenceIdFor,
  occursOn,
  prefsFromDoc,
  shouldSendDailyNudge,
} from "./reminder";

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
