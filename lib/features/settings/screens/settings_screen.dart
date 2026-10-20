/// Presents local preferences, security options, and application information.
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
import '../../../features/settings/settings_state.dart';
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

  Future<void> _save(
    BuildContext context,
    Future<void> Function() operation,
  ) async {
    try {
      await operation();
    } on Exception {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).error_generic)),
        );
      }
    }
  }

  Future<void> _setBiometric(
    BuildContext context,
    WidgetRef ref, {
    required bool enabled,
  }) async {
    final notifier = ref.read(settingsProvider.notifier);
    final l10n = AppLocalizations.of(context);
    late final KeyManager keyManager;
    late final bool previouslyEnabled;
    try {
      keyManager = await ref.read(keyManagerProvider.future);
      previouslyEnabled = await keyManager.isBiometricEnabled();
    } on Exception {
      if (context.mounted) {
        _showMessage(context, l10n.error_generic);
      }
      return;
    }
    final localAuth = ref.read(localAuthProvider);
    var authenticated = false;
    if (enabled) {
      try {
        if (!await localAuth.canCheckBiometrics ||
            !await localAuth.isDeviceSupported()) {
          if (context.mounted) {
            _showMessage(context, l10n.settings_biometric_unavailable);
          }
          return;
        }
        authenticated = await localAuth.authenticate(
          localizedReason: l10n.settings_biometric_reason,
          options: const AuthenticationOptions(biometricOnly: true),
        );
      } on PlatformException {
        authenticated = false;
      }
      if (!authenticated) {
        if (context.mounted) {
          _showMessage(context, l10n.error_generic);
        }
        return;
      }
    }
    try {
      await keyManager.setBiometricEnabled(enabled: authenticated);
      await notifier.updateBiometricEnabled(authenticated);
    } on Exception {
      try {
        await keyManager.setBiometricEnabled(enabled: previouslyEnabled);
      } on Exception {
        if (context.mounted) {
          _showMessage(context, l10n.error_generic);
        }
      }
      if (context.mounted) {
        _showMessage(context, l10n.error_generic);
      }
    }
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _chooseBackupFolder(BuildContext context, WidgetRef ref) async {
    final fileService = ref.read(backupFileServiceProvider);
    final l10n = AppLocalizations.of(context);
    try {
      final folder = await fileService.pickDirectory();
      if (folder != null && context.mounted) {
        await _save(
          context,
          () => ref.read(settingsProvider.notifier).updateBackupFolder(folder),
        );
      }
    } on Exception {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.error_generic)));
      }
    }
  }

  Future<void> _showInformationDialog(
    BuildContext context, {
    required String title,
    required String message,
  }) {
    final l10n = AppLocalizations.of(context);
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.action_cancel),
          ),
        ],
      ),
    );
  }

  Future<void> _changePassphrase(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final oldController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();
    String? validationMessage;
    final values = await showDialog<List<String>>(
      context: context,
      builder: (BuildContext dialogContext) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setDialogState) =>
            AlertDialog(
              title: Text(l10n.settings_change_passphrase),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    TextField(
                      controller: oldController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: l10n.settings_current_passphrase,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s3),
                    TextField(
                      controller: newController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: l10n.settings_new_passphrase,
                        helperText: l10n.setup_passphrase_hint,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s3),
                    TextField(
                      controller: confirmController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: l10n.setup_confirm_passphrase,
                        errorText: validationMessage,
                      ),
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(l10n.action_cancel),
                ),
                FilledButton(
                  onPressed: () {
                    if (newController.text.runes.length < 12) {
                      setDialogState(
                        () =>
                            validationMessage = l10n.setup_passphrase_too_short,
                      );
                      return;
                    }
                    if (newController.text != confirmController.text) {
                      setDialogState(
                        () =>
                            validationMessage = l10n.setup_passphrase_mismatch,
                      );
                      return;
                    }
                    Navigator.of(
                      dialogContext,
                    ).pop(<String>[oldController.text, newController.text]);
                  },
                  child: Text(l10n.settings_passphrase_save),
                ),
              ],
            ),
      ),
    );
    if (values == null || !context.mounted) {
      oldController.dispose();
      newController.dispose();
      confirmController.dispose();
      return;
    }
    try {
      final keyManager = await ref.read(keyManagerProvider.future);
      await keyManager.changePassphrase(
        currentPassphrase: values[0],
        newPassphrase: values[1],
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.settings_passphrase_changed)),
        );
      }
    } on Exception {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.settings_passphrase_change_failed)),
        );
      }
    } finally {
      oldController
        ..clear()
        ..dispose();
      newController
        ..clear()
        ..dispose();
      confirmController
        ..clear()
        ..dispose();
    }
  }

  Future<void> _regenerateRecoveryKey(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final l10n = AppLocalizations.of(context);
    final passphraseController = TextEditingController();
    final passphrase = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(l10n.settings_regenerate_recovery),
        content: TextField(
          controller: passphraseController,
          obscureText: true,
          decoration: InputDecoration(
            labelText: l10n.settings_current_passphrase,
          ),
          onSubmitted: (String value) => Navigator.of(dialogContext).pop(value),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.action_cancel),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(passphraseController.text),
            child: Text(l10n.settings_recovery_regenerate_action),
          ),
        ],
      ),
    );
    if (passphrase == null || !context.mounted) {
      passphraseController.dispose();
      return;
    }

    try {
      final keyManager = await ref.read(keyManagerProvider.future);
      final recoveryKey = await keyManager.regenerateRecoveryKey(
        passphrase: passphrase,
      );
      if (context.mounted) {
        await _showRecoveryKeyDialog(context, recoveryKey);
      }
    } on Exception {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.settings_recovery_regenerate_failed)),
        );
      }
    } finally {
      passphraseController
        ..clear()
        ..dispose();
    }
  }

  Future<void> _showRecoveryKeyDialog(
    BuildContext context,
    String recoveryKey,
  ) async {
    final l10n = AppLocalizations.of(context);
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(l10n.recovery_key_dialog_title),
        content: Column(
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
                  ScaffoldMessenger.of(
                    dialogContext,
                  ).showSnackBar(SnackBar(content: Text(l10n.error_generic)));
                }
              } on MissingPluginException {
                if (dialogContext.mounted) {
                  ScaffoldMessenger.of(
                    dialogContext,
                  ).showSnackBar(SnackBar(content: Text(l10n.error_generic)));
                }
              }
            },
            icon: const Icon(Icons.copy),
            label: Text(l10n.recovery_key_dialog_copy),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.recovery_key_dialog_confirm),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final settingsAsync = ref.watch(settingsProvider);
    final settings = settingsAsync.valueOrNull ?? const SettingsState();
    final biometricAvailability = ref.watch(biometricAvailabilityProvider);
    final theme = Theme.of(context);

    return AppScaffold(
      title: l10n.settings_title,
      currentNavIndex: 2,
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.s2),
        children: <Widget>[
          _SectionHeader(title: l10n.settings_general),
          ListTile(
            title: Text(l10n.settings_language),
            trailing: DropdownButton<String>(
              value: settings.language,
              items: <DropdownMenuItem<String>>[
                DropdownMenuItem<String>(
                  value: 'en',
                  child: Text(l10n.settings_language_english),
                ),
                DropdownMenuItem<String>(
                  value: 'zh-Hant',
                  child: Text(l10n.settings_language_traditional_chinese),
                ),
              ],
              onChanged: settingsAsync.isLoading
                  ? null
                  : (String? value) {
                      if (value != null) {
                        unawaited(
                          _save(
                            context,
                            () => ref
                                .read(settingsProvider.notifier)
                                .updateLanguage(value),
                          ),
                        );
                      }
                    },
            ),
          ),
          ListTile(
            title: Text(l10n.settings_theme),
            trailing: DropdownButton<String>(
              value: settings.themeMode,
              items: <DropdownMenuItem<String>>[
                DropdownMenuItem<String>(
                  value: 'system',
                  child: Text(l10n.settings_theme_system),
                ),
                DropdownMenuItem<String>(
                  value: 'light',
                  child: Text(l10n.settings_theme_light),
                ),
                DropdownMenuItem<String>(
                  value: 'dark',
                  child: Text(l10n.settings_theme_dark),
                ),
              ],
              onChanged: settingsAsync.isLoading
                  ? null
                  : (String? value) {
                      if (value != null) {
                        unawaited(
                          _save(
                            context,
                            () => ref
                                .read(settingsProvider.notifier)
                                .updateThemeMode(value),
                          ),
                        );
                      }
                    },
            ),
          ),
          ListTile(
            title: Text(l10n.settings_auto_lock),
            trailing: DropdownButton<int>(
              value: settings.autoLockMinutes,
              items: <int>[5, 15, 30]
                  .map(
                    (int minutes) => DropdownMenuItem<int>(
                      value: minutes,
                      child: Text(l10n.settings_minutes(minutes)),
                    ),
                  )
                  .toList(growable: false),
              onChanged: settingsAsync.isLoading
                  ? null
                  : (int? value) {
                      if (value != null) {
                        unawaited(
                          _save(
                            context,
                            () => ref
                                .read(settingsProvider.notifier)
                                .updateAutoLockMinutes(value),
                          ),
                        );
                      }
                    },
            ),
          ),
          _SectionHeader(title: l10n.settings_security),
          biometricAvailability.when(
            loading: () => SwitchListTile(
              title: Text(l10n.settings_biometric),
              subtitle: Text(l10n.settings_biometric_unavailable),
              value: false,
              onChanged: null,
            ),
            error: (Object error, StackTrace stackTrace) => SwitchListTile(
              title: Text(l10n.settings_biometric),
              subtitle: Text(l10n.settings_biometric_unavailable),
              value: false,
              onChanged: null,
            ),
            data: (bool supported) => SwitchListTile(
              title: Text(l10n.settings_biometric),
              subtitle: supported
                  ? null
                  : Text(l10n.settings_biometric_unavailable),
              value: settings.biometricEnabled,
              onChanged: supported && !settingsAsync.isLoading
                  ? (bool value) =>
                        unawaited(_setBiometric(context, ref, enabled: value))
                  : null,
            ),
          ),
          ListTile(
            title: Text(l10n.settings_change_passphrase),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => unawaited(_changePassphrase(context, ref)),
          ),
          ListTile(
            title: Text(l10n.settings_regenerate_recovery),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => unawaited(_regenerateRecoveryKey(context, ref)),
          ),
          ListTile(
            title: Text(l10n.settings_max_attempts),
            subtitle: Text(l10n.settings_max_attempts_preference_only),
            trailing: DropdownButton<int>(
              value: settings.maxFailedAttempts,
              items: <int>[5, 10, 20]
                  .map(
                    (int attempts) => DropdownMenuItem<int>(
                      value: attempts,
                      child: Text(l10n.settings_attempts(attempts)),
                    ),
                  )
                  .toList(growable: false),
              onChanged: settingsAsync.isLoading
                  ? null
                  : (int? value) {
                      if (value != null) {
                        unawaited(
                          _save(
                            context,
                            () => ref
                                .read(settingsProvider.notifier)
                                .updateMaxFailedAttempts(value),
                          ),
                        );
                      }
                    },
            ),
          ),
          _SectionHeader(title: l10n.settings_backup),
          ListTile(
            title: Text(l10n.settings_auto_backup),
            subtitle: Text(l10n.settings_auto_backup_note),
            trailing: DropdownButton<String>(
              value: settings.autoBackupFrequency,
              items: <DropdownMenuItem<String>>[
                DropdownMenuItem<String>(
                  value: 'off',
                  child: Text(l10n.settings_backup_off),
                ),
                DropdownMenuItem<String>(
                  value: 'daily',
                  child: Text(l10n.settings_backup_daily),
                ),
                DropdownMenuItem<String>(
                  value: 'weekly',
                  child: Text(l10n.settings_backup_weekly),
                ),
              ],
              onChanged: settingsAsync.isLoading
                  ? null
                  : (String? value) {
                      if (value != null) {
                        unawaited(
                          _save(
                            context,
                            () => ref
                                .read(settingsProvider.notifier)
                                .updateAutoBackupFrequency(value),
                          ),
                        );
                      }
                    },
            ),
          ),
          ListTile(
            title: Text(l10n.settings_backup_folder),
            subtitle: Text(
              settings.backupFolder.isEmpty
                  ? l10n.settings_backup_folder_default
                  : settings.backupFolder,
            ),
            onTap: settingsAsync.isLoading
                ? null
                : () => unawaited(_chooseBackupFolder(context, ref)),
          ),
          ListTile(
            title: Text(l10n.settings_backup_now),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/backup'),
          ),
          ListTile(
            title: Text(l10n.settings_restore_backup),
            leading: const Icon(Icons.restore),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/restore'),
          ),
          ListTile(
            title: Text(l10n.export_pdf_title),
            leading: const Icon(Icons.picture_as_pdf_outlined),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/export'),
          ),
          _SectionHeader(title: l10n.settings_audit),
          ListTile(
            title: Text(l10n.settings_view_audit),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/settings/audit'),
          ),
          ListTile(
            title: Text(l10n.settings_audit_retention),
            subtitle: Text(l10n.settings_audit_retention_value),
          ),
          _SectionHeader(title: l10n.settings_about),
          ListTile(
            title: Text(l10n.settings_version),
            subtitle: ref
                .watch(appVersionProvider)
                .when(
                  loading: () => const LinearProgressIndicator(),
                  error: (Object error, StackTrace stackTrace) =>
                      Text(l10n.error_generic),
                  data: Text.new,
                ),
          ),
          ListTile(
            title: Text(l10n.settings_privacy_policy),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => unawaited(
              _showInformationDialog(
                context,
                title: l10n.settings_privacy_policy,
                message: l10n.settings_privacy_policy_body,
              ),
            ),
          ),
          _SectionHeader(title: l10n.settings_danger),
          ListTile(
            title: Text(l10n.settings_reset_app),
            leading: Icon(Icons.warning_amber, color: theme.colorScheme.error),
            onTap: () => unawaited(
              _showInformationDialog(
                context,
                title: l10n.settings_reset_app,
                message: l10n.settings_coming_soon_body,
              ),
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: Text(l10n.settings_logout),
            onTap: () => unawaited(_logout(context, ref)),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s4,
        AppSpacing.s4,
        AppSpacing.s4,
        AppSpacing.s1,
      ),
      child: Text(
        title,
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
