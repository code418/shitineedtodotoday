import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snitd/app/router.dart';
import 'package:snitd/core/design/widgets/app_button.dart';
import 'package:snitd/core/strings/app_strings.dart';
import 'package:snitd/features/auth/application/sign_in_service.dart';
import 'package:snitd/features/auth/data/auth_repository.dart';
import 'package:snitd/features/auth/presentation/sign_in_screen.dart';
import 'package:snitd/features/settings/application/settings_providers.dart';

class _FakeSignIn implements SignInService {
  SignInResult result = const SignInResult(cancelled: false);
  Object? error;
  final emailAttempts = <(String, String)>[];
  var googleAttempts = 0;

  Future<SignInResult> _answer() async {
    if (error != null) throw error!;
    return result;
  }

  @override
  Future<SignInResult> signInWithEmail({
    required String email,
    required String password,
  }) {
    emailAttempts.add((email, password));
    return _answer();
  }

  @override
  Future<SignInResult> signInWithGoogle() {
    googleAttempts++;
    return _answer();
  }

  @override
  Future<SignInResult> signInWithCredential(AuthCredential credential) =>
      _answer();
}

class _Auth implements AuthRepository {
  final resets = <String>[];

  @override
  Future<void> sendPasswordReset(String email) async => resets.add(email);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  const strings = AppStrings.clean;
  late _FakeSignIn signIn;
  late _Auth auth;
  late SharedPreferences prefs;

  setUp(() async {
    signIn = _FakeSignIn();
    auth = _Auth();
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  Future<void> pump(WidgetTester tester, {String query = ''}) async {
    final router = GoRouter(
      initialLocation: '${Routes.signIn}$query',
      routes: [
        GoRoute(
          path: Routes.today,
          builder: (_, _) => const Scaffold(body: Text('TODAY')),
        ),
        GoRoute(
          path: Routes.signIn,
          builder: (_, state) => SignInScreen(
            initialEmail: state.uri.queryParameters['email'],
            fromOnboarding: state.uri.queryParameters['from'] == 'onboarding',
          ),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          signInServiceProvider.overrideWithValue(signIn),
          authRepositoryProvider.overrideWithValue(auth),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> fillAndSubmit(WidgetTester tester) async {
    await tester.enterText(find.byType(TextField).first, ' a@b.com ');
    await tester.enterText(find.byType(TextField).last, 'secret123');
    await tester.tap(find.widgetWithText(AppButton, strings.signInCta));
    await tester.pumpAndSettle();
  }

  testWidgets('an empty form shows field errors and never signs in', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(find.widgetWithText(AppButton, strings.signInCta));
    await tester.pumpAndSettle();

    expect(find.text('Enter your email'), findsOneWidget);
    expect(find.text('Enter your password'), findsOneWidget);
    expect(signIn.emailAttempts, isEmpty);
  });

  testWidgets('signing in lands on Today and says the guest tasks came too', (
    tester,
  ) async {
    signIn.result = const SignInResult(cancelled: false, mergedTasks: 2);
    await pump(tester);
    await fillAndSubmit(tester);

    expect(signIn.emailAttempts, [('a@b.com', 'secret123')]);
    expect(find.text('TODAY'), findsOneWidget);
    expect(find.text(strings.signedInMerged), findsOneWidget);
  });

  testWidgets('with nothing to merge it just says welcome back', (
    tester,
  ) async {
    await pump(tester);
    await fillAndSubmit(tester);
    expect(find.text(strings.signedInWelcome), findsOneWidget);
  });

  testWidgets('a merge failure after signing in is admitted, not hidden', (
    tester,
  ) async {
    signIn.result = const SignInResult(cancelled: false, mergeFailed: true);
    await pump(tester);
    await fillAndSubmit(tester);
    expect(find.text('TODAY'), findsOneWidget);
    expect(find.text(strings.signedInMergeFailed), findsOneWidget);
  });

  testWidgets('a wrong password stays put with a clear message', (
    tester,
  ) async {
    signIn.error = FirebaseAuthException(code: 'invalid-credential');
    await pump(tester);
    await fillAndSubmit(tester);

    expect(find.byType(SignInScreen), findsOneWidget);
    expect(find.text(strings.signInBadCredentials), findsOneWidget);
  });

  testWidgets('signing in from onboarding completes onboarding', (
    tester,
  ) async {
    await pump(tester, query: '?from=onboarding');
    await fillAndSubmit(tester);

    expect(prefs.getBool('onboarding_complete'), isTrue);
    expect(find.text('TODAY'), findsOneWidget);
  });

  testWidgets('forgot password emails the typed address', (tester) async {
    await pump(tester, query: '?email=a%40b.com');

    // Prefilled from the route (e.g. an upgrade that found it in use).
    expect(find.text('a@b.com'), findsOneWidget);
    await tester.tap(find.text(strings.forgotPassword));
    await tester.pumpAndSettle();

    expect(auth.resets, ['a@b.com']);
    expect(find.text(strings.passwordResetSent), findsOneWidget);
  });

  testWidgets('a dismissed Google picker stays quiet', (tester) async {
    signIn.result = SignInResult.cancel;
    await pump(tester);
    await tester.tap(find.text(strings.continueWithGoogle));
    await tester.pumpAndSettle();

    expect(signIn.googleAttempts, 1);
    expect(find.byType(SignInScreen), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
  });
}
