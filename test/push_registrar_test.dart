import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:snitd/features/notifications/application/push_registrar.dart';
import 'package:snitd/features/notifications/data/push_messaging.dart';
import 'package:snitd/features/notifications/data/push_token_repository.dart';

class FakePushMessaging implements PushMessaging {
  FakePushMessaging(this.token);
  final String? token;
  bool permissionRequested = false;
  final _refresh = StreamController<String>.broadcast();

  @override
  Future<void> requestPermission() async => permissionRequested = true;

  @override
  Future<String?> getToken() async => token;

  @override
  Stream<String> get onTokenRefresh => _refresh.stream;

  void emitRefresh(String next) => _refresh.add(next);
}

class FakePushTokenRepository implements PushTokenRepository {
  final List<({String owner, String token, String platform})> registered = [];
  final List<({String owner, String token})> removed = [];

  @override
  Future<void> register(
    String ownerId, {
    required String token,
    required String platform,
  }) async =>
      registered.add((owner: ownerId, token: token, platform: platform));

  @override
  Future<void> remove(String ownerId, String token) async =>
      removed.add((owner: ownerId, token: token));
}

void main() {
  test('registers the current token and asks for permission', () async {
    final messaging = FakePushMessaging('tok-1');
    final repo = FakePushTokenRepository();
    final registrar = PushRegistrar(
      messaging: messaging,
      tokens: repo,
      platform: 'android',
    );

    await registrar.registerFor('u1');

    expect(messaging.permissionRequested, isTrue);
    expect(repo.registered, hasLength(1));
    expect(repo.registered.single.owner, 'u1');
    expect(repo.registered.single.token, 'tok-1');
    expect(repo.registered.single.platform, 'android');
    await registrar.dispose();
  });

  test('skips registration when no token is available', () async {
    final messaging = FakePushMessaging(null);
    final repo = FakePushTokenRepository();
    final registrar = PushRegistrar(
      messaging: messaging,
      tokens: repo,
      platform: 'android',
    );

    await registrar.registerFor('u1');

    expect(messaging.permissionRequested, isTrue);
    expect(repo.registered, isEmpty);
    await registrar.dispose();
  });

  test('re-registers when the token refreshes', () async {
    final messaging = FakePushMessaging('tok-1');
    final repo = FakePushTokenRepository();
    final registrar = PushRegistrar(
      messaging: messaging,
      tokens: repo,
      platform: 'ios',
    );

    await registrar.registerFor('u1');
    messaging.emitRefresh('tok-2');
    await Future<void>.delayed(Duration.zero);

    expect(repo.registered.map((r) => r.token), ['tok-1', 'tok-2']);
    expect(repo.registered.last.platform, 'ios');
    await registrar.dispose();
  });
}
