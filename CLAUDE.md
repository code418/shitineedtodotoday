# CLAUDE.md

Guidance for working in this repository.

## What this is

**Shit I Need To Do Today** — a Flutter + Firebase app for managing recurring
chores without getting overwhelmed. The user composes a task and sets how often
it needs doing; the app builds a manageable **daily checklist** and, when
something is missed, **neatly reschedules** it instead of letting work pile up.
Recurrence ranges from strict (every Monday) to fuzzy (once a week, every
summer).

Current state: **scaffold / P0** — the architecture, models and a forgiving
`Scheduler` seam exist; the real scheduling engine and task UI are stubbed.
See `docs/ROADMAP.md` for the phased plan.

## Stack & key decisions

- **Flutter**, Android-first (iOS / web / desktop are generated and build, but
  Android is the priority platform and CI's primary build).
- **Riverpod** (plain providers, no codegen) for state; **go_router** for nav.
- **Freezed** + **json_serializable** for immutable models (requires codegen).
- **Firebase**: anonymous-first Auth, Cloud Firestore, FCM, Analytics,
  Crashlytics, Cloud Functions — all in **europe-west2 (London)**.
- **Reminders are server-driven (FCM only)** via a scheduled Cloud Function —
  no on-device local notifications.
- `riverpod_lint` / `custom_lint` are intentionally omitted (version clash with
  current Riverpod/Freezed). Re-add when constraints align.
- Package name `snitd`; application/bundle id `io.agilepixel.snitd`; display
  name "Shit I Need To Do Today".

## Commands

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # regenerate *.freezed.dart / *.g.dart
flutter run                                                 # Android by default
flutter analyze                                             # must be clean
flutter test                                                # unit + widget
dart format .                                               # CI enforces formatting

flutter build apk --debug                                   # priority target
flutter build web --release

# Cloud Functions (Node 22)
cd functions && npm install && npm run build                # tsc -> lib/
```

**After editing any Freezed/JSON model, re-run `build_runner`** or analysis/tests
will fail on stale generated files. Generated `*.freezed.dart` / `*.g.dart`
files are committed and excluded from analysis (see `analysis_options.yaml`).

## Architecture

Feature-first, layered. The `core/` and each feature's `domain/` + `data/`
layers are deliberately **UI-agnostic and platform-agnostic** so future
surfaces (Android widgets, WearOS) can reuse them with only a thin
`presentation/` swapped in. Don't import `presentation/` or Flutter widgets from
`domain/`.

```
lib/
  main.dart                 # bootstrap: Firebase init + Crashlytics + anon sign-in,
                            #   degrades to offline mode if Firebase isn't configured
  app/                      # MaterialApp.router (app.dart), router.dart, theme.dart
  core/firebase/            # firebase_providers.dart (instances + firebaseReadyProvider),
                            #   firebase_options.dart (committed PLACEHOLDER — throws)
  features/
    auth/data/              # AuthRepository (anonymous-first) + providers
    tasks/
      domain/task.dart      # Task model
      domain/scheduling/    # THE CORE:
        recurrence.dart     #   sealed Recurrence: StrictRecurrence | FlexibleRecurrence
        task_occurrence.dart#   TaskOccurrence (+ status, actualDurationMinutes)
        scheduler.dart      #   Scheduler interface + PlaceholderScheduler
      data/                 # FirestoreTaskRepository (users/{uid}/tasks/{id})
      application/          # schedulerProvider, todayChecklistProvider
      presentation/         # today_screen.dart (placeholder checklist)
functions/src/index.ts      # scheduled reminder dispatcher (FCM) — placeholder
firestore.rules             # owner-only: a user only touches users/{their uid}/**
```

### Where to implement the next milestone (P1)
- The real engine replaces `PlaceholderScheduler` in `scheduler.dart`; every
  consumer reads it through `schedulerProvider`, so nothing else changes.
- `todayChecklistProvider` (`tasks_providers.dart`) currently passes empty
  lists — wire it to the owner's tasks + persisted occurrences.
- Firestore mapping for `Task` currently uses `toJson`/`fromJson`; `DateTime`
  fields will need Firestore `Timestamp` handling when persistence goes live.

## Conventions

- Single quotes, trailing commas, ordered imports (enforced by
  `analysis_options.yaml`). Run `dart format .` before committing.
- New `TODO`s for deferred work use `// TODO(upcoming): ...` and should point at
  the relevant roadmap phase.
- Keep Firebase reads behind the providers in `core/firebase/`; only read them
  when `firebaseReadyProvider` is true (accessing a Firebase singleton before
  `Firebase.initializeApp` throws).

## Firebase / secrets

- No project secrets in the repo. `lib/firebase_options.dart` is a committed
  placeholder that throws until `flutterfire configure` regenerates it.
- `google-services.json`, `GoogleService-Info.plist`, `.firebaserc`,
  `functions/node_modules`, `.env*` are git-ignored. Don't commit real values.
- The `google-services` Gradle plugin is intentionally **not** applied, so the
  Android build compiles without `google-services.json` (FlutterFire initialises
  from `firebase_options.dart`).
- Firestore location must be **europe-west2 (London)** — chosen once at project
  creation, permanent. Functions are already pinned to that region.

### First-time Firebase setup

Prerequisites: `npm i -g firebase-tools` and
`dart pub global activate flutterfire_cli`.

1. **Create the Firebase project** and, when creating the Firestore database,
   choose location **`europe-west2` (London)**. This is permanent — set it
   correctly up front.
2. **Generate the Flutter config** (overwrites the placeholder
   `lib/firebase_options.dart`; `firebase_options.dart.example` shows the
   shape):
   ```bash
   flutterfire configure --project=<your-firebase-project-id>
   ```
3. **Point the CLI at the project:** `cp .firebaserc.example .firebaserc` then
   set the project id.
4. In the console, **enable** Anonymous sign-in, Firestore, Cloud Messaging,
   Analytics and Crashlytics.
5. **Deploy** rules & functions:
   ```bash
   firebase deploy --only firestore:rules
   cd functions && npm install && npm run deploy
   ```

## Git workflow

The initial scaffold was committed to `main`. **Future work uses feature
branches + PRs** — don't commit straight to `main` going forward.
