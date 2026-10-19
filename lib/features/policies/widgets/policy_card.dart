/// Presents a privacy-aware summary of one insurance policy.
library;

// User-facing text must come from AppLocalizations.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../l10n/app_localizations.dart';
import '../models/policy.dart';
import '../models/policy_status.dart';

/// Reusable policy summary card.
class PolicyCard extends StatelessWidget {
  /// Creates a policy card for [policy].
  const PolicyCard({required this.policy, this.onTap, super.key});

  /// Policy displayed by the card.
  final Policy policy;

  /// Called when the policy card is selected.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final status = switch (policy.status) {
      PolicyStatus.active => l10n.policy_status_active,
      PolicyStatus.lapsed => l10n.policy_status_lapsed,
      PolicyStatus.surrendered => l10n.policy_status_surrendered,
    };
    final locale = Localizations.localeOf(context).toString();
    final effectiveDate = DateFormat.yMd(locale).format(policy.effectiveDate);
    return Card(
      child: ListTile(
        leading: const Icon(Icons.description_outlined),
        title: Text(
          policy.policyNo,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: Text(
          l10n.policy_card_summary(policy.company, effectiveDate, status),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
