/// Presents the settings placeholder and the current logout action.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/audit/audit_event_type.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/app_providers.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../theme/app_theme.dart';

/// Screen for reviewing and changing local preferences.
class SettingsScreen extends ConsumerWidget {
  /// Creates a settings screen.
  const SettingsScreen({super.key});

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await ConfirmDialog.showConfirmDialog(
      context: context,
      title: l10n.settings_logout_confirm_title,
      message: l10n.settings_logout_confirm_body,
      confirmLabel: l10n.settings_logout_confirm_action,
      cancelLabel: l10n.archive_delete_cancel,
      isDestructive: true,
    );
    if (!confirmed || !context.mounted) {
      return;
    }

    try {
      final audit = await ref.read(auditRepositoryProvider.future);
      await audit.append(eventType: AuditEventType.logout);
      final keyManager = await ref.read(keyManagerProvider.future);
      keyManager.onAudit = null;
      await keyManager.logout();
      ref.read(keyManagerStateProvider.notifier).state = keyManager.state;
      if (context.mounted) {
        context.go('/login');
      }
    } on Exception {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.error_generic)));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return AppScaffold(
      title: l10n.settings_title,
      currentNavIndex: 2,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.s6),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(
                  Icons.settings_outlined,
                  size: 64,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: AppSpacing.s4),
                Text(
                  l10n.settings_coming_soon,
                  style: theme.textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.s2),
                Text(
                  l10n.settings_coming_soon_body,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.s8),
                OutlinedButton.icon(
                  onPressed: () => unawaited(_logout(context, ref)),
                  icon: const Icon(Icons.logout),
                  label: Text(l10n.settings_logout),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
