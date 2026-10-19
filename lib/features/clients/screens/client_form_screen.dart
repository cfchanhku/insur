/// Hosts the localized create and edit client form.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../features/clients/models/client.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/app_providers.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../widgets/client_form.dart';

/// Route-level screen for creating or editing a client.
class ClientFormScreen extends ConsumerWidget {
  /// Creates the form screen; [id] selects edit mode when present.
  const ClientFormScreen({this.id, super.key});

  /// Existing client identifier for edit mode.
  final String? id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final title = id == null
        ? l10n.client_form_title_new
        : l10n.client_form_title_edit;
    final clientAsync = id == null ? null : ref.watch(clientByIdProvider(id!));

    return AppScaffold(
      title: title,
      showBottomNav: false,
      body: clientAsync == null
          ? _form(context, ref, null, l10n)
          : clientAsync.when(
              loading: () => const LoadingIndicator(),
              error: (Object error, StackTrace stackTrace) =>
                  ErrorState(message: l10n.error_generic),
              data: (Client? client) => client == null
                  ? ErrorState(message: l10n.client_not_found)
                  : _form(context, ref, client, l10n),
            ),
    );
  }

  Widget _form(
    BuildContext context,
    WidgetRef ref,
    Client? client,
    AppLocalizations l10n,
  ) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: ClientForm(
          initialClient: client,
          onCancel: () => context.pop(),
          onSaved: (Client value) async {
            final repository = await ref.read(clientRepositoryProvider.future);
            await repository.save(value);
            ref
              ..invalidate(clientListProvider)
              ..invalidate(clientPolicyCountsProvider);
            if (id != null) {
              ref.invalidate(clientByIdProvider(id!));
            }
            if (context.mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(l10n.client_form_saved)));
              context.pop();
            }
          },
        ),
      ),
    );
  }
}
