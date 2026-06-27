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
    required this.composerNewTitle,
    required this.composerEditTitle,
    required this.composerTitleLabel,
    required this.composerTitleHint,
    required this.composerCategoryLabel,
    required this.composerCategoryHint,
    required this.composerEffortLabel,
    required this.composerRecurrenceLabel,
    required this.composerSave,
    required this.recurrenceEveryday,
    required this.recurrenceWeekdays,
    required this.recurrenceWeekly,
    required this.recurrenceMonthly,
    required this.pickADay,
    required this.titleRequired,
    required this.taskAdded,
    required this.durationPrompt,
    required this.durationSubtitle,
    required this.durationSave,
    required this.learnedQuicker,
    required this.learnedSettled,
    required this.learnedPrefix,
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

  // Task composer
  final String composerNewTitle;
  final String composerEditTitle;
  final String composerTitleLabel;
  final String composerTitleHint;
  final String composerCategoryLabel;
  final String composerCategoryHint;
  final String composerEffortLabel;
  final String composerRecurrenceLabel;
  final String composerSave;

  // Recurrence presets
  final String recurrenceEveryday;
  final String recurrenceWeekdays;
  final String recurrenceWeekly;
  final String recurrenceMonthly;

  // Validation / feedback
  final String pickADay;
  final String titleRequired;
  final String taskAdded;

  // Duration / effort logging
  final String durationPrompt;
  final String durationSubtitle;
  final String durationSave;
  final String learnedQuicker;
  final String learnedSettled;
  final String learnedPrefix;

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
    composerNewTitle: 'New task',
    composerEditTitle: 'Edit task',
    composerTitleLabel: 'What needs doing?',
    composerTitleHint: 'e.g. Wash bedding',
    composerCategoryLabel: 'Category (optional)',
    composerCategoryHint: 'e.g. Kitchen',
    composerEffortLabel: 'Roughly how long?',
    composerRecurrenceLabel: 'How often?',
    composerSave: 'Save task',
    recurrenceEveryday: 'Every day',
    recurrenceWeekdays: 'Specific days',
    recurrenceWeekly: 'Once a week',
    recurrenceMonthly: 'Once a month',
    pickADay: 'Pick at least one day',
    titleRequired: 'Give it a name first',
    taskAdded: 'Added to your list',
    durationPrompt: 'How long did it take?',
    durationSubtitle: 'A rough number is fine — it helps us plan better.',
    durationSave: 'Log it',
    learnedQuicker: 'quicker than you thought',
    learnedSettled: 'good to know',
    learnedPrefix: 'Learned: usually',
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
    composerNewTitle: 'New shit',
    composerEditTitle: 'Edit shit',
    composerTitleLabel: "What's the shit?",
    composerTitleHint: 'e.g. Wash the bloody bedding',
    composerCategoryLabel: 'Category (optional)',
    composerCategoryHint: 'e.g. Kitchen',
    composerEffortLabel: 'Roughly how long?',
    composerRecurrenceLabel: 'How often?',
    composerSave: 'Save it',
    recurrenceEveryday: 'Every day',
    recurrenceWeekdays: 'Specific days',
    recurrenceWeekly: 'Once a week',
    recurrenceMonthly: 'Once a month',
    pickADay: 'Pick at least one day',
    titleRequired: 'Give it a name first',
    taskAdded: 'On the list',
    durationPrompt: 'How long did that take?',
    durationSubtitle: "A rough number's fine — helps us plan your shit better.",
    durationSave: 'Log it',
    learnedQuicker: 'faster than you reckoned',
    learnedSettled: 'good to know',
    learnedPrefix: 'Learned: usually',
  );
}
