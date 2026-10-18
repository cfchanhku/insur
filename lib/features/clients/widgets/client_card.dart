/// Presents a concise, privacy-aware client summary.
library;

// TODO(insur): Implement — see docs/IMPLEMENTATION_PLAN.md
// User-facing text must come from AppLocalizations.

import 'package:flutter/material.dart';
import '../models/client.dart';

/// Reusable client summary card.
class ClientCard extends StatelessWidget {
  /// Creates a client card for [client].
  const ClientCard({required this.client, super.key});

  /// Client displayed by the card.
  final Client client;

  @override
  Widget build(BuildContext context) {
    throw UnimplementedError('ClientCard.build');
  }
}
