/// A scaffold for routes whose feature screen is not implemented.
library;

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// Displays a localized recovery placeholder.
class PlaceholderScreen extends StatelessWidget {
  /// Creates the placeholder screen.
  const PlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.recovery_title)),
      body: Center(child: Text(l10n.coming_soon)),
    );
  }
}
