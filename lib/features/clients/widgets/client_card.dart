/// Presents a concise, privacy-aware client summary.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../l10n/app_localizations.dart';

import '../models/client.dart';
import '../models/client_enums.dart';

/// Reusable client summary card.
class ClientCard extends ConsumerWidget {
  /// Creates a client card for [client].
  const ClientCard({
    required this.client,
    required this.policyCount,
    this.onTap,
    super.key,
  });

  /// Client displayed by the card.
  final Client client;

  /// Number of active policies belonging to [client].
  final int policyCount;

  /// Optional tap callback.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final role = switch (client.role) {
      ClientRole.holder => l10n.client_role_holder,
      ClientRole.insured => l10n.client_role_insured,
    };
    final date = DateFormat.yMd(
      Localizations.localeOf(context).toString(),
    ).format(client.dob);
    final subtitle = '$role · $date · ${l10n.home_policy_count(policyCount)}';
    final colors = <Color>[
      theme.colorScheme.primaryContainer,
      theme.colorScheme.secondaryContainer,
      theme.colorScheme.tertiaryContainer,
    ];
    final color = colors[(client.name.hashCode & 0x7fffffff) % colors.length];
    final initials = client.name.trim().isEmpty
        ? ''
        : client.name.trim().substring(0, 1).toUpperCase();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: color,
          foregroundColor: theme.colorScheme.onSurface,
          child: Text(initials),
        ),
        title: Text(
          client.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleMedium,
        ),
        subtitle: Text(
          subtitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall,
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
