/// Provides offline recovery-key authentication and mandatory passphrase reset.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/audit/audit_event_type.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/app_providers.dart';
import '../../../theme/app_theme.dart';

/// Screen for recovering access with the offline recovery key.
class RecoveryScreen extends ConsumerStatefulWidget {
  /// Creates the recovery screen.
  const RecoveryScreen({super.key});

  @override
  ConsumerState<RecoveryScreen> createState() => _RecoveryScreenState();
}

class _RecoveryScreenState extends ConsumerState<RecoveryScreen> {
  final TextEditingController _recoveryKeyController = TextEditingController();
  final TextEditingController _passphraseController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  bool _recoveryAccepted = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _recoveryKeyController.dispose();
    _passphraseController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    if (_isLoading) {
      return;
    }
    final l10n = AppLocalizations.of(context);
    if (!_recoveryAccepted) {
      setState(() => _isLoading = true);
      try {
        final keyManager = await ref.read(keyManagerProvider.future);
        keyManager.onAudit = null;
        final recovered = await keyManager.recoveryKeyLogin(
          recoveryKey: _recoveryKeyController.text,
        );
        if (!recovered) {
          _recoveryKeyController.clear();
          if (mounted) {
            _showMessage(l10n.recovery_invalid_key);
          }
          return;
        }
        _recoveryKeyController.clear();
        ref.read(keyManagerStateProvider.notifier).state = keyManager.state;
        final audit = await ref.read(auditRepositoryProvider.future);
        await audit.append(eventType: AuditEventType.recoveryUsed);
        if (mounted) {
          setState(() => _recoveryAccepted = true);
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
      return;
    }

    final passphrase = _passphraseController.text;
    if (passphrase.runes.length < 12) {
      _showMessage(l10n.setup_passphrase_too_short);
      return;
    }
    if (passphrase != _confirmController.text) {
      _showMessage(l10n.setup_passphrase_mismatch);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final keyManager = await ref.read(keyManagerProvider.future);
      await keyManager.setPassphraseAfterRecovery(newPassphrase: passphrase);
      if (mounted) {
        context.go('/home');
      }
    } on Exception {
      if (mounted) {
        _showMessage(l10n.error_generic);
      }
    } finally {
      _passphraseController.clear();
      _confirmController.clear();
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
    return Scaffold(
      appBar: AppBar(title: Text(l10n.recovery_title)),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.s6),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  _recoveryAccepted
                      ? l10n.recovery_set_new_passphrase
                      : l10n.recovery_enter_key,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: AppSpacing.s4),
                if (!_recoveryAccepted)
                  TextField(
                    controller: _recoveryKeyController,
                    decoration: InputDecoration(
                      labelText: l10n.recovery_key_label,
                    ),
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _continue(),
                  )
                else ...<Widget>[
                  TextField(
                    controller: _passphraseController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: l10n.settings_new_passphrase,
                      helperText: l10n.setup_passphrase_hint,
                    ),
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: AppSpacing.s3),
                  TextField(
                    controller: _confirmController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: l10n.setup_confirm_passphrase,
                    ),
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _continue(),
                  ),
                ],
                const SizedBox(height: AppSpacing.s4),
                FilledButton(
                  onPressed: _isLoading ? null : _continue,
                  child: Text(
                    _isLoading
                        ? l10n.recovery_working
                        : _recoveryAccepted
                        ? l10n.recovery_reset_passphrase
                        : l10n.recovery_continue,
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
