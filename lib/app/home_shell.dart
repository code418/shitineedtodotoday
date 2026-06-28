import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/design/design.dart';
import '../features/insights/presentation/insights_screen.dart';
import '../features/schedule/presentation/schedule_screen.dart';
import '../features/settings/application/settings_providers.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/tasks/presentation/today_screen.dart';

/// The root shell that hosts the four bottom-nav tabs:
/// Today · Schedule · Insights · You.
class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key, this.initialTab = 0});

  /// Which tab to open on first build (0 = Today … 3 = You). Lets deep links /
  /// notification taps to `/schedule` or `/insights` land on the right tab.
  final int initialTab;

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  late int _index = widget.initialTab.clamp(0, 3);

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(appStringsProvider);

    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [
          TodayScreen(),
          ScheduleScreen(),
          InsightsScreen(),
          SettingsScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          NavigationDestination(
            icon: Icon(AppIcons.checklist),
            label: strings.navToday,
          ),
          NavigationDestination(
            icon: Icon(AppIcons.calendar),
            label: strings.navSchedule,
          ),
          NavigationDestination(
            icon: Icon(AppIcons.insights),
            label: strings.navInsights,
          ),
          NavigationDestination(
            icon: Icon(AppIcons.person),
            label: strings.navYou,
          ),
        ],
      ),
    );
  }
}
