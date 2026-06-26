# Shit I Need To Do Today

A mobile app to make recurring daily tasks easier to cope with.

You compose a task, set **how often** it needs doing, and the app builds a
manageable **daily checklist** of what to do today. If you don't get to
something, it's forgiving and **neatly reschedules** instead of letting work
pile up. Task timing ranges from strict (every Monday) to fuzzy (once a week,
every summer).

> Status: **scaffold / P0**. This is a buildable foundation — the scheduling
> engine and task UI are stubbed. See [`docs/ROADMAP.md`](docs/ROADMAP.md).

## Stack

- **Flutter** (Android-first; iOS, web and desktop also generated)
- **Riverpod** for state management, **go_router** for navigation
- **Freezed** + **json_serializable** for immutable models
- **Firebase**: Auth (anonymous-first), Cloud Firestore, Cloud Messaging (FCM),
  Analytics, Crashlytics, and Cloud Functions — all in the
  **europe-west2 (London)** region

## Project layout

```
lib/
  main.dart                     # bootstrap: Firebase + Crashlytics + anon sign-in
  app/                          # MaterialApp, router, theme
  core/firebase/                # Firebase instance providers + placeholder options
  features/
    auth/                       # anonymous-first auth repository + providers
    tasks/
      domain/                   # Task model + the scheduling core:
        scheduling/             #   Recurrence (strict|flexible), TaskOccurrence,
                                #   Scheduler (buildToday / rescheduleMissed)
      data/                     # Firestore-backed TaskRepository
      application/              # Riverpod providers (scheduler, today's checklist)
      presentation/             # Today screen (placeholder)
functions/                      # Cloud Functions (TypeScript) — reminder dispatcher
firestore.rules                 # owner-only security rules
.github/workflows/ci.yml        # analyze, test, build apk + web, build functions
```

The `core/` and feature `domain/` + `data/` layers are kept UI-agnostic so
future surfaces (Android widgets, WearOS) can reuse them — see the roadmap.

## Prerequisites

- Flutter SDK `3.44.x` (Dart `3.12+`)
- For Cloud Functions: Node.js `22`
- A Firebase project (for anything beyond the offline UI)
- CLIs: `npm i -g firebase-tools` and
  `dart pub global activate flutterfire_cli`

## Getting started

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # generate Freezed/JSON
flutter run                                                 # runs Android by default
```

Without Firebase configured the app still runs — it boots into an
**unconfigured / offline** mode and shows a "Firebase is not configured" notice.

## Firebase setup

`lib/firebase_options.dart` is committed as a **placeholder** and throws until
you generate the real one for your own project. No project secrets are in the
repo (`google-services.json`, `GoogleService-Info.plist` and `.firebaserc` are
git-ignored).

1. **Create the project and pick the London region.** When creating the
   Firestore database, choose location **`europe-west2` (London)** — the
   closest region to our users. ⚠️ The Firestore location is permanent, so set
   it correctly up front. Cloud Functions are already pinned to `europe-west2`
   in `functions/src/index.ts`.

2. **Generate the Flutter Firebase config:**
   ```bash
   flutterfire configure --project=<your-firebase-project-id>
   ```
   This overwrites `lib/firebase_options.dart` and adds the per-platform files.
   (`firebase_options.dart.example` shows the expected shape.)

3. **Point the CLI at your project:**
   ```bash
   cp .firebaserc.example .firebaserc   # then set your project id
   ```

4. **Enable** Anonymous sign-in (Authentication), Firestore, Cloud Messaging,
   Analytics and Crashlytics in the Firebase console.

5. **Deploy rules & functions:**
   ```bash
   firebase deploy --only firestore:rules
   cd functions && npm install && npm run deploy
   ```

## Common commands

```bash
flutter analyze            # static analysis
flutter test               # unit + widget tests
dart format .              # format (CI enforces this)
flutter build apk --debug  # Android build (priority target)
flutter build web --release

# Cloud Functions
cd functions
npm install
npm run build              # tsc -> lib/
npm run serve              # build + Firebase emulator
```

## Notes

- `riverpod_lint` / `custom_lint` are intentionally omitted for now due to a
  version clash with current Riverpod/Freezed; re-add when constraints align.
- Future development uses feature branches + PRs.
