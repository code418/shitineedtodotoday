import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/push_messaging.dart';
import '../data/push_token_repository.dart';

/// Coordinates FCM device-token registration: asks for permission, stores the
/// current token for the owner, and keeps it fresh on rotation. Pure
/// orchestration over the [PushMessaging] and [PushTokenRepository] seams, so
/// it's testable without Firebase.
class PushRegistrar {
  PushRegistrar({
    required this.messaging,
    required this.tokens,
    required this.platform,
  });

  final PushMessaging messaging;
  final PushTokenRepository tokens;
  final String platform;

  StreamSubscription<String>? _subscription;

  /// The token most recently registered, tracked so a rotation can drop the
  /// previous doc and [unregister] can remove exactly this device's token.
  String? _currentToken;

  /// Request permission, store the current token (if any), and subscribe to
  /// refreshes for [ownerId].
  Future<void> registerFor(String ownerId) async {
    await messaging.requestPermission();
    final token = await messaging.getToken();
    if (token != null) {
      await tokens.register(ownerId, token: token, platform: platform);
      _currentToken = token;
    }
    await _subscription?.cancel();
    _subscription = messaging.onTokenRefresh.listen((next) async {
      // On rotation, drop the previous token doc before writing the new one —
      // otherwise stale docs pile up under the owner (keyed by token value) and
      // can misdirect pushes here after the user signs out.
      final previous = _currentToken;
      if (previous != null && previous != next) {
        await tokens.remove(ownerId, previous);
      }
      await tokens.register(ownerId, token: next, platform: platform);
      _currentToken = next;
    });
  }

  /// Detach this device from [ownerId]: stop listening for refreshes and remove
  /// the current token from that owner so the dispatcher stops pushing their
  /// reminders here. Call on sign-out, before switching owners — otherwise the
  /// signed-out account keeps this device registered and its nudges keep
  /// arriving. The FCM token itself stays valid for the next owner to claim.
  Future<void> unregister(String ownerId) async {
    await _subscription?.cancel();
    _subscription = null;
    final token = _currentToken ?? await messaging.getToken();
    if (token != null) {
      await tokens.remove(ownerId, token);
    }
    _currentToken = null;
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
  }
}

final pushRegistrarProvider = Provider<PushRegistrar>((ref) {
  final registrar = PushRegistrar(
    messaging: ref.watch(pushMessagingProvider),
    tokens: ref.watch(pushTokenRepositoryProvider),
    platform: kIsWeb ? 'web' : defaultTargetPlatform.name,
  );
  ref.onDispose(registrar.dispose);
  return registrar;
});
