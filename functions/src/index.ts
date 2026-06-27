import {initializeApp} from "firebase-admin/app";
import {getFirestore} from "firebase-admin/firestore";
import {getMessaging} from "firebase-admin/messaging";
import {logger, setGlobalOptions} from "firebase-functions/v2";
import {onSchedule} from "firebase-functions/v2/scheduler";

import {minuteOfDayInZone, prefsFromDoc, shouldSendDailyNudge} from "./reminder";

// Run all functions in London (europe-west2) — the region closest to our
// users — to keep latency and data residency tight.
setGlobalOptions({region: "europe-west2"});

initializeApp();

const TIME_ZONE = "Europe/London";
// Tolerance of 14 means the window is [nudge, nudge+14], which is narrower than
// one 15-minute tick interval — so exactly one tick can fire per nudge time
// (prevents double-sends when two consecutive ticks both fall in a wider window).
const TICK_TOLERANCE_MINUTES = 14;

/**
 * Reminder dispatcher.
 *
 * Runs every 15 minutes. For each user it reads their notification prefs, sends
 * a single gentle daily nudge at their chosen time (respecting quiet hours)
 * when they have something on their list, and pushes it to their registered FCM
 * device tokens. This server-driven push is the app's reminder mechanism — no
 * on-device local notifications.
 *
 * Push copy is always the clean register (the OS-level notification, like the
 * launcher label, stays clean regardless of the in-app profanity toggle).
 *
 * MVP "has something to do" = the user has at least one active task. A future
 * refinement can run the recurrence engine server-side to count only the items
 * that actually fall on today.
 */
export const sendDueReminders = onSchedule(
  {schedule: "every 15 minutes", timeZone: TIME_ZONE},
  async () => {
    const db = getFirestore();
    const messaging = getMessaging();
    const nowMinute = minuteOfDayInZone(new Date(), TIME_ZONE);

    const users = await db.collection("users").get();
    let pushed = 0;
    let recipients = 0;

    for (const user of users.docs) {
      const uid = user.id;

      const prefsSnap = await db.doc(`users/${uid}/meta/notifications`).get();
      const prefs = prefsFromDoc(prefsSnap.data());

      const activeTask = await db
        .collection(`users/${uid}/tasks`)
        .where("isActive", "==", true)
        .limit(1)
        .get();
      const hasOpenTasks = !activeTask.empty;

      if (
        !shouldSendDailyNudge({
          prefs,
          nowMinute,
          hasOpenTasks,
          toleranceMinutes: TICK_TOLERANCE_MINUTES,
        })
      ) {
        continue;
      }

      const tokensSnap = await db.collection(`users/${uid}/tokens`).get();
      const tokens = tokensSnap.docs
        .map((d) => (d.get("token") as string | undefined) ?? d.id)
        .filter((t): t is string => Boolean(t));
      if (tokens.length === 0) continue;

      recipients += 1;
      const result = await messaging.sendEachForMulticast({
        tokens,
        notification: {
          title: "Stuff I Need To Do Today",
          body: "You've got things lined up for today — open when you're ready.",
        },
      });
      pushed += result.successCount;

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
    }

    logger.info(
      `sendDueReminders tick — nowMinute=${nowMinute}, ` +
        `recipients=${recipients}, pushes=${pushed}`,
    );
  },
);
