/// Lists, restores, and permanently deletes archived records.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../features/clients/models/client.dart';
import '../../../features/clients/models/client_enums.dart';
import '../../../features/plans/models/plan.dart';
import '../../../features/plans/models/plan_category.dart';
import '../../../features/policies/models/policy.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/app_providers.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../theme/app_theme.dart';

/// Archive navigation destination containing archived clients, policies, and plans.
class ArchiveScreen extends ConsumerStatefulWidget {
  /// Creates the archive screen.
  const ArchiveScreen({super.key});

  @override
  ConsumerState<ArchiveScreen> createState() => _ArchiveScreenState();
}

class _ArchiveScreenState extends ConsumerState<ArchiveScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppScaffold(
      title: l10n.archive_title,
      currentNavIndex: 1,
      body: Column(
        children: <Widget>[
          TabBar(
            controller: _tabController,
            tabs: <Widget>[
              Tab(text: l10n.archive_tab_clients),
              Tab(text: l10n.archive_tab_policies),
              Tab(text: l10n.archive_tab_plans),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const <Widget>[
                _ArchivedClientsTab(),
                _ArchivedPoliciesTab(),
                _ArchivedPlansTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ArchivedClientsTab extends ConsumerWidget {
  const _ArchivedClientsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return _archiveList<Client>(
      context: context,
      value: ref.watch(archivedClientsProvider),
      emptyMessage: l10n.archive_empty_clients,
      records: (List<Client> clients) => clients
          .map(
            (Client client) => _ArchivedRecordCard(
              title: client.name,
              subtitle: _subtitle(
                context,
                _clientRoleLabel(l10n, client.role),
                client.archivedAt,
              ),
              restore: () => unawaited(_restoreClient(context, ref, client)),
              delete: () => unawaited(_deleteClient(context, ref, client)),
              l10n: l10n,
            ),
          )
          .toList(growable: false),
    );
  }
}

class _ArchivedPoliciesTab extends ConsumerWidget {
  const _ArchivedPoliciesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return _archiveList<Policy>(
      context: context,
      value: ref.watch(archivedPoliciesProvider),
      emptyMessage: l10n.archive_empty_policies,
      records: (List<Policy> policies) => policies
          .map(
            (Policy policy) => _ArchivedRecordCard(
              title: policy.policyNo,
              subtitle: _subtitle(context, policy.company, policy.archivedAt),
              restore: () => unawaited(_restorePolicy(context, ref, policy)),
              delete: () => unawaited(_deletePolicy(context, ref, policy)),
              l10n: l10n,
            ),
          )
          .toList(growable: false),
    );
  }
}

class _ArchivedPlansTab extends ConsumerWidget {
  const _ArchivedPlansTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return _archiveList<Plan>(
      context: context,
      value: ref.watch(archivedPlansProvider),
      emptyMessage: l10n.archive_empty_plans,
      records: (List<Plan> plans) => plans
          .map(
            (Plan plan) => _ArchivedRecordCard(
              leading: Icon(_planIcon(plan.category)),
              title: plan.planName,
              subtitle: _subtitle(
                context,
                _planCategoryLabel(l10n, plan.category),
                plan.archivedAt,
              ),
              restore: () => unawaited(_restorePlan(context, ref, plan)),
              delete: () => unawaited(_deletePlan(context, ref, plan)),
              l10n: l10n,
            ),
          )
          .toList(growable: false),
    );
  }
}

Widget _archiveList<T>({
  required BuildContext context,
  required AsyncValue<List<T>> value,
  required String emptyMessage,
  required List<Widget> Function(List<T> records) records,
}) {
  final l10n = AppLocalizations.of(context);
  return value.when(
    loading: () => const LoadingIndicator(),
    error: (Object error, StackTrace stackTrace) =>
        Center(child: Text(l10n.error_generic)),
    data: (List<T> values) {
      if (values.isEmpty) {
        return Center(
          child: Text(
            emptyMessage,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        );
      }
      final items = records(values);
      return ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.s4),
        itemCount: items.length,
        separatorBuilder: (BuildContext context, int index) =>
            const SizedBox(height: AppSpacing.s2),
        itemBuilder: (BuildContext context, int index) => items[index],
      );
    },
  );
}

class _ArchivedRecordCard extends StatelessWidget {
  const _ArchivedRecordCard({
    required this.title,
    required this.subtitle,
    required this.restore,
    required this.delete,
    required this.l10n,
    this.leading,
  });

  final String title;
  final Widget subtitle;
  final VoidCallback restore;
  final VoidCallback delete;
  final AppLocalizations l10n;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      child: ListTile(
        leading: leading,
        title: Text(title),
        subtitle: subtitle,
        isThreeLine: true,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            IconButton(
              tooltip: l10n.archive_restore,
              onPressed: restore,
              color: colors.primary,
              icon: const Icon(Icons.restore),
            ),
            IconButton(
              tooltip: l10n.archive_delete,
              onPressed: delete,
              color: colors.error,
              icon: const Icon(Icons.delete_forever),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _subtitle(BuildContext context, String detail, DateTime? archivedAt) {
  final locale = Localizations.localeOf(context).toString();
  final date = archivedAt == null
      ? '—'
      : DateFormat.yMd(locale).format(archivedAt);
  final l10n = AppLocalizations.of(context);
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[Text(detail), Text(l10n.archive_archived_on(date))],
  );
}

String _clientRoleLabel(AppLocalizations l10n, ClientRole role) =>
    switch (role) {
      ClientRole.holder => l10n.client_role_holder,
      ClientRole.insured => l10n.client_role_insured,
    };

String _planCategoryLabel(AppLocalizations l10n, PlanCategory category) =>
    switch (category) {
      PlanCategory.life => l10n.plan_category_life,
      PlanCategory.ci => l10n.plan_category_ci,
      PlanCategory.hospital => l10n.plan_category_hospital,
      PlanCategory.accident => l10n.plan_category_accident,
      PlanCategory.savings => l10n.plan_category_savings,
      PlanCategory.other => l10n.plan_category_other,
    };

IconData _planIcon(PlanCategory category) => switch (category) {
  PlanCategory.life => Icons.favorite_outline,
  PlanCategory.ci => Icons.health_and_safety_outlined,
  PlanCategory.hospital => Icons.local_hospital_outlined,
  PlanCategory.accident => Icons.warning_amber_outlined,
  PlanCategory.savings => Icons.savings_outlined,
  PlanCategory.other => Icons.more_horiz,
};

Future<bool> _confirmRestore(BuildContext context, AppLocalizations l10n) =>
    ConfirmDialog.showConfirmDialog(
      context: context,
      title: l10n.archive_restore_confirm_title,
      message: l10n.archive_restore_confirm_body,
      confirmLabel: l10n.archive_restore_confirm_action,
      cancelLabel: l10n.archive_delete_cancel,
    );

Future<bool> _confirmPermanentDelete(
  BuildContext context,
  AppLocalizations l10n,
) async {
  final firstConfirmation = await ConfirmDialog.showConfirmDialog(
    context: context,
    title: l10n.archive_delete_confirm_title,
    message: l10n.archive_delete_confirm_body_1,
    confirmLabel: l10n.archive_delete_continue,
    cancelLabel: l10n.archive_delete_cancel,
    isDestructive: true,
  );
  if (!firstConfirmation || !context.mounted) {
    return false;
  }
  return ConfirmDialog.showConfirmDialog(
    context: context,
    title: l10n.archive_delete_confirm_title,
    message: l10n.archive_delete_confirm_body_2,
    confirmLabel: l10n.archive_delete_final,
    cancelLabel: l10n.archive_delete_cancel,
    isDestructive: true,
  );
}

Future<void> _restoreClient(
  BuildContext context,
  WidgetRef ref,
  Client client,
) async {
  final l10n = AppLocalizations.of(context);
  if (!await _confirmRestore(context, l10n) || !context.mounted) {
    return;
  }
  try {
    await (await ref.read(clientRepositoryProvider.future)).restore(client.id!);
    ref
      ..invalidate(archivedClientsProvider)
      ..invalidate(clientListProvider)
      ..invalidate(clientByIdProvider(client.id!))
      ..invalidate(clientPolicyCountsProvider);
    if (context.mounted) {
      _showMessage(context, l10n.archive_restore_success);
    }
  } on Exception {
    if (context.mounted) {
      _showMessage(context, l10n.archive_error_restore(l10n.error_generic));
    }
  }
}

Future<void> _deleteClient(
  BuildContext context,
  WidgetRef ref,
  Client client,
) async {
  final l10n = AppLocalizations.of(context);
  if (!await _confirmPermanentDelete(context, l10n) || !context.mounted) {
    return;
  }
  try {
    await (await ref.read(clientRepositoryProvider.future)).delete(client.id!);
    ref
      ..invalidate(archivedClientsProvider)
      ..invalidate(clientListProvider)
      ..invalidate(clientByIdProvider(client.id!))
      ..invalidate(clientPolicyCountsProvider)
      ..invalidate(archivedPoliciesProvider)
      ..invalidate(archivedPlansProvider);
    if (context.mounted) {
      _showMessage(context, l10n.archive_delete_success);
    }
  } on Exception {
    if (context.mounted) {
      _showMessage(context, l10n.archive_error_delete(l10n.error_generic));
    }
  }
}

Future<void> _restorePolicy(
  BuildContext context,
  WidgetRef ref,
  Policy policy,
) async {
  final l10n = AppLocalizations.of(context);
  if (!await _confirmRestore(context, l10n) || !context.mounted) {
    return;
  }
  try {
    await (await ref.read(policyRepositoryProvider.future)).restore(policy.id!);
    ref
      ..invalidate(archivedPoliciesProvider)
      ..invalidate(policiesByClientProvider(policy.clientId))
      ..invalidate(policyByIdProvider(policy.id!))
      ..invalidate(clientPolicyCountProvider(policy.clientId))
      ..invalidate(clientPolicyCountsProvider);
    if (context.mounted) {
      _showMessage(context, l10n.archive_restore_success);
    }
  } on Exception {
    if (context.mounted) {
      _showMessage(context, l10n.archive_error_restore(l10n.error_generic));
    }
  }
}

Future<void> _deletePolicy(
  BuildContext context,
  WidgetRef ref,
  Policy policy,
) async {
  final l10n = AppLocalizations.of(context);
  if (!await _confirmPermanentDelete(context, l10n) || !context.mounted) {
    return;
  }
  try {
    await (await ref.read(policyRepositoryProvider.future)).delete(policy.id!);
    ref
      ..invalidate(archivedPoliciesProvider)
      ..invalidate(policiesByClientProvider(policy.clientId))
      ..invalidate(policyByIdProvider(policy.id!))
      ..invalidate(clientPolicyCountProvider(policy.clientId))
      ..invalidate(clientPolicyCountsProvider)
      ..invalidate(archivedPlansProvider)
      ..invalidate(plansByPolicyProvider(policy.id!));
    if (context.mounted) {
      _showMessage(context, l10n.archive_delete_success);
    }
  } on Exception {
    if (context.mounted) {
      _showMessage(context, l10n.archive_error_delete(l10n.error_generic));
    }
  }
}

Future<void> _restorePlan(
  BuildContext context,
  WidgetRef ref,
  Plan plan,
) async {
  final l10n = AppLocalizations.of(context);
  if (!await _confirmRestore(context, l10n) || !context.mounted) {
    return;
  }
  try {
    await (await ref.read(planRepositoryProvider.future)).restore(plan.id!);
    ref
      ..invalidate(archivedPlansProvider)
      ..invalidate(plansByPolicyProvider(plan.policyId))
      ..invalidate(planByIdProvider(plan.id!));
    if (context.mounted) {
      _showMessage(context, l10n.archive_restore_success);
    }
  } on Exception {
    if (context.mounted) {
      _showMessage(context, l10n.archive_error_restore(l10n.error_generic));
    }
  }
}

Future<void> _deletePlan(BuildContext context, WidgetRef ref, Plan plan) async {
  final l10n = AppLocalizations.of(context);
  if (!await _confirmPermanentDelete(context, l10n) || !context.mounted) {
    return;
  }
  try {
    await (await ref.read(planRepositoryProvider.future)).delete(plan.id!);
    ref
      ..invalidate(archivedPlansProvider)
      ..invalidate(plansByPolicyProvider(plan.policyId))
      ..invalidate(planByIdProvider(plan.id!))
      ..invalidate(ridersByPlanProvider(plan.id!));
    if (context.mounted) {
      _showMessage(context, l10n.archive_delete_success);
    }
  } on Exception {
    if (context.mounted) {
      _showMessage(context, l10n.archive_error_delete(l10n.error_generic));
    }
  }
}

void _showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
