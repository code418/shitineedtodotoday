import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/design.dart';
import '../../../features/settings/application/settings_providers.dart';
import '../data/auth_repository.dart';
import '../domain/account_validation.dart';

class AccountScreen extends ConsumerStatefulWidget {
  const AccountScreen({super.key});

  @override
  ConsumerState<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends ConsumerState<AccountScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  String? _emailError;
  String? _passwordError;
  bool _loading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _upgrade() async {
    final strings = ref.read(appStringsProvider);
    final emailErr = validateEmail(_emailCtrl.text);
    final passErr = validatePassword(_passwordCtrl.text);
    if (emailErr != null || passErr != null) {
      setState(() {
        _emailError = emailErr;
        _passwordError = passErr;
      });
      return;
    }
    setState(() {
      _emailError = null;
      _passwordError = null;
      _loading = true;
    });
    try {
      await ref
          .read(authRepositoryProvider)
          .linkEmailPassword(
            email: _emailCtrl.text.trim(),
            password: _passwordCtrl.text,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(strings.accountUpgraded)));
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      final msg =
          e.code == 'email-already-in-use' ||
              e.code == 'credential-already-in-use'
          ? strings.emailInUse
          : e.code == 'weak-password'
          ? strings.weakPassword
          : strings.upgradeFailed;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(strings.upgradeFailed)));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signOut() async {
    final strings = ref.read(appStringsProvider);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(strings.signOutConfirmTitle),
        content: Text(strings.signOutConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(strings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(strings.signOut),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(authRepositoryProvider).signOut();
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(appStringsProvider);
    final status = ref.watch(accountStatusProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(strings.accountTitle)),
      body: ListView(
        padding: const EdgeInsets.all(AppLayout.screenPad),
        children: [
          if (status.isAnonymous || !status.signedIn) ...[
            // Guest card
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(strings.guestTitle, style: theme.textTheme.titleMedium),
                  const SizedBox(height: AppSpacing.x2),
                  Text(strings.guestBody, style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.x4),

            // Email field
            Text(strings.emailLabel, style: theme.textTheme.labelMedium),
            const SizedBox(height: AppSpacing.x1),
            TextField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              decoration: InputDecoration(
                hintText: 'you@example.com',
                filled: true,
                fillColor: AppColors.surfaceSunken,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  borderSide: BorderSide.none,
                ),
                errorText: _emailError,
              ),
            ),
            const SizedBox(height: AppSpacing.x4),

            // Password field
            Text(strings.passwordLabel, style: theme.textTheme.labelMedium),
            const SizedBox(height: AppSpacing.x1),
            TextField(
              controller: _passwordCtrl,
              obscureText: true,
              decoration: InputDecoration(
                hintText: '••••••••',
                filled: true,
                fillColor: AppColors.surfaceSunken,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  borderSide: BorderSide.none,
                ),
                errorText: _passwordError,
              ),
            ),
            const SizedBox(height: AppSpacing.x5),

            AppButton(
              label: strings.upgradeCta,
              block: true,
              pill: true,
              onPressed: _loading ? null : _upgrade,
            ),
          ] else ...[
            // Signed-in card
            AppCard(
              child: Row(
                children: [
                  AppAvatar(name: status.email ?? ''),
                  const SizedBox(width: AppSpacing.x4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          strings.signedInAs,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          status.email ?? '',
                          style: theme.textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.x4),
            AppButton(
              label: strings.signOut,
              variant: AppButtonVariant.ghost,
              onPressed: _signOut,
            ),
          ],
        ],
      ),
    );
  }
}
