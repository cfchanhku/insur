/// Creates encrypted local backups of the unlocked vault.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;

import '../../../core/backup/backup_format.dart';
import '../../../core/database/schema.dart';
import '../../../core/security/key_manager.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/app_providers.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../theme/app_theme.dart';
import '../../settings/settings_notifier.dart';

/// Guides the user through creating a passphrase-protected backup.
class BackupScreen extends ConsumerStatefulWidget {
  /// Creates the backup screen.
  const BackupScreen({super.key});

  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends ConsumerState<BackupScreen> {
  final TextEditingController _passphraseController = TextEditingController();
  final TextEditingController _confirmationController = TextEditingController();
  String _passphrase = '';
  String _confirmation = '';
  String? _destinationPath;
  bool _isCreating = false;
  String? _error;

  bool get _isValid =>
      _passphrase.runes.length >= 12 &&
      _passphrase == _confirmation &&
      _destinationPath != null;

  @override
  void dispose() {
    _passphraseController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  Future<void> _chooseDestination() async {
    final l10n = AppLocalizations.of(context);
    try {
      final appVersion = await ref.read(appVersionProvider.future);
      final suggestedName = BackupFormat.generateFileName(
        timestamp: DateTime.now(),
        schemaVersion: Schema.currentSchemaVersion,
        appVersion: appVersion,
      );
      final destination = await ref
          .read(backupFileServiceProvider)
          .pickSaveLocation(suggestedName: suggestedName);
      if (mounted && destination != null) {
        setState(() {
          _destinationPath = destination;
          _error = null;
        });
      }
    } on Exception {
      if (mounted) {
        setState(() => _error = l10n.backup_error);
      }
    }
  }

  Future<void> _createBackup() async {
    if (!_isValid || _isCreating) {
      return;
    }
    final l10n = AppLocalizations.of(context);
    final passphrase = _passphrase;
    final destinationPath = _destinationPath!;
    setState(() {
      _isCreating = true;
      _error = null;
    });
    var databaseClosed = false;
    try {
      final keyManager = await ref.read(keyManagerProvider.future);
      if (keyManager.state != KeyManagerState.unlocked) {
        throw StateError('Vault is not unlocked');
      }
      final openedDatabase = await ref.read(appDatabaseProvider.future);
      final service = await ref.read(backupServiceProvider.future);
      await openedDatabase.close();
      databaseClosed = true;
      ref
        ..invalidate(appDatabaseProvider)
        ..invalidate(backupServiceProvider);

      final result = await service.createBackup(
        passphrase: passphrase,
        dbFilePath: openedDatabase.path,
        destinationPath: destinationPath,
      );
      await ref.read(appDatabaseProvider.future);
      databaseClosed = false;
      final refreshedService = await ref.read(backupServiceProvider.future);
      await refreshedService.recordBackupAudit(result);
      await ref.read(settingsProvider.future);
      await ref
          .read(settingsProvider.notifier)
          .recordBackup(
            path: result.path,
            at: result.createdAt!,
            sizeBytes: result.sizeBytes,
          );
      if (mounted) {
        await _showSuccess(result.path, l10n);
      }
    } on Exception {
      if (databaseClosed) {
        try {
          await ref.read(appDatabaseProvider.future);
        } on Exception {
          // A reopen failure still leaves the operation visibly failed.
        }
      }
      if (mounted) {
        setState(() => _error = l10n.backup_error);
      }
    } finally {
      _clearPasswords();
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }

  Future<void> _showSuccess(String savedPath, AppLocalizations l10n) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(l10n.backup_success_title),
        content: Text(l10n.backup_success_body(savedPath)),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(path.dirname(savedPath))));
            },
            child: Text(l10n.backup_open_folder),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.action_back),
          ),
        ],
      ),
    );
  }

  void _clearPasswords() {
    _passphraseController.clear();
    _confirmationController.clear();
    _passphrase = '';
    _confirmation = '';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final settings = ref.watch(settingsProvider).valueOrNull;
    final lastBackup = settings?.lastBackupAt;
    final lastBackupSize = settings?.lastBackupSizeBytes;
    final lastBackupText = lastBackup == null
        ? l10n.backup_never
        : l10n.backup_last_backup(
            DateFormat.yMMMd(
              l10n.localeName,
            ).add_jm().format(lastBackup.toLocal()),
          );
    return AppScaffold(
      title: l10n.backup_title,
      showBottomNav: false,
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.s4),
        children: <Widget>[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.s4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Icon(
                    Icons.lock_outline,
                    size: 48,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: AppSpacing.s2),
                  Text(
                    l10n.backup_info_card_title,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.s1),
                  Text(
                    l10n.backup_info_card_body,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s2),
                  Text(
                    lastBackupText,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: lastBackup == null
                          ? theme.colorScheme.onSurfaceVariant
                          : null,
                    ),
                  ),
                  if (settings?.lastBackupPath.isNotEmpty ?? false)
                    SelectableText(settings!.lastBackupPath),
                  if (lastBackupSize != null)
                    Text(
                      l10n.backup_last_backup_size(
                        NumberFormat.decimalPattern(
                          l10n.localeName,
                        ).format(lastBackupSize),
                      ),
                      style: theme.textTheme.bodySmall,
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.s3),
          TextField(
            controller: _passphraseController,
            obscureText: true,
            autocorrect: false,
            enableSuggestions: false,
            onChanged: (String value) => setState(() {
              _passphrase = value;
              _error = null;
            }),
            decoration: InputDecoration(
              labelText: l10n.backup_passphrase,
              helperText: l10n.backup_passphrase_hint,
            ),
          ),
          const SizedBox(height: AppSpacing.s2),
          TextField(
            controller: _confirmationController,
            obscureText: true,
            autocorrect: false,
            enableSuggestions: false,
            onChanged: (String value) => setState(() {
              _confirmation = value;
              _error = null;
            }),
            decoration: InputDecoration(
              labelText: l10n.backup_confirm_passphrase,
              errorText:
                  _confirmation.isNotEmpty && _confirmation != _passphrase
                  ? l10n.backup_password_mismatch
                  : null,
            ),
          ),
          const SizedBox(height: AppSpacing.s3),
          Text(
            _destinationPath == null
                ? l10n.backup_destination_required
                : l10n.backup_destination_selected(_destinationPath!),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _isCreating ? null : _chooseDestination,
              icon: const Icon(Icons.folder),
              label: Text(l10n.backup_choose_destination),
            ),
          ),
          if (_error != null) ...<Widget>[
            const SizedBox(height: AppSpacing.s2),
            Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
          ],
          if (_isCreating) ...<Widget>[
            const SizedBox(height: AppSpacing.s2),
            const LinearProgressIndicator(),
            const SizedBox(height: AppSpacing.s1),
            Text(l10n.backup_creating),
          ],
          const SizedBox(height: AppSpacing.s3),
          FilledButton(
            onPressed: _isValid && !_isCreating ? _createBackup : null,
            child: Text(l10n.backup_create),
          ),
        ],
      ),
    );
  }
}
