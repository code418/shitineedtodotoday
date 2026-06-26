# Roadmap

**Stuff I Need To Do Today** (SINTDT) helps people stay on top of recurring chores
*without* getting overwhelmed. You add a task, say how often it needs doing,
and the app builds a manageable **daily checklist**. Miss something? It forgives
you and neatly reschedules instead of letting work pile up.

Everything below builds on the two foundations laid in the scaffold:

- the **recurrence model** — strict (every Monday) through fuzzy (once a week,
  every summer); see `lib/features/tasks/domain/scheduling/recurrence.dart`
- the **forgiving `Scheduler`** seam — `buildToday` / `rescheduleMissed`; see
  `lib/features/tasks/domain/scheduling/scheduler.dart`

## Phases

### P0 — Scaffold ✅ (this commit)
Buildable Flutter app (Android-first; iOS/web/desktop ride along), Riverpod,
anonymous-first auth, Firebase wired (Firestore, FCM, Analytics, Crashlytics,
Cloud Functions in **europe-west2 / London**), domain models, the `Scheduler`
seam, CI, and docs.

### P1 — MVP
- Task CRUD (compose a task, set its recurrence, effort estimate, category).
- Real `Scheduler.buildToday`: materialise occurrences from strict + flexible
  recurrences.
- The daily checklist: complete / skip, with **record-how-long-it-took** on
  completion.
- Basic forgiving reschedule for missed items.
- Persist tasks + occurrences to Firestore, scoped to the anonymous user.

### P2 — The forgiving scheduler, properly
- **Smart load balancing** — per-task effort weight + a daily "energy budget"
  so no single day is overwhelming.
- **Effort learning** — refine each task's `estimatedEffortMinutes` from the
  recorded actuals.
- **Forgiving controls** — "not today" / snooze, and an overwhelm **reset**
  ("declare bankruptcy") that reschedules everything cleanly.
- **Categories / rooms / zones** and a first-run onboarding wizard built on the
  **starter templates** — a curated weekly cleaning plan (themed days + time
  estimates) transcribed from the planner PDF already ships in
  `lib/features/tasks/data/starter_tasks.dart` and is offered on the empty
  Today screen; P1/P2 wires "tap to add" into real task creation.
- **Seasonal & one-off tasks** ("every summer", annual deep-clean).

### P3 — Reminders
- Server-driven **FCM push** reminders via the scheduled Cloud Function
  (`functions/src/index.ts`), targeting stored device tokens.
- Notification preferences: quiet hours, per-task reminder times.

### P4 — Accounts & sharing
- Upgrade the anonymous account to Google / Apple / email (link, don't lose
  data).
- Offline-first persistence and multi-device sync.
- **Shared households** — assign and share tasks across members.

### P5 — Insight & intelligence
- Completion trends; surface which tasks slip most (Analytics-driven).
- **Adaptive scheduling** — learn *when* tasks actually get done and suggest
  better slots.
- Calendar / agenda view with drag-to-reschedule.

### P6 — Multi-surface & accessibility
The `core/` and feature `domain/` + `data/` layers are deliberately
UI-agnostic so new surfaces reuse them with only a thin `presentation/` layer.
When the second surface lands, extract `core` + `domain` into a shared package
(melos workspace).

- **Android home-screen widgets** — a glanceable "today" checklist widget with
  tap-to-complete, straight from the home screen (no app launch needed).
- **WearOS** companion — quick-glance checklist, tap-to-complete, log-duration.
- Wear tiles / complications and (later) iOS widgets.
- **Accessibility** — a low-friction "focus" mode (one task at a time), large
  tap targets, and full screen-reader support.

## Notes
- **Region:** all Firebase compute/data should sit in **europe-west2 (London)**.
  Functions already pin this; pick the matching Firestore location at project
  creation (it can't be changed later) — see the README.
- **Lint plugins:** `riverpod_lint` / `custom_lint` were left out of the
  scaffold due to a version clash with the current Riverpod/Freezed releases.
  Re-add them once their constraints catch up.
