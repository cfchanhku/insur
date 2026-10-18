/// Displays the current vault authentication status.
library;

// TODO(insur): Implement — see docs/IMPLEMENTATION_PLAN.md
// User-facing text must come from AppLocalizations.

import 'package:flutter/material.dart';

/// Authentication status presentation for auth screens.
class AuthStatusCard extends StatelessWidget {
  /// Creates an authentication status card.
  const AuthStatusCard({required this.isAuthenticated, super.key});

  /// Whether the vault is currently unlocked.
  final bool isAuthenticated;

  @override
  Widget build(BuildContext context) {
    throw UnimplementedError('AuthStatusCard.build');
  }
}
