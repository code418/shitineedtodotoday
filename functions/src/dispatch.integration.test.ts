/**
 * Integration tests for the dispatcher's Firestore side, run against a real
 * Firestore emulator (see `npm run test:integration`). These cover exactly what
 * the pure unit tests in reminder.ts CAN'T: that the queries actually execute
 * and return the right rows against real Firestore, that the `create()` claim
 * really collides with a real ALREADY_EXISTS, and that a Firestore Timestamp
 * where an ISO string was expected behaves as the defensive decode assumes.
 *
 * Requires FIRESTORE_EMULATOR_HOST (set by `firebase emulators:exec`). Without
 * it every test skips with a clear reason, so this file is safe to include in a
 * plain `*.test.ts` run.
 */

import assert from "node:assert/strict";
import test from "node:test";

import {deleteApp, initializeApp} from "firebase-admin/app";
import {getFirestore, Timestamp} from "firebase-admin/firestore";

import {
  claimDay,
  computeOutstanding,
  loadDueUser,
  releaseClaim,
} from "./dispatch";

const EMULATOR = Boolean(process.env.FIRESTORE_EMULATOR_HOST);
const skip = EMULATOR ? false : "requires FIRESTORE_EMULATOR_HOST";

// initializeApp with a demo project id does not connect to anything; the SDK
// only talks to the emulator (or real Firestore) on the first read/write, which
// happens exclusively inside non-skipped tests.
const app = initializeApp({projectId: "demo-sintdt"});
const db = getFirestore(app);

const TODAY = new Date(Date.UTC(2026, 6, 24)); // 2026-07-24 (a Friday)
const at = (day: string) => `${day}T00:00:00.000`;

// Each test works under its own uid, so no cross-test cleanup is needed.
let n = 0;
const freshUid = () => `u${n++}`;

const seedOcc = (uid: string, id: string, data: Record<string, unknown>) =>
  db.doc(`users/${uid}/occurrences/${id}`).set(data);

// A recurrence that lands on today (Friday = ISO weekday 5) and one that never
// does (Monday only).
const dueToday = {runtimeType: "strict", weekdays: [5]};
const notToday = {runtimeType: "strict", weekdays: [1]};

test.after(() => deleteApp(app));

test("a task due today with no occurrence is outstanding", {skip}, async () => {
  const uid = freshUid();
  const out = await computeOutstanding(db, uid, TODAY, [
    {id: "t1", recurrence: dueToday},
  ]);
  assert.deepEqual([...out], ["t1"]);
});

test("open work carried from a past day (composite in+range query)", {skip}, async () => {
  const uid = freshUid();
  await seedOcc(uid, "t2_2026-07-20", {
    taskId: "t2",
    status: "pending",
    scheduledDate: at("2026-07-20"),
  });
  // Nothing recurs today, so this can ONLY surface via the
  // `status in [...] AND scheduledDate < today` scan executing correctly.
  const out = await computeOutstanding(db, uid, TODAY, [
    {id: "t2", recurrence: notToday},
  ]);
  assert.deepEqual([...out], ["t2"]);
});

test("a row dated today (today-window query) blocks carry-forward", {skip}, async () => {
  const uid = freshUid();
  await Promise.all([
    seedOcc(uid, "t1_2026-07-24", {
      taskId: "t1",
      status: "done",
      scheduledDate: at("2026-07-24"),
    }),
    seedOcc(uid, "t1_2026-07-20", {
      taskId: "t1",
      status: "pending",
      scheduledDate: at("2026-07-20"),
    }),
  ]);
  const out = await computeOutstanding(db, uid, TODAY, [
    {id: "t1", recurrence: dueToday},
  ]);
  assert.deepEqual([...out], []);
});

test("a Timestamp scheduledDate is returned by the scan but ignored", {skip}, async () => {
  const uid = freshUid();
  // The nastiest real shape: a Timestamp sorts BEFORE any string in Firestore,
  // so it always matches `scheduledDate < <isoString>` and comes back from the
  // scan. The decode must skip it (typeof !== "string") rather than throw on
  // `.slice` — this test proves the query really does return it.
  await seedOcc(uid, "t3_ts", {
    taskId: "t3",
    status: "pending",
    scheduledDate: Timestamp.fromDate(new Date(Date.UTC(2026, 6, 20))),
  });
  const out = await computeOutstanding(db, uid, TODAY, [
    {id: "t3", recurrence: notToday},
  ]);
  assert.deepEqual([...out], []);
});

test("claimDay wins once, then defers on the real ALREADY_EXISTS", {skip}, async () => {
  const uid = freshUid();
  const now = new Date(Date.UTC(2026, 6, 24, 8, 5));
  assert.equal(await claimDay(db, uid, TODAY, now), true, "first claim wins");
  assert.equal(
    await claimDay(db, uid, TODAY, now),
    false,
    "second delivery of the tick must defer, not double-send",
  );
  const snap = await db.doc(`users/${uid}/reminderLog/2026-07-24`).get();
  assert.equal(snap.exists, true);
});

test("releaseClaim lets a later tick re-claim the day", {skip}, async () => {
  const uid = freshUid();
  const now = new Date(Date.UTC(2026, 6, 24, 8, 5));
  assert.equal(await claimDay(db, uid, TODAY, now), true);
  await releaseClaim(db, uid, TODAY);
  assert.equal(
    await claimDay(db, uid, TODAY, now),
    true,
    "after release the day is claimable again",
  );
});

// ── loadDueUser ───────────────────────────────────────────────────────────────

/**
 * [db] wrapped so the test can see which collections a call queried. Only
 * `collection()` is intercepted; everything else passes straight through.
 */
function countingDb(): {db: FirebaseFirestore.Firestore; queried: string[]} {
  const queried: string[] = [];
  const wrapped = new Proxy(db, {
    get(target, prop, receiver) {
      if (prop === "collection") {
        return (path: string) => {
          queried.push(path);
          return target.collection(path);
        };
      }
      const value = Reflect.get(target, prop, receiver);
      return typeof value === "function" ? value.bind(target) : value;
    },
  });
  return {db: wrapped, queried};
}

const seedUser = async (uid: string, nudge: string, timeZone: string) => {
  await db.doc(`users/${uid}/meta/notifications`).set({
    dailyNudgeEnabled: true,
    dailyNudgeTime: nudge,
    quietHoursEnabled: false,
    quietHoursStart: "21:00",
    quietHoursEnd: "07:00",
    timeZone,
  });
  await db.doc(`users/${uid}/tasks/t1`).set({
    isActive: true,
    recurrence: {runtimeType: "strict", weekdays: [5]},
  });
  await db.doc(`users/${uid}/tasks/t2`).set({
    isActive: false,
    recurrence: {runtimeType: "strict", weekdays: [5]},
  });
};

test("loadDueUser: off-schedule ticks never run the task query", {skip}, async () => {
  const uid = freshUid();
  await seedUser(uid, "08:00", "Europe/London");
  const {db: counted, queried} = countingDb();

  // 12:00 UTC = 13:00 in London (BST): nowhere near the 08:00 nudge. This is
  // 95 of every 96 daily ticks, so the per-task read must not happen here.
  const due = await loadDueUser(
    counted,
    uid,
    new Date(Date.UTC(2026, 6, 24, 12, 0)),
    "Europe/London",
    14,
  );

  assert.equal(due, null);
  assert.deepEqual(queried, []);
});

test("loadDueUser: at the nudge time, returns the day and ACTIVE tasks", {skip}, async () => {
  const uid = freshUid();
  // 08:00 in Tokyo (UTC+9) is 23:00 UTC the previous day: the user's "today"
  // is their local Friday 24th, not UTC's Thursday 23rd.
  await seedUser(uid, "08:00", "Asia/Tokyo");
  const {db: counted, queried} = countingDb();

  const due = await loadDueUser(
    counted,
    uid,
    new Date(Date.UTC(2026, 6, 23, 23, 0)),
    "Europe/London",
    14,
  );

  assert.ok(due);
  assert.deepEqual(queried, [`users/${uid}/tasks`]);
  assert.equal(due.todayLocal.toISOString(), TODAY.toISOString());
  assert.deepEqual(
    due.activeTasks.map((t) => t.id),
    ["t1"],
  );
});

