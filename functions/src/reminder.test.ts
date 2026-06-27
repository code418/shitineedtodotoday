import assert from "node:assert/strict";
import test from "node:test";

import {
  defaultPrefs,
  isWithinQuietHours,
  minuteOfDay,
  minuteOfDayInZone,
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
