import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';

/// Where the Android widget reads its snapshot (a JSON string) from.
const kWidgetSnapshotKey = 'today_snapshot';

/// The native provider class, as registered in AndroidManifest.xml.
const kTodayWidgetProvider = 'io.agilepixel.snitd.TodayWidgetProvider';

/// Seam over the `home_widget` plugin — the only file importing it — so the
/// snapshot sync, the background tick and the "add to home screen" prompt are
/// testable without platform channels. The widget is Android-only: elsewhere
/// every call is a quiet no-op.
abstract interface class HomeWidgetBridge {
  /// Stores [snapshotJson] and asks the widget to redraw from it.
  Future<void> publish(String snapshotJson);

  /// The last published snapshot, or null.
  Future<String?> read();

  /// Whether the launcher can add the widget from inside the app.
  Future<bool> canPin();

  /// Shows the launcher's "add widget" prompt.
  Future<void> requestPin();

  /// Registers the Dart entry point that handles taps on the widget.
  Future<void> registerTapHandler(FutureOr<void> Function(Uri?) handler);
}

class PluginHomeWidgetBridge implements HomeWidgetBridge {
  bool get _supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  @override
  Future<void> publish(String snapshotJson) async {
    if (!_supported) return;
    await HomeWidget.saveWidgetData<String>(kWidgetSnapshotKey, snapshotJson);
    await HomeWidget.updateWidget(qualifiedAndroidName: kTodayWidgetProvider);
  }

  @override
  Future<String?> read() async {
    if (!_supported) return null;
    return HomeWidget.getWidgetData<String>(kWidgetSnapshotKey);
  }

  @override
  Future<bool> canPin() async {
    if (!_supported) return false;
    return await HomeWidget.isRequestPinWidgetSupported() ?? false;
  }

  @override
  Future<void> requestPin() async {
    if (!_supported) return;
    await HomeWidget.requestPinWidget(
      qualifiedAndroidName: kTodayWidgetProvider,
    );
  }

  @override
  Future<void> registerTapHandler(FutureOr<void> Function(Uri?) handler) async {
    if (!_supported) return;
    await HomeWidget.registerInteractivityCallback(handler);
  }
}

final homeWidgetBridgeProvider = Provider<HomeWidgetBridge>(
  (ref) => PluginHomeWidgetBridge(),
);

/// Whether this device's launcher can add the widget from inside the app.
final widgetPinSupportedProvider = FutureProvider<bool>(
  (ref) => ref.watch(homeWidgetBridgeProvider).canPin(),
);
