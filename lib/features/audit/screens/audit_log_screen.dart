/// Displays read-only audit history and verifies its integrity.
library;

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/audit/audit_entry.dart';
import '../../../core/audit/audit_event_type.dart';
import '../../../core/audit/verification_result.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/app_providers.dart';
import '../providers/audit_providers.dart';

/// Read-only audit history and full-chain integrity verification.
class AuditLogScreen extends ConsumerStatefulWidget {
  /// Creates an audit log screen.
  const AuditLogScreen({super.key});

  @override
  ConsumerState<AuditLogScreen> createState() => _AuditLogScreenState();
}

class _AuditLogScreenState extends ConsumerState<AuditLogScreen> {
  static const int _pageSize = 100;

  AuditEventType? _eventType;
  DateTimeRange? _dateRange;
  VerificationResult? _verification;
  bool _verificationFailed = false;
  bool _isVerifying = false;
  int _limit = _pageSize;

  AuditFilter get _filter => AuditFilter(
    eventType: _eventType,
    from: _dateRange == null
        ? null
        : DateTime(
            _dateRange!.start.year,
            _dateRange!.start.month,
            _dateRange!.start.day,
          ).toUtc(),
    to: _dateRange == null
        ? null
        : DateTime(
            _dateRange!.end.year,
            _dateRange!.end.month,
            _dateRange!.end.day + 1,
          ).subtract(const Duration(microseconds: 1)).toUtc(),
    limit: _limit,
  );

  Future<void> _verifyChain() async {
    if (_isVerifying) {
      return;
    }
    setState(() {
      _isVerifying = true;
      _verificationFailed = false;
    });
    try {
      final repository = await ref.read(auditRepositoryProvider.future);
      final result = await repository.verifyChain();
      if (mounted) {
        setState(() => _verification = result);
      }
    } on Exception {
      if (mounted) {
        setState(() {
          _verification = null;
          _verificationFailed = true;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isVerifying = false);
      }
    }
  }

  Future<void> _selectDateRange() async {
    final now = DateTime.now();
    final selected = await showDateRangePicker(
      context: context,
      firstDate: DateTime(1970),
      lastDate: DateTime(now.year, now.month, now.day),
      initialDateRange: _dateRange,
    );
    if (selected != null && mounted) {
      setState(() {
        _dateRange = selected;
        _limit = _pageSize;
      });
    }
  }

  void _clearFilters() {
    setState(() {
      _eventType = null;
      _dateRange = null;
      _limit = _pageSize;
    });
  }

  Future<void> _showEntryDetails(AuditEntry entry) async {
    final l10n = AppLocalizations.of(context);
    final timestamp = DateFormat.yMMMd(
      l10n.localeName,
    ).add_jm().format(entry.timestamp.toLocal());
    final entityValue = entry.entityType ?? l10n.audit_entity_none;
    final entityId = entry.entityId ?? l10n.audit_entity_none;
    final metadata = const JsonEncoder.withIndent(
      '  ',
    ).convert(entry.metadata ?? <String, Object?>{});
    final json = const JsonEncoder.withIndent('  ').convert(entry.toJson());

    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(l10n.audit_entry_details),
        content: SizedBox(
          width: 560,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                _DetailLine(
                  label: l10n.audit_event_type,
                  value: _eventLabel(l10n, entry.eventType),
                ),
                _DetailLine(label: l10n.audit_timestamp, value: timestamp),
                _DetailLine(label: l10n.audit_entity, value: entityValue),
                _DetailLine(label: l10n.audit_entity_id, value: entityId),
                _DetailLine(label: l10n.audit_metadata, value: metadata),
                _DetailLine(label: l10n.audit_prev_hash, value: entry.prevHash),
                _DetailLine(
                  label: l10n.audit_entry_hash,
                  value: entry.entryHash,
                ),
              ],
            ),
          ),
        ),
        actions: <Widget>[
          TextButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: json));
              if (dialogContext.mounted) {
                Navigator.of(dialogContext).pop();
              }
              if (mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(l10n.audit_copied)));
              }
            },
            icon: const Icon(Icons.copy),
            label: Text(l10n.audit_copy_json),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.action_cancel),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final entriesAsync = ref.watch(auditEntriesProvider(_filter));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.audit_log_title),
        actions: <Widget>[
          IconButton(
            tooltip: l10n.audit_verify,
            onPressed: _isVerifying ? null : _verifyChain,
            icon: _isVerifying
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.verified_outlined),
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                DropdownButton<AuditEventType?>(
                  value: _eventType,
                  items: <DropdownMenuItem<AuditEventType?>>[
                    DropdownMenuItem<AuditEventType?>(
                      child: Text(l10n.audit_filter_all),
                    ),
                    ...AuditEventType.values.map(
                      (AuditEventType type) =>
                          DropdownMenuItem<AuditEventType?>(
                            value: type,
                            child: Text(_eventLabel(l10n, type)),
                          ),
                    ),
                  ],
                  onChanged: (AuditEventType? value) {
                    setState(() {
                      _eventType = value;
                      _limit = _pageSize;
                    });
                  },
                ),
                TextButton.icon(
                  onPressed: _selectDateRange,
                  icon: const Icon(Icons.date_range),
                  label: Text(
                    _dateRange == null
                        ? l10n.audit_filter_any_date
                        : l10n.audit_filter_date_range(
                            DateFormat.yMMMd(
                              l10n.localeName,
                            ).format(_dateRange!.start),
                            DateFormat.yMMMd(
                              l10n.localeName,
                            ).format(_dateRange!.end),
                          ),
                  ),
                ),
                TextButton(
                  onPressed: _eventType == null && _dateRange == null
                      ? null
                      : _clearFilters,
                  child: Text(l10n.audit_filter_clear),
                ),
              ],
            ),
          ),
          _ChainStatusBanner(
            verification: _verification,
            verificationFailed: _verificationFailed,
          ),
          Expanded(
            child: entriesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (Object error, StackTrace stackTrace) =>
                  Center(child: Text(l10n.error_generic)),
              data: (List<AuditEntry> entries) {
                if (entries.isEmpty) {
                  return Center(child: Text(l10n.audit_empty));
                }
                return ListView.builder(
                  itemCount:
                      entries.length + (entries.length == _limit ? 1 : 0),
                  itemBuilder: (BuildContext context, int index) {
                    if (index == entries.length) {
                      return Padding(
                        padding: const EdgeInsets.all(16),
                        child: Center(
                          child: OutlinedButton(
                            onPressed: () =>
                                setState(() => _limit += _pageSize),
                            child: Text(l10n.audit_load_more),
                          ),
                        ),
                      );
                    }
                    final entry = entries[index];
                    final entitySubtitle = entry.entityType == null
                        ? null
                        : '${entry.entityType}'
                              '${entry.entityId == null ? '' : ' · ${_shortId(entry.entityId!)}'}';
                    return ListTile(
                      leading: Icon(_eventIcon(entry.eventType)),
                      title: Text(_eventLabel(l10n, entry.eventType)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            DateFormat.yMMMd(
                              l10n.localeName,
                            ).add_jm().format(entry.timestamp.toLocal()),
                          ),
                          if (entitySubtitle != null) Text(entitySubtitle),
                        ],
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => unawaited(_showEntryDetails(entry)),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ChainStatusBanner extends StatelessWidget {
  const _ChainStatusBanner({
    required this.verification,
    required this.verificationFailed,
  });

  final VerificationResult? verification;
  final bool verificationFailed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final result = verification;
    final Color background;
    final Color foreground;
    final IconData icon;
    final String message;

    if (verificationFailed || (result != null && !result.isValid)) {
      background = theme.colorScheme.errorContainer;
      foreground = theme.colorScheme.onErrorContainer;
      icon = Icons.error_outline;
      message = verificationFailed
          ? l10n.audit_verify_error
          : l10n.audit_chain_broken(
              result!.brokenAt ?? 0,
              result.reason ?? l10n.audit_verify_error,
            );
    } else if (result != null) {
      background = theme.colorScheme.secondaryContainer;
      foreground = theme.colorScheme.onSecondaryContainer;
      icon = Icons.verified_outlined;
      message = l10n.audit_chain_valid(result.entryCount ?? 0);
    } else {
      background = theme.colorScheme.surfaceContainerHighest;
      foreground = theme.colorScheme.onSurfaceVariant;
      icon = Icons.help_outline;
      message = l10n.audit_chain_unverified;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: background,
      child: Row(
        children: <Widget>[
          Icon(icon, color: foreground),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message, style: TextStyle(color: foreground)),
          ),
        ],
      ),
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 2),
          SelectableText(value),
        ],
      ),
    );
  }
}

String _eventLabel(AppLocalizations l10n, AuditEventType type) {
  return switch (type) {
    AuditEventType.appSetup => l10n.audit_event_app_setup,
    AuditEventType.loginSuccess => l10n.audit_event_login_success,
    AuditEventType.loginFail => l10n.audit_event_login_fail,
    AuditEventType.logout => l10n.audit_event_logout,
    AuditEventType.autoLock => l10n.audit_event_auto_lock,
    AuditEventType.recoveryUsed => l10n.audit_event_recovery_used,
    AuditEventType.recoveryKeyRotated => l10n.audit_event_recovery_key_rotated,
    AuditEventType.create => l10n.audit_event_create,
    AuditEventType.update => l10n.audit_event_update,
    AuditEventType.archive => l10n.audit_event_archive,
    AuditEventType.restore => l10n.audit_event_restore,
    AuditEventType.delete => l10n.audit_event_delete,
    AuditEventType.exportPdf => l10n.audit_event_export_pdf,
    AuditEventType.backup => l10n.audit_event_backup,
    AuditEventType.restoreDb => l10n.audit_event_restore_db,
    AuditEventType.migration => l10n.audit_event_migration,
    AuditEventType.purge => l10n.audit_event_purge,
  };
}

IconData _eventIcon(AuditEventType type) {
  return switch (type) {
    AuditEventType.appSetup => Icons.settings,
    AuditEventType.loginSuccess ||
    AuditEventType.loginFail ||
    AuditEventType.logout ||
    AuditEventType.autoLock ||
    AuditEventType.recoveryUsed ||
    AuditEventType.recoveryKeyRotated => Icons.key,
    AuditEventType.create => Icons.add_circle_outline,
    AuditEventType.update => Icons.edit_outlined,
    AuditEventType.archive => Icons.archive_outlined,
    AuditEventType.restore => Icons.restore,
    AuditEventType.delete => Icons.delete_outline,
    AuditEventType.exportPdf => Icons.picture_as_pdf_outlined,
    AuditEventType.backup || AuditEventType.restoreDb => Icons.save_outlined,
    AuditEventType.migration => Icons.sync,
    AuditEventType.purge => Icons.cleaning_services_outlined,
  };
}

String _shortId(String value) =>
    value.length <= 12 ? value : '…${value.substring(value.length - 8)}';
