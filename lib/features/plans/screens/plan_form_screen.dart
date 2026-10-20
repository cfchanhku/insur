/// Creates and edits plans and their inline riders.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../features/plans/models/plan.dart';
import '../../../features/plans/models/plan_category.dart';
import '../../../features/riders/models/rider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/app_providers.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/async_button.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../theme/app_theme.dart';

/// Full-screen plan form with an inline editor for riders.
class PlanFormScreen extends ConsumerStatefulWidget {
  /// Creates a plan form. Supply an existing [id] or a new [policyId].
  const PlanFormScreen({this.id, this.policyId, super.key})
    : assert(id != null || policyId != null, 'Provide id or policyId');

  /// Existing plan UUID in edit mode.
  final String? id;

  /// Owning policy UUID in create mode.
  final String? policyId;

  @override
  ConsumerState<PlanFormScreen> createState() => _PlanFormScreenState();
}

class _PlanFormScreenState extends ConsumerState<PlanFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _planNameController = TextEditingController();
  final TextEditingController _coverageController = TextEditingController();
  final TextEditingController _paymentTermController = TextEditingController();
  final TextEditingController _coveragePeriodController =
      TextEditingController();
  final TextEditingController _deductibleController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  PlanCategory _category = PlanCategory.life;
  Plan? _loadedPlan;
  final List<_RiderDraft> _riders = <_RiderDraft>[];
  final Set<String> _removedRiderIds = <String>{};
  String? _error;
  bool _initialized = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _initialized = widget.id == null;
  }

  @override
  void dispose() {
    _planNameController.dispose();
    _coverageController.dispose();
    _paymentTermController.dispose();
    _coveragePeriodController.dispose();
    _deductibleController.dispose();
    _notesController.dispose();
    for (final rider in _riders) {
      rider.dispose();
    }
    super.dispose();
  }

  void _populate(Plan plan, List<Rider> riders) {
    _loadedPlan = plan;
    _category = plan.category;
    _planNameController.text = plan.planName;
    _coverageController.text = plan.coverageAmount?.toString() ?? '';
    _paymentTermController.text = plan.paymentTerm ?? '';
    _coveragePeriodController.text = plan.coveragePeriod ?? '';
    _deductibleController.text = plan.deductible?.toString() ?? '';
    _notesController.text = plan.notes ?? '';
    _riders.addAll(riders.map(_RiderDraft.fromRider));
    _initialized = true;
  }

  String? _categoryLabel(AppLocalizations l10n, PlanCategory category) =>
      switch (category) {
        PlanCategory.life => l10n.plan_category_life,
        PlanCategory.ci => l10n.plan_category_ci,
        PlanCategory.hospital => l10n.plan_category_hospital,
        PlanCategory.accident => l10n.plan_category_accident,
        PlanCategory.savings => l10n.plan_category_savings,
        PlanCategory.other => l10n.plan_category_other,
      };

  bool _showPlanName() =>
      _category == PlanCategory.hospital || _category == PlanCategory.other;
  bool _showCoverage() => _category != PlanCategory.savings;
  bool _showPaymentTerm() => <PlanCategory>{
    PlanCategory.life,
    PlanCategory.ci,
    PlanCategory.hospital,
    PlanCategory.savings,
  }.contains(_category);
  bool _showCoveragePeriod() =>
      _category == PlanCategory.life || _category == PlanCategory.ci;
  bool _showDeductible() => _category == PlanCategory.hospital;
  bool _showRiders() => <PlanCategory>{
    PlanCategory.ci,
    PlanCategory.hospital,
    PlanCategory.accident,
  }.contains(_category);

  String? _validateOptionalAmount(String? value, AppLocalizations l10n) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    final amount = double.tryParse(value.trim());
    return amount == null || amount < 0
        ? l10n.plan_form_error_coverage_invalid
        : null;
  }

  Future<void> _save(String policyId) async {
    final l10n = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_showPlanName() && _planNameController.text.trim().isEmpty) {
      setState(() => _error = l10n.plan_form_error_name_required);
      return;
    }
    for (final rider in _riders) {
      if (rider.nameController.text.trim().isEmpty) {
        setState(() => _error = l10n.rider_error_name_required);
        return;
      }
    }
    setState(() {
      _isSaving = true;
      _error = null;
    });
    var planSaved = false;
    try {
      final planRepository = await ref.read(planRepositoryProvider.future);
      final riderRepository = await ref.read(riderRepositoryProvider.future);
      final now = DateTime.now().toUtc();
      // Use the localized category label as the persisted default plan name.
      final name = _showPlanName()
          ? _planNameController.text.trim()
          : _categoryLabel(l10n, _category)!;
      final savedPlan = await planRepository.save(
        Plan(
          id: widget.id,
          policyId: policyId,
          category: _category,
          planName: name,
          coverageAmount: _showCoverage()
              ? _parseAmount(_coverageController.text)
              : null,
          deductible: _showDeductible()
              ? _parseAmount(_deductibleController.text)
              : null,
          paymentTerm: _showPaymentTerm()
              ? _optionalText(_paymentTermController.text)
              : null,
          coveragePeriod: _showCoveragePeriod()
              ? _optionalText(_coveragePeriodController.text)
              : null,
          notes: _optionalText(_notesController.text),
          createdAt: _loadedPlan?.createdAt ?? now,
          updatedAt: now,
          archivedAt: _loadedPlan?.archivedAt,
        ),
      );
      planSaved = true;
      final savedPlanId = savedPlan.id!;
      final ridersToSave = _showRiders() ? _riders : <_RiderDraft>[];
      for (final draft in ridersToSave) {
        await riderRepository.save(
          Rider(
            id: draft.id,
            planId: savedPlanId,
            riderName: draft.nameController.text.trim(),
            coverageAmount: _parseAmount(draft.coverageController.text),
            paymentTerm: _optionalText(draft.paymentTermController.text),
            deductible: _parseAmount(draft.deductibleController.text),
            waitingPeriod: _optionalText(draft.waitingPeriodController.text),
            createdAt: draft.original?.createdAt ?? now,
            updatedAt: now,
            archivedAt: draft.original?.archivedAt,
          ),
        );
      }
      final riderIdsToArchive = <String>{
        ..._removedRiderIds,
        if (!_showRiders())
          for (final rider in _riders)
            if (rider.id != null) rider.id!,
      };
      for (final riderId in riderIdsToArchive) {
        await riderRepository.archive(riderId);
      }
      ref
        ..invalidate(plansByPolicyProvider(policyId))
        ..invalidate(planByIdProvider(savedPlanId))
        ..invalidate(ridersByPlanProvider(savedPlanId));
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.plan_form_saved)));
        context.pop();
      }
    } on Exception {
      if (mounted) {
        setState(
          () => _error = planSaved
              ? l10n.plan_form_error_partial_save
              : l10n.plan_form_error_save(l10n.error_generic),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _addRider() {
    setState(() {
      _riders.add(_RiderDraft());
      _error = null;
    });
  }

  void _removeRider(int index) {
    setState(() {
      final removed = _riders.removeAt(index);
      if (removed.id != null) {
        _removedRiderIds.add(removed.id!);
      }
      removed.dispose();
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isEditing = widget.id != null;
    final planAsync = isEditing
        ? ref.watch(planByIdProvider(widget.id!))
        : const AsyncValue<Plan?>.data(null);
    final ridersAsync = isEditing
        ? ref.watch(ridersByPlanProvider(widget.id!))
        : const AsyncValue<List<Rider>>.data(<Rider>[]);
    if (isEditing &&
        planAsync.hasValue &&
        ridersAsync.hasValue &&
        !_initialized) {
      final plan = planAsync.valueOrNull;
      final riders = ridersAsync.valueOrNull;
      if (plan != null && riders != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && !_initialized) {
            setState(() => _populate(plan, riders));
          }
        });
      }
    }
    final policyId = _loadedPlan?.policyId ?? widget.policyId;
    return AppScaffold(
      title: isEditing ? l10n.plan_form_title_edit : l10n.plan_form_title_new,
      showBottomNav: false,
      body: isEditing && !_initialized
          ? _loadingOrError(planAsync, ridersAsync, l10n)
          : _buildForm(context, l10n, policyId!),
    );
  }

  Widget _loadingOrError(
    AsyncValue<Plan?> planAsync,
    AsyncValue<List<Rider>> ridersAsync,
    AppLocalizations l10n,
  ) {
    if (planAsync.isLoading || ridersAsync.isLoading) {
      return const LoadingIndicator();
    }
    if (planAsync.hasError || ridersAsync.hasError) {
      return ErrorState(message: l10n.error_generic);
    }
    if (planAsync.valueOrNull == null) {
      return ErrorState(message: l10n.plan_not_found);
    }
    return const LoadingIndicator();
  }

  Widget _buildForm(
    BuildContext context,
    AppLocalizations l10n,
    String policyId,
  ) {
    final theme = Theme.of(context);
    return Form(
      key: _formKey,
      child: Column(
        children: <Widget>[
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.s6),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 700),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      DropdownButtonFormField<PlanCategory>(
                        initialValue: _category,
                        decoration: InputDecoration(
                          labelText: l10n.plan_category,
                        ),
                        items: PlanCategory.values
                            .map(
                              (PlanCategory category) =>
                                  DropdownMenuItem<PlanCategory>(
                                    value: category,
                                    child: Text(
                                      _categoryLabel(l10n, category)!,
                                    ),
                                  ),
                            )
                            .toList(growable: false),
                        onChanged: (PlanCategory? value) {
                          if (value != null) {
                            setState(() {
                              _category = value;
                              _error = null;
                            });
                          }
                        },
                      ),
                      if (_showPlanName()) ...<Widget>[
                        const SizedBox(height: AppSpacing.s3),
                        TextFormField(
                          controller: _planNameController,
                          decoration: InputDecoration(
                            labelText: l10n.plan_name,
                          ),
                          textInputAction: TextInputAction.next,
                          validator: (String? value) =>
                              _showPlanName() &&
                                  (value == null || value.trim().isEmpty)
                              ? l10n.plan_form_error_category_required
                              : null,
                        ),
                      ],
                      if (_showCoverage()) ...<Widget>[
                        const SizedBox(height: AppSpacing.s3),
                        _amountField(
                          controller: _coverageController,
                          label: l10n.plan_coverage_amount,
                          textInputAction: TextInputAction.next,
                          validator: (String? value) =>
                              _validateOptionalAmount(value, l10n),
                        ),
                      ],
                      if (_showPaymentTerm()) ...<Widget>[
                        const SizedBox(height: AppSpacing.s3),
                        TextFormField(
                          controller: _paymentTermController,
                          decoration: InputDecoration(
                            labelText: l10n.plan_payment_term,
                          ),
                          textInputAction: TextInputAction.next,
                        ),
                      ],
                      if (_showCoveragePeriod()) ...<Widget>[
                        const SizedBox(height: AppSpacing.s3),
                        TextFormField(
                          controller: _coveragePeriodController,
                          decoration: InputDecoration(
                            labelText: l10n.plan_coverage_period,
                          ),
                          textInputAction: TextInputAction.next,
                        ),
                      ],
                      if (_showDeductible()) ...<Widget>[
                        const SizedBox(height: AppSpacing.s3),
                        _amountField(
                          controller: _deductibleController,
                          label: l10n.plan_deductible,
                          textInputAction: TextInputAction.next,
                          validator: (String? value) =>
                              _validateOptionalAmount(value, l10n),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.s3),
                      TextFormField(
                        controller: _notesController,
                        minLines: 3,
                        maxLines: 5,
                        textInputAction: TextInputAction.newline,
                        decoration: InputDecoration(labelText: l10n.plan_notes),
                      ),
                      if (_showRiders()) ...<Widget>[
                        const SizedBox(height: AppSpacing.s6),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                l10n.plan_riders_section,
                                style: theme.textTheme.titleLarge,
                              ),
                            ),
                            TextButton.icon(
                              onPressed: _isSaving ? null : _addRider,
                              icon: const Icon(Icons.add),
                              label: Text(l10n.plan_add_rider),
                            ),
                          ],
                        ),
                        if (_riders.isEmpty)
                          Text(
                            l10n.plan_no_riders,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          )
                        else
                          ..._riders.asMap().entries.map(
                            (MapEntry<int, _RiderDraft> entry) => _RiderCard(
                              draft: entry.value,
                              index: entry.key,
                              onRemove: () => _removeRider(entry.key),
                              l10n: l10n,
                            ),
                          ),
                      ],
                      if (_error != null) ...<Widget>[
                        const SizedBox(height: AppSpacing.s3),
                        Text(
                          _error!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.error,
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.s6),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 700),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.s6,
                    AppSpacing.s2,
                    AppSpacing.s6,
                    AppSpacing.s3,
                  ),
                  child: Row(
                    children: <Widget>[
                      TextButton(
                        onPressed: _isSaving ? null : () => context.pop(),
                        child: Text(l10n.plan_form_cancel),
                      ),
                      const Spacer(),
                      AsyncButton(
                        onPressed: _isSaving ? null : () => _save(policyId),
                        label: l10n.plan_form_save,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RiderDraft {
  _RiderDraft()
    : nameController = TextEditingController(),
      coverageController = TextEditingController(),
      paymentTermController = TextEditingController(),
      deductibleController = TextEditingController(),
      waitingPeriodController = TextEditingController(),
      original = null;

  _RiderDraft.fromRider(Rider rider)
    : nameController = TextEditingController(text: rider.riderName),
      coverageController = TextEditingController(
        text: rider.coverageAmount?.toString() ?? '',
      ),
      paymentTermController = TextEditingController(
        text: rider.paymentTerm ?? '',
      ),
      deductibleController = TextEditingController(
        text: rider.deductible?.toString() ?? '',
      ),
      waitingPeriodController = TextEditingController(
        text: rider.waitingPeriod ?? '',
      ),
      original = rider;

  final TextEditingController nameController;
  final TextEditingController coverageController;
  final TextEditingController paymentTermController;
  final TextEditingController deductibleController;
  final TextEditingController waitingPeriodController;
  final Rider? original;

  String? get id => original?.id;

  void dispose() {
    nameController.dispose();
    coverageController.dispose();
    paymentTermController.dispose();
    deductibleController.dispose();
    waitingPeriodController.dispose();
  }
}

class _RiderCard extends StatelessWidget {
  const _RiderCard({
    required this.draft,
    required this.index,
    required this.onRemove,
    required this.l10n,
  });

  final _RiderDraft draft;
  final int index;
  final VoidCallback onRemove;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Card(
      key: ValueKey<String>('rider-$index'),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s4),
        child: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: TextFormField(
                    controller: draft.nameController,
                    decoration: InputDecoration(labelText: l10n.rider_name),
                    textInputAction: TextInputAction.next,
                    validator: (String? value) =>
                        value == null || value.trim().isEmpty
                        ? l10n.rider_error_name_required
                        : null,
                  ),
                ),
                IconButton(
                  tooltip: l10n.plan_remove_rider,
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s2),
            _amountField(
              controller: draft.coverageController,
              label: l10n.rider_coverage_amount,
              textInputAction: TextInputAction.next,
              validator: (String? value) => _validateDraftAmount(value, l10n),
            ),
            const SizedBox(height: AppSpacing.s2),
            TextFormField(
              controller: draft.paymentTermController,
              decoration: InputDecoration(labelText: l10n.rider_payment_term),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: AppSpacing.s2),
            _amountField(
              controller: draft.deductibleController,
              label: l10n.rider_deductible,
              textInputAction: TextInputAction.next,
              validator: (String? value) => _validateDraftAmount(value, l10n),
            ),
            const SizedBox(height: AppSpacing.s2),
            TextFormField(
              controller: draft.waitingPeriodController,
              decoration: InputDecoration(labelText: l10n.rider_waiting_period),
              textInputAction: TextInputAction.done,
            ),
          ],
        ),
      ),
    );
  }
}

Widget _amountField({
  required TextEditingController controller,
  required String label,
  TextInputAction? textInputAction,
  FormFieldValidator<String>? validator,
}) {
  return TextFormField(
    controller: controller,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    textInputAction: textInputAction,
    decoration: InputDecoration(labelText: label),
    validator: validator,
  );
}

String? _validateDraftAmount(String? value, AppLocalizations l10n) {
  if (value == null || value.trim().isEmpty) {
    return null;
  }
  final amount = double.tryParse(value.trim());
  return amount == null || amount < 0
      ? l10n.plan_form_error_coverage_invalid
      : null;
}

double? _parseAmount(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : double.parse(trimmed);
}

String? _optionalText(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}
