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
    required this.recurrenceSeasonal,
    required this.recurrenceOneOff,
    required this.chooseDate,
    required this.pickADate,
    required this.pickADay,
    required this.titleRequired,
    required this.taskAdded,
    required this.actionFailed,
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

    // Onboarding wizard
    required this.welcomeTitle,
    required this.welcomeBody,
    required this.paceStepTitle,
    required this.paceStepBody,
    required this.pickStepTitle,
    required this.pickStepBody,
    required this.onboardingNext,
    required this.onboardingBack,
    required this.getStarted,
    required this.skipForNow,
    required this.onboardingAdded,

    // Reminders / notification settings
    required this.remindersTitle,
    required this.remindersSettingsLink,
    required this.dailyNudgeTitle,
    required this.dailyNudgeSubtitle,
    required this.reminderTimeLabel,
    required this.quietHoursTitle,
    required this.quietHoursSubtitle,
    required this.nudgeInQuietHoursWarning,
    required this.quietStartLabel,
    required this.quietEndLabel,
    required this.previewHeading,
    required this.testNudge,
    required this.testNudgeSent,
    required this.nudgeBodyHasTasks,
    required this.nudgeBodyClear,

    // Household
    required this.householdTitle,
    required this.householdSettingsLink,
    required this.householdMembersHeading,
    required this.addMemberCta,
    required this.memberNameHint,
    required this.whoseTurnHeading,
    required this.unassignedLabel,
    required this.reassignTitle,
    required this.removeMember,
    required this.youLabel,
    required this.householdEmpty,

    // Account / upgrade
    required this.accountTitle,
    required this.accountSettingsLink,
    required this.guestTitle,
    required this.guestBody,
    required this.emailLabel,
    required this.passwordLabel,
    required this.upgradeCta,
    required this.continueWithGoogle,
    required this.orSeparator,
    required this.accountUpgraded,
    required this.signedInAs,
    required this.signOut,
    required this.signOutConfirmTitle,
    required this.signOutConfirmBody,
    required this.emailInUse,
    required this.weakPassword,
    required this.upgradeFailed,

    // Insights
    required this.insightsTitle,
    required this.insightsSettingsLink,
    required this.periodWeek,
    required this.periodMonth,
    required this.periodYear,
    required this.completionRateLabel,
    required this.streakLabel,
    required this.timeSpentLabel,
    required this.slipsHeading,
    required this.noSlips,
    required this.suggestionHeading,
    required this.suggestionApply,
    required this.suggestionApplied,
    required this.suggestionTail,
    required this.insightsEmpty,

    // Schedule
    required this.scheduleTitle,
    required this.scheduleSettingsLink,
    required this.scheduleDragHint,
    required this.scheduleEmptyDay,
    required this.movedToDay,
    required this.alreadyOnThatDay,
    required this.todayLabelShort,

    // Bottom nav
    required this.navToday,
    required this.navSchedule,
    required this.navInsights,
    required this.navYou,
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
  final String recurrenceSeasonal;
  final String recurrenceOneOff;

  // Date picker
  final String chooseDate;
  final String pickADate;

  // Validation / feedback
  final String pickADay;
  final String titleRequired;
  final String taskAdded;

  /// Shown when a save/sync action fails (e.g. offline write error).
  final String actionFailed;

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

  // Onboarding wizard
  final String welcomeTitle;
  final String welcomeBody;
  final String paceStepTitle;
  final String paceStepBody;
  final String pickStepTitle;
  final String pickStepBody;
  final String onboardingNext;
  final String onboardingBack;
  final String getStarted;
  final String skipForNow;
  final String onboardingAdded;

  // Reminders / notification settings
  final String remindersTitle;
  final String remindersSettingsLink;
  final String dailyNudgeTitle;
  final String dailyNudgeSubtitle;
  final String reminderTimeLabel;
  final String quietHoursTitle;
  final String quietHoursSubtitle;
  final String nudgeInQuietHoursWarning;
  final String quietStartLabel;
  final String quietEndLabel;
  final String previewHeading;
  final String testNudge;
  final String testNudgeSent;
  final String nudgeBodyHasTasks;
  final String nudgeBodyClear;

  // Household
  final String householdTitle;
  final String householdSettingsLink;
  final String householdMembersHeading;
  final String addMemberCta;
  final String memberNameHint;
  final String whoseTurnHeading;
  final String unassignedLabel;
  final String reassignTitle;
  final String removeMember;
  final String youLabel;
  final String householdEmpty;

  // Account / upgrade
  final String accountTitle;
  final String accountSettingsLink;
  final String guestTitle;
  final String guestBody;
  final String emailLabel;
  final String passwordLabel;
  final String upgradeCta;
  final String continueWithGoogle;
  final String orSeparator;
  final String accountUpgraded;
  final String signedInAs;
  final String signOut;
  final String signOutConfirmTitle;
  final String signOutConfirmBody;
  final String emailInUse;
  final String weakPassword;
  final String upgradeFailed;

  // Insights
  final String insightsTitle;
  final String insightsSettingsLink;
  final String periodWeek;
  final String periodMonth;
  final String periodYear;
  final String completionRateLabel;
  final String streakLabel;
  final String timeSpentLabel;
  final String slipsHeading;
  final String noSlips;
  final String suggestionHeading;
  final String suggestionApply;
  final String suggestionApplied;

  /// Appended after the task title to form the full suggestion sentence.
  /// E.g. "Vacuum [suggestionTail]".
  final String suggestionTail;
  final String insightsEmpty;

  // Schedule
  final String scheduleTitle;
  final String scheduleSettingsLink;
  final String scheduleDragHint;
  final String scheduleEmptyDay;
  final String movedToDay;
  final String alreadyOnThatDay;
  final String todayLabelShort;

  // Bottom nav
  final String navToday;
  final String navSchedule;
  final String navInsights;
  final String navYou;

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
    recurrenceSeasonal: 'Seasonal',
    recurrenceOneOff: 'One-off',
    chooseDate: 'Choose a date',
    pickADate: 'Pick a date first',
    pickADay: 'Pick at least one day',
    titleRequired: 'Give it a name first',
    taskAdded: 'Added to your list',
    actionFailed: "Couldn't save that — please try again.",
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
    welcomeTitle: 'Welcome to your calmer to-do list',
    welcomeBody:
        "Add what needs doing, say how often, and we'll build a manageable daily "
        'checklist — and quietly reschedule anything you miss.',
    paceStepTitle: "What's a realistic day?",
    paceStepBody:
        "We'll keep each day under this so it never piles up. You can change it any time.",
    pickStepTitle: 'Start with a ready-made routine?',
    pickStepBody:
        'A gentle weekly cleaning plan, split into themed days. Pick the days you '
        'want — or skip and add your own.',
    onboardingNext: 'Next',
    onboardingBack: 'Back',
    getStarted: 'Get started',
    skipForNow: 'Skip for now',
    onboardingAdded: 'Your list is ready',
    remindersTitle: 'Reminders',
    remindersSettingsLink: 'Reminders',
    dailyNudgeTitle: 'Daily nudge',
    dailyNudgeSubtitle: 'One gentle reminder about your list each day.',
    reminderTimeLabel: 'Remind me at',
    quietHoursTitle: 'Quiet hours',
    quietHoursSubtitle: "We won't nudge you during these hours.",
    nudgeInQuietHoursWarning:
        'Your reminder time is inside quiet hours, so it '
        "won't be sent. Pick a time outside quiet hours.",
    quietStartLabel: 'From',
    quietEndLabel: 'Until',
    previewHeading: 'Preview',
    testNudge: 'Send a test nudge',
    testNudgeSent: 'Test nudge sent',
    nudgeBodyHasTasks:
        "You've got things lined up for today — open when you're ready.",
    nudgeBodyClear: 'Nothing on today. Enjoy the breather.',
    householdTitle: 'Household',
    householdSettingsLink: 'Household',
    householdMembersHeading: 'Who pitches in',
    addMemberCta: 'Add someone',
    memberNameHint: 'Name',
    whoseTurnHeading: "Today's turns",
    unassignedLabel: 'Anyone',
    reassignTitle: 'Whose turn?',
    removeMember: 'Remove',
    youLabel: 'You',
    householdEmpty:
        'Add the people you share chores with, then hand tasks round.',
    accountTitle: 'Account',
    accountSettingsLink: 'Account',
    guestTitle: "You're a guest",
    guestBody:
        'Your list is saved to this device. Add an email to keep it safe and '
        'use it on another device — nothing is lost.',
    emailLabel: 'Email',
    passwordLabel: 'Password',
    upgradeCta: 'Save my account',
    continueWithGoogle: 'Continue with Google',
    orSeparator: 'or',
    accountUpgraded: 'Account saved — your stuff is safe now',
    signedInAs: 'Signed in as',
    signOut: 'Sign out',
    signOutConfirmTitle: 'Sign out?',
    signOutConfirmBody: "You'll need your email and password to sign back in.",
    emailInUse: 'That email is already in use',
    weakPassword: 'That password is too weak',
    upgradeFailed: "Couldn't save your account — please try again",
    insightsTitle: 'Insights',
    insightsSettingsLink: 'Insights',
    periodWeek: 'Week',
    periodMonth: 'Month',
    periodYear: 'Year',
    completionRateLabel: 'Done vs skipped',
    streakLabel: 'Day streak',
    timeSpentLabel: 'Time spent',
    slipsHeading: 'Slips most often',
    noSlips: 'Nothing slipping — nicely done.',
    suggestionHeading: 'A gentle suggestion',
    suggestionApply: 'Make it flexible',
    suggestionApplied: 'Done — it can move to a quieter day now',
    suggestionTail:
        'slips a fair bit — making it flexible lets it move to a quieter day.',
    insightsEmpty: 'Tick a few things off and your trends show up here.',
    scheduleTitle: 'Schedule',
    scheduleSettingsLink: 'Schedule',
    scheduleDragHint: 'Press and hold a task, then drag it to another day.',
    scheduleEmptyDay: 'Nothing here',
    movedToDay: 'Moved to',
    alreadyOnThatDay: 'That task is already on that day',
    todayLabelShort: 'Today',
    navToday: 'Today',
    navSchedule: 'Schedule',
    navInsights: 'Insights',
    navYou: 'You',
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
    recurrenceSeasonal: 'Seasonal',
    recurrenceOneOff: 'One-off',
    chooseDate: 'Choose a date',
    pickADate: 'Pick a date first',
    pickADay: 'Pick at least one day',
    titleRequired: 'Give it a name first',
    taskAdded: 'On the list',
    actionFailed: "Couldn't save that — give it another go.",
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
    welcomeTitle: 'Welcome to your calmer shit-list',
    welcomeBody:
        "Add your shit, say how often, and we'll build a checklist that won't do "
        'your head in — and quietly shuffle whatever you miss.',
    paceStepTitle: "What's a realistic day?",
    paceStepBody:
        "We'll keep each day under this so it never piles up. Change it whenever.",
    pickStepTitle: 'Start with a ready-made routine?',
    pickStepBody:
        'A no-nonsense weekly plan, split into themed days. Pick the days you '
        'want — or skip and add your own.',
    onboardingNext: 'Next',
    onboardingBack: 'Back',
    getStarted: 'Get started',
    skipForNow: 'Skip for now',
    onboardingAdded: "Your list's ready",
    remindersTitle: 'Reminders',
    remindersSettingsLink: 'Reminders',
    dailyNudgeTitle: 'Daily nudge',
    dailyNudgeSubtitle: 'One gentle nudge about your shit each day.',
    reminderTimeLabel: 'Nudge me at',
    quietHoursTitle: 'Quiet hours',
    quietHoursSubtitle: "We won't bother you during these hours.",
    nudgeInQuietHoursWarning:
        "Your nudge time is inside quiet hours, so it won't "
        'be sent. Pick a time outside quiet hours.',
    quietStartLabel: 'From',
    quietEndLabel: 'Until',
    previewHeading: 'Preview',
    testNudge: 'Send a test nudge',
    testNudgeSent: 'Test nudge sent',
    nudgeBodyHasTasks:
        "You've got shit lined up today — open when you're ready.",
    nudgeBodyClear: 'Sweet F.A. today. Enjoy the breather.',
    householdTitle: 'Household',
    householdSettingsLink: 'Household',
    householdMembersHeading: 'Who pitches in',
    addMemberCta: 'Add someone',
    memberNameHint: 'Name',
    whoseTurnHeading: "Today's turns",
    unassignedLabel: 'Anyone',
    reassignTitle: 'Whose turn?',
    removeMember: 'Remove',
    youLabel: 'You',
    householdEmpty:
        'Add the folk you share chores with, then hand the shit round.',
    accountTitle: 'Account',
    accountSettingsLink: 'Account',
    guestTitle: "You're a guest",
    guestBody:
        "Your shit's saved to this device. Add an email to keep it safe and "
        "use it elsewhere — nothing's lost.",
    emailLabel: 'Email',
    passwordLabel: 'Password',
    upgradeCta: 'Save my account',
    continueWithGoogle: 'Continue with Google',
    orSeparator: 'or',
    accountUpgraded: "Account saved — your shit's safe now",
    signedInAs: 'Signed in as',
    signOut: 'Sign out',
    signOutConfirmTitle: 'Sign out?',
    signOutConfirmBody: "You'll need your email and password to sign back in.",
    emailInUse: 'That email is already in use',
    weakPassword: 'That password is too weak',
    upgradeFailed: "Couldn't save your account — please try again",
    insightsTitle: 'Insights',
    insightsSettingsLink: 'Insights',
    periodWeek: 'Week',
    periodMonth: 'Month',
    periodYear: 'Year',
    completionRateLabel: 'Done vs skipped',
    streakLabel: 'Day streak',
    timeSpentLabel: 'Time spent',
    slipsHeading: 'Slips most often',
    noSlips: 'Nothing slipping — nicely done.',
    suggestionHeading: 'A gentle suggestion',
    suggestionApply: 'Make it flexible',
    suggestionApplied: 'Done — it can move to a quieter day now',
    suggestionTail:
        'slips a fair bit — make it flexible so it can shift to a quieter day.',
    insightsEmpty: 'Tick a few things off and your trends show up here.',
    scheduleTitle: 'Schedule',
    scheduleSettingsLink: 'Schedule',
    scheduleDragHint: 'Press and hold a task, then drag it to another day.',
    scheduleEmptyDay: 'Nothing here',
    movedToDay: 'Moved to',
    alreadyOnThatDay: 'That task is already on that day',
    todayLabelShort: 'Today',
    navToday: 'Today',
    navSchedule: 'Schedule',
    navInsights: 'Insights',
    navYou: 'You',
  );
}
