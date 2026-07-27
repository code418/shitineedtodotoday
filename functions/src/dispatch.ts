/**
 * Firestore-touching side of the reminder dispatcher.
 *
 * Split out of index.ts so the actual reads/writes — the composite-index scan,
 * the today-window query, and the atomic once-per-day claim — can be exercised
 * against a real Firestore (emulator) in dispatch.integration.test.ts, not just
 * mirrored by the pure unit tests in reminder.ts. index.ts wires these into the
 * scheduled trigger; the decision logic still lives in reminder.ts.
 */

import {
  OPEN_OCCURRENCE_STATUSES,
  RecurrenceJson,
  addUtcDays,
  claimExpiry,
  dayStartBound,
  isAlreadyExistsError,
  occurrenceIdFor,
  occursOn,
  outstandingTaskIds,
  reminderClaimId,
} from "./reminder";

/** An active task as the dispatcher needs it: its id and recurrence. */
export interface ActiveTask {
  id: string;
  recurrence: RecurrenceJson;
}

/**
 * Upper bound on the overdue-occurrence scan per user. We only need to know
 * whether *any* carried-forward work survives the still-live-task filter, so a
 * bounded read keeps a long-lived account's history from driving cost. Ordered
 * oldest-first (the inequality field orders the query), and a truncated scan is
 * surfaced via [onCapHit] rather than silently treated as complete.
 */
export const OVERDUE_SCAN_LIMIT = 200;

/**
 * The task ids the client's checklist would show as outstanding for [uid] on
 * [todayLocal], read from Firestore. Combines the three sources
 * `outstandingTaskIds` models: this cycle's materialised occurrences (by id),
 * everything dated today, and open work carried forward from earlier days.
 */
export async function computeOutstanding(
  db: FirebaseFirestore.Firestore,
  uid: string,
  todayLocal: Date,
  activeTasks: ActiveTask[],
  onCapHit?: (limit: number) => void,
): Promise<Set<string>> {
  // Tasks whose recurrence actually lands on today — weekly tasks should not
  // fire every day.
  const tasksToday = activeTasks.filter((t) =>
    occursOn(t.recurrence ?? {}, todayLocal),
  );

  const occurrences = db.collection(`users/${uid}/occurrences`);
  const [cycleSnaps, todaySnap, pastSnap] = await Promise.all([
    // Has this cycle's occurrence been created at all? Looked up by
    // deterministic id (index-free GET), because the client dedupes fresh
    // materialisation by id too — an occurrence dragged to another day keeps
    // the id it was generated under and is NOT regenerated.
    Promise.all(
      tasksToday.map((t) =>
        occurrences.doc(occurrenceIdFor(t.id, todayLocal)).get(),
      ),
    ),
    // Everything dated today, whatever its status: open rows are visible work,
    // and settled ones still claim their task against carry-forward.
    occurrences
      .where("scheduledDate", ">=", dayStartBound(todayLocal))
      .where("scheduledDate", "<", dayStartBound(addUtcDays(todayLocal, 1)))
      .get(),
    // Work the user missed on an earlier day. The client carries these onto
    // today's checklist, so they are genuinely outstanding even when nothing
    // recurs today — without this, a task missed on Monday shows outstanding
    // all week but is never nudged until its next natural day.
    occurrences
      .where("status", "in", OPEN_OCCURRENCE_STATUSES)
      .where("scheduledDate", "<", dayStartBound(todayLocal))
      .limit(OVERDUE_SCAN_LIMIT)
      .get(),
  ]);

  if (pastSnap.size === OVERDUE_SCAN_LIMIT) onCapHit?.(OVERDUE_SCAN_LIMIT);

  const row = (d: FirebaseFirestore.DocumentSnapshot) => ({
    taskId: d.get("taskId"),
    status: d.get("status"),
    scheduledDate: d.get("scheduledDate"),
  });
  return outstandingTaskIds({
    todayRows: todaySnap.docs.map(row),
    pastOpenRows: pastSnap.docs.map(row),
    dueTodayTaskIds: tasksToday.map((t) => t.id),
    // Keyed off the task we asked for, not the document's own taskId field, so a
    // malformed doc still counts as "this cycle already exists".
    materialisedTaskIds: new Set(
      tasksToday.filter((_, i) => cycleSnaps[i].exists).map((t) => t.id),
    ),
    activeTaskIds: new Set(activeTasks.map((t) => t.id)),
    today: todayLocal,
  });
}

/**
 * Atomically claim [uid]'s nudge for [todayLocal]. Returns true if this call
 * won the claim (so the caller should send), false if the day was already
 * claimed by another at-least-once delivery of the same tick.
 *
 * Uses `create()` (fails if the doc exists) so the claim is atomic against a
 * concurrent duplicate rather than racing it like a read-then-write would.
 */
export async function claimDay(
  db: FirebaseFirestore.Firestore,
  uid: string,
  todayLocal: Date,
  now: Date,
): Promise<boolean> {
  const claimRef = db.doc(
    `users/${uid}/reminderLog/${reminderClaimId(todayLocal)}`,
  );
  try {
    await claimRef.create({sentAt: now, expireAt: claimExpiry(now)});
    return true;
  } catch (err) {
    if (isAlreadyExistsError(err)) return false;
    throw err;
  }
}

/**
 * Release a claim whose send reached nobody, so a retry of the tick can try
 * again. Swallows errors — a failed release is not worth failing the tick over.
 */
export async function releaseClaim(
  db: FirebaseFirestore.Firestore,
  uid: string,
  todayLocal: Date,
): Promise<void> {
  await db
    .doc(`users/${uid}/reminderLog/${reminderClaimId(todayLocal)}`)
    .delete()
    .catch(() => undefined);
}
