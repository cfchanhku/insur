/// Displays a non-sensitive audit event summary.
library;

// TODO(insur): Implement — see docs/IMPLEMENTATION_PLAN.md
// User-facing text must come from AppLocalizations.

import 'package:flutter/material.dart';
import '../models/audit_event.dart';

/// Reusable audit event list item.
class AuditEventTile extends StatelessWidget {
  /// Creates a tile for [event].
  const AuditEventTile({required this.event, super.key});

  /// Safe audit event summary to display.
  final AuditEvent event;

  @override
  Widget build(BuildContext context) {
    throw UnimplementedError('AuditEventTile.build');
  }
}
