/// Displays a client's decrypted profile and related policy section.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../features/clients/models/client.dart';
import '../../../features/clients/models/client_enums.dart';
import '../../../features/policies/models/policy.dart';
import '../../../features/policies/widgets/policy_card.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/app_providers.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/skeletons.dart';
import '../../../theme/app_theme.dart';

/// Full-screen view of one persisted client.
class ClientDetailScreen extends ConsumerStatefulWidget {
  /// Creates a client detail screen for [id].
  const ClientDetailScreen({
    required this.id,
    this.embedded = false,
    super.key,
  });

  /// Persisted client identifier.
  final String id;

  /// Whether this detail is shown inside the Home master-detail pane.
  final bool embedded;

  @override
  ConsumerState<ClientDetailScreen> createState() => _ClientDetailScreenState();
}

class _ClientDetailScreenState extends ConsumerState<ClientDetailScreen> {
  Future<void> _archive() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await ConfirmDialog.showConfirmDialog(
      context: context,
      title: l10n.client_archive_confirm_title,
      message: l10n.client_archive_confirm_body,
      confirmLabel: l10n.client_archive_confirm_action,
      cancelLabel: l10n.client_archive_cancel,
      isDestructive: true,
    );
    if (!confirmed || !mounted) {
      return;
    }

    try {
      final repository = await ref.read(clientRepositoryProvider.future);
      await repository.archive(widget.id);
      ref
        ..invalidate(clientListProvider)
        ..invalidate(archivedClientsProvider)
        ..invalidate(clientPolicyCountsProvider)
        ..invalidate(clientByIdProvider(widget.id));
      if (mounted) {
        context.pop();
      }
    } on Exception {
      _showArchiveError(l10n);
    }
  }

  void _showArchiveError(AppLocalizations l10n) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.client_archive_error)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final clientAsync = ref.watch(clientByIdProvider(widget.id));
    final client = clientAsync.valueOrNull;

    final body = clientAsync.when(
      loading: () => const LoadingIndicator(),
      error: (Object error, StackTrace stackTrace) => ErrorState(
        message: l10n.error_generic,
        onRetry: () => ref.invalidate(clientByIdProvider(widget.id)),
      ),
      data: (Client? data) => data == null
          ? ErrorState(message: l10n.client_not_found)
          : _ClientDetails(client: data),
    );
    if (widget.embedded) {
      return body;
    }
    return AppScaffold(
      title: client?.name ?? l10n.client_detail_title,
      showBottomNav: false,
      actions: client == null
          ? null
          : <Widget>[
              IconButton(
                tooltip: l10n.client_edit,
                onPressed: () => context.push('/clients/${widget.id}/edit'),
                icon: const Icon(Icons.edit),
              ),
              PopupMenuButton<String>(
                tooltip: l10n.client_archive,
                onSelected: (String value) {
                  if (value == 'archive') {
                    unawaited(_archive());
                  }
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  PopupMenuItem<String>(
                    value: 'archive',
                    child: Text(l10n.client_archive),
                  ),
                ],
              ),
            ],
      body: body,
    );
  }
}

class _ClientDetails extends ConsumerWidget {
  const _ClientDetails({required this.client});

  final Client client;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final role = switch (client.role) {
      ClientRole.holder => l10n.client_role_holder,
      ClientRole.insured => l10n.client_role_insured,
    };
    final gender = switch (client.gender) {
      Gender.male => l10n.gender_male,
      Gender.female => l10n.gender_female,
      Gender.other => l10n.gender_other,
    };
    final initials = client.name.trim().isEmpty
        ? ''
        : client.name.trim().substring(0, 1).toUpperCase();
    final policies = client.id == null
        ? const AsyncValue<List<Policy>>.data(<Policy>[])
        : ref.watch(policiesByClientProvider(client.id!));

    return RefreshIndicator(
      onRefresh: client.id == null
          ? () async {}
          : () async {
              ref.invalidate(policiesByClientProvider(client.id!));
              await ref.read(policiesByClientProvider(client.id!).future);
            },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
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
                          l10n.client_info_section,
                          style: theme.textTheme.titleLarge,
                        ),
                        const SizedBox(height: AppSpacing.s4),
                        Row(
                          children: <Widget>[
                            CircleAvatar(
                              radius: 32,
                              backgroundColor:
                                  theme.colorScheme.primaryContainer,
                              child: Text(
                                initials,
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  color: theme.colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.s4),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    client.name,
                                    style: theme.textTheme.titleLarge,
                                  ),
                                  Text(
                                    role,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: AppSpacing.s8),
                        _infoRow(context, l10n.client_gender, gender),
                        _infoRow(
                          context,
                          l10n.client_dob,
                          DateFormat.yMd(
                            Localizations.localeOf(context).toString(),
                          ).format(client.dob),
                        ),
                        _infoRow(
                          context,
                          l10n.client_phone,
                          client.phone ?? '—',
                        ),
                        _infoRow(
                          context,
                          l10n.client_email,
                          client.email ?? '—',
                        ),
                        _infoRow(
                          context,
                          l10n.client_notes,
                          client.notes ?? '—',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.s4),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.s6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                l10n.client_policies_section,
                                style: theme.textTheme.titleLarge,
                              ),
                            ),
                            TextButton.icon(
                              onPressed: client.id == null
                                  ? null
                                  : () => context.push(
                                      '/clients/${client.id}/policies/new',
                                    ),
                              icon: const Icon(Icons.add),
                              label: Text(l10n.client_add_policy),
                            ),
                          ],
                        ),
                        policies.when(
                          loading: () => const PolicyListSkeleton(),
                          error: (Object error, StackTrace stackTrace) =>
                              ErrorState(
                                message: l10n.error_generic,
                                onRetry: client.id == null
                                    ? null
                                    : () => ref.invalidate(
                                        policiesByClientProvider(client.id!),
                                      ),
                              ),
                          data: (List<Policy> policies) => policies.isEmpty
                              ? Text(
                                  l10n.client_no_policies,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                )
                              : Column(
                                  children: policies
                                      .map<Widget>((Policy policy) {
                                        final card = PolicyCard(
                                          policy: policy,
                                          onTap: policy.id == null
                                              ? null
                                              : () => context.push(
                                                  '/policies/${policy.id}',
                                                ),
                                        ).animate().fadeIn(duration: 180.ms);
                                        if (policy.id == null ||
                                            MediaQuery.sizeOf(context).width >
                                                600) {
                                          return card;
                                        }
                                        return Dismissible(
                                          key: ValueKey<String>(policy.id!),
                                          direction:
                                              DismissDirection.endToStart,
                                          background: Container(
                                            color: theme.colorScheme.error,
                                            alignment: Alignment.centerRight,
                                            padding: const EdgeInsets.only(
                                              right: AppSpacing.s5,
                                            ),
                                            child: Icon(
                                              Icons.archive_outlined,
                                              color: theme.colorScheme.onError,
                                            ),
                                          ),
                                          confirmDismiss: (_) =>
                                              ConfirmDialog.showConfirmDialog(
                                                context: context,
                                                title: l10n
                                                    .policy_archive_confirm_title,
                                                message: l10n
                                                    .policy_archive_confirm_body,
                                                confirmLabel: l10n
                                                    .policy_archive_confirm_action,
                                                isDestructive: true,
                                                icon: Icons.archive_outlined,
                                              ),
                                          onDismissed: (_) async {
                                            try {
                                              final repository = await ref.read(
                                                policyRepositoryProvider.future,
                                              );
                                              await repository.archive(
                                                policy.id!,
                                              );
                                              ref
                                                ..invalidate(
                                                  policiesByClientProvider(
                                                    client.id!,
                                                  ),
                                                )
                                                ..invalidate(
                                                  archivedPoliciesProvider,
                                                );
                                              if (context.mounted) {
                                                AppSnackBar.showSuccess(
                                                  context,
                                                  l10n.policy_archived_snack,
                                                );
                                              }
                                            } on Exception {
                                              if (context.mounted) {
                                                AppSnackBar.showError(
                                                  context,
                                                  l10n.error_generic,
                                                );
                                              }
                                              ref.invalidate(
                                                policiesByClientProvider(
                                                  client.id!,
                                                ),
                                              );
                                            }
                                          },
                                          child: card,
                                        );
                                      })
                                      .toList(growable: false),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.s4),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.s6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          l10n.client_reviews_section,
                          style: theme.textTheme.titleLarge,
                        ),
                        const SizedBox(height: AppSpacing.s2),
                        Text(
                          l10n.client_no_reviews,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 120,
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
}
