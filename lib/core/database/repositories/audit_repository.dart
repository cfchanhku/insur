/// Defines read and verification operations for audit history.
library;

// TODO(insur): Implement — see docs/IMPLEMENTATION_PLAN.md

import '../../../features/audit/models/audit_event.dart';

/// Retrieves safe audit summaries and verifies the log chain.
class AuditRepository {
  /// Returns audit events in reverse chronological order.
  Future<List<AuditEvent>> findRecent({required int limit}) async {
    throw UnimplementedError('AuditRepository.findRecent');
  }

  /// Verifies integrity of the complete audit chain.
  Future<bool> verifyChain() async {
    throw UnimplementedError('AuditRepository.verifyChain');
  }
}
