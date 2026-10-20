/// Presents the client list and manages session inactivity locking.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/audit/audit_event_type.dart';
import '../../../features/clients/models/client.dart';
import '../../../features/clients/models/client_enums.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/app_providers.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/skeletons.dart';
import '../../../theme/app_theme.dart';
import '../../clients/screens/client_detail_screen.dart';
import '../../clients/widgets/client_card.dart';

/// Home route containing the searchable list of active clients.
class HomeScreen extends ConsumerStatefulWidget {
  /// Creates the home screen.
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final FocusNode _searchFocusNode = FocusNode();
  final TextEditingController _searchController = TextEditingController();
  String? _selectedClientId;

  bool _isDesktop(BuildContext context) => switch (Theme.of(context).platform) {
    TargetPlatform.windows ||
    TargetPlatform.macOS ||
    TargetPlatform.linux => true,
    _ => false,
  };

  bool get _isEditingText {
    final focusContext = FocusManager.instance.primaryFocus?.context;
    return _searchFocusNode.hasFocus || focusContext?.widget is EditableText;
  }

  void _handleEscape(BuildContext context) {
    if (_isEditingText) {
      if (_searchController.text.isNotEmpty) {
        _searchController.clear();
        ref.read(clientSearchQueryProvider.notifier).state = '';
      } else {
        _searchFocusNode.unfocus();
      }
      return;
    }
    if (context.canPop()) {
      context.pop();
    }
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

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
    final width = MediaQuery.sizeOf(context).width;
    final hasDetailPane = width > 600;
    final isDesktop = width > 1024;
    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.keyN, control: true): () {
          if (_isDesktop(context) && !_isEditingText) {
            unawaited(context.push('/clients/new'));
          }
        },
        const SingleActivator(LogicalKeyboardKey.keyN, meta: true): () {
          if (_isDesktop(context) && !_isEditingText) {
            unawaited(context.push('/clients/new'));
          }
        },
        const SingleActivator(LogicalKeyboardKey.keyF, control: true): () {
          if (_isDesktop(context)) {
            _searchFocusNode.requestFocus();
          }
        },
        const SingleActivator(LogicalKeyboardKey.keyF, meta: true): () {
          if (_isDesktop(context)) {
            _searchFocusNode.requestFocus();
          }
        },
        const SingleActivator(LogicalKeyboardKey.keyL, control: true): () {
          if (_isDesktop(context) && !_isEditingText) {
            unawaited(_lock());
          }
        },
        const SingleActivator(LogicalKeyboardKey.keyL, meta: true): () {
          if (_isDesktop(context) && !_isEditingText) {
            unawaited(_lock());
          }
        },
        const SingleActivator(LogicalKeyboardKey.escape): () {
          if (_isDesktop(context)) {
            _handleEscape(context);
          }
        },
      },
      child: Focus(
        autofocus: true,
        child: AppScaffold(
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
              tooltip: l10n.export_pdf_title,
              onPressed: () => context.push('/export'),
              icon: const Icon(Icons.ios_share),
            ),
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
                  key: const ValueKey<String>('home-search'),
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  onChanged: (String value) =>
                      ref.read(clientSearchQueryProvider.notifier).state =
                          value,
                  decoration: InputDecoration(
                    hintText: l10n.home_search_hint,
                    labelText: l10n.home_search_hint,
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
                            ref.read(clientFilterProvider.notifier).state =
                                null,
                      ),
                      ChoiceChip(
                        label: Text(l10n.home_filter_holder),
                        selected:
                            ref.watch(clientFilterProvider) ==
                            ClientRole.holder,
                        onSelected: (bool selected) =>
                            ref.read(clientFilterProvider.notifier).state =
                                selected ? ClientRole.holder : null,
                      ),
                      ChoiceChip(
                        label: Text(l10n.home_filter_insured),
                        selected:
                            ref.watch(clientFilterProvider) ==
                            ClientRole.insured,
                        onSelected: (bool selected) =>
                            ref.read(clientFilterProvider.notifier).state =
                                selected ? ClientRole.insured : null,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.s2),
              Expanded(
                child: _clientResults(context, l10n, hasDetailPane, isDesktop),
              ),
            ],
          ),
        ),
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
    bool hasDetailPane,
    bool isDesktop,
  ) {
    final clientsAsync = ref.watch(filteredClientsProvider);
    final allClientsAsync = ref.watch(clientListProvider);
    final policyCountsAsync = ref.watch(clientPolicyCountsProvider);

    return clientsAsync.when(
      loading: () => const ClientListSkeleton(),
      error: (Object error, StackTrace stackTrace) => ErrorState(
        message: l10n.home_load_error(l10n.error_generic),
        onRetry: () {
          ref
            ..invalidate(clientListProvider)
            ..invalidate(clientPolicyCountsProvider);
        },
      ),
      data: (List<Client> clients) => policyCountsAsync.when(
        loading: () => const ClientListSkeleton(),
        error: (Object error, StackTrace stackTrace) => ErrorState(
          message: l10n.error_generic,
          onRetry: () {
            ref
              ..invalidate(clientListProvider)
              ..invalidate(clientPolicyCountsProvider);
          },
        ),
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

          if (hasDetailPane) {
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
                  width: isDesktop ? 400 : 320,
                  child: _buildClientList(
                    clients,
                    policyCounts,
                    l10n: l10n,
                    hasDetailPane: hasDetailPane,
                    isDesktop: isDesktop,
                  ),
                ),
                const VerticalDivider(width: 1),
                Expanded(
                  child: selected == null
                      ? EmptyState(
                          icon: Icons.person_outline,
                          title: l10n.home_detail_prompt,
                          subtitle: '',
                        )
                      : ClientDetailScreen(id: selected.id!, embedded: true),
                ),
              ],
            );
          }
          return _buildClientList(
            clients,
            policyCounts,
            l10n: l10n,
            hasDetailPane: hasDetailPane,
            isDesktop: isDesktop,
          );
        },
      ),
    );
  }

  Widget _buildClientList(
    List<Client> clients,
    Map<String, int> policyCounts, {
    required AppLocalizations l10n,
    required bool hasDetailPane,
    required bool isDesktop,
  }) {
    return RefreshIndicator(
      onRefresh: () async {
        ref
          ..invalidate(clientListProvider)
          ..invalidate(clientPolicyCountsProvider);
        await Future.wait<void>(<Future<void>>[
          ref.read(clientListProvider.future).then<void>((_) {}),
          ref.read(clientPolicyCountsProvider.future).then<void>((_) {}),
        ]);
      },
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
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
          final card = ClientCard(
            client: client,
            policyCount: id == null ? 0 : policyCounts[id] ?? 0,
            onTap: id == null
                ? null
                : () {
                    if (hasDetailPane) {
                      setState(() => _selectedClientId = id);
                    } else {
                      unawaited(context.push('/clients/$id'));
                    }
                  },
          ).animate().fadeIn(duration: 180.ms).slideY(begin: 0.02);
          if (id == null || MediaQuery.sizeOf(context).width > 600) {
            return card;
          }
          return Dismissible(
            key: ValueKey<String>(id),
            direction: DismissDirection.endToStart,
            background: _archiveBackground(context),
            confirmDismiss: (_) => ConfirmDialog.showConfirmDialog(
              context: context,
              title: AppLocalizations.of(context).client_archive_confirm_title,
              message: AppLocalizations.of(context).client_archive_confirm_body,
              confirmLabel: AppLocalizations.of(
                context,
              ).client_archive_confirm_action,
              cancelLabel: AppLocalizations.of(context).client_archive_cancel,
              isDestructive: true,
              icon: Icons.archive_outlined,
            ),
            onDismissed: (_) => _archiveClient(id, context, l10n),
            child: card,
          );
        },
      ),
    );
  }

  Future<void> _archiveClient(
    String id,
    BuildContext context,
    AppLocalizations l10n,
  ) async {
    try {
      final repository = await ref.read(clientRepositoryProvider.future);
      await repository.archive(id);
      ref
        ..invalidate(clientListProvider)
        ..invalidate(clientPolicyCountsProvider)
        ..invalidate(archivedClientsProvider);
      if (context.mounted) {
        AppSnackBar.showSuccess(context, l10n.client_archived_snack);
      }
    } on Exception {
      if (context.mounted) {
        AppSnackBar.showError(context, l10n.client_archive_error);
      }
      ref.invalidate(clientListProvider);
    }
  }
}

Widget _archiveBackground(BuildContext context) => Container(
  color: Theme.of(context).colorScheme.error,
  alignment: Alignment.centerRight,
  padding: const EdgeInsets.only(right: AppSpacing.s5),
  child: Icon(
    Icons.archive_outlined,
    color: Theme.of(context).colorScheme.onError,
  ),
);
