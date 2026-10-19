/// Shows policy information and the plans attached to it.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../l10n/app_localizations.dart';
import '../../../providers/app_providers.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../theme/app_theme.dart';
import '../../plans/widgets/plan_card.dart';
import '../models/policy.dart';
import '../models/policy_status.dart';

/// Full-screen details for a persisted policy.
class PolicyDetailScreen extends ConsumerStatefulWidget {
  /// Creates a policy detail screen for [id].
  const PolicyDetailScreen({required this.id, super.key});

  /// Persisted policy UUID.
  final String id;

  @override
  ConsumerState<PolicyDetailScreen> createState() => _PolicyDetailScreenState();
}

class _PolicyDetailScreenState extends ConsumerState<PolicyDetailScreen> {
  Future<void> _archive(String clientId) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await ConfirmDialog.showConfirmDialog(
      context: context,
      title: l10n.policy_archive_confirm_title,
      message: l10n.policy_archive_confirm_body,
      confirmLabel: l10n.policy_archive_confirm_action,
      cancelLabel: l10n.action_cancel,
      isDestructive: true,
    );
    if (!confirmed || !mounted) {
      return;
    }
    try {
      final repository = await ref.read(policyRepositoryProvider.future);
      await repository.archive(widget.id);
      ref
        ..invalidate(policiesByClientProvider(clientId))
        ..invalidate(archivedPoliciesProvider)
        ..invalidate(policyByIdProvider(widget.id));
      if (mounted) {
        context.pop();
      }
    } on Exception {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.error_generic)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final policyAsync = ref.watch(policyByIdProvider(widget.id));
    final policy = policyAsync.valueOrNull;
    return AppScaffold(
      title: policy?.policyNo ?? l10n.policy_detail_title,
      showBottomNav: false,
      actions: policy == null
          ? null
          : <Widget>[
              IconButton(
                tooltip: l10n.policy_edit,
                onPressed: () => context.push('/policies/${widget.id}/edit'),
                icon: const Icon(Icons.edit),
              ),
              PopupMenuButton<String>(
                tooltip: l10n.policy_archive,
                onSelected: (String value) {
                  if (value == 'archive') {
                    unawaited(_archive(policy.clientId));
                  }
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  PopupMenuItem<String>(
                    value: 'archive',
                    child: Text(l10n.policy_archive),
                  ),
                ],
              ),
            ],
      body: policyAsync.when(
        loading: () => const LoadingIndicator(),
        error: (Object error, StackTrace stackTrace) =>
            ErrorState(message: l10n.error_generic),
        data: (Policy? value) => value == null
            ? ErrorState(message: l10n.policy_not_found)
            : _PolicyDetails(policy: value),
      ),
    );
  }
}

class _PolicyDetails extends ConsumerWidget {
  const _PolicyDetails({required this.policy});

  final Policy policy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();
    final plans = ref.watch(plansByPolicyProvider(policy.id!));
    final status = switch (policy.status) {
      PolicyStatus.active => l10n.policy_status_active,
      PolicyStatus.lapsed => l10n.policy_status_lapsed,
      PolicyStatus.surrendered => l10n.policy_status_surrendered,
    };
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.s6),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.s6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        l10n.policy_info_section,
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: AppSpacing.s4),
                      _infoRow(context, l10n.policy_company, policy.company),
                      _infoRow(context, l10n.policy_no, policy.policyNo),
                      _infoRow(
                        context,
                        l10n.policy_effective_date,
                        DateFormat.yMd(locale).format(policy.effectiveDate),
                      ),
                      _infoRow(
                        context,
                        l10n.policy_first_premium_date,
                        DateFormat.yMd(locale).format(policy.firstPremiumDate),
                      ),
                      _infoRow(context, l10n.policy_currency, policy.currency),
                      _infoRow(context, l10n.policy_status, status),
                      if (policy.notes != null)
                        _infoRow(context, l10n.policy_notes, policy.notes!),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.s4),
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      l10n.policy_plans_section,
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () =>
                        context.push('/policies/${policy.id}/plans/new'),
                    icon: const Icon(Icons.add),
                    label: Text(l10n.policy_add_plan),
                  ),
                ],
              ),
              plans.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (Object error, StackTrace stackTrace) =>
                    Text(l10n.error_generic),
                data: (values) => values.isEmpty
                    ? Text(
                        l10n.policy_no_plans,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      )
                    : Column(
                        children: values
                            .map(
                              (plan) => PlanCard(
                                plan: plan,
                                onTap: plan.id == null
                                    ? null
                                    : () => context.push(
                                        '/plans/${plan.id}/edit',
                                      ),
                              ),
                            )
                            .toList(growable: false),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _infoRow(BuildContext context, String label, String value) {
  final theme = Theme.of(context);
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.s1),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          width: 160,
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(child: Text(value, style: theme.textTheme.bodyMedium)),
      ],
    ),
  );
}
