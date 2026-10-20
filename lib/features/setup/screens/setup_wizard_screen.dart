/// Provides the initial passphrase setup step.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';

import '../../../core/audit/audit_event_type.dart';
import '../../../core/security/key_manager.dart';
import '../../../features/settings/settings_notifier.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/app_providers.dart';
import '../../../theme/app_theme.dart';

/// Initial vault setup form.
class SetupWizardScreen extends ConsumerStatefulWidget {
  /// Creates the setup wizard.
  const SetupWizardScreen({super.key});

  @override
  ConsumerState<SetupWizardScreen> createState() => _SetupWizardScreenState();
}

class _SetupWizardScreenState extends ConsumerState<SetupWizardScreen> {
  String _passphrase = '';
  String _confirm = '';
  String _recoveryKey = '';
  String _recoveryConfirmation = '';
  int _step = 0;
  bool _isLoading = false;
  bool _setupEventRecorded = false;

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    if (_passphrase.runes.length < 12) {
      _showMessage(l10n.setup_passphrase_too_short);
      return;
    }
    if (_passphrase != _confirm) {
      _showMessage(l10n.setup_passphrase_mismatch);
      return;
    }
    await _createVault();
  }

  Future<void> _createVault() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _isLoading = true);
    try {
      final keyManager = await ref.read(keyManagerProvider.future);
      keyManager.onAudit = null;
      if (keyManager.state != KeyManagerState.unlocked) {
        await keyManager.setup(passphrase: _passphrase);
      }
      ref.read(keyManagerStateProvider.notifier).state = keyManager.state;
      final recoveryKey = await keyManager.setupRecoveryKey(
        passphrase: _passphrase,
      );
      final audit = await ref.read(auditRepositoryProvider.future);
      if (!_setupEventRecorded) {
        await audit.append(eventType: AuditEventType.appSetup);
        _setupEventRecorded = true;
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _recoveryKey = recoveryKey;
        _step = 1;
      });
    } on Exception {
      if (mounted) {
        _showMessage(l10n.setup_error);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _confirmRecoveryKey() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _isLoading = true);
    try {
      final keyManager = await ref.read(keyManagerProvider.future);
      final confirmed = await keyManager.confirmRecoveryKey(
        recoveryKey: _recoveryConfirmation,
      );
      if (!confirmed) {
        if (mounted) {
          _showMessage(l10n.recovery_invalid_key);
        }
        return;
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _passphrase = '';
        _confirm = '';
        _recoveryConfirmation = '';
        _recoveryKey = '';
        _step = 2;
      });
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

  Future<void> _enableBiometric() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _isLoading = true);
    try {
      final localAuth = ref.read(localAuthProvider);
      if (!await localAuth.canCheckBiometrics ||
          !await localAuth.isDeviceSupported()) {
        _showMessage(l10n.settings_biometric_unavailable);
        return;
      }
      final authenticated = await localAuth.authenticate(
        localizedReason: l10n.settings_biometric_reason,
        options: const AuthenticationOptions(biometricOnly: true),
      );
      if (!authenticated) {
        _showMessage(l10n.error_generic);
        return;
      }
      await ref.read(settingsProvider.future);
      final keyManager = await ref.read(keyManagerProvider.future);
      await keyManager.setBiometricEnabled(enabled: true);
      try {
        await ref.read(settingsProvider.notifier).updateBiometricEnabled(true);
      } on Exception {
        await keyManager.setBiometricEnabled(enabled: false);
        rethrow;
      }
      if (mounted) {
        context.go('/home');
      }
    } on PlatformException {
      if (mounted) {
        _showMessage(l10n.error_generic);
      }
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

  Future<void> _skipBiometric() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _isLoading = true);
    try {
      await ref.read(settingsProvider.future);
      final keyManager = await ref.read(keyManagerProvider.future);
      await keyManager.setBiometricEnabled(enabled: false);
      await ref.read(settingsProvider.notifier).updateBiometricEnabled(false);
      if (mounted) {
        context.go('/home');
      }
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

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final stepLabels = <String>[
      l10n.setupStepPassphrase,
      l10n.setupStepRecovery,
      l10n.setupStepBiometric,
    ];
    return Scaffold(
      appBar: AppBar(title: Text(l10n.setup_title)),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.s6),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(l10n.setupStepOf(_step + 1, 3)),
                const SizedBox(height: AppSpacing.s2),
                LinearProgressIndicator(value: (_step + 1) / 3),
                const SizedBox(height: AppSpacing.s3),
                Text(stepLabels[_step], style: theme.textTheme.titleMedium),
                const SizedBox(height: AppSpacing.s3),
                if (_step == 0) ...<Widget>[
                  Text(l10n.setup_subtitle, style: theme.textTheme.bodyLarge),
                  const SizedBox(height: AppSpacing.s4),
                  TextField(
                    obscureText: true,
                    onChanged: (String value) => _passphrase = value,
                    decoration: InputDecoration(
                      labelText: l10n.setup_passphrase,
                      helperText: l10n.setup_passphrase_hint,
                    ),
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: AppSpacing.s3),
                  TextField(
                    obscureText: true,
                    onChanged: (String value) => _confirm = value,
                    decoration: InputDecoration(
                      labelText: l10n.setup_confirm_passphrase,
                    ),
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) {
                      if (!_isLoading) {
                        unawaited(_submit());
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.s4),
                  FilledButton(
                    onPressed: _isLoading ? null : _submit,
                    child: Text(
                      _isLoading ? l10n.setup_creating : l10n.setup_create,
                    ),
                  ),
                ] else if (_step == 1) ...<Widget>[
                  Text(l10n.recovery_key_dialog_body),
                  const SizedBox(height: AppSpacing.s4),
                  SelectableText(
                    _recoveryKey,
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: TextButton.icon(
                      onPressed: () async {
                        try {
                          await Clipboard.setData(
                            ClipboardData(text: _recoveryKey),
                          );
                          if (mounted) {
                            _showMessage(l10n.recovery_key_copied);
                          }
                        } on PlatformException {
                          if (mounted) {
                            _showMessage(l10n.error_generic);
                          }
                        } on MissingPluginException {
                          if (mounted) {
                            _showMessage(l10n.error_generic);
                          }
                        }
                      },
                      icon: const Icon(Icons.copy),
                      label: Text(l10n.recovery_key_dialog_copy),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s3),
                  TextField(
                    onChanged: (String value) => _recoveryConfirmation = value,
                    decoration: InputDecoration(
                      labelText: l10n.setup_recovery_confirmation,
                    ),
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _confirmRecoveryKey(),
                  ),
                  const SizedBox(height: AppSpacing.s4),
                  FilledButton(
                    onPressed: _isLoading ? null : _confirmRecoveryKey,
                    child: Text(
                      _isLoading
                          ? l10n.recovery_working
                          : l10n.setup_recovery_confirm,
                    ),
                  ),
                ] else ...<Widget>[
                  Text(l10n.setup_biometric_prompt),
                  const SizedBox(height: AppSpacing.s4),
                  ref
                      .watch(biometricAvailabilityProvider)
                      .when(
                        loading: () => const LinearProgressIndicator(),
                        error: (Object error, StackTrace stackTrace) =>
                            Text(l10n.settings_biometric_unavailable),
                        data: (bool supported) => supported
                            ? FilledButton.icon(
                                onPressed: _isLoading ? null : _enableBiometric,
                                icon: const Icon(Icons.fingerprint),
                                label: Text(l10n.setup_enable_biometric),
                              )
                            : Text(l10n.settings_biometric_unavailable),
                      ),
                  const SizedBox(height: AppSpacing.s3),
                  TextButton(
                    onPressed: _isLoading ? null : _skipBiometric,
                    child: Text(l10n.setup_skip_biometric),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
