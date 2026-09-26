import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../settings/application/settings_providers.dart';
import '../../tasks/application/tasks_providers.dart';
import '../data/home_widget_bridge.dart';
import '../domain/widget_snapshot.dart';

/// Keeps the home-screen widget in step with Today: whenever the checklist,
/// its tasks or the string set change, the widget gets a fresh snapshot.
/// Listened to from the app root so it runs for the app's whole life.
final widgetSyncProvider = Provider<void>((ref) {
  final ownerId = ref.watch(currentOwnerIdProvider);
  // Wait for real data: the checklist reads as empty while its streams load,
  // and publishing that would flash "nothing today" on the home screen.
  final loaded =
      ref.watch(tasksProvider).hasValue &&
      ref.watch(occurrencesProvider).hasValue;
  if (ownerId == null || !loaded) return;

  final snapshot = buildWidgetSnapshot(
    checklist: ref.watch(todayChecklistProvider),
    tasks: ref.watch(tasksProvider).value!,
    today: ref.watch(clockProvider)(),
    ownerId: ownerId,
    strings: ref.watch(appStringsProvider),
  );
  ref.read(_widgetPublisherProvider).publish(jsonEncode(snapshot.toJson()));
});

/// Publishes snapshots, skipping repeats (the checklist recomputes far more
/// often than it actually changes).
class _WidgetPublisher {
  _WidgetPublisher(this._bridge);

  final HomeWidgetBridge _bridge;
  String? _last;

  void publish(String json) {
    if (json == _last) return;
    _last = json;
    unawaited(
      _bridge.publish(json).catchError((Object error) {
        _last = null; // let the next change retry
        debugPrint('Home widget update failed: $error');
      }),
    );
  }
}

final _widgetPublisherProvider = Provider<_WidgetPublisher>(
  (ref) => _WidgetPublisher(ref.watch(homeWidgetBridgeProvider)),
);
