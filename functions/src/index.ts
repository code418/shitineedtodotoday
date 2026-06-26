import {initializeApp} from "firebase-admin/app";
import {logger, setGlobalOptions} from "firebase-functions/v2";
import {onSchedule} from "firebase-functions/v2/scheduler";

// Run all functions in London (europe-west2) — the region closest to our
// users — to keep latency and data residency tight.
setGlobalOptions({region: "europe-west2"});

initializeApp();

/**
 * Reminder dispatcher (skeleton).
 *
 * Runs periodically, finds task occurrences that are due, and pushes an FCM
 * message to each owner's registered device tokens. This server-driven push is
 * the app's reminder mechanism (no on-device local notifications for now).
 *
 * TODO(upcoming): implement the real query + FCM payload once the scheduling
 * engine and per-user token storage land — see docs/ROADMAP.md (P3). Wired up
 * now so the region, schedule and deploy pipeline exist from day one.
 */
export const sendDueReminders = onSchedule(
  {schedule: "every 15 minutes", timeZone: "Europe/London"},
  async () => {
    logger.info(
      "sendDueReminders tick — placeholder, no reminders dispatched yet.",
    );
  },
);
