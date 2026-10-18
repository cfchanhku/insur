/// Presents a concise summary of a plan rider.
library;

// TODO(insur): Implement — see docs/IMPLEMENTATION_PLAN.md
// User-facing text must come from AppLocalizations.

import 'package:flutter/material.dart';
import '../models/rider.dart';

/// Reusable rider summary card.
class RiderCard extends StatelessWidget {
  /// Creates a rider card for [rider].
  const RiderCard({required this.rider, super.key});

  /// Rider displayed by the card.
  final Rider rider;

  @override
  Widget build(BuildContext context) {
    throw UnimplementedError('RiderCard.build');
  }
}
