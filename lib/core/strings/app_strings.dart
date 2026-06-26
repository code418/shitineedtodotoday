/// User-facing app "chrome" text, in two registers.
///
/// Every string the app renders as UI furniture (titles, buttons, empty
/// states) lives here so it can be swapped wholesale by the profanity toggle
/// (see `features/settings`). Task content (e.g. the starter cleaning plan) is
/// *data*, not chrome, and is intentionally not routed through here.
///
/// Pick the active set via `appStringsProvider`; default is [AppStrings.clean].
class AppStrings {
  const AppStrings({
    required this.appTitle,
    required this.todayTitle,
    required this.addTask,
    required this.comingSoon,
    required this.emptyTitle,
    required this.emptyBody,
    required this.suggestionsHeader,
    required this.suggestionsSubtitle,
    required this.firebaseNotConfigured,
    required this.settingsTitle,
    required this.profanityTitle,
    required this.profanitySubtitle,
  });

  /// In-app title (task switcher / MaterialApp). The OS launcher label is the
  /// native, always-clean app name and is unaffected by the toggle.
  final String appTitle;
  final String todayTitle;
  final String addTask;
  final String comingSoon;
  final String emptyTitle;
  final String emptyBody;
  final String suggestionsHeader;
  final String suggestionsSubtitle;
  final String firebaseNotConfigured;
  final String settingsTitle;
  final String profanityTitle;
  final String profanitySubtitle;

  /// The default, store-safe wording.
  static const AppStrings clean = AppStrings(
    appTitle: 'Stuff I Need To Do Today',
    todayTitle: 'Today',
    addTask: 'Add task',
    comingSoon: 'Adding tasks arrives in the next milestone.',
    emptyTitle: 'Nothing on your list today',
    emptyBody:
        'Pick a few ready-made tasks to get started — or add your own. '
        "We'll build a manageable daily checklist from them.",
    suggestionsHeader: 'Suggested starters',
    suggestionsSubtitle:
        'A gentle weekly cleaning routine, split into themed days.',
    firebaseNotConfigured:
        'Firebase is not configured. Run `flutterfire configure` to enable '
        'sync and reminders.',
    settingsTitle: 'Settings',
    profanityTitle: 'Profanity mode',
    profanitySubtitle:
        'Swap the wording for something a little more… honest. Off by default.',
  );

  /// The cheeky, mildly-sweary wording — opt-in via the profanity toggle.
  static const AppStrings profane = AppStrings(
    appTitle: 'Shit I Need To Do Today',
    todayTitle: "Today's Shit",
    addTask: 'Add some shit',
    comingSoon: 'Adding shit arrives in the next milestone.',
    emptyTitle: 'Sweet F.A. to do today',
    emptyBody:
        'Pick some ready-made shit to get cracking — or add your own. '
        "We'll sort it into a checklist that won't do your head in.",
    suggestionsHeader: 'Shit to get you started',
    suggestionsSubtitle:
        'A no-nonsense weekly cleaning routine, split into themed days.',
    firebaseNotConfigured:
        "Firebase isn't set up yet. Run `flutterfire configure` to sync your "
        'shit and get reminders.',
    settingsTitle: 'Settings',
    profanityTitle: 'Profanity mode',
    profanitySubtitle:
        'Swap the wording for something a little more… honest. Off by default.',
  );
}
