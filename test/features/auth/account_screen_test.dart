import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snitd/core/design/widgets/app_button.dart';
import 'package:snitd/core/strings/app_strings.dart';
import 'package:snitd/features/auth/data/auth_repository.dart';
import 'package:snitd/features/auth/domain/account_status.dart';
import 'package:snitd/features/auth/presentation/account_screen.dart';
import 'package:snitd/features/notifications/application/notification_providers.dart';
import 'package:snitd/features/notifications/application/push_registrar.dart';
import 'package:snitd/features/notifications/data/device_time_zone.dart';
import 'package:snitd/features/notifications/data/notification_prefs_repository.dart';
import 'package:snitd/features/notifications/domain/notification_prefs.dart';
import 'package:snitd/features/settings/application/settings_providers.dart';

import '../../push_registrar_test.dart'
    show FakePushMessaging, FakePushTokenRepository;

// ── Fake ─────────────────────────────────────────────────────────────────────

/// Minimal [User] stub for ensureSignedIn's return value.
class _FakeUser implements User {
  @override
  String get uid => 'anon-2';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAuthRepository implements AuthRepository {
  String? linkedEmail;
  String? linkedPassword;
  bool signedOut = false;
  bool ensureSignedInCalled = false;
  int ensureSignedInCount = 0;

  /// When set, [ensureSignedIn] blocks on this until completed — lets a test
  /// hold the sign-out chain in flight to probe the re-entrancy guard.
  Completer<void>? ensureSignedInGate;
  bool linkGoogleCalled = false;

  /// What [linkGoogle] should do: return this value, unless [googleError] is set
  /// (then throw it). `true` = linked, `false` = user cancelled.
  bool googleResult = true;
  Object? googleError;

  @override
  Stream<User?> userChanges() => const Stream.empty();

  @override
  User? get currentUser => null;

  @override
  Future<User> ensureSignedIn() async {
    ensureSignedInCalled = true;
    ensureSignedInCount++;
    if (ensureSignedInGate != null) await ensureSignedInGate!.future;
    return _FakeUser();
  }

  @override
  Future<void> signOut() async => signedOut = true;

  @override
  Future<void> linkEmailPassword({
    required String email,
    required String password,
  }) async {
    linkedEmail = email;
    linkedPassword = password;
  }

  /// Sign-in is exercised through SignInService / the sign-in screen tests;
  /// here it only needs to exist.
  @override
  Future<User> signInWithEmail({
    required String email,
    required String password,
  }) async => _FakeUser();

  @override
  Future<AuthCredential?> googleCredential() async => null;

  @override
  Future<User> signInWithCredential(AuthCredential credential) async =>
      _FakeUser();

  @override
  Future<void> sendPasswordReset(String email) async {}

  @override
  Future<bool> linkGoogle() async {
    linkGoogleCalled = true;
    if (googleError != null) throw googleError!;
    return googleResult;
  }
}

class _FakeDeviceTimeZone implements DeviceTimeZone {
  _FakeDeviceTimeZone(this._zone);
  final String? _zone;
  @override
  Future<String?> current() async => _zone;
}

/// Records time-zone merge-writes; nothing else is exercised here.
class _RecordingPrefsRepository implements NotificationPrefsRepository {
  final List<(String, String)> timeZoneWrites = [];

  @override
  Stream<NotificationPrefs> watch(String ownerId) =>
      Stream.value(NotificationPrefs.defaults);

  @override
  Future<void> save(String ownerId, NotificationPrefs prefs) async {}

  @override
  Future<void> saveTimeZone(String ownerId, String timeZone) async =>
      timeZoneWrites.add((ownerId, timeZone));
}

// ── Helpers ───────────────────────────────────────────────────────────────────

Future<ProviderScope> _buildScope({
  required WidgetTester tester,
  required _FakeAuthRepository fake,
  required AccountStatus status,
  List<Override> extraOverrides = const [],
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();

  final scope = ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      authRepositoryProvider.overrideWithValue(fake),
      accountStatusProvider.overrideWithValue(status),
      ...extraOverrides,
    ],
    child: const MaterialApp(home: AccountScreen()),
  );
  await tester.pumpWidget(scope);
  await tester.pumpAndSettle();
  return scope;
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  testWidgets(
    'entering valid credentials and tapping upgrade calls linkEmailPassword',
    (tester) async {
      final fake = _FakeAuthRepository();
      await _buildScope(
        tester: tester,
        fake: fake,
        status: const AccountStatus(signedIn: true, isAnonymous: true),
      );

      await tester.enterText(find.byType(TextField).first, 'test@example.com');
      await tester.enterText(find.byType(TextField).last, 'password123');

      await tester.tap(find.text('Save my account'));
      await tester.pumpAndSettle();

      expect(fake.linkedEmail, 'test@example.com');
    },
  );

  testWidgets('tapping Continue with Google links and confirms', (
    tester,
  ) async {
    final fake = _FakeAuthRepository()..googleResult = true;
    await _buildScope(
      tester: tester,
      fake: fake,
      status: const AccountStatus(signedIn: true, isAnonymous: true),
    );

    expect(find.text('Continue with Google'), findsOneWidget);
    await tester.tap(find.text('Continue with Google'));
    await tester.pumpAndSettle();

    expect(fake.linkGoogleCalled, isTrue);
    expect(find.text('Account saved — your stuff is safe now'), findsOneWidget);
  });

  testWidgets('cancelling the Google picker shows no confirmation', (
    tester,
  ) async {
    final fake = _FakeAuthRepository()..googleResult = false; // cancelled
    await _buildScope(
      tester: tester,
      fake: fake,
      status: const AccountStatus(signedIn: true, isAnonymous: true),
    );

    await tester.tap(find.text('Continue with Google'));
    await tester.pumpAndSettle();

    expect(fake.linkGoogleCalled, isTrue);
    expect(
      find.text('Account saved — your stuff is safe now'),
      findsNothing,
      reason: 'a cancelled sign-in must not claim success',
    );
  });

  testWidgets('a Google account already in use shows the in-use message', (
    tester,
  ) async {
    final fake = _FakeAuthRepository()
      ..googleError = FirebaseAuthException(code: 'credential-already-in-use');
    await _buildScope(
      tester: tester,
      fake: fake,
      status: const AccountStatus(signedIn: true, isAnonymous: true),
    );

    await tester.tap(find.text('Continue with Google'));
    await tester.pumpAndSettle();

    expect(find.text('That email is already in use'), findsOneWidget);
  });

  testWidgets('upgraded account shows email and sign out button', (
    tester,
  ) async {
    final fake = _FakeAuthRepository();
    await _buildScope(
      tester: tester,
      fake: fake,
      status: const AccountStatus(
        signedIn: true,
        isAnonymous: false,
        email: 'a@b.com',
      ),
    );

    expect(find.text('a@b.com'), findsOneWidget);
    expect(find.text('Sign out'), findsOneWidget);
  });

  testWidgets('sign-out warns that this device starts over empty', (
    tester,
  ) async {
    final fake = _FakeAuthRepository();
    await _buildScope(
      tester: tester,
      fake: fake,
      status: const AccountStatus(
        signedIn: true,
        isAnonymous: false,
        email: 'a@b.com',
      ),
    );

    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();

    // The old copy promised "you'll need your email and password to sign
    // back in" — there was no way to sign back in at all.
    expect(find.text(AppStrings.clean.signOutConfirmBody), findsOneWidget);
    expect(AppStrings.clean.signOutConfirmBody, contains('empty list'));
    expect(find.textContaining('email and password'), findsNothing);

    // Cancelling leaves the account alone.
    await tester.tap(find.text(AppStrings.clean.cancel));
    await tester.pumpAndSettle();
    expect(fake.signedOut, isFalse);
  });

  testWidgets('signing out re-establishes a fresh anonymous session', (
    tester,
  ) async {
    final fake = _FakeAuthRepository();
    await _buildScope(
      tester: tester,
      fake: fake,
      status: const AccountStatus(
        signedIn: true,
        isAnonymous: false,
        email: 'a@b.com',
      ),
    );

    // Tap the Sign out button, then confirm in the dialog.
    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign out').last);
    await tester.pumpAndSettle();

    expect(fake.signedOut, isTrue);
    // Anonymous-first: a new anonymous session is created so the app stays
    // usable rather than being left ownerless.
    expect(fake.ensureSignedInCalled, isTrue);
  });

  testWidgets(
    'signing out registers the fresh session for push AND its time zone',
    (tester) async {
      // The new anonymous uid starts with no prefs doc, so without a fresh
      // time-zone write the dispatcher nudges it on London time until the next
      // cold start — the same registration app start-up does must run here.
      final fake = _FakeAuthRepository();
      final tokens = FakePushTokenRepository();
      final prefs = _RecordingPrefsRepository();
      await _buildScope(
        tester: tester,
        fake: fake,
        status: const AccountStatus(
          signedIn: true,
          isAnonymous: false,
          email: 'a@b.com',
        ),
        extraOverrides: [
          pushRegistrarProvider.overrideWithValue(
            PushRegistrar(
              messaging: FakePushMessaging('tok-1'),
              tokens: tokens,
              platform: 'android',
            ),
          ),
          timeZoneRegistrarProvider.overrideWithValue(
            TimeZoneRegistrar(
              device: _FakeDeviceTimeZone('America/New_York'),
              prefs: prefs,
            ),
          ),
        ],
      );

      await tester.tap(find.text('Sign out'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sign out').last);
      await tester.pumpAndSettle();

      expect(tokens.registered.map((r) => r.owner), ['anon-2']);
      expect(prefs.timeZoneWrites, [('anon-2', 'America/New_York')]);
    },
  );

  testWidgets('sign-out is re-entrancy-guarded while the chain is in flight', (
    tester,
  ) async {
    final gate = Completer<void>();
    final fake = _FakeAuthRepository()..ensureSignedInGate = gate;
    await _buildScope(
      tester: tester,
      fake: fake,
      status: const AccountStatus(
        signedIn: true,
        isAnonymous: false,
        email: 'a@b.com',
      ),
    );

    AppButton signOutButton() =>
        tester.widget<AppButton>(find.widgetWithText(AppButton, 'Sign out'));
    expect(signOutButton().onPressed, isNotNull, reason: 'enabled at rest');

    // Tap + confirm; ensureSignedIn now blocks on the gate, holding the
    // sign-out chain in flight.
    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign out').last); // confirm
    await tester.pump();
    await tester.pump();

    // While in flight the button is disabled, so a rapid second tap can't
    // launch a concurrent sign-out.
    expect(
      signOutButton().onPressed,
      isNull,
      reason: 'sign-out must be re-entrancy-guarded while in flight',
    );

    gate.complete();
    await tester.pumpAndSettle();

    // Exactly one sign-out ran; the re-established session was created once.
    expect(fake.ensureSignedInCount, 1);
  });
}
