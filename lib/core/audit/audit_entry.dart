/// Represents one immutable event in the tamper-evident audit chain.
library;

// TODO(insur): Implement — see docs/IMPLEMENTATION_PLAN.md

/// Contains the non-sensitive metadata required to verify an audit event.
class AuditEntry {
  /// Creates an audit entry.
  const AuditEntry({
    required this.id,
    required this.occurredAt,
    required this.eventType,
    required this.previousHash,
    required this.entryHash,
  });

  /// Unique identifier for this audit entry.
  final String id;

  /// UTC time at which the event occurred.
  final DateTime occurredAt;

  /// Stable event code; must not contain user data.
  final String eventType;

  /// Hash of the preceding entry in the chain.
  final String previousHash;

  /// Hash authenticating this entry and its predecessor.
  final String entryHash;
}
