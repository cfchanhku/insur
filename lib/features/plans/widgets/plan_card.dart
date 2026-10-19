/// Presents a summary of a plan and its localized category.
library;

// User-facing text must come from AppLocalizations.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../l10n/app_localizations.dart';
import '../models/plan.dart';
import '../models/plan_category.dart';

/// Reusable plan summary card.
class PlanCard extends StatelessWidget {
  /// Creates a plan card for [plan].
  const PlanCard({required this.plan, this.onTap, super.key});

  /// Plan displayed by the card.
  final Plan plan;

  /// Called when the plan card is selected.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final categoryLabel = switch (plan.category) {
      PlanCategory.life => l10n.plan_category_life,
      PlanCategory.ci => l10n.plan_category_ci,
      PlanCategory.hospital => l10n.plan_category_hospital,
      PlanCategory.accident => l10n.plan_category_accident,
      PlanCategory.savings => l10n.plan_category_savings,
      PlanCategory.other => l10n.plan_category_other,
    };
    final coverage = plan.coverageAmount == null
        ? '—'
        : NumberFormat.decimalPattern(
            Localizations.localeOf(context).toString(),
          ).format(plan.coverageAmount);
    final title = plan.planName.isEmpty ? categoryLabel : plan.planName;
    final icon = switch (plan.category) {
      PlanCategory.life => Icons.favorite_outline,
      PlanCategory.ci => Icons.health_and_safety_outlined,
      PlanCategory.hospital => Icons.local_hospital_outlined,
      PlanCategory.accident => Icons.warning_amber_outlined,
      PlanCategory.savings => Icons.savings_outlined,
      PlanCategory.other => Icons.more_horiz,
    };
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(l10n.plan_card_summary(categoryLabel, coverage)),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
