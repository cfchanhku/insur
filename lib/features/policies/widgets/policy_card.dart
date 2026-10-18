/// Presents a privacy-aware summary of one insurance policy.
library;

// TODO(insur): Implement — see docs/IMPLEMENTATION_PLAN.md
// User-facing text must come from AppLocalizations.

import 'package:flutter/material.dart';
import '../models/policy.dart';

/// Reusable policy summary card.
class PolicyCard extends StatelessWidget {
  /// Creates a policy card for [policy].
  const PolicyCard({required this.policy, super.key});

  /// Policy displayed by the card.
  final Policy policy;

  @override
  Widget build(BuildContext context) {
    throw UnimplementedError('PolicyCard.build');
  }
}
