/// Displays non-sensitive backup status and timestamp information.
library;

// TODO(insur): Implement — see docs/IMPLEMENTATION_PLAN.md
// User-facing text must come from AppLocalizations.

import 'package:flutter/material.dart';
import '../models/backup_record.dart';

/// Reusable backup metadata card.
class BackupStatusCard extends StatelessWidget {
  /// Creates a status card for [backup].
  const BackupStatusCard({required this.backup, super.key});

  /// Backup metadata displayed by this card.
  final BackupRecord backup;

  @override
  Widget build(BuildContext context) {
    throw UnimplementedError('BackupStatusCard.build');
  }
}
