/// Selects client records and exports a localized PDF.
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;
import 'package:printing/printing.dart';

import '../../../core/audit/audit_event_type.dart';
import '../../../core/security/pdf_encryption_exception.dart';
import '../../../features/clients/models/client.dart';
import '../../../features/clients/models/client_enums.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/app_providers.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../theme/app_theme.dart';
import '../pdf/pdf_exporter.dart';

/// Exports selected clients with their active policy data.
class ExportPdfScreen extends ConsumerStatefulWidget {
  /// Creates the PDF export screen.
  const ExportPdfScreen({super.key});

  @override
  ConsumerState<ExportPdfScreen> createState() => _ExportPdfScreenState();
}

class _ExportPdfScreenState extends ConsumerState<ExportPdfScreen> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmationController = TextEditingController();
  final Set<String> _selectedClientIds = <String>{};
  String _pdfLanguage = 'follow';
  String _password = '';
  String _confirmation = '';
  bool _allowPrint = true;
  bool _isExporting = false;
  String? _error;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  String _resolvedLanguage() {
    if (_pdfLanguage != 'follow') {
      return _pdfLanguage;
    }
    final locale = Localizations.localeOf(context);
    return locale.scriptCode == 'Hant' ? 'zh-Hant' : 'en';
  }

  Future<List<ClientExportBundle>> _loadBundles(
    List<Client> clients,
    Set<String> selectedIds,
  ) async {
    final clientRepository = await ref.read(clientRepositoryProvider.future);
    final policyRepository = await ref.read(policyRepositoryProvider.future);
    final planRepository = await ref.read(planRepositoryProvider.future);
    final riderRepository = await ref.read(riderRepositoryProvider.future);
    final bundles = <ClientExportBundle>[];
    for (final client in clients.where(
      (Client item) => selectedIds.contains(item.id),
    )) {
      final clientId = client.id;
      if (clientId == null) {
        throw StateError('Selected client is not persisted');
      }
      final persistedClient = await clientRepository.findById(clientId);
      if (persistedClient == null) {
        throw StateError('Selected client is no longer available');
      }
      final policies = await policyRepository.findByClientId(clientId);
      final policyBundles = <PolicyWithPlans>[];
      for (final policy in policies) {
        final policyId = policy.id;
        if (policyId == null) {
          throw StateError('Policy is not persisted');
        }
        final plans = await planRepository.findByPolicyId(policyId);
        final planBundles = <PlanWithRiders>[];
        for (final plan in plans) {
          final planId = plan.id;
          if (planId == null) {
            throw StateError('Plan is not persisted');
          }
          final riders = await riderRepository.findByPlanId(planId);
          planBundles.add(PlanWithRiders(plan: plan, riders: riders));
        }
        policyBundles.add(PolicyWithPlans(policy: policy, plans: planBundles));
      }
      bundles.add(
        ClientExportBundle(client: persistedClient, policies: policyBundles),
      );
    }
    return bundles;
  }

  Future<void> _export(List<Client> clients) async {
    final l10n = AppLocalizations.of(context);
    if (_selectedClientIds.isEmpty ||
        _password.runes.length < 8 ||
        _password != _confirmation ||
        _isExporting) {
      return;
    }
    final password = _password;
    final selectedIds = Set<String>.of(_selectedClientIds);
    final languageCode = _resolvedLanguage();
    setState(() {
      _isExporting = true;
      _error = null;
    });
    Uint8List? pdfBytes;
    try {
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final destinationPath = await ref
          .read(backupFileServiceProvider)
          .pickSaveLocation(
            suggestedName: 'insurance_overview_$timestamp.pdf',
            extension: 'pdf',
          );
      if (destinationPath == null) {
        return;
      }
      final bundles = await _loadBundles(clients, selectedIds);
      final locale = languageCode == 'zh-Hant'
          ? const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant')
          : const Locale('en');
      final localizedStrings = await AppLocalizations.delegate.load(locale);
      pdfBytes = await PdfExporter.exportBundles(
        bundles: bundles,
        languageCode: languageCode,
        allowPrint: _allowPrint,
        password: password,
        l10n: localizedStrings,
      );
      await File(destinationPath).writeAsBytes(pdfBytes, flush: true);
      pdfBytes.fillRange(0, pdfBytes.length, 0);
      final audit = await ref.read(auditRepositoryProvider.future);
      await audit.append(
        eventType: AuditEventType.exportPdf,
        metadata: <String, Object?>{
          'count': bundles.length,
          'language': languageCode,
          'encrypted': true,
        },
      );
      if (mounted) {
        await _showSuccess(destinationPath, l10n);
      }
    } on PdfEncryptionException {
      if (mounted) {
        setState(() => _error = l10n.export_pdf_encryption_error);
      }
    } on Exception {
      if (mounted) {
        setState(() => _error = l10n.export_pdf_error);
      }
    } finally {
      if (pdfBytes != null) {
        pdfBytes.fillRange(0, pdfBytes.length, 0);
      }
      _clearPasswords();
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Future<void> _showSuccess(String savedPath, AppLocalizations l10n) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(l10n.export_pdf_success_title),
        content: Text(l10n.export_pdf_success_body(savedPath)),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.action_back),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await _shareFile(savedPath, l10n);
            },
            child: Text(l10n.export_pdf_open_file),
          ),
        ],
      ),
    );
  }

  Future<void> _shareFile(String savedPath, AppLocalizations l10n) async {
    Uint8List? bytes;
    try {
      bytes = await File(savedPath).readAsBytes();
      await Printing.sharePdf(bytes: bytes, filename: path.basename(savedPath));
    } on Exception {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.error_generic)));
      }
    } finally {
      bytes?.fillRange(0, bytes.length, 0);
    }
  }

  void _clearPasswords() {
    _passwordController.clear();
    _confirmationController.clear();
    _password = '';
    _confirmation = '';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final clientsAsync = ref.watch(clientListProvider);
    final clients = clientsAsync.valueOrNull ?? const <Client>[];
    final clientIds = clients
        .map((Client client) => client.id)
        .whereType<String>()
        .toList(growable: false);
    final allSelected =
        clientIds.isNotEmpty && clientIds.every(_selectedClientIds.contains);
    final canExport =
        _selectedClientIds.isNotEmpty &&
        _password.runes.length >= 8 &&
        _password == _confirmation &&
        !_isExporting;

    return AppScaffold(
      title: l10n.export_pdf_title,
      showBottomNav: false,
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.s4),
        children: <Widget>[
          Text(l10n.export_pdf_subtitle, style: theme.textTheme.titleSmall),
          if (clientsAsync.isLoading) const LinearProgressIndicator(),
          if (clientsAsync.hasError)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.s2),
              child: Text(
                l10n.error_generic,
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ),
          if (clientsAsync.hasValue && clients.isEmpty)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.s2),
              child: Text(l10n.export_pdf_empty_clients),
            ),
          if (clients.isNotEmpty) ...<Widget>[
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: allSelected,
              title: Text(l10n.export_pdf_select_all),
              onChanged: _isExporting
                  ? null
                  : (bool? selected) => setState(() {
                      if (selected ?? false) {
                        _selectedClientIds.addAll(clientIds);
                      } else {
                        _selectedClientIds.clear();
                      }
                    }),
            ),
            ...clients.map((Client client) {
              final clientId = client.id;
              if (clientId == null) {
                return const SizedBox.shrink();
              }
              final role = client.role == ClientRole.holder
                  ? l10n.client_role_holder
                  : l10n.client_role_insured;
              return CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _selectedClientIds.contains(clientId),
                title: Text(client.name),
                subtitle: Text(role),
                onChanged: _isExporting
                    ? null
                    : (bool? selected) => setState(() {
                        if (selected ?? false) {
                          _selectedClientIds.add(clientId);
                        } else {
                          _selectedClientIds.remove(clientId);
                        }
                      }),
              );
            }),
          ],
          const Divider(),
          Text(l10n.export_pdf_encryption_info),
          const SizedBox(height: AppSpacing.s2),
          DropdownButtonFormField<String>(
            key: ValueKey<String>(_pdfLanguage),
            initialValue: _pdfLanguage,
            decoration: InputDecoration(labelText: l10n.export_pdf_language),
            items: <DropdownMenuItem<String>>[
              DropdownMenuItem<String>(
                value: 'follow',
                child: Text(l10n.export_pdf_language_follow),
              ),
              DropdownMenuItem<String>(
                value: 'en',
                child: Text(l10n.settings_language_english),
              ),
              DropdownMenuItem<String>(
                value: 'zh-Hant',
                child: Text(l10n.settings_language_traditional_chinese),
              ),
            ],
            onChanged: _isExporting
                ? null
                : (String? value) {
                    if (value != null) {
                      setState(() => _pdfLanguage = value);
                    }
                  },
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.export_pdf_allow_print),
            value: _allowPrint,
            onChanged: _isExporting
                ? null
                : (bool value) => setState(() => _allowPrint = value),
          ),
          TextField(
            controller: _passwordController,
            obscureText: true,
            autocorrect: false,
            enableSuggestions: false,
            onChanged: (String value) => setState(() {
              _password = value;
              _error = null;
            }),
            decoration: InputDecoration(
              labelText: l10n.export_pdf_password,
              helperText: l10n.export_pdf_password_hint,
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
              labelText: l10n.export_pdf_confirm_password,
              helperText: l10n.export_pdf_password_policy_note,
            ),
          ),
          if (_error != null) ...<Widget>[
            const SizedBox(height: AppSpacing.s2),
            Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
          ],
          if (_isExporting) ...<Widget>[
            const SizedBox(height: AppSpacing.s2),
            const LinearProgressIndicator(),
            const SizedBox(height: AppSpacing.s1),
            Text(l10n.export_pdf_exporting),
          ],
          const SizedBox(height: AppSpacing.s3),
          FilledButton(
            onPressed: canExport ? () => _export(clients) : null,
            child: Text(l10n.export_pdf_export),
          ),
        ],
      ),
    );
  }
}
