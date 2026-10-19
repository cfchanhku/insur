/// Presents the local vault unlock screen after auto-lock or manual lock.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/audit/audit_event_type.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/app_providers.dart';
import '../../../theme/app_theme.dart';

/// Passphrase gate displayed when the vault is locked.
class LockScreen extends ConsumerStatefulWidget {
  /// Creates the lock screen.
  const LockScreen({super.key});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  String _passphrase = '';
  bool _isLoading = false;

  Future<void> _unlock() async {
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
        _showMessage(l10n.login_error(10 - keyManager.failedAttempts));
        return;
      }
      ref.read(keyManagerStateProvider.notifier).state = keyManager.state;
      final audit = await ref.read(auditRepositoryProvider.future);
      await audit.append(eventType: AuditEventType.loginSuccess);
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
    return Scaffold(
      appBar: AppBar(title: Text(l10n.lock_title)),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.s6),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Icon(
                  Icons.lock_outline,
                  size: AppSpacing.s16,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: AppSpacing.s4),
                Text(
                  l10n.lock_subtitle,
                  style: theme.textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.s4),
                TextField(
                  obscureText: true,
                  onChanged: (String value) => _passphrase = value,
                  decoration: InputDecoration(labelText: l10n.login_passphrase),
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _unlock(),
                ),
                const SizedBox(height: AppSpacing.s4),
                FilledButton(
                  onPressed: _isLoading ? null : _unlock,
                  child: Text(l10n.lock_unlock),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
