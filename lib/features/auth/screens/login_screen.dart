/// Presents the localized passphrase and biometric login screen.
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';

import '../../../core/audit/audit_event_type.dart';
import '../../../core/security/key_manager.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/app_providers.dart';
import '../../../theme/app_theme.dart';

/// Login form for unlocking the local vault.
class LoginScreen extends ConsumerStatefulWidget {
  /// Creates the login screen.
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  static const int _maximumFailedAttempts = 10;

  late final Future<bool> _biometricAvailability;
  String _passphrase = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _biometricAvailability = _biometricAvailable(ref.read(localAuthProvider));
  }

  Future<void> _signIn() async {
    if (_isLoading) {
      return;
    }
    setState(() => _isLoading = true);
    final l10n = AppLocalizations.of(context);
    try {
      final keyManager = await ref.read(keyManagerProvider.future);
      keyManager.onAudit = null;
      final success = await keyManager.unlock(passphrase: _passphrase);
      if (!mounted) {
        return;
      }
      if (!success) {
        final remaining = math.max(
          0,
          _maximumFailedAttempts - keyManager.failedAttempts,
        );
        _showMessage(l10n.login_error(remaining));
        return;
      }
      await _finishUnlock(keyManager);
    } on Exception {
      if (mounted) {
        _showMessage(l10n.error_generic);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signInWithBiometric() async {
    if (_isLoading) {
      return;
    }
    setState(() => _isLoading = true);
    final l10n = AppLocalizations.of(context);
    try {
      final keyManager = await ref.read(keyManagerProvider.future);
      keyManager.onAudit = null;
      final success = await keyManager.unlockWithBiometric();
      if (!mounted) {
        return;
      }
      if (!success) {
        _showMessage(l10n.error_generic);
        return;
      }
      await _finishUnlock(keyManager, biometric: true);
    } on Exception {
      if (mounted) {
        _showMessage(l10n.error_generic);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _finishUnlock(
    KeyManager keyManager, {
    bool biometric = false,
  }) async {
    ref.read(keyManagerStateProvider.notifier).state = keyManager.state;
    final audit = await ref.read(auditRepositoryProvider.future);
    final restoredSchema = ref.read(pendingRestoreAuditSchemaProvider);
    if (restoredSchema != null) {
      await audit.append(
        eventType: AuditEventType.restoreDb,
        metadata: <String, Object?>{'schema_version': restoredSchema},
      );
      ref.read(pendingRestoreAuditSchemaProvider.notifier).state = null;
    }
    await audit.append(
      eventType: AuditEventType.loginSuccess,
      metadata: biometric ? <String, Object?>{'method': 'biometric'} : null,
    );
    if (mounted) {
      context.go('/home');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.login_title)),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.s6),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(l10n.login_subtitle, style: theme.textTheme.bodyLarge),
                const SizedBox(height: AppSpacing.s4),
                TextField(
                  obscureText: true,
                  onChanged: (String value) => _passphrase = value,
                  decoration: InputDecoration(labelText: l10n.login_passphrase),
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _signIn(),
                ),
                const SizedBox(height: AppSpacing.s4),
                FilledButton(
                  onPressed: _isLoading ? null : _signIn,
                  child: Text(
                    _isLoading ? l10n.login_signing_in : l10n.login_sign_in,
                  ),
                ),
                FutureBuilder<bool>(
                  future: _biometricAvailability,
                  builder:
                      (BuildContext context, AsyncSnapshot<bool> snapshot) {
                        if (snapshot.data != true) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.s2),
                          child: OutlinedButton.icon(
                            onPressed: _isLoading ? null : _signInWithBiometric,
                            icon: const Icon(Icons.fingerprint),
                            label: Text(l10n.login_biometric),
                          ),
                        );
                      },
                ),
                Align(
                  alignment: AlignmentDirectional.center,
                  child: TextButton(
                    onPressed: () => context.go('/recovery'),
                    child: Text(l10n.login_forgot),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<bool> _biometricAvailable(LocalAuthentication localAuth) async {
  try {
    return await localAuth.canCheckBiometrics &&
        await localAuth.isDeviceSupported();
  } on Exception {
    return false;
  }
}
