/// Restores the unlocked vault from an authenticated encrypted backup.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as path;

import '../../../core/security/key_manager.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/app_providers.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../theme/app_theme.dart';

/// Confirms destructive replacement and restores a backup.
class RestoreScreen extends ConsumerStatefulWidget {
  /// Creates the restore screen.
  const RestoreScreen({super.key});

  @override
  ConsumerState<RestoreScreen> createState() => _RestoreScreenState();
}

class _RestoreScreenState extends ConsumerState<RestoreScreen> {
  final TextEditingController _passphraseController = TextEditingController();
  String? _selectedFilePath;
  String _passphrase = '';
  bool _confirmed = false;
  bool _isRestoring = false;
  String? _error;

  bool get _isValid =>
      _selectedFilePath != null && _passphrase.isNotEmpty && _confirmed;

  @override
  void dispose() {
    _passphraseController.dispose();
    super.dispose();
  }

  Future<void> _selectFile() async {
    final l10n = AppLocalizations.of(context);
    try {
      final selectedPath = await ref
          .read(backupFileServiceProvider)
          .pickOpenFile();
      if (mounted && selectedPath != null) {
        setState(() {
          _selectedFilePath = selectedPath;
          _error = null;
        });
      }
    } on Exception {
      if (mounted) {
        setState(() => _error = l10n.restore_error);
      }
    }
  }

  Future<bool> _confirmRestore(AppLocalizations l10n) async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext dialogContext) => AlertDialog(
            title: Text(l10n.restore_confirm_title),
            content: Text(l10n.restore_confirm_body),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(l10n.action_cancel),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                  foregroundColor: Theme.of(context).colorScheme.onError,
                ),
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(l10n.restore_confirm_action),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _restore() async {
    if (!_isValid || _isRestoring) {
      return;
    }
    final l10n = AppLocalizations.of(context);
    if (!await _confirmRestore(l10n) || !mounted) {
      return;
    }
    final passphrase = _passphrase;
    final sourcePath = _selectedFilePath!;
    setState(() {
      _isRestoring = true;
      _error = null;
    });
    var databaseClosed = false;
    KeyManager? keyManager;
    try {
      final activeKeyManager = await ref.read(keyManagerProvider.future);
      keyManager = activeKeyManager;
      if (activeKeyManager.state != KeyManagerState.unlocked) {
        throw StateError('Vault is not unlocked');
      }
      final openedDatabase = await ref.read(appDatabaseProvider.future);
      final service = await ref.read(backupServiceProvider.future);
      final backupDirectory = await ref
          .read(backupFileServiceProvider)
          .getDefaultBackupDirectory();
      final timeToken = DateTime.now().toUtc().toIso8601String().replaceAll(
        RegExp('[:.]'),
        '-',
      );
      final preRestorePath = path.join(
        backupDirectory.path,
        'pre_restore_$timeToken.enc',
      );
      final dbPath = openedDatabase.path;
      await openedDatabase.close();
      databaseClosed = true;
      ref
        ..invalidate(appDatabaseProvider)
        ..invalidate(backupServiceProvider);
      final result = await service.restoreBackup(
        passphrase: passphrase,
        sourcePath: sourcePath,
        dbFilePath: dbPath,
        preRestoreBackupPath: preRestorePath,
      );

      ref.read(pendingRestoreAuditSchemaProvider.notifier).state =
          result.schemaVersion;
      ref.read(keyManagerStateProvider.notifier).state = activeKeyManager.state;
      ref.invalidate(appDatabaseProvider);
      databaseClosed = false;
      _clearPassphrase();
      if (mounted) {
        await showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext dialogContext) => AlertDialog(
            title: Text(l10n.restore_success_title),
            content: Text(l10n.restore_success_body),
            actions: <Widget>[
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(l10n.login_sign_in),
              ),
            ],
          ),
        );
        if (mounted) {
          context.go('/login');
        }
      }
    } on Exception {
      if (databaseClosed && keyManager?.state == KeyManagerState.unlocked) {
        try {
          await ref.read(appDatabaseProvider.future);
        } on Exception {
          // The user still receives a generic failure and can retry login.
        }
      }
      if (keyManager != null) {
        ref.read(keyManagerStateProvider.notifier).state = keyManager.state;
      }
      if (mounted) {
        setState(() {
          _error = l10n.restore_error;
          _isRestoring = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.restore_error)));
      }
    } finally {
      _clearPassphrase();
      if (mounted && _isRestoring) {
        setState(() => _isRestoring = false);
      }
    }
  }

  void _clearPassphrase() {
    _passphraseController.clear();
    _passphrase = '';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return AppScaffold(
      title: l10n.restore_title,
      showBottomNav: false,
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.s4),
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(AppSpacing.s3),
            decoration: BoxDecoration(
              color: theme.colorScheme.tertiaryContainer,
              borderRadius: BorderRadius.circular(AppSpacing.s2),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(
                  Icons.warning_amber,
                  color: theme.colorScheme.onTertiaryContainer,
                ),
                const SizedBox(width: AppSpacing.s2),
                Expanded(
                  child: Text(
                    l10n.restore_warning,
                    style: TextStyle(
                      color: theme.colorScheme.onTertiaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.s3),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.s3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  if (_selectedFilePath == null)
                    OutlinedButton.icon(
                      onPressed: _isRestoring ? null : _selectFile,
                      icon: const Icon(Icons.file_open),
                      label: Text(l10n.restore_select_file),
                    )
                  else ...<Widget>[
                    Text(
                      l10n.restore_file_selected(
                        path.basename(_selectedFilePath!),
                      ),
                    ),
                    TextButton(
                      onPressed: _isRestoring ? null : _selectFile,
                      child: Text(l10n.restore_select_file),
                    ),
                  ],
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
            decoration: InputDecoration(labelText: l10n.restore_passphrase),
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _confirmed,
            title: Text(l10n.restore_confirm_checkbox),
            onChanged: _isRestoring
                ? null
                : (bool? value) => setState(() => _confirmed = value ?? false),
          ),
          if (_error != null) ...<Widget>[
            const SizedBox(height: AppSpacing.s2),
            Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
          ],
          if (_isRestoring) ...<Widget>[
            const SizedBox(height: AppSpacing.s2),
            const LinearProgressIndicator(),
            const SizedBox(height: AppSpacing.s1),
            Text(l10n.restore_restoring),
          ],
          const SizedBox(height: AppSpacing.s3),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              foregroundColor: theme.colorScheme.onError,
            ),
            onPressed: _isValid && !_isRestoring ? _restore : null,
            child: Text(l10n.restore_action),
          ),
        ],
      ),
    );
  }
}
