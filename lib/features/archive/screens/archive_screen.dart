/// Displays the archive route placeholder.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/app_scaffold.dart';

/// Archive navigation destination, pending archive management support.
class ArchiveScreen extends ConsumerWidget {
  /// Creates the archive placeholder screen.
  const ArchiveScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return AppScaffold(
      title: l10n.archive_title,
      currentNavIndex: 1,
      body: Center(child: Text(l10n.coming_soon)),
    );
  }
}
