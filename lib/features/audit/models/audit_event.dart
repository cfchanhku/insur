/// Describes a non-sensitive event displayed in the audit history.
library;

// TODO(insur): Implement — see docs/IMPLEMENTATION_PLAN.md

/// Safe event metadata for audit-log presentation.
class AuditEvent {
  /// Creates an audit event summary.
  const AuditEvent({
    required this.id,
    required this.eventType,
    required this.occurredAt,
  });

  /// UUID identifying the audit event.
  final String id;

  /// Stable event code that must not contain personal data.
  final String eventType;

  /// UTC time at which the event occurred.
  final DateTime occurredAt;
}
