import {initializeApp} from "firebase-admin/app";
import {getFirestore} from "firebase-admin/firestore";
import {getMessaging} from "firebase-admin/messaging";
import {logger, setGlobalOptions} from "firebase-functions/v2";
import {onSchedule} from "firebase-functions/v2/scheduler";

import {
  RecurrenceJson,
  localDateOnly,
  minuteOfDayInZone,
  occursOn,
  prefsFromDoc,
  shouldSendDailyNudge,
} from "./reminder";

// Run all functions in London (europe-west2) — the region closest to our
// users — to keep latency and data residency tight.
setGlobalOptions({region: "europe-west2"});

initializeApp();

const TIME_ZONE = "Europe/London";
// Tolerance of 14 means the window is [nudge, nudge+14], which is narrower than
// one 15-minute tick interval — so exactly one tick can fire per nudge time
// (prevents double-sends when two consecutive ticks both fall in a wider window).
const TICK_TOLERANCE_MINUTES = 14;

// Users processed concurrently per chunk — large enough to be fast, small
// enough to stay well within Cloud Functions memory and Firestore quota limits.
const CHUNK = 25;

/**
 * Reminder dispatcher.
 *
 * Runs every 15 minutes. For each user it reads their notification prefs and
 * active tasks in parallel, sends a single gentle daily nudge at their chosen
 * time (respecting quiet hours) when at least one task actually falls on today
 * (recurrence-aware), and pushes it to their registered FCM device tokens.
 * This server-driven push is the app's reminder mechanism — no on-device local
 * notifications.
 *
 * Push copy is always the clean register (the OS-level notification, like the
 * launcher label, stays clean regardless of the in-app profanity toggle).
 *
 * Users are processed in parallel chunks to avoid serial timeout at scale.
 */
export const sendDueReminders = onSchedule(
  {schedule: "every 15 minutes", timeZone: TIME_ZONE},
  async () => {
    const db = getFirestore();
    const messaging = getMessaging();
    const now = new Date();
    const nowMinute = minuteOfDayInZone(now, TIME_ZONE);
    // Today's LOCAL calendar day as a date-only UTC Date (DST-safe).
    const todayLocal = localDateOnly(now, TIME_ZONE);

    const users = await db.collection("users").get();
    let pushed = 0;
    let recipients = 0;

    /**
     * Process a single user: read prefs + active tasks in parallel, evaluate
     * recurrence to decide if there's genuinely something to do today, send a
     * push if the nudge should fire, and prune any stale tokens.
     */
    async function processUser(
      uid: string,
    ): Promise<{recipients: number; pushed: number}> {
      const [prefsSnap, tasksSnap] = await Promise.all([
        db.doc(`users/${uid}/meta/notifications`).get(),
        db
          .collection(`users/${uid}/tasks`)
          .where("isActive", "==", true)
          .get(),
      ]);

      const prefs = prefsFromDoc(prefsSnap.data());
      // Only nudge when a task's recurrence actually falls on today — weekly
      // tasks should not fire every day.
      // Note: a further refinement could exclude tasks already done/skipped
      // today; out of scope here.
      const hasOpenTasks = tasksSnap.docs.some((t) =>
        occursOn((t.get("recurrence") ?? {}) as RecurrenceJson, todayLocal),
      );

      if (
        !shouldSendDailyNudge({
          prefs,
          nowMinute,
          hasOpenTasks,
          toleranceMinutes: TICK_TOLERANCE_MINUTES,
        })
      ) {
        return {recipients: 0, pushed: 0};
      }

      const tokensSnap = await db.collection(`users/${uid}/tokens`).get();
      const tokens = tokensSnap.docs
        .map((d) => (d.get("token") as string | undefined) ?? d.id)
        .filter((t): t is string => Boolean(t));
      if (tokens.length === 0) return {recipients: 0, pushed: 0};

      const result = await messaging.sendEachForMulticast({
        tokens,
        notification: {
          title: "Stuff I Need To Do Today",
          body: "You've got things lined up for today — open when you're ready.",
        },
      });

      // Prune tokens the device no longer accepts so we don't keep retrying.
      const stale: string[] = [];
      result.responses.forEach((r, i) => {
        const code = r.error?.code ?? "";
        if (
          !r.success &&
          (code.includes("registration-token-not-registered") ||
            code.includes("invalid-argument"))
        ) {
          stale.push(tokens[i]);
        }
      });
      await Promise.all(
        stale.map((t) =>
          db.doc(`users/${uid}/tokens/${t}`).delete().catch(() => undefined),
        ),
      );

      return {recipients: 1, pushed: result.successCount};
    }

    // Process users in bounded-concurrency chunks to avoid timeout at scale.
    for (let i = 0; i < users.docs.length; i += CHUNK) {
      const slice = users.docs.slice(i, i + CHUNK);
      const results = await Promise.all(slice.map((d) => processUser(d.id)));
      for (const r of results) {
        recipients += r.recipients;
        pushed += r.pushed;
      }
    }

    logger.info(
      `sendDueReminders tick — nowMinute=${nowMinute}, ` +
        `recipients=${recipients}, pushes=${pushed}`,
    );
  },
);
