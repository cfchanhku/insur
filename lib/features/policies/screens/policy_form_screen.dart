/// Creates and edits insurance policies.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../features/policies/models/policy.dart';
import '../../../features/policies/models/policy_status.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/app_providers.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../theme/app_theme.dart';

/// Full-screen policy form for create or edit mode.
class PolicyFormScreen extends ConsumerStatefulWidget {
  /// Creates a policy form. Supply either an existing [id] or a new [clientId].
  const PolicyFormScreen({this.id, this.clientId, super.key})
    : assert(id != null || clientId != null, 'Provide id or clientId');

  /// Existing policy UUID in edit mode.
  final String? id;

  /// Owning client UUID in create mode.
  final String? clientId;

  @override
  ConsumerState<PolicyFormScreen> createState() => _PolicyFormScreenState();
}

class _PolicyFormScreenState extends ConsumerState<PolicyFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _companyController = TextEditingController();
  final TextEditingController _policyNoController = TextEditingController();
  final TextEditingController _effectiveDateController =
      TextEditingController();
  final TextEditingController _firstPremiumDateController =
      TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  DateTime _effectiveDate = DateTime.now();
  DateTime _firstPremiumDate = DateTime.now();
  String _currency = 'HKD';
  PolicyStatus _status = PolicyStatus.active;
  String? _dateError;
  bool _initialized = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _initialized = widget.id == null;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncDateText();
  }

  @override
  void dispose() {
    _companyController.dispose();
    _policyNoController.dispose();
    _effectiveDateController.dispose();
    _firstPremiumDateController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _populate(Policy policy) {
    _companyController.text = policy.company;
    _policyNoController.text = policy.policyNo;
    _notesController.text = policy.notes ?? '';
    _effectiveDate = policy.effectiveDate;
    _firstPremiumDate = policy.firstPremiumDate;
    _currency = policy.currency;
    _status = policy.status;
    _syncDateText();
    _initialized = true;
  }

  void _syncDateText() {
    final locale = Localizations.localeOf(context).toString();
    final formatter = DateFormat.yMd(locale);
    _effectiveDateController.text = formatter.format(_effectiveDate);
    _firstPremiumDateController.text = formatter.format(_firstPremiumDate);
  }

  Future<void> _chooseDate({required bool effective}) async {
    final current = effective ? _effectiveDate : _firstPremiumDate;
    final chosen = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (chosen == null || !mounted) {
      return;
    }
    setState(() {
      if (effective) {
        _effectiveDate = chosen;
      } else {
        _firstPremiumDate = chosen;
      }
      _dateError = null;
      _syncDateText();
    });
  }

  Future<void> _save(Policy? existing) async {
    final l10n = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_firstPremiumDate.isBefore(_effectiveDate)) {
      setState(() => _dateError = l10n.policy_form_error_dates);
      return;
    }
    setState(() {
      _dateError = null;
      _isSaving = true;
    });
    try {
      final repository = await ref.read(policyRepositoryProvider.future);
      final now = DateTime.now().toUtc();
      final clientId = existing?.clientId ?? widget.clientId!;
      final saved = await repository.save(
        Policy(
          id: widget.id,
          clientId: clientId,
          company: _companyController.text.trim(),
          policyNo: _policyNoController.text.trim(),
          effectiveDate: _effectiveDate,
          firstPremiumDate: _firstPremiumDate,
          currency: _currency,
          status: _status,
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
          createdAt: existing?.createdAt ?? now,
          updatedAt: now,
          archivedAt: existing?.archivedAt,
        ),
      );
      ref
        ..invalidate(policiesByClientProvider(clientId))
        ..invalidate(policyByIdProvider(saved.id!))
        ..invalidate(clientPolicyCountProvider(clientId))
        ..invalidate(clientPolicyCountsProvider);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.policy_form_saved)));
        context.pop();
      }
    } on Exception {
      if (mounted) {
        setState(
          () => _dateError = l10n.policy_form_error_save(l10n.error_generic),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isEditing = widget.id != null;
    final policyAsync = isEditing
        ? ref.watch(policyByIdProvider(widget.id!))
        : const AsyncValue<Policy?>.data(null);
    if (isEditing && policyAsync.hasValue && !_initialized) {
      final policy = policyAsync.valueOrNull;
      if (policy != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && !_initialized) {
            setState(() => _populate(policy));
          }
        });
      }
    }
    return AppScaffold(
      title: isEditing
          ? l10n.policy_form_title_edit
          : l10n.policy_form_title_new,
      showBottomNav: false,
      body: isEditing && !_initialized
          ? policyAsync.when(
              loading: () => const LoadingIndicator(),
              error: (Object error, StackTrace stackTrace) =>
                  ErrorState(message: l10n.error_generic),
              data: (Policy? policy) => policy == null
                  ? ErrorState(message: l10n.policy_not_found)
                  : const LoadingIndicator(),
            )
          : _buildForm(context, l10n, policyAsync.valueOrNull),
    );
  }

  Widget _buildForm(
    BuildContext context,
    AppLocalizations l10n,
    Policy? existing,
  ) {
    final theme = Theme.of(context);
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.s6),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Column(
              children: <Widget>[
                TextFormField(
                  controller: _companyController,
                  decoration: InputDecoration(labelText: l10n.policy_company),
                  validator: (String? value) =>
                      value == null || value.trim().isEmpty
                      ? l10n.policy_form_error_company_required
                      : null,
                ),
                const SizedBox(height: AppSpacing.s3),
                TextFormField(
                  controller: _policyNoController,
                  decoration: InputDecoration(labelText: l10n.policy_no),
                  validator: (String? value) =>
                      value == null || value.trim().isEmpty
                      ? l10n.policy_form_error_policy_no_required
                      : null,
                ),
                const SizedBox(height: AppSpacing.s3),
                TextFormField(
                  controller: _effectiveDateController,
                  readOnly: true,
                  onTap: () => _chooseDate(effective: true),
                  decoration: InputDecoration(
                    labelText: l10n.policy_effective_date,
                    suffixIcon: const Icon(Icons.calendar_today),
                  ),
                ),
                const SizedBox(height: AppSpacing.s3),
                TextFormField(
                  controller: _firstPremiumDateController,
                  readOnly: true,
                  onTap: () => _chooseDate(effective: false),
                  decoration: InputDecoration(
                    labelText: l10n.policy_first_premium_date,
                    suffixIcon: const Icon(Icons.calendar_today),
                  ),
                ),
                const SizedBox(height: AppSpacing.s3),
                DropdownButtonFormField<String>(
                  initialValue: _currency,
                  decoration: InputDecoration(labelText: l10n.policy_currency),
                  items:
                      <(String, String)>[
                            ('HKD', l10n.currency_hkd),
                            ('USD', l10n.currency_usd),
                            ('CNY', l10n.currency_cny),
                            ('EUR', l10n.currency_eur),
                            ('GBP', l10n.currency_gbp),
                            ('JPY', l10n.currency_jpy),
                            ('SGD', l10n.currency_sgd),
                          ]
                          .map(
                            ((String, String) item) => DropdownMenuItem<String>(
                              value: item.$1,
                              child: Text(item.$2),
                            ),
                          )
                          .toList(growable: false),
                  onChanged: (String? value) {
                    if (value != null) {
                      setState(() => _currency = value);
                    }
                  },
                  validator: (String? value) =>
                      value != null && RegExp(r'^[A-Z]{3}$').hasMatch(value)
                      ? null
                      : l10n.policy_form_error_currency_invalid,
                ),
                const SizedBox(height: AppSpacing.s3),
                DropdownButtonFormField<PolicyStatus>(
                  initialValue: _status,
                  decoration: InputDecoration(labelText: l10n.policy_status),
                  items: PolicyStatus.values
                      .map(
                        (PolicyStatus status) => DropdownMenuItem<PolicyStatus>(
                          value: status,
                          child: Text(switch (status) {
                            PolicyStatus.active => l10n.policy_status_active,
                            PolicyStatus.lapsed => l10n.policy_status_lapsed,
                            PolicyStatus.surrendered =>
                              l10n.policy_status_surrendered,
                          }),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (PolicyStatus? value) {
                    if (value != null) {
                      setState(() => _status = value);
                    }
                  },
                ),
                const SizedBox(height: AppSpacing.s3),
                TextFormField(
                  controller: _notesController,
                  minLines: 3,
                  maxLines: 5,
                  decoration: InputDecoration(labelText: l10n.policy_notes),
                ),
                if (_dateError != null) ...<Widget>[
                  const SizedBox(height: AppSpacing.s3),
                  Text(
                    _dateError!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.s6),
                Row(
                  children: <Widget>[
                    TextButton(
                      onPressed: _isSaving ? null : () => context.pop(),
                      child: Text(l10n.policy_form_cancel),
                    ),
                    const Spacer(),
                    FilledButton(
                      onPressed: _isSaving ? null : () => _save(existing),
                      child: _isSaving
                          ? Text(l10n.policy_form_saving)
                          : Text(l10n.policy_form_save),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
