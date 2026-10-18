/// Records and verifies tamper-evident audit events.
library;

// TODO(insur): Implement — see docs/IMPLEMENTATION_PLAN.md

import 'audit_entry.dart';

/// Appends audit events and verifies the hash chain.
class AuditLogger {
  /// Records a non-sensitive [entry] in the audit log.
  Future<void> record(AuditEntry entry) async {
    throw UnimplementedError('AuditLogger.record');
  }

  /// Appends an event identified by the non-sensitive [eventType].
  Future<AuditEntry> append({required String eventType}) async {
    throw UnimplementedError('AuditLogger.append');
  }

  /// Verifies the integrity of the complete audit chain.
  Future<bool> verifyChain() async {
    throw UnimplementedError('AuditLogger.verifyChain');
  }
}
