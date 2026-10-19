/// Provides the initial passphrase setup step.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/audit/audit_event_type.dart';
import '../../../core/security/key_manager.dart';
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
      final confirmed = await _showRecoveryKey(recoveryKey);
      if (confirmed && mounted) {
        setState(() {
          _passphrase = '';
          _confirm = '';
        });
        context.go('/home');
      }
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

  Future<bool> _showRecoveryKey(String recoveryKey) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return PopScope(
          canPop: false,
          child: AlertDialog(
            title: Text(l10n.recovery_key_dialog_title),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(l10n.recovery_key_dialog_body),
                  const SizedBox(height: AppSpacing.s4),
                  SelectableText(
                    recoveryKey,
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton.icon(
                onPressed: () async {
                  try {
                    await Clipboard.setData(ClipboardData(text: recoveryKey));
                    if (dialogContext.mounted) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        SnackBar(content: Text(l10n.recovery_key_copied)),
                      );
                    }
                  } on PlatformException {
                    if (dialogContext.mounted) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        SnackBar(content: Text(l10n.error_generic)),
                      );
                    }
                  } on MissingPluginException {
                    if (dialogContext.mounted) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        SnackBar(content: Text(l10n.error_generic)),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.copy),
                label: Text(l10n.recovery_key_dialog_copy),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(l10n.recovery_key_dialog_confirm),
              ),
            ],
          ),
        );
      },
    );
    return confirmed ?? false;
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
      appBar: AppBar(title: Text(l10n.setup_title)),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.s6),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
