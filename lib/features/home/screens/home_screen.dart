/// Presents the client list and manages session inactivity locking.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/audit/audit_event_type.dart';
import '../../../features/clients/models/client.dart';
import '../../../features/clients/models/client_enums.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/app_providers.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../theme/app_theme.dart';
import '../../clients/widgets/client_card.dart';

/// Home route containing the searchable list of active clients.
class HomeScreen extends ConsumerStatefulWidget {
  /// Creates the home screen.
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String? _selectedClientId;

  Future<void> _lock() async {
    final audit = await ref.read(auditRepositoryProvider.future);
    await audit.append(eventType: AuditEventType.autoLock);
    final keyManager = await ref.read(keyManagerProvider.future);
    keyManager.onAudit = null;
    await keyManager.lock();
    if (!mounted) {
      return;
    }
    ref.read(keyManagerStateProvider.notifier).state = keyManager.state;
    context.go('/lock');
  }

  Future<void> _logout() async {
    final audit = await ref.read(auditRepositoryProvider.future);
    await audit.append(eventType: AuditEventType.logout);
    final keyManager = await ref.read(keyManagerProvider.future);
    keyManager.onAudit = null;
    await keyManager.logout();
    if (!mounted) {
      return;
    }
    ref.read(keyManagerStateProvider.notifier).state = keyManager.state;
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDesktop = MediaQuery.sizeOf(context).width > 1024;
    return AppScaffold(
      title: l10n.home_title,
      leading: Builder(
        builder: (BuildContext context) => IconButton(
          tooltip: l10n.nav_settings,
          onPressed: () => Scaffold.of(context).openDrawer(),
          icon: const Icon(Icons.menu),
        ),
      ),
      drawer: _buildDrawer(context, l10n),
      actions: <Widget>[
        IconButton(
          tooltip: l10n.home_lock,
          onPressed: _lock,
          icon: const Icon(Icons.lock),
        ),
        PopupMenuButton<String>(
          tooltip: l10n.home_logout,
          onSelected: (String value) {
            if (value == 'logout') {
              unawaited(_logout());
            }
          },
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            PopupMenuItem<String>(
              value: 'logout',
              child: Text(l10n.home_logout),
            ),
          ],
        ),
      ],
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/clients/new'),
        icon: const Icon(Icons.add),
        label: Text(l10n.home_add_client),
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.s4,
              AppSpacing.s3,
              AppSpacing.s4,
              AppSpacing.s2,
            ),
            child: TextField(
              onChanged: (String value) =>
                  ref.read(clientSearchQueryProvider.notifier).state = value,
              decoration: InputDecoration(
                hintText: l10n.home_search_hint,
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: AppSpacing.s2,
                children: <Widget>[
                  ChoiceChip(
                    label: Text(l10n.home_filter_all),
                    selected: ref.watch(clientFilterProvider) == null,
                    onSelected: (_) =>
                        ref.read(clientFilterProvider.notifier).state = null,
                  ),
                  ChoiceChip(
                    label: Text(l10n.home_filter_holder),
                    selected:
                        ref.watch(clientFilterProvider) == ClientRole.holder,
                    onSelected: (bool selected) =>
                        ref.read(clientFilterProvider.notifier).state = selected
                        ? ClientRole.holder
                        : null,
                  ),
                  ChoiceChip(
                    label: Text(l10n.home_filter_insured),
                    selected:
                        ref.watch(clientFilterProvider) == ClientRole.insured,
                    onSelected: (bool selected) =>
                        ref.read(clientFilterProvider.notifier).state = selected
                        ? ClientRole.insured
                        : null,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.s2),
          Expanded(child: _clientResults(context, l10n, isDesktop)),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, AppLocalizations l10n) {
    return Builder(
      builder: (BuildContext drawerContext) => NavigationDrawer(
        onDestinationSelected: (int index) {
          Navigator.of(drawerContext).pop();
          switch (index) {
            case 0:
              context.go('/home');
              return;
            case 1:
              context.go('/archive');
              return;
            case 2:
              context.go('/settings');
              return;
          }
        },
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 16, 16, 10),
            child: Text(
              l10n.app_title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          NavigationDrawerDestination(
            icon: const Icon(Icons.people),
            label: Text(l10n.nav_home),
          ),
          NavigationDrawerDestination(
            icon: const Icon(Icons.archive),
            label: Text(l10n.nav_archive),
          ),
          NavigationDrawerDestination(
            icon: const Icon(Icons.settings),
            label: Text(l10n.nav_settings),
          ),
        ],
      ),
    );
  }

  Widget _clientResults(
    BuildContext context,
    AppLocalizations l10n,
    bool isDesktop,
  ) {
    final clientsAsync = ref.watch(filteredClientsProvider);
    final allClientsAsync = ref.watch(clientListProvider);
    final policyCountsAsync = ref.watch(clientPolicyCountsProvider);

    return clientsAsync.when(
      loading: () => const LoadingIndicator(),
      error: (Object error, StackTrace stackTrace) => ErrorState(
        message: l10n.home_load_error(l10n.error_generic),
        onRetry: () {
          ref
            ..invalidate(clientListProvider)
            ..invalidate(clientPolicyCountsProvider);
        },
      ),
      data: (List<Client> clients) => policyCountsAsync.when(
        loading: () => const LoadingIndicator(),
        error: (Object error, StackTrace stackTrace) =>
            ErrorState(message: l10n.error_generic),
        data: (Map<String, int> policyCounts) {
          final allClients = allClientsAsync.valueOrNull ?? <Client>[];
          if (allClients.isEmpty) {
            return EmptyState(
              icon: Icons.people_outline,
              title: l10n.home_empty_title,
              subtitle: l10n.home_empty_subtitle,
              action: FilledButton.icon(
                onPressed: () => context.push('/clients/new'),
                icon: const Icon(Icons.add),
                label: Text(l10n.home_add_client),
              ),
            );
          }
          if (clients.isEmpty) {
            return EmptyState(
              icon: Icons.search_off,
              title: l10n.home_no_match,
              subtitle: '',
            );
          }

          if (isDesktop) {
            Client? selected;
            for (final client in clients) {
              if (client.id == _selectedClientId) {
                selected = client;
                break;
              }
            }
            return Row(
              children: <Widget>[
                SizedBox(
                  width: 420,
                  child: _buildClientList(clients, policyCounts, isDesktop),
                ),
                const VerticalDivider(width: 1),
                Expanded(
                  child: selected == null
                      ? EmptyState(
                          icon: Icons.person_outline,
                          title: l10n.home_detail_prompt,
                          subtitle: '',
                        )
                      : _buildDesktopDetail(
                          context,
                          selected,
                          policyCounts[selected.id] ?? 0,
                          l10n,
                        ),
                ),
              ],
            );
          }
          return _buildClientList(clients, policyCounts, isDesktop);
        },
      ),
    );
  }

  Widget _buildClientList(
    List<Client> clients,
    Map<String, int> policyCounts,
    bool isDesktop,
  ) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s4,
        AppSpacing.s2,
        AppSpacing.s4,
        96,
      ),
      itemCount: clients.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.s2),
      itemBuilder: (BuildContext context, int index) {
        final client = clients[index];
        final id = client.id;
        return ClientCard(
          client: client,
          policyCount: id == null ? 0 : policyCounts[id] ?? 0,
          onTap: id == null
              ? null
              : () {
                  if (isDesktop) {
                    setState(() => _selectedClientId = id);
                  } else {
                    unawaited(context.push('/clients/$id'));
                  }
                },
        );
      },
    );
  }

  Widget _buildDesktopDetail(
    BuildContext context,
    Client client,
    int policyCount,
    AppLocalizations l10n,
  ) {
    final theme = Theme.of(context);
    final role = switch (client.role) {
      ClientRole.holder => l10n.client_role_holder,
      ClientRole.insured => l10n.client_role_insured,
    };
    final initials = client.name.trim().isEmpty
        ? ''
        : client.name.trim().substring(0, 1).toUpperCase();
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Card(
          margin: const EdgeInsets.all(AppSpacing.s6),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.s6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Text(initials),
                    ),
                    const SizedBox(width: AppSpacing.s4),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(client.name, style: theme.textTheme.titleLarge),
                          Text(role, style: theme.textTheme.bodyMedium),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.s4),
                Text(
                  '${l10n.client_dob}: ${DateFormat.yMd(Localizations.localeOf(context).toString()).format(client.dob)}',
                ),
                if (client.phone != null)
                  Text('${l10n.client_phone}: ${client.phone}'),
                if (client.email != null)
                  Text('${l10n.client_email}: ${client.email}'),
                const SizedBox(height: AppSpacing.s2),
                Text(l10n.home_policy_count(policyCount)),
                const SizedBox(height: AppSpacing.s4),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(
                    onPressed: () => context.push('/clients/${client.id}'),
                    child: Text(l10n.home_open_details),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
