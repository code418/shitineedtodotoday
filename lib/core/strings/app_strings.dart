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

    // Task detail / delete
    required this.deleteTaskTitle,
    required this.deleteTaskBody,
    required this.deleteConfirm,
    required this.cancel,
    required this.effortHeading,
    required this.historyHeading,
    required this.noEffortYet,
    required this.noHistoryYet,
    required this.notToday,
    required this.skippedLabel,
    required this.movedLabel,
    required this.taskSkipped,
    required this.taskUpdated,
    required this.taskDeleted,
    required this.estimateLabel,

    // Energy budget / overwhelm reset
    required this.todaysLoad,
    required this.dailyPaceTitle,
    required this.dailyPaceSubtitle,
    required this.overBudgetTitle,
    required this.spreadAction,
    required this.spreadDone,
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

  // Task detail / delete
  final String deleteTaskTitle;
  final String deleteTaskBody;
  final String deleteConfirm;
  final String cancel;
  final String effortHeading;
  final String historyHeading;
  final String noEffortYet;
  final String noHistoryYet;
  final String notToday;
  final String skippedLabel;
  final String movedLabel;
  final String taskSkipped;
  final String taskUpdated;
  final String taskDeleted;
  final String estimateLabel;

  // Energy budget / overwhelm reset
  final String todaysLoad;
  final String dailyPaceTitle;
  final String dailyPaceSubtitle;
  final String overBudgetTitle;
  final String spreadAction;
  final String spreadDone;

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
    deleteTaskTitle: 'Delete this task?',
    deleteTaskBody:
        'This removes the task and its history. It cannot be undone.',
    deleteConfirm: 'Delete',
    cancel: 'Cancel',
    effortHeading: 'Effort',
    historyHeading: 'History',
    noEffortYet:
        'Tick it off a few times and your effort history shows up here.',
    noHistoryYet: 'Nothing logged yet.',
    notToday: 'Not today',
    skippedLabel: 'skipped',
    movedLabel: 'moved',
    taskSkipped: 'Moved off today — no problem.',
    taskUpdated: 'Saved',
    taskDeleted: 'Removed',
    estimateLabel: 'Estimate',
    todaysLoad: "Today's load",
    dailyPaceTitle: 'Daily pace',
    dailyPaceSubtitle:
        'Roughly how much you can take on in a day. We keep each day under this.',
    overBudgetTitle: "Today's looking full — want to spread it out?",
    spreadAction: 'Spread it out',
    spreadDone: 'Spread across the days ahead',
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
    deleteTaskTitle: 'Bin this shit?',
    deleteTaskBody: 'This bins the task and its history. No takebacks.',
    deleteConfirm: 'Bin it',
    cancel: 'Cancel',
    effortHeading: 'Effort',
    historyHeading: 'History',
    noEffortYet:
        'Tick it off a few times and your effort history shows up here.',
    noHistoryYet: 'Nothing logged yet.',
    notToday: 'Not today',
    skippedLabel: 'skipped',
    movedLabel: 'moved',
    taskSkipped: "Off today's list — no problem.",
    taskUpdated: 'Saved',
    taskDeleted: 'Binned',
    estimateLabel: 'Estimate',
    todaysLoad: "Today's load",
    dailyPaceTitle: 'Daily pace',
    dailyPaceSubtitle:
        'How much you can be arsed with in a day. We keep each day under this.',
    overBudgetTitle: "Today's a lot — want to spread it out?",
    spreadAction: 'Spread it out',
    spreadDone: 'Spread across the days ahead',
  );
}
