# Stuff I Need To Do Today

A friendly little app for staying on top of everyday chores — without the guilt
or the overwhelm.

> The name is **SINTDT** — "Stuff I Need To Do Today" — with a knowing wink at a
> slightly more colourful original. There's an optional **profanity mode**
> (off by default) in Settings that swaps the in-app wording for something a
> little more… honest.

## The idea

Keeping on top of regular tasks is hard. Most to-do apps just pile up missed
items until the list feels impossible and you give up.

**SINTDT** works differently:

- 📝 **Add a task and say how often it needs doing** — "every Monday", "once a
  week", "every summer", whatever fits.
- ☀️ **Get a simple daily checklist** — just what actually needs doing *today*,
  not a scary backlog.
- 🤝 **Miss something? No problem.** The app is forgiving: it quietly finds a
  new time for it instead of letting things stack up.
- ⏱️ **Tell it how long things really take** — so it gets smarter about giving
  you a realistic, manageable day.

The goal is simple: make recurring tasks easier to cope with.

## Where it's heading

This repository is the **starting foundation** of the app. The groundwork is in
place; the day-to-day features are being built next. Some of what's planned:

- Creating tasks and ticking them off your daily list
- Smartly spreading work so no single day feels overwhelming
- Gentle reminders
- Categories (e.g. by room), ready-made routines, and shared household lists
- A home-screen widget and a smartwatch (WearOS) companion

See [`docs/ROADMAP.md`](docs/ROADMAP.md) for the full plan.

## For developers

This is a [Flutter](https://flutter.dev) app with a
[Firebase](https://firebase.google.com) backend, currently at an early
**scaffold** stage (a buildable skeleton — the main features are stubbed).

Quick start:

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

The app runs even before Firebase is set up (it shows an "offline" notice).
Technical details — architecture, conventions, commands and the full Firebase
setup (including the London region) — live in
[`CLAUDE.md`](CLAUDE.md).

## Platforms

Android is the primary focus for now. iOS, web and desktop builds are also
generated and the codebase is structured to grow onto more devices later.
