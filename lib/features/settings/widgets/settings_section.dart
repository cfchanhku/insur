/// Groups related settings with a localized section heading.
library;

// TODO(insur): Implement — see docs/IMPLEMENTATION_PLAN.md
// User-facing text must come from AppLocalizations.

import 'package:flutter/material.dart';

/// Reusable settings section container.
class SettingsSection extends StatelessWidget {
  /// Creates a section with [title] and [children].
  const SettingsSection({
    required this.title,
    required this.children,
    super.key,
  });

  /// Localized section heading.
  final String title;

  /// Settings controls displayed in this section.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    throw UnimplementedError('SettingsSection.build');
  }
}
