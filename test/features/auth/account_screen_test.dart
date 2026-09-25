import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snitd/app/router.dart';
import 'package:snitd/core/design/widgets/app_button.dart';
import 'package:snitd/core/firebase/firebase_providers.dart';
import 'package:snitd/core/strings/app_strings.dart';
import 'package:snitd/features/auth/application/sign_in_service.dart';
import 'package:snitd/features/auth/data/auth_repository.dart';
import 'package:snitd/features/auth/domain/account_status.dart';
import 'package:snitd/features/auth/presentation/account_screen.dart';
import 'package:snitd/features/auth/presentation/sign_in_screen.dart';
import 'package:snitd/features/notifications/application/notification_providers.dart';
import 'package:snitd/features/notifications/application/push_registrar.dart';
import 'package:snitd/features/notifications/data/device_time_zone.dart';
import 'package:snitd/features/notifications/data/notification_prefs_repository.dart';
import 'package:snitd/features/notifications/domain/notification_prefs.dart';
import 'package:snitd/features/settings/application/settings_providers.dart';
import 'package:snitd/features/tasks/application/tasks_providers.dart';

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
    if (linkError != null) throw linkError!;
    linkedEmail = email;
    linkedPassword = password;
  }

  /// When set, [linkEmailPassword] throws it (e.g. email-already-in-use).
  Object? linkError;

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

  testWidgets('a guest is offered "Already have an account? Sign in"', (
    tester,
  ) async {
    await _buildScope(
      tester: tester,
      fake: _FakeAuthRepository(),
      status: const AccountStatus(signedIn: true, isAnonymous: true),
      extraOverrides: [firebaseReadyProvider.overrideWithValue(true)],
    );
    expect(find.text(AppStrings.clean.haveAccountSignIn), findsOneWidget);
  });

  testWidgets('without Firebase there is no sign-in link', (tester) async {
    await _buildScope(
      tester: tester,
      fake: _FakeAuthRepository(),
      status: const AccountStatus(signedIn: true, isAnonymous: true),
    );
    expect(find.text(AppStrings.clean.haveAccountSignIn), findsNothing);
  });

  testWidgets('offline, sign-out still completes instead of spinning', (
    tester,
  ) async {
    // Detaching the push token is a Firestore delete, which only completes
    // once the server acknowledges it — offline, never.
    final fake = _FakeAuthRepository();
    await _buildScope(
      tester: tester,
      fake: fake,
      status: const AccountStatus(
        signedIn: true,
        isAnonymous: false,
        email: 'a@b.com',
      ),
      extraOverrides: [
        currentOwnerIdProvider.overrideWithValue('u1'),
        pushRegistrarProvider.overrideWithValue(
          PushRegistrar(
            messaging: FakePushMessaging('tok'),
            tokens: _HangingTokens(),
            platform: 'android',
          ),
        ),
      ],
    );

    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign out').last);
    await tester.pump();
    expect(fake.signedOut, isFalse, reason: 'still waiting on the delete');

    await tester.pump(SignInService.detachTimeout);
    await tester.pumpAndSettle();
    expect(fake.signedOut, isTrue);
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
    // back in" when there was no way back in; now it says where to find it.
    expect(find.text(AppStrings.clean.signOutConfirmBody), findsOneWidget);
    expect(AppStrings.clean.signOutConfirmBody, contains('empty list'));
    expect(AppStrings.clean.signOutConfirmBody, contains('sign back in'));
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

  group('an upgrade that finds the account already exists', () {
    /// The Account screen inside a router, so "sign in instead" can navigate.
    Future<void> pumpRouted(
      WidgetTester tester,
      _FakeAuthRepository fake, {
      SignInService? signIn,
    }) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final router = GoRouter(
        initialLocation: Routes.account,
        routes: [
          GoRoute(
            path: Routes.today,
            builder: (_, _) => const Scaffold(body: Text('TODAY')),
          ),
          GoRoute(
            path: Routes.account,
            builder: (_, _) => const AccountScreen(),
          ),
          GoRoute(
            path: Routes.signIn,
            builder: (_, state) =>
                SignInScreen(initialEmail: state.uri.queryParameters['email']),
          ),
        ],
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            authRepositoryProvider.overrideWithValue(fake),
            accountStatusProvider.overrideWithValue(
              const AccountStatus(signedIn: true, isAnonymous: true),
            ),
            if (signIn != null) signInServiceProvider.overrideWithValue(signIn),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('email in use offers sign-in with the address carried over', (
      tester,
    ) async {
      final fake = _FakeAuthRepository()
        ..linkError = FirebaseAuthException(code: 'email-already-in-use');
      await pumpRouted(tester, fake);

      await tester.enterText(find.byType(TextField).first, 'me@home.com');
      await tester.enterText(find.byType(TextField).last, 'password123');
      await tester.tap(find.text('Save my account'));
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.clean.emailInUse), findsOneWidget);

      await tester.tap(find.text(AppStrings.clean.signInInstead));
      await tester.pumpAndSettle();

      expect(find.byType(SignInScreen), findsOneWidget);
      expect(find.text('me@home.com'), findsOneWidget);
    });

    testWidgets('a Google account in use signs straight in to it', (
      tester,
    ) async {
      final credential = GoogleAuthProvider.credential(idToken: 'tok');
      final fake = _FakeAuthRepository()
        ..googleError = FirebaseAuthException(
          code: 'credential-already-in-use',
          credential: credential,
        );
      final signIn = _RecordingSignIn();
      await pumpRouted(tester, fake, signIn: signIn);

      await tester.tap(find.text(AppStrings.clean.continueWithGoogle));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.clean.signInInstead));
      await tester.pumpAndSettle();

      // The credential from the failed link is reused: no second picker.
      expect(signIn.credentials, [credential]);
      expect(find.text('TODAY'), findsOneWidget);
      expect(find.text(AppStrings.clean.signedInMerged), findsOneWidget);
    });
  });
}

class _RecordingSignIn implements SignInService {
  final credentials = <AuthCredential>[];

  @override
  Future<SignInResult> signInWithCredential(AuthCredential credential) async {
    credentials.add(credential);
    return const SignInResult(cancelled: false, mergedTasks: 1);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// A token store whose deletes never complete (offline).
class _HangingTokens extends FakePushTokenRepository {
  @override
  Future<void> remove(String ownerId, String token) => Completer<void>().future;
}
