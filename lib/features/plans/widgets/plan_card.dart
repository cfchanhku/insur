/// Presents a summary of a plan and its localized category.
library;

// TODO(insur): Implement — see docs/IMPLEMENTATION_PLAN.md
// User-facing text must come from AppLocalizations.

import 'package:flutter/material.dart';
import '../models/plan.dart';

/// Reusable plan summary card.
class PlanCard extends StatelessWidget {
  /// Creates a plan card for [plan].
  const PlanCard({required this.plan, super.key});

  /// Plan displayed by the card.
  final Plan plan;

  @override
  Widget build(BuildContext context) {
    throw UnimplementedError('PlanCard.build');
  }
}
